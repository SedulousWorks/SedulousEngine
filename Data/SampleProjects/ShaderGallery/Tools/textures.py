#!/usr/bin/env python3
"""textures.py: the gallery's generated textures, written into generated/ (shaders.py imports them).

  Tiles.png  a 512 px square of 4 x 4 warm stone tiles with grout and a little grain: lesson 2's
             texture (made here rather than downloaded, so the first lessons need nothing else).
  Noise.png  a 512 px tiling cloud noise (grey): what lesson 6 dissolves by.
  Rock030_Color.jpg, Rock030_NormalGL.jpg
             ambientCG's Rock030 at 1K (CC0, Licenses/AmbientCG-Rock030-CC0.txt), downloaded once:
             lesson 5's triplanar rock and lesson 9's hammered metal.
"""
import io, math, os, random, urllib.request, zipfile
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "generated")


def tiles(path, size=512, count=4, grout=6):
    rng = random.Random(7)
    img = Image.new("RGB", (size, size))
    px = img.load()
    cell = size // count
    shades = [[rng.uniform(0.78, 1.0) for _ in range(count)] for _ in range(count)]
    for y in range(size):
        for x in range(size):
            cx, cy = x % cell, y % cell
            if cx < grout or cy < grout:
                v = 0.32 + rng.uniform(-0.03, 0.03)
                px[x, y] = (int(255 * v), int(235 * v), int(215 * v))
                continue
            s = shades[y // cell][x // cell] * (1.0 + rng.uniform(-0.05, 0.05))
            px[x, y] = (min(255, int(222 * s)), min(255, int(186 * s)), min(255, int(150 * s)))
    img.save(path)


def noise(path, size=512, octaves=5):
    """Value noise on a lattice that wraps, summed over octaves, so the texture tiles."""
    rng = random.Random(11)
    layers = []
    for o in range(octaves):
        cells = 4 << o
        layers.append((cells, [[rng.random() for _ in range(cells)] for _ in range(cells)], 0.5 ** o))
    total = sum(w for _, _, w in layers)
    img = Image.new("L", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            v = 0.0
            for cells, grid, w in layers:
                fx, fy = x * cells / size, y * cells / size
                ix, iy = int(fx), int(fy)
                tx, ty = fx - ix, fy - iy
                tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
                a, b = grid[iy][ix], grid[iy][(ix + 1) % cells]
                c, d = grid[(iy + 1) % cells][ix], grid[(iy + 1) % cells][(ix + 1) % cells]
                v += w * ((a + (b - a) * tx) * (1 - ty) + (c + (d - c) * tx) * ty)
            # Stretch the middle out: summed octaves crowd round a half.
            v = min(1.0, max(0.0, (v / total - 0.5) * 2.2 + 0.5))
            px[x, y] = int(255 * v)
    img.save(path)


ROCK = "https://ambientcg.com/get?file=Rock030_1K-JPG.zip"
ROCK_FILES = {"Rock030_1K-JPG_Color.jpg": "Rock030_Color.jpg",
              "Rock030_1K-JPG_NormalGL.jpg": "Rock030_NormalGL.jpg"}


def rock():
    """Rock030's colour and (OpenGL, +Y up) normal map, unchanged, unless already here."""
    if all(os.path.exists(os.path.join(OUT, f)) for f in ROCK_FILES.values()):
        return
    # ambientCG refuses urllib's own User-Agent.
    request = urllib.request.Request(ROCK, headers={"User-Agent": "ShaderGallery-textures/1.0"})
    with urllib.request.urlopen(request) as r:
        archive = zipfile.ZipFile(io.BytesIO(r.read()))
    for inside, name in ROCK_FILES.items():
        open(os.path.join(OUT, name), "wb").write(archive.read(inside))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    tiles(os.path.join(OUT, "Tiles.png"))
    noise(os.path.join(OUT, "Noise.png"))
    rock()
    print("wrote", ", ".join(sorted(os.listdir(OUT))))
