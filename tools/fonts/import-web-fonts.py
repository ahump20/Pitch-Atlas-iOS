#!/usr/bin/env python3
"""Import the fourteen Latin font faces pitch-atlas.com loads into the app bundle.

The web loads @fontsource packages (versions pinned in the web repo's
package-lock.json). This downloads the same woff2 files from jsDelivr,
decompresses each to TTF with fontTools, names the file after its PostScript
name, and prints a sha256 table for Resources/Fonts/LICENSES.md.

Usage: python3 tools/fonts/import-web-fonts.py PitchAtlas/Resources/Fonts
Needs: fonttools and brotli (pip install fonttools brotli).
"""
import hashlib
import io
import sys
import urllib.request
from pathlib import Path

from fontTools.ttLib import TTFont

PACKAGES = {
    "newsreader": "5.2.10",
    "hanken-grotesk": "5.2.8",
    "martian-mono": "5.2.7",
    "anton": "5.2.7",
}

# (package, weight, style) — the faces the web imports in src/.
FACES = [
    ("newsreader", 400, "normal"), ("newsreader", 400, "italic"), ("newsreader", 500, "normal"),
    ("newsreader", 600, "normal"), ("newsreader", 600, "italic"),
    ("hanken-grotesk", 400, "normal"), ("hanken-grotesk", 400, "italic"), ("hanken-grotesk", 500, "normal"),
    ("hanken-grotesk", 600, "normal"), ("hanken-grotesk", 700, "normal"),
    ("martian-mono", 400, "normal"), ("martian-mono", 500, "normal"), ("martian-mono", 600, "normal"),
    ("anton", 400, "normal"),
]


def main(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    rows = []
    for pkg, weight, style in FACES:
        ver = PACKAGES[pkg]
        url = f"https://cdn.jsdelivr.net/npm/@fontsource/{pkg}@{ver}/files/{pkg}-latin-{weight}-{style}.woff2"
        with urllib.request.urlopen(url, timeout=60) as resp:
            data = resp.read()
        font = TTFont(io.BytesIO(data), recalcTimestamp=False)
        font.flavor = None
        ps_name = font["name"].getDebugName(6)
        if not ps_name:
            raise SystemExit(f"no PostScript name in {url}")
        target = out_dir / f"{ps_name}.ttf"
        font.save(target)
        digest = hashlib.sha256(target.read_bytes()).hexdigest()
        rows.append((pkg, ver, weight, style, ps_name, target.name, digest))
        print(f"{ps_name:40} {target.name}")
    print()
    print("| Package | Version | Weight | Style | PostScript name | sha256 |")
    print("|---|---|---|---|---|---|")
    for pkg, ver, weight, style, ps, _, digest in rows:
        print(f"| @fontsource/{pkg} | {ver} | {weight} | {style} | `{ps}` | `{digest[:16]}…` |")


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "PitchAtlas/Resources/Fonts"))
