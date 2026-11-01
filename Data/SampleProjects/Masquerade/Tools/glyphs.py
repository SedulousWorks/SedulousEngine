#!/usr/bin/env python3
"""glyphs.py: the pad's buttons as pictures for the game's prompts, drawn here (no third-party art)
in Roboto (Data/Engine/Fonts, Apache 2.0) and imported through the editor's MCP as textures in
UI/Glyphs, one per button the controls bind. MasqueradeSheet.css draws a prompt's glyph by its
binding (`prompt[binding="pad-south"]`, the token foundation.input names the button by), filled by
importscripts.py from `{{Texture:PadSouth}}`; a key stays a keycap of its own name in text. Also
the ring a decal draws on the floor under your own guest (YouRing, maps.py).

  Tools/glyphs.py          draws them into Tools/generated/glyphs and imports them
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp

ROBOTO = os.path.normpath(os.path.join(HERE, "../../../Engine/Fonts/roboto/Roboto-Bold.ttf"))
OUT = os.path.join(HERE, "generated", "glyphs")
SIZE = 96          # drawn at four times, then reduced, for smooth edges
SCALE = 4
INK = (16, 22, 44)  # the night blue the cards are, so a glyph reads as part of them

# name: (shape, fill, label). The face buttons in the colours pads print them in.
GLYPHS = {
    "PadSouth": ("circle", (88, 178, 72), "A"),
    "PadEast": ("circle", (214, 72, 64), "B"),
    "PadWest": ("circle", (64, 120, 214), "X"),
    "PadNorth": ("circle", (232, 196, 64), "Y"),
    "PadLB": ("bumper", (200, 204, 216), "LB"),
    "PadRB": ("bumper", (200, 204, 216), "RB"),
    "PadLS": ("stick", (200, 204, 216), "LS"),
    "PadStart": ("pill", (200, 204, 216), "menu"),
    "LeftStick": ("stick", (200, 204, 216), "L"),
}


def draw(shape, fill, label):
    s = SIZE * SCALE
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    m = s * 0.06
    if shape == "circle":
        d.ellipse([m, m, s - m, s - m], fill=fill)
    elif shape == "stick":
        d.ellipse([m, m, s - m, s - m], fill=fill)
        r = s * 0.30
        d.ellipse([s / 2 - r, s / 2 - r, s / 2 + r, s / 2 + r], outline=INK, width=int(s * 0.04))
    elif shape == "bumper":
        d.rounded_rectangle([m, s * 0.24, s - m, s * 0.76], radius=s * 0.18, fill=fill)
    elif shape == "pill":
        d.rounded_rectangle([s * 0.14, s * 0.22, s * 0.86, s * 0.78], radius=s * 0.28, fill=fill)
    if label == "menu":  # three bars, as pads print the menu button
        for i in (-1, 0, 1):
            y = s / 2 + i * s * 0.11
            d.rounded_rectangle([s * 0.32, y - s * 0.03, s * 0.68, y + s * 0.03], radius=s * 0.03, fill=INK)
        return im.resize((SIZE, SIZE), Image.LANCZOS)
    size = {"circle": 0.56, "stick": 0.34, "bumper": 0.36, "pill": 0.42}[shape]
    font = ImageFont.truetype(ROBOTO, int(s * size))
    box = d.textbbox((0, 0), label, font=font)
    d.text(((s - (box[2] - box[0])) / 2 - box[0], (s - (box[3] - box[1])) / 2 - box[1]), label, font=font, fill=INK)
    return im.resize((SIZE, SIZE), Image.LANCZOS)


def ring():
    """The floor's ring under your own guest (a decal, maps.py, tinted gold there): white, its
    edges soft, on a clear ground."""
    s = 256 * SCALE
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for k, (outer, inner, alpha) in enumerate(((0.48, 0.36, 70), (0.46, 0.38, 160), (0.44, 0.40, 255))):
        d.ellipse([s * (0.5 - outer), s * (0.5 - outer), s * (0.5 + outer), s * (0.5 + outer)], fill=(255, 255, 255, alpha))
        d.ellipse([s * (0.5 - inner), s * (0.5 - inner), s * (0.5 + inner), s * (0.5 + inner)], fill=(0, 0, 0, 0))
    return im.resize((256, 256), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, "YouRing.png")
    ring().save(path)
    r = mcp("asset_import", {"source": path, "group": "UI/Glyphs", "importer": "Texture"})
    print("UI/Glyphs/YouRing", r["guid"])
    for name, (shape, fill, label) in GLYPHS.items():
        path = os.path.join(OUT, name + ".png")
        draw(shape, fill, label).save(path)
        r = mcp("asset_import", {"source": path, "group": "UI/Glyphs", "importer": "Texture"})
        print("UI/Glyphs/" + name, r["guid"])


if __name__ == "__main__":
    main()
