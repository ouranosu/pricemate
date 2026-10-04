"""Run with: python -m unittest discover -s scripts -p 'test_*.py'."""
import plistlib
import tempfile
import unittest
import zipfile
from pathlib import Path

from verify_ios_localizations import check, verify


class LocalizationVerificationTests(unittest.TestCase):
    def setUp(self):
        root = Path(__file__).resolve().parents[1] / "ios/Runner"
        self.files = {name: (root / name).read_bytes() for name in (
            "Info.plist", "ja.lproj/InfoPlist.strings", "en.lproj/InfoPlist.strings")}
        info = plistlib.loads(self.files["Info.plist"])
        info["CFBundleDevelopmentRegion"] = "en"
        self.files["Info.plist"] = plistlib.dumps(info, fmt=plistlib.FMT_BINARY)
        for language in ("ja", "en"):
            name = f"{language}.lproj/InfoPlist.strings"
            self.files[name] = plistlib.dumps(plistlib.loads(self.files[name]),
                                            fmt=plistlib.FMT_BINARY)

    def test_binary_ipa_and_archive_with_spaces(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            ipa = root / "Price Mate.ipa"
            archive = root / "Runner.xcarchive"
            app = archive / "Products/Applications/Runner.app"
            with zipfile.ZipFile(ipa, "w") as output:
                for name, data in self.files.items():
                    output.writestr(f"Payload/Runner.app/{name}", data)
                    target = app / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(data)
            for path in (ipa, archive, app):
                self.assertEqual(check(path)["CFBundleDevelopmentRegion"], "en")

    def test_missing_japanese_resource_fails(self):
        del self.files["ja.lproj/InfoPlist.strings"]
        with self.assertRaises(KeyError):
            verify(self.files.__getitem__)

    def test_missing_language_declaration_fails(self):
        info = plistlib.loads(self.files["Info.plist"])
        info["CFBundleLocalizations"] = ["en"]
        self.files["Info.plist"] = plistlib.dumps(info)
        with self.assertRaisesRegex(ValueError, "CFBundleLocalizations"):
            verify(self.files.__getitem__)

    def test_empty_permission_fails(self):
        name = "en.lproj/InfoPlist.strings"
        strings = plistlib.loads(self.files[name])
        strings["NSCameraUsageDescription"] = ""
        self.files[name] = plistlib.dumps(strings)
        with self.assertRaisesRegex(ValueError, "NSCameraUsageDescription"):
            verify(self.files.__getitem__)

    def test_unresolved_archive_region_fails(self):
        info = plistlib.loads(self.files["Info.plist"])
        info["CFBundleDevelopmentRegion"] = "$(DEVELOPMENT_LANGUAGE)"
        self.files["Info.plist"] = plistlib.dumps(info)
        with self.assertRaisesRegex(ValueError, "unresolved"):
            verify(self.files.__getitem__)

    def test_empty_ipa_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "empty.ipa"
            with zipfile.ZipFile(path, "w"):
                pass
            with self.assertRaisesRegex(ValueError, "exactly one"):
                check(path)
