# Sedulous.VG Upgrade Plan

Plan to bring Sedulous.VG up to parity with Sedulous.Drawing for UI use cases, so
it can serve as the primary rendering API for a new game UI framework.

Slug integration and SDF/MSDF are intentionally out of scope for this plan -
they can be added later as parallel paths without disturbing this work.

## Context

**Sedulous.VG today** - vector graphics via tessellated paths with coverage-based
analytical AA. Has shapes (rect/rounded/circle/ellipse/polygon/star), paths,
strokes with caps/joins/dashes, gradients (linear/radial/conic via `IVGFill`),
clipping, opacity, blend modes, transform stack. Higher quality than Drawing
for curves. Vertex is 24 bytes (pos, uv, color, coverage).

**Sedulous.Drawing today** - batched 2D rasterizer. Has everything VG has plus
images, nine-slice, sprites + animation, text via `IFontAtlas`, `IFontService`,
`IBrush` (Solid/LinearGradient/RadialGradient/ImageBrush), `Pen`. Vertex is 20
bytes (pos, uv, color). Uses `ShapeRasterizer` - simpler but lower quality than
VG's tessellator.

**What's missing in VG for UI:**
- `VGCommand` has a `TextureIndex` field but `VGBatch` has no `Textures` list
  - the field is dead
- No image rendering
- No text rendering
- No point-to-point `DrawLine`, no `DrawBorderRect` / `DrawBorderRoundedRect`
- No immediate-mode path API - every ad-hoc shape requires `PathBuilder` +
  `Path` + manual `delete`

**Assets already in place:**
- `Sedulous.Images` - `IImageData`, `OwnedImageData`, `ImageDataRef`, `PixelFormat`,
  `NineSlice` (extracted from Drawing so VG can depend on it without pulling in Drawing)
- `Sedulous.Fonts` - `IFont`, `IFontAtlas`, `ITextShaper`, `CachedFont`, `FontManager`,
  `IFontService`, glyph/position/hit-test types
- `Sedulous.Fonts.TTF` - `FontService` (concrete implementation), TrueType font/atlas/shaper/loader

## Goals

1. VG can render everything a UI framework needs: shapes, images (incl. nine-slice),
   text, with gradients, opacity, clipping, transforms.
2. VG's existing high-quality shape tessellation path is preserved - no regression
   in curve quality or AA.
3. Existing VG callers keep working - new capabilities are additive.
4. Drawing remains the right tool for sprite batching, particles, in-world 2D -
   this plan does not deprecate Drawing.

## Non-goals

- SDF / MSDF text (future phase)
- Slug integration (separate parallel renderer)
- Stencil clipping, drop shadow, outer glow (future)
- Path boolean operations
- Porting sprite + sprite animation APIs (stay in Drawing)

## Open questions to resolve before starting

1. **`IFontService` location.** ✅ **Resolved** - interface in `Sedulous.Fonts`,
   concrete `FontService` implementation in `Sedulous.Fonts.TTF`. VG will depend
   on `Sedulous.Fonts` for the interface; apps pick an implementation.

2. **Text atlas pixel format.** ✅ **Resolved** - atlases expanded to RGBA8 at
   upload time (white RGB + alpha from R). One unified shader path samples
   `texture.a * vertex.color.a`. SDF/MSDF later gets its own shader branch.

3. **`NineSlice`** - ✅ **Resolved** - moved to `Sedulous.Images`.

4. **`IVGFill` vs `IBrush`** - keep them separate. `IVGFill` has `ConicGradient`,
   `IBrush` has `ImageBrush` - they've diverged intentionally. Don't unify.
   A `VGImageFill` can be added later if/when needed.

## Phase 1 - Texture infrastructure

Goal: make `VGCommand.TextureIndex` functional. Prerequisite for images and text.

**`Sedulous.VG` BeefProj.toml:**
- Add `Sedulous.Images` dependency.

**`VGBatch`:**
- Add `public List<IImageData> Textures`.
- `Clear()` clears textures.
- `GetTextureForCommand(index)` helper (mirrors `DrawBatch`).

**`VGContext`:**
- Constructor creates a 1x1 white `OwnedImageData`, adds at `Textures[0]`.
- `Clear()` re-adds white texture at index 0.
- New state:
  ```
  private int32 mCurrentTextureIndex = 0;  // white by default
  ```
- Helpers:
  ```
  private int32 GetOrAddTexture(IImageData tex)   // lookup or append, returns index
  private void SetupForSolidDraw()                 // ensures current = white (0)
  private void SetupForTextureDraw(int32 index)    // flushes if changed
  ```
- `FlushCurrentCommand` writes `cmd.TextureIndex = mCurrentTextureIndex`.
- All existing shape methods call `SetupForSolidDraw()` at start.

**Shader / renderer:**
- VG's fragment shader now samples the bound texture. For solid shapes, UV
  defaults to `(0.5, 0.5)` into the 1x1 white texture → sample returns (1,1,1,1),
  no behavioral change.
- Uniform/bindings updated to carry a per-command texture.

**Verification:**
- All existing VG sample code renders identically (white texture pass-through).
- `VGBatch.Textures.Count >= 1` always after construction.

## Phase 2 - Images

Goal: API parity with `DrawContext.DrawImage` / `DrawNineSlice`.

`NineSlice` is already in `Sedulous.Images` and available via the Phase 1 dependency.

**`VGContext` additions:**
```
void DrawImage(IImageData tex, Vector2 pos);
void DrawImage(IImageData tex, Vector2 pos, Color tint);
void DrawImage(IImageData tex, RectangleF destRect);
void DrawImage(IImageData tex, RectangleF destRect, RectangleF srcRect, Color tint);
void DrawNineSlice(IImageData tex, RectangleF destRect, RectangleF srcRect,
                   NineSlice slices, Color tint);
```

**Implementation notes:**
- Images emit quads directly (no tessellator - they're axis-aligned textured rectangles).
- Transform applied via `TransformRect` on the destination corners.
- Nine-slice emits 9 quads (or skip degenerate ones). Port logic from Drawing's
  `ShapeRasterizer.RasterizeNineSlice`.
- Coverage = 1.0 for all image vertices (no analytical AA).
- Opacity applied to tint before vertex emission.

**Skip for now:**
- `DrawImageBrush` / `VGImageFill` - revisit if UI needs image-filled arbitrary paths.
- Sprites + `SpriteAnimation` - leave in Drawing.

## Phase 3 - Text

Goal: API parity with `DrawContext.DrawText`.

`IFontService` interface lives in `Sedulous.Fonts` (already done). VG adds
`Sedulous.Fonts` as a dependency to consume it. Apps that want TTF fonts pull in
`Sedulous.Fonts.TTF` and construct its `FontService` - VG doesn't care about the
concrete implementation.

**`VGContext` constructor changes:**
```
public this(IFontService fontService = null)
{
    ...
    mFontService = fontService;
}
public IFontService FontService => mFontService;
```

**Text rendering APIs (mirror Drawing exactly):**
```
void DrawText(StringView text, IFontAtlas atlas, IImageData atlasTexture,
              Vector2 pos, Color color);
void DrawText(StringView text, IFontAtlas atlas, IImageData atlasTexture,
              Vector2 pos, IVGFill fill);
void DrawText(StringView text, IFont font, IFontAtlas atlas, IImageData atlasTexture,
              RectangleF bounds, TextAlignment align, Color color);
void DrawText(StringView text, IFont font, IFontAtlas atlas, IImageData atlasTexture,
              RectangleF bounds, TextAlignment hAlign, VerticalAlignment vAlign, Color color);
```

**Convenience overloads using `IFontService`:**
```
void DrawText(StringView text, CachedFont font, Vector2 pos, Color color);
void DrawText(StringView text, CachedFont font, RectangleF bounds,
              TextAlignment hAlign, VerticalAlignment vAlign, Color color);
```
These look up `font.Atlas` and get the atlas texture from
`mFontService.GetAtlasTexture(font)`. The UI framework will call these.

**Measurement (needed for layout):**
```
Vector2 MeasureText(StringView text, IFont font);
float MeasureTextWidth(StringView text, IFont font);
```
Thin wrappers over `IFont.MeasureString` + `FontMetrics.LineHeight`.

**Implementation:**
- Port glyph loop from `DrawContext.DrawText` - iterate codepoints,
  `atlas.GetGlyphQuad(codepoint, ref cursorX, cursorY, out quad)`, emit 4 verts
  + 6 indices per glyph.
- Textured path (same `SetupForTextureDraw` as images).
- Coverage = 1.0 for glyph vertices.

**Atlas format:** atlases uploaded as RGBA8. VG's text path performs the grayscale →
RGBA8 expansion itself on first use of a given `IFontAtlas`:
- Private cache in `VGContext` keyed by `IFontAtlas` reference, value is an
  `OwnedImageData` (RGBA8) with white RGB and alpha copied from the atlas's R channel.
- Cache entries live for the lifetime of the `VGContext`. Cleared by `VGContext.Clear`
  (since atlas identity may change across frames) - or kept persistent; TBD based on
  usage patterns.
- When the shape of `IFontAtlas.PixelData` ever changes (e.g. atlas growth), VG
  detects via size mismatch and rebuilds the RGBA copy.
- One unified shader path samples `texture.a * vertex.color.a * coverage`.

This keeps `Sedulous.Fonts` and font loaders untouched - they continue to produce
R8 atlases. VG owns the conversion because it's a VG rendering concern, not a font
concern. When SDF/MSDF lands it gets its own atlas format + shader branch.

## Phase 4 - UI-shape ergonomics

Pure API surface additions - 2-5 line wrappers over existing VG primitives.

**New on `VGContext`:**
```
void DrawLine(Vector2 a, Vector2 b, Color color, float thickness = 1.0f);

void DrawRect(RectangleF rect, Color color, float thickness = 1.0f);       // alias for StrokeRect, naming parity
void DrawBorderRect(RectangleF rect, Color color, float thickness = 1.0f); // stroke inset to fit inside bounds

void DrawRoundedRect(RectangleF rect, float radius, Color color, float thickness = 1.0f);        // alias for StrokeRoundedRect
void DrawBorderRoundedRect(RectangleF rect, float radius, Color color, float thickness = 1.0f);  // UI border variant

void DrawCircle(Vector2 center, float radius, Color color, float thickness = 1.0f);   // alias
void DrawEllipse(Vector2 center, float rx, float ry, Color color, float thickness = 1.0f);
```

**`Pen` convenience struct** (optional - wraps `StrokeStyle`):
```
struct Pen {
    Color Color;
    float Thickness;
    VGLineCap Cap;
    VGLineJoin Join;
}
```
Overloads that take `Pen` delegate to `StrokePath(..., .(pen.Thickness, pen.Cap, pen.Join))`.

## Phase 5 - Immediate-mode path API

Goal: eliminate the `PathBuilder → Path → defer delete path → FillPath` ceremony
for one-off shapes.

**`VGContext` internal state:**
```
private PathBuilder mCurrentPath = new .() ~ delete _;
private bool mPathOpen = false;
```

**New API:**
```
void BeginPath();
void MoveTo(float x, float y);
void LineTo(float x, float y);
void QuadTo(float cx, float cy, float x, float y);
void CubicTo(float c1x, float c1y, float c2x, float c2y, float x, float y);
void ArcTo(float cx, float cy, float radius, float startAngle, float endAngle);
void ClosePath();

void Fill(Color color, FillRule rule = .EvenOdd);
void Fill(IVGFill fill, FillRule rule = .EvenOdd);
void Stroke(Color color, StrokeStyle style);
void Stroke(Color color, float thickness = 1.0f);
```

**Implementation:**
- `BeginPath` clears `mCurrentPath`, sets `mPathOpen = true`.
- `MoveTo` / `LineTo` / etc. forward to `mCurrentPath`.
- `Fill` / `Stroke` tessellate directly from the builder's command + point lists
  without going through an intermediate `Path` allocation. May require a new
  `FillTessellator.TessellateFromBuilder` overload, or rework tessellator to
  accept spans directly.

**Keep existing `FillPath(Path, ...)` API** - callers that want cached reusable
paths keep using the builder pattern.

## Phase 6 - Deferred

- Sprite + animation support (stays in Drawing unless UI explicitly needs it)
- `VGImageFill` (image-filled arbitrary paths)
- SDF / MSDF font atlas variants + shader branch
- Stencil clipping
- Drop shadow / outer glow helpers
- Path boolean ops
- **Zero-allocation path tessellation.** Today `Fill` / `Stroke` (both the
  immediate-mode API from Phase 5 and the convenience methods like `FillRect`
  / `FillCircle`) go through `PathBuilder.ToPath()`, which allocates fresh
  `List<PathCommand>` + `List<Vector2>` + `Path`. Teach `PathFlattener` and
  `FillTessellator` to accept `PathBuilder` (or raw command/point spans)
  directly, so the tessellator reads the builder's existing storage without
  a snapshot. Benefits: the immediate-mode API, all the shape convenience
  methods, and `DrawLine` / stroke wrappers all become allocation-free.

## Execution order

All open questions resolved. Ready to start.

1. **Phase 1** (texture infrastructure + shader update). Verify all existing VG
   samples render identically.
2. **Phase 2 (images) and Phase 3 (text) in parallel** - both sit on Phase 1
   and don't interfere.
3. **Phase 4 (UI ergonomics)** - pure API surface, cheap.
4. **Phase 5 (immediate-mode paths)** - independent; do whenever convenient.

After Phase 3, VG has enough to render a real UI framework. Phases 4-5 are
quality-of-life improvements with no capability change.

## Files touched (summary)

### New
- (none - `Sedulous.Images` already exists)

### Modified

**`Sedulous.Drawing`:**
- Add `using Sedulous.Images;` where `NineSlice` is referenced (already done
  if the move is complete).
- `BeefProj.toml` - keep current dependencies.

**`Sedulous.VG`:**
- `BeefProj.toml` - add `Sedulous.Images`, `Sedulous.Fonts` dependencies.
- `VGBatch.bf` - add `Textures` list.
- `VGContext.bf` - all new APIs (Phases 1-5), texture state, font service,
  immediate-mode path state.
- (Possibly) `VGTextRenderer.bf` - private helper for glyph loop if `VGContext`
  gets too big.
- (Possibly) `Pen.bf` - convenience struct.

**VG renderer (wherever VG geometry is consumed for GPU rendering):**
- Update shader to sample per-command texture.
- Update pipeline/bind-group setup to bind `VGBatch.Textures[cmd.TextureIndex]`.
- Add atlas-texture-upload hook if atlases are exposed through `IFontService`.
