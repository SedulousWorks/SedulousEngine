# Slug Font Rendering

## Overview

Slug is a GPU font rendering algorithm by Eric Lengyel that renders glyphs directly from quadratic Bézier curve data in the fragment shader. Unlike atlas-based approaches, Slug produces resolution-independent, crisp text at any scale or perspective without pre-rendered texture images or signed distance fields.

- **Patent**: Dedicated to public domain by Eric Lengyel (2019)
- **Shaders**: MIT / Apache-2.0 dual licensed
- **Reference**: https://github.com/EricLengyel/Slug
- **Paper**: Lengyel 2017, "GPU-Centered Font Rendering Directly from Glyph Outlines" (JCGT)

## Architecture

```
Sedulous.Slug           Core algorithm (no external dependencies)
Sedulous.Slug.TTF       TTF/OTF loading via stb_truetype
Sedulous.Slug.Renderer  GPU rendering via Sedulous.RHI + Sedulous.Shaders
Sedulous.Slug.Tests     Unit tests
SlugSample              Demo application
```

Shaders: `shaders/slug.vert.hlsl`, `slug.frag.hlsl`

## How It Works

### Pipeline

```
1. Load TTF        → SlugTTFLoader.LoadFromFile()     → SlugFont (curves + metrics)
2. Build textures  → SlugTextureBuilder.Build()        → curve + band texture data
3. Initialize GPU  → SlugTextRenderer.Initialize()     → uploads textures, compiles shaders, creates pipeline
4. Each frame:
   a. Begin()      → clear geometry staging
   b. DrawText()   → add glyph quads to staging buffer (CPU)
   c. Prepare()    → upload to per-frame GPU buffers (WriteMappedBuffer, no sync stall)
   d. Render()     → set pipeline, bind group, draw indexed
```

### Two Textures

| Texture | Format | Purpose |
|---------|--------|---------|
| **Curve texture** | RGBA16F | Bézier control points. Each curve = 2 texels: `(p1.x, p1.y, p2.x, p2.y)` then `(p3.x, p3.y, 0, 0)` |
| **Band texture** | RGBA16UI | Spatial acceleration. Maps horizontal/vertical bands to curves that intersect them |

Both use a fixed width of 4096 texels.

### Pixel Shader Algorithm

For each pixel:
1. Compute `pixelsPerEm = 1 / fwidth(renderCoord)`
2. Determine horizontal/vertical band indices via `bandTransform`
3. **Horizontal ray**: loop curves in horizontal band, solve `C_y(t) = 0`, accumulate `xcov`
4. **Vertical ray**: loop curves in vertical band, solve `C_x(t) = 0`, accumulate `ycov`
5. Combine: `coverage = max(|xcov·xwgt + ycov·ywgt| / (xwgt+ywgt), min(|xcov|, |ycov|))`
6. Optional: `coverage = sqrt(coverage)` (SLUG_WEIGHT for optical weight boost at small sizes)
7. Output: `color × coverage`

### Vertex Structure (68 bytes, 5 attributes)

```
Attribute 0 (pos):  float4  xy = object-space position, zw = dilation normal
Attribute 1 (tex):  float4  xy = em-space coords, zw = packed glyph/band data
Attribute 2 (jac):  float4  2×2 inverse Jacobian matrix
Attribute 3 (bnd):  float4  band scale xy + band offset zw
Attribute 4 (col):  ubyte4  linear RGBA color (normalized)
```

### Constant Buffer

```hlsl
cbuffer ParamStruct : register(b0)
{
    float4 slug_matrix[4];   // MVP matrix (4 rows, row-major)
    float4 slug_viewport;    // viewport width, height in pixels
};
```

### Dynamic Dilation

The vertex shader expands glyph quads by half a pixel in viewport space using the MVP matrix and normal vectors, ensuring edge pixels are always shaded. Works correctly under perspective and arbitrary transforms.

### GPU State

- **Blend**: SrcAlpha / OneMinusSrcAlpha (standard alpha blend)
- **Cull**: None (text quads are not backface culled)
- **Depth**: configurable (off for 2D overlay, on for 3D world text)
- **Textures**: accessed via texel load (no samplers needed)
- **Bind group**: single set with uniform buffer (b0) + curve texture (t0) + band texture (t1)

## Source Files

### Sedulous.Slug (core)

| File | Description |
|------|-------------|
| `SlugTypes.bf` | Enums, flags, constants |
| `SlugMath.bf` | Vector2D/4D, Point2D, Box2D, Color4U, ColorRGBA, QuadraticBezier2D |
| `SlugGlyph.bf` | `SlugGlyphData` (curves + metrics per glyph), `SlugFont` (font container) |
| `SlugTextureBuilder.bf` | Builds curve texture (RGBA16F) and band texture (RGBA16UI) from curves |
| `SlugGeometryBuilder.bf` | CountGlyphs, BuildText, MeasureString - vertex/triangle generation |
| `SlugVertex.bf` | Vertex4U, Triangle16/32, GeometryBuffer, SlugUniforms |
| `SlugShader.bf` | Embedded HLSL shader source (fallback; prefer loading from files) |

### Sedulous.Slug.TTF

| File | Description |
|------|-------------|
| `SlugTTFLoader.bf` | Extracts quadratic Bézier curves from TTF/OTF via `stbtt_GetGlyphShape()`. Handles Y-flip (font Y-up → screen Y-down), line→curve conversion, cubic→quadratic approximation. Computes bounding boxes from actual curve control points with padding. |

### Sedulous.Slug.Renderer

| File | Description |
|------|-------------|
| `SlugRenderResources.bf` | GPU resource container |
| `SlugTextRenderer.bf` | Multi-buffered renderer. Creates textures, compiles shaders via ShaderSystem, manages per-frame vertex/index/uniform buffers (CpuToGpu, WriteMappedBuffer). API: Begin/DrawText/Prepare/Render. |

## Usage

```beef
using Sedulous.Slug;
using Sedulous.Slug.TTF;
using Sedulous.Slug.Renderer;

// --- Startup ---

// Load font and extract curves
let font = SlugTTFLoader.LoadFromFile("Roboto-Regular.ttf").Value;

// Build curve + band textures on CPU
let textureData = SlugTextureBuilder.Build(font).Value;
defer { delete textureData.CurveTextureData; delete textureData.BandTextureData; }

// Initialize GPU renderer (uploads textures, compiles shaders, creates pipeline)
let renderer = new SlugTextRenderer(device);
renderer.Initialize(font, textureData, frameCount, swapChainFormat, shaderSystem);

// --- Each Frame ---

renderer.Begin();
renderer.DrawText("Hello World", 20, 50, 32.0f);
renderer.DrawText("Small text", 20, 90, 12.0f, .(200, 200, 200, 255));
renderer.Prepare(frameIndex, viewportWidth, viewportHeight);

// Inside render pass:
renderer.Render(renderPass, frameIndex);

// --- Shutdown ---
renderer.Dispose();
delete renderer;
delete font;
```

## Implementation Notes

### Band Texture Layout

For each glyph, the band texture stores:
- Horizontal band headers at offsets `[0 .. hBands-1]` from glyph location
- Vertical band headers at offsets `[hBands .. hBands+vBands-1]` from glyph location
- Each header contains `(curveCount, offsetToCurveList)`
- Curve lists contain `(curveLoc.x, curveLoc.y)` pointing into the curve texture
- Horizontal bands sorted by descending max X (for early exit in shader)
- Vertical bands sorted by descending max Y (for early exit in shader)

Band count per glyph: `min(32, curveCount)` for correct rendering of complex glyphs.

Additional optimizations from the Slug reference:
- **Epsilon overlap**: bands overlap by 1/1024 em-space to prevent curves at exact boundaries from being missed
- **Skip parallel lines**: straight horizontal lines excluded from horizontal bands, straight vertical lines excluded from vertical bands - they can't contribute to winding number for parallel rays
- **Shared band data** (not yet implemented): adjacent bands with identical curve sets can share data; subsets can point into larger band's data
- **Shared curve texels** (not yet implemented): connected curves share an endpoint (p3 of curve N = p1 of curve N+1), so the second texel of one curve can be the first texel of the next

### Coordinate System

TTF fonts use Y-up. Screen rendering uses Y-down. The TTF loader negates all Y coordinates during curve extraction so the entire pipeline (texture builder, geometry builder, shader) operates in Y-down consistently.

### Vulkan Compatibility

- Binding shifts are applied automatically by the Vulkan RHI backend
- Y-flip handled via `SlugUniforms.Ortho2D(width, height, device.FlipProjectionRequired)`
- Shaders compiled to SPIRV via DXC (ShaderSystem)

### Known Limitations

- No kerning (stb_truetype has `stbtt_GetGlyphKernAdvance` but not yet wired up)
- Quad geometry only (no tight bounding polygons)
- Single font per renderer instance
- No multi-line layout (caller must position lines manually)
- No cap height pixel alignment (could ensure crisp glyph tops at common sizes using OS/2 sCapHeight)

## Potential Uses

- **Overlay/debug text**: resolution-independent, one font for all sizes, no atlas management
- **3D world text**: same shader with scene camera MVP, depth-tested pipeline variant
- **HUD/UI text**: crisp at any DPI, no re-rasterization on resize
