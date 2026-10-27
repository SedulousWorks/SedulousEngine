#!/usr/bin/env python3
# Usage: Code/Tools/icon-sheet.py Data/Editor/Icons out.png
# A contact sheet of the editor's icons at 16 and 32 px, rendered by librsvg into cairo through
# ctypes (the Python GObject cairo bridge is not installed).
import ctypes, os, glob, sys
from PIL import Image, ImageDraw
rsvg = ctypes.CDLL('librsvg-2.so.2'); cairo = ctypes.CDLL('libcairo.so.2')
rsvg.rsvg_handle_new_from_file.restype = ctypes.c_void_p
rsvg.rsvg_handle_new_from_file.argtypes = [ctypes.c_char_p, ctypes.c_void_p]
cairo.cairo_image_surface_create.restype = ctypes.c_void_p
cairo.cairo_create.restype = ctypes.c_void_p
cairo.cairo_create.argtypes = [ctypes.c_void_p]
cairo.cairo_image_surface_get_data.restype = ctypes.POINTER(ctypes.c_ubyte)
cairo.cairo_image_surface_get_data.argtypes = [ctypes.c_void_p]
cairo.cairo_image_surface_get_stride.argtypes = [ctypes.c_void_p]
cairo.cairo_surface_flush.argtypes = [ctypes.c_void_p]
cairo.cairo_destroy.argtypes = [ctypes.c_void_p]
cairo.cairo_surface_destroy.argtypes = [ctypes.c_void_p]
class Rect(ctypes.Structure):
    _fields_ = [('x', ctypes.c_double), ('y', ctypes.c_double), ('width', ctypes.c_double), ('height', ctypes.c_double)]
rsvg.rsvg_handle_render_document.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.POINTER(Rect), ctypes.c_void_p]

def render(path, size):
    h = rsvg.rsvg_handle_new_from_file(path.encode(), None)
    surf = cairo.cairo_image_surface_create(0, size, size)  # ARGB32
    cr = cairo.cairo_create(surf)
    rect = Rect(0, 0, size, size)
    rsvg.rsvg_handle_render_document(h, cr, ctypes.byref(rect), None)
    cairo.cairo_surface_flush(surf)
    stride = cairo.cairo_image_surface_get_stride(surf)
    data = ctypes.string_at(cairo.cairo_image_surface_get_data(surf), stride * size)
    im = Image.frombuffer('RGBA', (size, size), data, 'raw', 'BGRA', stride, 1).copy()
    cairo.cairo_destroy(cr); cairo.cairo_surface_destroy(surf)
    return im

files = sorted(glob.glob(os.path.join(sys.argv[1], '*.svg')))
cols, cell = 8, 96
rows = (len(files) + cols - 1) // cols
sheet = Image.new('RGB', (cols * cell, rows * cell), (27, 30, 35))
d = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    for sz, ox in [(16, 8), (32, 36)]:
        im = render(f, sz)
        sheet.paste(im, ((i % cols) * cell + ox, (i // cols) * cell + 12), im)
    d.text(((i % cols) * cell + 6, (i // cols) * cell + 72), os.path.basename(f)[:-4][:15], fill=(150, 155, 165))
sheet.save(sys.argv[2])
print(len(files))
