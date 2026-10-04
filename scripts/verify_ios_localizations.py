"""Validate source resources, a built .app, .xcarchive, or .ipa (stdlib only)."""
import argparse
import plistlib
import sys
import zipfile
from pathlib import Path

LANGUAGES = {"ja", "en"}
REQUIRED_KEYS = {
    "CFBundleDisplayName",
    "NSCameraUsageDescription",
    "NSPhotoLibraryUsageDescription",
    "NSUserTrackingUsageDescription",
}


def verify(read, source=False):
    info = plistlib.loads(read("Info.plist"))
    if set(info.get("CFBundleLocalizations", [])) != LANGUAGES:
        raise ValueError("CFBundleLocalizations must contain ja and en")
    region = info.get("CFBundleDevelopmentRegion")
    if region not in (LANGUAGES | ({"$(DEVELOPMENT_LANGUAGE)"} if source else set())):
        raise ValueError(f"Invalid or unresolved development region: {region!r}")
    for language in sorted(LANGUAGES):
        # Xcode may compile XML strings resources to binary plists; both work.
        strings = plistlib.loads(read(f"{language}.lproj/InfoPlist.strings"))
        for key in REQUIRED_KEYS:
            if not isinstance(strings.get(key), str) or not strings[key].strip():
                raise ValueError(f"{language}: missing or empty {key}")
        expected = "プライスメイト" if language == "ja" else "PriceMate"
        if strings["CFBundleDisplayName"] != expected:
            raise ValueError(f"{language}: unexpected localized display name")
    return info


def check(path, source=False):
    if path.suffix == ".ipa":
        with zipfile.ZipFile(path) as archive:
            roots = [n.removesuffix("Info.plist") for n in archive.namelist()
                     if n.startswith("Payload/") and n.endswith(".app/Info.plist")
                     and n.count("/") == 2]
            if len(roots) != 1:
                raise ValueError("Expected exactly one top-level app in IPA")
            return verify(lambda name: archive.read(roots[0] + name))
    if path.suffix == ".xcarchive":
        apps = list((path / "Products/Applications").glob("*.app"))
        if len(apps) != 1:
            raise ValueError("Expected exactly one app in archive")
        path = apps[0]
    return verify(lambda name: (path / name).read_bytes(), source)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path)
    parser.add_argument("--source", action="store_true",
                        help="Validate ios/Runner before build (allows Xcode variable)")
    args = parser.parse_args()
    try:
        info = check(args.path, args.source)
    except (OSError, ValueError, KeyError, zipfile.BadZipFile, plistlib.InvalidFileException) as error:
        print(f"error: iOS localization verification failed: {error}", file=sys.stderr)
        return 1
    print(f"PASS iOS localizations: ja, en; localized names and permissions present; "
          f"version={info.get('CFBundleShortVersionString', '?')} "
          f"build={info.get('CFBundleVersion', '?')}; {args.path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
