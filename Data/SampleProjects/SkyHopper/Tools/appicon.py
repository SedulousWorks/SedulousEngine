#!/usr/bin/env python3
"""Sky Hopper's app icon: Branding/AppIcon.png, 512 pixels square, what the Android preset's
androidIcon names. A dusk sky (#FFB25B into #7A4FB5), a cloud, and the HUD's star
(Sources/IconStar.svg's gold) on it. Drawn as an SVG here and rendered by librsvg into cairo
through ctypes, as Code/Tools/icon-sheet.py does.

    python3 Tools/appicon.py          (from the project folder)
"""
import ctypes
import os
import sys
import tempfile

from PIL import Image

SIZE = 512
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'Branding', 'AppIcon.png')

ICON = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFB25B"/>
      <stop offset="1" stop-color="#7A4FB5"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" fill="url(#sky)"/>
  <g fill="#FFFFFF">
    <circle cx="170" cy="380" r="70"/>
    <circle cx="260" cy="350" r="90"/>
    <circle cx="350" cy="385" r="65"/>
    <rect x="100" y="380" width="320" height="70" rx="35"/>
  </g>
  <g transform="translate(256 210) scale(13) translate(-12 -11.4)">
    <polygon points="12,1.2 15.2,8.1 22.7,8.9 17.1,14 18.7,21.5 12,17.6 5.3,21.5 6.9,14 1.3,8.9 8.8,8.1" fill="#D99A00"/>
    <polygon points="12,3.8 14.4,9.4 20.3,10 15.8,14.1 17.1,20 12,16.9 6.9,20 8.2,14.1 3.7,10 9.6,9.4" fill="#FFC93C"/>
    <polygon points="12,3.8 14.4,9.4 12,10.5 9.6,9.4" fill="#FFE58A"/>
  </g>
</svg>
'''


class Rect(ctypes.Structure):
    _fields_ = [('x', ctypes.c_double), ('y', ctypes.c_double), ('width', ctypes.c_double),
                ('height', ctypes.c_double)]


def render(svg_path, size):
    rsvg = ctypes.CDLL('librsvg-2.so.2')
    cairo = ctypes.CDLL('libcairo.so.2')
    rsvg.rsvg_handle_new_from_file.restype = ctypes.c_void_p
    rsvg.rsvg_handle_new_from_file.argtypes = [ctypes.c_char_p, ctypes.c_void_p]
    rsvg.rsvg_handle_render_document.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.POINTER(Rect),
                                                 ctypes.c_void_p]
    cairo.cairo_image_surface_create.restype = ctypes.c_void_p
    cairo.cairo_create.restype = ctypes.c_void_p
    cairo.cairo_create.argtypes = [ctypes.c_void_p]
    cairo.cairo_image_surface_get_data.restype = ctypes.POINTER(ctypes.c_ubyte)
    cairo.cairo_image_surface_get_data.argtypes = [ctypes.c_void_p]
    cairo.cairo_image_surface_get_stride.argtypes = [ctypes.c_void_p]
    cairo.cairo_surface_flush.argtypes = [ctypes.c_void_p]
    cairo.cairo_destroy.argtypes = [ctypes.c_void_p]
    cairo.cairo_surface_destroy.argtypes = [ctypes.c_void_p]

    handle = rsvg.rsvg_handle_new_from_file(svg_path.encode(), None)
    if not handle:
        sys.exit('librsvg could not read the icon')
    surface = cairo.cairo_image_surface_create(0, size, size)  # ARGB32
    context = cairo.cairo_create(surface)
    rect = Rect(0, 0, size, size)
    rsvg.rsvg_handle_render_document(handle, context, ctypes.byref(rect), None)
    cairo.cairo_surface_flush(surface)
    stride = cairo.cairo_image_surface_get_stride(surface)
    data = ctypes.string_at(cairo.cairo_image_surface_get_data(surface), stride * size)
    image = Image.frombuffer('RGBA', (size, size), data, 'raw', 'BGRA', stride, 1).copy()
    cairo.cairo_destroy(context)
    cairo.cairo_surface_destroy(surface)
    return image


def main():
    with tempfile.TemporaryDirectory() as scratch:
        svg = os.path.join(scratch, 'AppIcon.svg')
        with open(svg, 'w') as f:
            f.write(ICON)
        image = render(svg, SIZE)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    image.save(OUT)
    print('wrote', os.path.normpath(OUT))


if __name__ == '__main__':
    main()
