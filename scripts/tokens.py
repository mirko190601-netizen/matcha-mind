#!/usr/bin/env python3
"""Generiert Design-System-Dateien aus design/designsystem-tokens.json.

Erzeugt:
  - DesignSystem/Colors.xcassets  (ein Colorset je Farbtoken, Any + Dark Appearance)
  - DesignSystem/Tokens.swift     (enum Space, enum Radius, enum Size)

Das Skript ist idempotent: beide Ziele werden bei jedem Lauf vollstaendig
neu geschrieben (nicht gepatcht). Nur Python-Standardbibliothek, keine
zusaetzlichen Abhaengigkeiten.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TOKENS_JSON = REPO_ROOT / "design" / "designsystem-tokens.json"
COLORS_XCASSETS = REPO_ROOT / "DesignSystem" / "Colors.xcassets"
TOKENS_SWIFT = REPO_ROOT / "DesignSystem" / "Tokens.swift"


def load_tokens(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def kebab_to_camel(name: str) -> str:
    """'space-1' -> 'space1', 'radius-sm' -> 'radiusSm', 'touch-min' -> 'touchMin'."""
    parts = name.replace("_", "-").split("-")
    parts = [p for p in parts if p]
    if not parts:
        return name
    first, rest = parts[0], parts[1:]
    return first + "".join(p[:1].upper() + p[1:] for p in rest)


def px_to_float(value: str) -> float:
    """'16px' -> 16.0, '999px' -> 999.0."""
    value = value.strip()
    if value.endswith("px"):
        value = value[:-2]
    return float(value)


def hex_to_srgb_components(hex_str: str) -> tuple[float, float, float, float]:
    """'#rrggbb' oder '#rrggbbaa' -> (r, g, b, a) als Floats 0..1."""
    hex_str = hex_str.strip().lstrip("#")
    if len(hex_str) == 6:
        r, g, b = hex_str[0:2], hex_str[2:4], hex_str[4:6]
        a = "ff"
    elif len(hex_str) == 8:
        r, g, b, a = hex_str[0:2], hex_str[2:4], hex_str[4:6], hex_str[6:8]
    else:
        raise ValueError(f"Unerwartetes Hex-Farbformat: {hex_str!r}")
    return (
        int(r, 16) / 255.0,
        int(g, 16) / 255.0,
        int(b, 16) / 255.0,
        int(a, 16) / 255.0,
    )


def fmt_component(value: float) -> str:
    return f"{value:.3f}"


def colorset_contents(light_hex: str, dark_hex: str) -> dict:
    lr, lg, lb, la = hex_to_srgb_components(light_hex)
    dr, dg, db, da = hex_to_srgb_components(dark_hex)
    return {
        "colors": [
            {
                "color": {
                    "color-space": "srgb",
                    "components": {
                        "red": fmt_component(lr),
                        "green": fmt_component(lg),
                        "blue": fmt_component(lb),
                        "alpha": fmt_component(la),
                    },
                },
                "idiom": "universal",
            },
            {
                "appearances": [{"appearance": "luminosity", "value": "dark"}],
                "color": {
                    "color-space": "srgb",
                    "components": {
                        "red": fmt_component(dr),
                        "green": fmt_component(dg),
                        "blue": fmt_component(db),
                        "alpha": fmt_component(da),
                    },
                },
                "idiom": "universal",
            },
        ],
        "info": {"author": "xcode", "version": 1},
    }


def generate_colors_xcassets(color_tokens: list[dict], out_dir: Path) -> None:
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    root_contents = {"info": {"author": "xcode", "version": 1}}
    (out_dir / "Contents.json").write_text(
        json.dumps(root_contents, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    for token in color_tokens:
        name = token["name"]
        light_hex = token["value"]["light"]
        dark_hex = token["value"]["dark"]
        colorset_dir = out_dir / f"{name}.colorset"
        colorset_dir.mkdir(parents=True, exist_ok=True)
        contents = colorset_contents(light_hex, dark_hex)
        (colorset_dir / "Contents.json").write_text(
            json.dumps(contents, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )


def build_enum(enum_name: str, tokens: list[dict]) -> str:
    lines = [f"public enum {enum_name} {{"]
    for token in tokens:
        swift_name = kebab_to_camel(token["name"])
        value = px_to_float(token["value"])
        usage = token.get("usage", "").replace("\n", " ")
        if usage:
            lines.append(f"    /// {usage}")
        value_literal = f"{value:g}"
        lines.append(f"    public static let {swift_name}: CGFloat = {value_literal}")
    lines.append("}")
    return "\n".join(lines)


def generate_tokens_swift(data: dict, out_path: Path) -> None:
    spacing_tokens = data["spacing"]["tokens"]
    radius_tokens = data["radius"]["tokens"]
    size_tokens = data["size"]["tokens"]

    header = (
        "// Tokens.swift\n"
        "// Automatisch generiert von scripts/tokens.py aus design/designsystem-tokens.json.\n"
        "// NICHT MANUELL BEARBEITEN - Aenderungen werden beim naechsten Lauf ueberschrieben.\n"
        "\n"
        "import CoreGraphics\n"
        "\n"
    )

    body = "\n\n".join(
        [
            build_enum("Space", spacing_tokens),
            build_enum("Radius", radius_tokens),
            build_enum("Size", size_tokens),
        ]
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(header + body + "\n", encoding="utf-8")


def main() -> None:
    data = load_tokens(TOKENS_JSON)

    color_tokens = data["color"]["tokens"]
    generate_colors_xcassets(color_tokens, COLORS_XCASSETS)

    generate_tokens_swift(data, TOKENS_SWIFT)

    print(f"OK: {len(color_tokens)} Farb-Tokens -> {COLORS_XCASSETS}")
    print(f"OK: Tokens.swift -> {TOKENS_SWIFT}")


if __name__ == "__main__":
    main()
