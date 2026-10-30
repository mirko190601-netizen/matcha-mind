#!/usr/bin/env python3
"""Prueft, dass sicherheitskritische Testzugaenge (UI-Test-Personas,
simuliertes Datum - siehe MASTER-PROMPT.md Abschnitt 7.5 "Testzugaenge nur
in DEBUG") ausschliesslich innerhalb von ``#if DEBUG``-Bloecken verwendet
werden, damit sie im Release-Build nicht kompiliert werden.

Heuristik (bewusst einfach gehalten, kein echter Swift-Preprocessor): pro
Datei wird die Verschachtelungstiefe von ``#if``/``#endif`` mitgezaehlt.
Jede Fundstelle einer sicherheitskritischen Zeichenkette gilt als
abgesichert, wenn sie irgendwo zwischen einem ``#if DEBUG`` und seinem
passenden ``#endif`` liegt - unabhaengig davon, ob sie dort zufaellig in
einem ``#else``-Zweig steht (das deckt die in diesem Projekt verwendeten,
nicht verschachtelten ``#if DEBUG ... #endif``-Bloecke zuverlaessig ab;
komplexere Faelle mit ``#elseif``/``#else``-Umkehrungen muesste ein
richtiger Preprocessor pruefen).

Nutzung:
    python scripts/check_debug_only.py

Exit-Code 0 = alle Fundstellen abgesichert, 1 = mindestens eine Fundstelle
liegt ausserhalb von #if DEBUG.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Nur der echte App-Quellcode, nicht Tests/ oder scripts/ selbst - sonst
# waere z. B. diese Docstring-Erwaehnung der Muster ein falscher Treffer.
SOURCE_DIRS = ["App", "DesignSystem"]

SENSITIVE_PATTERNS = [
    re.compile(r"-uitest-persona"),
    re.compile(r"-uitest-date"),
    re.compile(r"ProcessInfo\.processInfo\.arguments"),
]

IF_RE = re.compile(r"^\s*#if\s+(.+?)\s*$")
ENDIF_RE = re.compile(r"^\s*#endif\b")


def is_debug_condition(condition: str) -> bool:
    return condition.strip() == "DEBUG"


def find_swift_files(root: Path) -> list[Path]:
    return sorted(root.rglob("*.swift"))


def check_file(path: Path) -> list[str]:
    """Liefert eine Fehlermeldung pro ungeschuetzter Fundstelle in `path`."""
    errors: list[str] = []
    # Stack: ein Eintrag pro offenem "#if", True = dieser Block wurde mit
    # "#if DEBUG" eroeffnet.
    debug_block_stack: list[bool] = []

    lines = path.read_text(encoding="utf-8").splitlines()
    for line_number, line in enumerate(lines, start=1):
        if_match = IF_RE.match(line)
        if if_match:
            debug_block_stack.append(is_debug_condition(if_match.group(1)))
            continue
        if ENDIF_RE.match(line):
            if debug_block_stack:
                debug_block_stack.pop()
            continue

        if any(pattern.search(line) for pattern in SENSITIVE_PATTERNS):
            if not any(debug_block_stack):
                errors.append(
                    f"{path.relative_to(REPO_ROOT)}:{line_number}: "
                    f"Testzugang ausserhalb von #if DEBUG gefunden: {line.strip()}"
                )
    return errors


def main() -> int:
    all_errors: list[str] = []
    for dir_name in SOURCE_DIRS:
        source_dir = REPO_ROOT / dir_name
        if not source_dir.exists():
            continue
        for swift_file in find_swift_files(source_dir):
            all_errors.extend(check_file(swift_file))

    if all_errors:
        print("FEHLER: Testzugaenge ausserhalb von #if DEBUG gefunden:")
        for error in all_errors:
            print(f"  - {error}")
        return 1

    print(
        "OK: alle Testzugaenge (-uitest-persona, -uitest-date, "
        "ProcessInfo.processInfo.arguments) liegen innerhalb von #if DEBUG."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
