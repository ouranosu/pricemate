"""Compose the App Store preview video from frames recorded by
test/app_preview_capture_test.dart.

    flutter test test/app_preview_capture_test.dart --dart-define=STORE_CAPTURE=true
    python scripts/make_app_preview.py

iPad 13" version: add --dart-define=IPAD=true to the test, then pass `ipad`.

Needs Pillow and imageio-ffmpeg (pip install pillow imageio-ffmpeg).
Output: 886x1920, 30fps, H.264 High, AAC silent stereo (App Store Connect
rejects previews without an audio track).
"""
import json
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
IPAD = sys.argv[1:] == ["ipad"]
SRC = ROOT / ("build/app_preview_ipad" if IPAD else "build/app_preview")
W, H = (1200, 1600) if IPAD else (886, 1920)
OUT = ROOT / f"deliverables/app-store/preview/PriceMate-preview-{'ipad' if IPAD else 'iphone'}-{W}x{H}.mp4"
DARK, LIGHT = (21, 63, 52), (245, 240, 223)
CREAM, GREEN = (255, 251, 238), (21, 63, 52)
BOLD, REG = "C:/Windows/Fonts/YuGothB.ttc", "C:/Windows/Fonts/YuGothM.ttc"
INTRO, OUTRO, FADE = 1.6, 2.6, 0.35

meta = json.loads((SRC / "events.json").read_text(encoding="utf-8"))
# App screen sits below the caption block (top 440px) with a 70px bottom margin.
SH = H - 440 - 70 if IPAD else round(H * 0.72)
SW = round(SH * meta["width"] / meta["height"])
SCALE = SW / meta["width"]  # logical app px -> canvas px
SX, SY = (W - SW) // 2, H - SH - 70
FPS, N = meta["fps"], meta["frames"]
scenes = [e for e in meta["events"] if "scene" in e]
taps = [e for e in meta["events"] if "tap" in e]


def font(path, size):
    return ImageFont.truetype(path, size)


def chrome(i, s):
    """Background, caption and device frame for scene i (screen pasted later)."""
    dark = i % 2 == 0
    bg, fg = (DARK, CREAM) if dark else (LIGHT, GREEN)
    im = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(im)
    blob = (36, 86, 71) if dark else (228, 230, 206)
    d.ellipse((W - 520, H - 760, W + 380, H + 140), fill=blob)
    if IPAD:
        d.ellipse((-300, H - 520, 300, H + 80), fill=blob)
    d.text((60, 70), "PriceMate", font=font(BOLD, 34), fill=fg)
    d.text((W - 60, 74), f"0{i + 1} / 0{len(scenes)}", font=font(REG, 26), fill=fg, anchor="ra")
    d.multiline_text((60, 150), s["title"], font=font(BOLD, 70), fill=fg, spacing=18)
    d.text((62, 360), s["sub"], font=font(REG, 29), fill=fg)
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle((SX, SY + 26, SX + SW, SY + SH + 26), 60, fill=110)
    im.paste((0, 0, 0), mask=shadow.filter(ImageFilter.GaussianBlur(28)))
    d.rounded_rectangle((SX - 14, SY - 14, SX + SW + 14, SY + SH + 14), 58, fill=(32, 51, 45))
    return im


def title_card(lines):
    im = Image.new("RGB", (W, H), DARK)
    icon = Image.open(ROOT / "assets/icon/icon.png").convert("RGBA").resize((260, 260), Image.LANCZOS)
    m = Image.new("L", icon.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, 259, 259), 58, fill=255)
    top = H // 2 - 320
    im.paste(icon, ((W - 260) // 2, top), m)
    d = ImageDraw.Draw(im)
    d.text((W // 2, top + 320), "PriceMate", font=font(BOLD, 84), fill=CREAM, anchor="ma")
    for k, (text, size) in enumerate(lines):
        d.text((W // 2, top + 460 + k * 70), text, font=font(REG, size), fill=CREAM, anchor="ma")
    return im


screen_mask = Image.new("L", (SW, SH), 0)
ImageDraw.Draw(screen_mask).rounded_rectangle((0, 0, SW - 1, SH - 1), 46, fill=255)
chromes = [chrome(i, s) for i, s in enumerate(scenes)]
starts = [s["scene"] for s in scenes]
intro = title_card([("家族で共有する、買い物価格メモ", 36)])
outro = title_card([("「いくらなら買う？」を、家族でひとつに。", 33), ("無料ではじめよう", 30)])


def ease(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def app_frame(n):
    scene = max(i for i, s in enumerate(starts) if s <= n)
    t = (n - starts[scene]) / (FADE * FPS)
    base = chromes[scene] if scene == 0 or t >= 1 else Image.blend(chromes[scene - 1], chromes[scene], ease(t))
    im = base.copy()
    shot = Image.open(SRC / f"frames/{n:05d}.png").convert("RGB").resize((SW, SH), Image.LANCZOS)
    im.paste(shot, (SX, SY), screen_mask)
    for tap in taps:  # touch marker: dot fades in, ring expands
        age = (n - tap["tap"]) / FPS
        if not 0 <= age < 0.9:
            continue
        x = SX + tap["x"] * SCALE
        y = SY + tap["y"] * SCALE
        ov = Image.new("RGBA", (W, H))
        d = ImageDraw.Draw(ov)
        a = ease(age / 0.15) * (1 - ease((age - 0.5) / 0.4))
        r = 34
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, int(150 * a)), outline=(21, 63, 52, int(200 * a)), width=4)
        if age > 0.25:
            rr = r + 60 * ease((age - 0.25) / 0.5)
            d.ellipse((x - rr, y - rr, x + rr, y + rr), outline=(21, 63, 52, int(160 * a)), width=3)
        im = Image.alpha_composite(im.convert("RGBA"), ov).convert("RGB")
    return im


def frames():
    first = app_frame(0)
    for k in range(int(INTRO * FPS)):
        t = (k - (INTRO - FADE) * FPS) / (FADE * FPS)
        yield intro if t < 0 else Image.blend(intro, first, ease(t))
    for n in range(N):
        yield app_frame(n)
    last = app_frame(N - 1)
    for k in range(int(OUTRO * FPS)):
        yield Image.blend(last, outro, ease(k / (FADE * FPS)))


OUT.parent.mkdir(parents=True, exist_ok=True)
total = int(INTRO * FPS) + N + int(OUTRO * FPS)
cmd = [
    imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error",
    "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
    "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000",
    "-c:v", "libx264", "-profile:v", "high", "-level", "4.0", "-pix_fmt", "yuv420p",
    "-b:v", "10M", "-maxrate", "12M", "-bufsize", "12M",
    "-c:a", "aac", "-b:a", "256k", "-shortest", "-movflags", "+faststart", str(OUT),
]
proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
for k, im in enumerate(frames()):
    proc.stdin.write(im.tobytes())
    if k in (int(INTRO * FPS) + 60, total - 20):
        im.save(OUT.with_name(f"check-{k:04d}.jpg"), quality=85)
proc.stdin.close()
assert proc.wait() == 0
seconds = total / FPS
assert 15 <= seconds <= 30, f"App previews must be 15-30s, got {seconds:.1f}s"
print(f"{OUT} {seconds:.1f}s {total} frames")
