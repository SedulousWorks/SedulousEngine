# SPDX-License-Identifier: MIT
# Copyright (c) 2026-Present Robert Campbell
#
# The Ember theme's nine-slice art (E13 of Specs/gui-lab-evolution-2.md), drawn here so it is ours
# to publish: rounded frames with soft edges, written as RGBA PNGs with nothing but the standard
# library. Run from anywhere: python3 MakeArt.py (it writes beside itself).
import math, os, struct, zlib

HERE = os.path.dirname(os.path.abspath(__file__))

def png(path, w, h, pixels):
    raw = b''.join(b'\x00' + bytes(pixels[y * w * 4:(y + 1) * w * 4]) for y in range(h))
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)) +
                chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))

def rounded(x, y, w, h, r):
    # Signed distance from a pixel centre to a rounded rectangle (negative inside).
    qx = abs(x - w / 2) - (w / 2 - r)
    qy = abs(y - h / 2) - (h / 2 - r)
    return math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - r

def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(4))

def frame(name, size, radius, top, bottom, edge, edgeWidth, light=None, inner=None):
    w = h = size
    out = []
    for y in range(h):
        for x in range(w):
            d = rounded(x + 0.5, y + 0.5, w, h, radius)
            cover = min(max(0.5 - d, 0.0), 1.0)            # the shape's soft edge
            fill = mix(top, bottom, y / (h - 1))
            ring = min(max(edgeWidth + 0.5 + d, 0.0), 1.0)  # within edgeWidth of the outline
            c = mix(fill, edge, ring)
            if light is not None and 1.5 <= y + 0.5 - edgeWidth <= 2.5 and d < -edgeWidth - 1:
                c = mix(c, light, 0.8)                     # a highlight just inside the top edge
            if inner is not None:
                di = rounded(x + 0.5, y + 0.5, w, h, radius) + edgeWidth + 3
                band = min(max(1.0 - abs(di), 0.0), 1.0)
                c = mix(c, inner, band * 0.9)              # an inset line inside the frame
            out += [int(round(c[0])), int(round(c[1])), int(round(c[2])), int(round(c[3] * cover))]
    png(os.path.join(HERE, name), w, h, out)

frame('button.png', 24, 6, (214, 118, 52, 255), (138, 58, 23, 255), (58, 22, 6, 255), 1.5, light=(250, 190, 120, 255))
frame('button-hover.png', 24, 6, (236, 142, 70, 255), (160, 72, 30, 255), (58, 22, 6, 255), 1.5, light=(255, 214, 150, 255))
frame('panel.png', 48, 12, (46, 31, 22, 245), (29, 19, 13, 245), (179, 122, 60, 255), 2.0, inner=(90, 59, 32, 255))
frame('field.png', 16, 4, (18, 12, 8, 255), (26, 17, 11, 255), (107, 74, 42, 255), 1.0)
