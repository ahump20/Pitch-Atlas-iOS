#!/usr/bin/env python3
"""Name the screenshot tour's attachments and shrink them for review.

usage: export-shots.py <exported-attachments-dir> <out-dir> [--full]

Reads the manifest that `xcrun xcresulttool export attachments` writes and
copies each screenshot out under the name the test gave it (atlas-01, ...).
By default each is a 2x JPEG (880x1912, the size of the site captures) for
side-by-side review; --full keeps the
original PNG (1320x2868 on the 6.9-inch iPhone, the App Store size).
"""
import json
import os
import re
import shutil
import subprocess
import sys

src, out = sys.argv[1], sys.argv[2]
full = "--full" in sys.argv[3:]
os.makedirs(out, exist_ok=True)

manifest_path = os.path.join(src, "manifest.json")
pairs = []
if os.path.exists(manifest_path):
    for test in json.load(open(manifest_path)):
        for attachment in test.get("attachments", []):
            exported = attachment["exportedFileName"]
            name = attachment.get("suggestedHumanReadableName") or exported
            match = re.match(r"^(.*?)_\d+_[0-9A-Fa-f-]{36}\.\w+$", name)
            pairs.append((exported, match.group(1) if match else os.path.splitext(name)[0]))
else:
    pairs = [(f, os.path.splitext(f)[0]) for f in sorted(os.listdir(src)) if f.lower().endswith((".png", ".jpg", ".jpeg"))]

for exported, base in pairs:
    source = os.path.join(src, exported)
    if full:
        shutil.copyfile(source, os.path.join(out, base + ".png"))
    else:
        subprocess.run(
            ["sips", "-s", "format", "jpeg", "-s", "formatOptions", "82", "-Z", "1912", source, "--out", os.path.join(out, base + ".jpg")],
            check=True, capture_output=True,
        )
print(f"{len(pairs)} screenshots -> {out}")
