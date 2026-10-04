#!/usr/bin/env python3
"""look.py [label]: play the title and the start of Block1 in the Game tab and measure the 3D image
(the HUD and minimap corners left out): mean and median brightness (0-255), and the share of
pixels crushed below 10 or clipped above 245. For tuning the shared look (block.py's POST and
ENVIRONMENT) by numbers before the eye."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pkgen import mcp
from PIL import Image


def stats(path, regions):
    # Regions are in the game's 1280x720; the PNG is what the Game tab drew, which is smaller
    # when the tab is (pie_screenshot reports the scale), so they scale to the image.
    im = Image.open(path).convert('L')
    sx, sy = im.width / 1280.0, im.height / 720.0
    px = []
    for (x0, y0, x1, y1) in regions:
        px.extend(im.crop((round(x0 * sx), round(y0 * sy), round(x1 * sx), round(y1 * sy))).getdata())
    px.sort()
    n = len(px)
    return dict(mean=round(sum(px) / n, 1), median=px[n // 2],
                crushed=round(100.0 * sum(1 for v in px if v < 10) / n, 1),
                clipped=round(100.0 * sum(1 for v in px if v > 245) / n, 1))


def key(k, at=0.05):
    return [{"at": at, "key": k}, {"at": at + 0.1, "key": k, "down": False}]


label = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    mcp("pie_stop", {})
except BaseException:
    pass
mcp("pie_start", {})
title = mcp("pie_run", {"duration": 1.5, "screenshots": [1.4]})["screenshots"][0]["path"]
mcp("pie_run", {"duration": 0.5, "input": key("Return")})
block = mcp("pie_run", {"duration": 2.0, "input": [{"at": 0, "key": "W"}, {"at": 1.9, "key": "W", "down": False}],
                        "screenshots": [1.9]})["screenshots"][0]["path"]
mcp("pie_stop", {})
# Title: the scene on either side of the menu. Block: the view below the HUD row.
print(label, "title", stats(title, [(0, 0, 440, 720), (840, 0, 1280, 720)]), title)
print(label, "block", stats(block, [(0, 240, 1280, 720)]), block)
