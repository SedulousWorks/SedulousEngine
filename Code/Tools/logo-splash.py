#!/usr/bin/env python3
# Usage: Code/Tools/logo-splash.py <scale> <out.png>
# The editor splash's logo (Data/Branding/sedulous-logo.svg) rendered at <scale> times the
# splash's 420 px width, by librsvg into cairo through ctypes as icon-sheet.py does. The splash
# draws the 1x picture at 100% and scales the 2x one down above it, so it stays sharp at any
# display scale up to 200%.
import ctypes, math, os, sys
from PIL import Image
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

kWidth, kViewWidth, kViewHeight = 420, 885.0, 200.0  # the 1x picture's width; the SVG's viewBox
scale = float(sys.argv[1])
width = round(kWidth * scale)
drawn = width * kViewHeight / kViewWidth
height = math.ceil(drawn)
svg = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'Data', 'Branding', 'sedulous-logo.svg')
h = rsvg.rsvg_handle_new_from_file(svg.encode(), None)
surf = cairo.cairo_image_surface_create(0, width, height)  # ARGB32, premultiplied
cr = cairo.cairo_create(surf)
rect = Rect(0, (height - drawn) / 2, width, drawn)
rsvg.rsvg_handle_render_document(h, cr, ctypes.byref(rect), None)
cairo.cairo_surface_flush(surf)
stride = cairo.cairo_image_surface_get_stride(surf)
data = ctypes.string_at(cairo.cairo_image_surface_get_data(surf), stride * height)
Image.frombuffer('RGBA', (width, height), data, 'raw', 'BGRa', stride, 1).save(sys.argv[2])
cairo.cairo_destroy(cr); cairo.cairo_surface_destroy(surf)
print(f'{sys.argv[2]}: {width} x {height}')
