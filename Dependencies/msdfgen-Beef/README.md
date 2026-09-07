# msdfgen-Beef

Beef bindings for [msdfgen](https://github.com/Chlumsky/msdfgen), the multi-channel signed
distance field generator.

- **Version:** 1.12.0
- **License:** MIT (`msdfgen/LICENSE.txt`)

## Why there is a wrapper

msdfgen is C++ and ships no C API at this version — there is no `extern "C"` anywhere in
the tree. `msdfgen-c/` is a thin C wrapper over the core surface a font atlas baker needs,
and `src/Msdfgen.bf` binds that. The same arrangement as `recastnavigation-Beef` and
`joltc-Beef`.

If msdfgen gains an official C API upstream, drop the wrapper and bind that instead: it is
one file plus its header, and the Beef side barely changes.

## Scope

**msdfgen-core only.** The `ext/` half wants FreeType, TinyXML and libpng; a caller already
has its own font loading and image IO, so pulling those in would buy nothing and cost three
dependencies. A caller therefore supplies the outline itself, as contours of edges — which
is what `Fonts.TrueType` already has from stb_truetype's glyph vertices.

## Winding

**Winding decides inside from outside.** In a Y-up space an outer contour is CLOCKWISE and
a hole is counter-clockwise, which is the direction TrueType outlines already come in.
Wound the other way a shape becomes its own cutout: the field inverts, the interior goes
negative, and a glyph renders as a hole in a filled cell. Nothing reports it —
`msdf_contour_winding` checks, and `msdf_shape_orient_contours` fixes input whose winding
cannot be trusted.

## Range

The range in `msdf_Transform` is in **shape units, not pixels**. A caller wanting N pixels
of spread divides N by the scale it is projecting with. Passing pixels straight in is the
usual cause of a field that looks flat or clips at the glyph edge.

## Building the native libraries

```
./build-native.sh make RELEASE      # configure
./build-native.sh build RELEASE     # build + copy into dist/Release-Linux64
```

Two archives are produced, `libmsdfgen-c.a` and `libmsdfgen-core.a`, and the BeefProj lists
them in that order: the wrapper references the core, and a static link resolves left to
right. Merging them into one would need `$<TARGET_OBJECTS>` on a static library, which is
CMake 3.21, above the 3.15 the other bindings build against.

Windows: `build-native.ps1 make` then `build-native.ps1 build ALL`.

## Test

`msdfgen-Beef-Test` builds a square, colours its edges, generates SDF/MSDF/MTSDF, and
checks the field is positive inside and negative outside — which is what catches an
inverted winding.
