#!/usr/bin/env python3
"""Validierungstest fuer scripts/tokens.py (reines Python, kein XCTest).

Prueft:
  1. Das Skript laeuft ohne Fehler (Exit-Code 0).
  2. DesignSystem/Tokens.swift enthaelt enum Space, enum Radius, enum Size.
  3. DesignSystem/Colors.xcassets enthaelt fuer jede Farbe aus dem JSON
     einen passenden <name>.colorset-Ordner.

Nur Python-Standardbibliothek.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TOKENS_JSON = REPO_ROOT / "design" / "designsystem-tokens.json"
TOKENS_SWIFT = REPO_ROOT / "DesignSystem" / "Tokens.swift"
COLORS_XCASSETS = REPO_ROOT / "DesignSystem" / "Colors.xcassets"
SCRIPT = REPO_ROOT / "scripts" / "tokens.py"


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)
    print(f"OK: {message}")


def test_script_runs() -> None:
    result = subprocess.run(
        [sys.executable, str(SCRIPT)],
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
    )
    check(result.returncode == 0, f"Skript laeuft ohne Fehler (Exit {result.returncode})")
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr)


def test_tokens_swift_contains_enums() -> None:
    content = TOKENS_SWIFT.read_text(encoding="utf-8")
    check("enum Space" in content, "Tokens.swift enthaelt 'enum Space'")
    check("enum Radius" in content, "Tokens.swift enthaelt 'enum Radius'")
    check("enum Size" in content, "Tokens.swift enthaelt 'enum Size'")


def test_colors_xcassets_has_all_tokens() -> None:
    data = json.loads(TOKENS_JSON.read_text(encoding="utf-8"))
    color_tokens = data["color"]["tokens"]
    check(COLORS_XCASSETS.exists(), "Colors.xcassets existiert")
    for token in color_tokens:
        name = token["name"]
        colorset_dir = COLORS_XCASSETS / f"{name}.colorset"
        check(colorset_dir.is_dir(), f"Colorset-Ordner vorhanden: {name}.colorset")
        contents_file = colorset_dir / "Contents.json"
        check(contents_file.is_file(), f"Contents.json vorhanden: {name}.colorset")


def main() -> None:
    test_script_runs()
    test_tokens_swift_contains_enums()
    test_colors_xcassets_has_all_tokens()
    print("\nAlle Tests gruen.")


if __name__ == "__main__":
    main()
