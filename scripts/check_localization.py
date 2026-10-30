#!/usr/bin/env python3
"""Prueft, dass jeder im App-Code verwendete Lokalisierungsschluessel
(``String(localized: "...")``) auch in ``Resources/Localizable.xcstrings``
als Eintrag vorhanden ist.

Nutzung:
    python scripts/check_localization.py

Exit-Code 0 = alle verwendeten Schluessel gefunden, 1 = mindestens ein
Schluessel fehlt im String Catalog.

Teil von Block B1 P4 (Navigation + String Catalogs). Durchsucht bewusst nur
den echten App-Quellcode (``App/``, ``DesignSystem/``, ``Illustration/``), nicht ``Tests/`` oder
``scripts/`` selbst - sonst wuerde z. B. das Regex-Muster in
``Tests/Unit/LocalizationCoverageTests.swift`` als (falscher) Schluessel-Treffer
gewertet.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIRS = ["App", "DesignSystem", "Illustration", "Games"]
CATALOG_PATH = REPO_ROOT / "Resources" / "Localizable.xcstrings"

# Matcht String(localized: "schluessel.name" ...). Der Schluessel steht immer
# als erstes Argument in Anfuehrungszeichen, weitere Parameter
# (defaultValue:, comment: usw.) sind fuer die Pruefung irrelevant.
KEY_PATTERN = re.compile(r'String\(localized:\s*"([^"]+)"')


def find_swift_files(root: Path) -> list[Path]:
    return sorted(root.rglob("*.swift"))


def used_keys() -> dict[str, list[Path]]:
    """Liefert jeden verwendeten Schluessel zusammen mit den Dateien, in denen er vorkommt."""
    usages: dict[str, list[Path]] = {}
    for dir_name in SOURCE_DIRS:
        source_dir = REPO_ROOT / dir_name
        if not source_dir.exists():
            continue
        for swift_file in find_swift_files(source_dir):
            text = swift_file.read_text(encoding="utf-8")
            for match in KEY_PATTERN.finditer(text):
                usages.setdefault(match.group(1), []).append(swift_file)
    return usages


def catalog_keys() -> set[str]:
    if not CATALOG_PATH.exists():
        print(f"FEHLER: String Catalog nicht gefunden: {CATALOG_PATH}")
        return set()
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    return set(catalog.get("strings", {}).keys())


def main() -> int:
    usages = used_keys()
    available = catalog_keys()
    missing = sorted(set(usages) - available)

    if missing:
        print("FEHLER: Lokalisierungsschlüssel fehlen in Localizable.xcstrings:")
        for key in missing:
            files = ", ".join(str(path.relative_to(REPO_ROOT)) for path in usages[key])
            print(f"  - {key}  (verwendet in: {files})")
        return 1

    print(f"OK: {len(usages)} verwendete Schlüssel, alle in Localizable.xcstrings vorhanden.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
