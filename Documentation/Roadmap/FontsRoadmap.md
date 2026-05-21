# Fonts Roadmap

Design notes and pending work for the Sedulous font pipeline.

## Current State - DONE

### Foundation projects
- ~~**Sedulous.Fonts**~~ - core types: IFont, IFontAtlas, IFontService, CachedFont, FontMetrics, GlyphInfo, AtlasRegion, GlyphPosition / GlyphQuad, FontLoadOptions, FontLoadResult, FontAtlasTexture helper (R8 -> RGBA8 expansion).
- ~~**Sedulous.Fonts.IO**~~ - source-format load pipeline abstractions: IFontParser, IFontAtlasBaker, FontParserFactory, FontAtlasBakerFactory, FontManager.
- ~~**Sedulous.Fonts.TTF**~~ - TrueType/OpenType backend: TrueTypeFont (with proper family-name extraction via stbtt_GetFontNameString), TrueTypeFontAtlas, TrueTypeFontParser, TrueTypeFontAtlasBaker, TrueTypeFontService, TrueTypeFonts.Initialize.
- ~~**Sedulous.Fonts.Baked**~~ - pure-data IFont/IFontAtlas implementations: BakedFont, BakedFontAtlas. No stb_truetype runtime dependency.
- ~~**Sedulous.Fonts.Resources**~~ - resource layer: FontResource (metadata + atlas-pixel sidecar), FontResourceManager, BakedFontService (IFontService impl over loaded `.font` resources), BakedFonts.Initialize.
- ~~**Sedulous.Fonts.Importer**~~ - edit-time TTF -> baked converter: FontImporter.Bake, BakedFontData.

### Service-level architecture
- ~~**TrueTypeFontService**~~ implements IFontService over a TTF source format. Mandatory IMount on construction; LoadFont opens via VFS when the mount routes the locator, falls back to direct disk only when constructed with null mount.
- ~~**BakedFontService**~~ implements IFontService over `.font` resources. Loads through the resource system; non-owning of the BakedFont/BakedFontAtlas inside the resource (FontResource owns those via refcount).
- ~~**Symmetric init helpers**~~ - TrueTypeFonts.Initialize registers parser + baker with their factories; BakedFonts.Initialize(ResourceSystem) registers FontResourceManager with the resource system.
- ~~**Dependency injection**~~ - UI subsystems (EngineUISubsystem, UISubsystem, GUISubsystem, LegacyUISubsystem, EngineLegacyUISubsystem) no longer own a TrueTypeFontService; they take an IFontService injected by the host application.

### VFS routing
- ~~**Application base owns `builtin://` mount**~~ - `Sedulous.Runtime.Client.Application` creates a FileSystemMount over its discovered AssetDirectory and registers it with the ResourceSystem before OnInitialize. Every derived app gets it automatically.
- ~~**EngineApplication owns its own `builtin://` mount**~~ - separate Application class hierarchy with its own mount; equivalent behavior.
- ~~**Host apps load fonts through VFS**~~ - editor, engine apps, sandboxes, ModelViewer construct TrueTypeFontService with their BuiltinMount and load via relative locator (`"fonts/roboto/Roboto-Regular.ttf"`) instead of `GetAssetPath`-resolved absolute paths.

### Resource format
- ~~**`.font` = metadata + sidecar**~~ - text-serialized metadata (family, metrics, atlas dims, glyph + kerning tables) plus `<locator>.bin` pixel sidecar. Mirrors the `.texture` convention. Editor's importer pre-bakes the atlas; shipped game has zero stb_truetype dependency on the load path.
- ~~**FontResource round-trip**~~ - OnSerialize covers family name, font metrics, atlas dims, white-pixel UV, per-glyph regions + GlyphInfo, kerning pairs. Atlas pixels go to the sidecar via WriteAtlasPixelsToStream; FontResourceManager reads them back and assigns via BakedFontAtlas.SetPixels.

### Editor pipeline
- ~~**FontAssetImporter**~~ - source `.ttf`/`.otf` -> `.font` + `.bin` via FontImporter.Bake. Preview uses TrueTypeFont directly (doesn't need the runtime parser factory).
- ~~**FontEditorPage**~~ - read-only metadata view + aspect-fit atlas preview.
- ~~**FontThumbnailGenerator**~~ - asset browser thumbnails from baked atlas.

### Tests
- ~~**BakedFontTests**~~ - pure-data coverage of BakedFont + BakedFontAtlas (metrics, glyph table, kerning, atlas regions, MeasureString, GetGlyphQuad).
- ~~**FontImporterTests**~~ - end-to-end TTF bake, options, ownership transfer.
- ~~**FontResourceRoundTripTests**~~ - metadata + sidecar serialization round-trip through OpenDDL.

---

## Multi-size baked fonts: design decision

**Recommendation: keep one size per `.font` file.** Do not pack multiple
pixel heights of the same family into a single resource.

### The problem statement

TrueType is intrinsically size-flexible: parse once, bake atlases at any
pixel height on demand. `TrueTypeFontService` builds a per-size cache
keyed by `FamilyName@PixelHeight`.

Baked fonts commit to whatever sizes the importer produced. A baked
`Roboto.font` at 16 px can't be queried at 24 px. To support multiple
sizes today, you import N `.font` files (e.g., `Roboto-16.font`,
`Roboto-24.font`) and call `BakedFontService.LoadFont(name, uri)` N
times.

The asymmetry feels wrong, which raises the question: should `.font`
store multiple sizes per resource?

### Why we say no

- **Atomic load + ref-counting per size.** Resources are refcounted
  per-handle. If only 16 px is in use, the 32 px atlas never enters
  memory. Bundling makes "load Roboto" pull every baked size even when
  consumers want one.
- **Hot reload granularity.** A change to one size re-bakes one file.
  With a bundle, every iteration reserializes / re-uploads everything.
- **Asset model symmetry.** `.texture`, `.audioclip`, `.mesh` are all
  one-thing-per-file. Grouping is a folder + naming convention, not a
  schema feature. Don't introduce a one-off rule for fonts.
- **Honest memory accounting.** Each `.font` resource has its own GUID,
  thumbnail, and visible footprint in the asset browser. Bundling
  hides cost behind a single line item.
- **Schema simplicity.** Multi-size bundles need either a list of
  (font, atlas) pairs (redundant family-name / codepoint-range
  metadata per entry) or a shared-metadata + per-size-atlas layout
  (changes the IFontAtlas API to "one atlas per font").

The "too many files" cost is overstated. A typical UI uses 3-5 body
sizes plus 1-2 title sizes - 8 `.font` files per project. The asset
browser groups by folder; that's enough.

### When clutter becomes real, the escape hatch is `.fontfamily`

If a future project ships dozens of sizes per family and the per-file
overhead becomes unworkable, the right answer is *additive*:
introduce a `.fontfamily` manifest resource that references multiple
`.font` sub-resources.

```
Roboto.fontfamily      <- manifest, refs Roboto-16, Roboto-24, ...
Roboto-16.font         <- actual baked font + atlas
Roboto-24.font
```

`BakedFontService.LoadFamily(name, vfs, "fonts/Roboto.fontfamily")`
walks the manifest and registers every referenced size. This keeps
each `.font` independently loadable / hot-reloadable while giving
consumers a single "load me" entry point for the family. The
underlying `.font` format doesn't change.

This is a future option, not committed to. Build it when there's
evidence the project needs it.

### What we should fix instead: size quantization in the importer

The real friction with baked fonts isn't file layout - it's that
you're locked to whatever sizes you baked. The importer should make
that decision ergonomic:

- Multi-size checkbox UI in `FontAssetImporter` (currently only bakes
  one size at default pixel height). Tick `[x] 11 [x] 12 [x] 14
  [x] 16 [x] 18 [x] 20 [x] 24 [x] 32` and the import produces N
  `.font` files in one action.
- Per-size override of codepoint range / atlas dims for special cases
  (a 64 px title font might need a larger atlas than a 12 px body
  font).
- Sensible defaults: pre-tick common UI sizes (16, 24) when the user
  hits import.

---

## Pending / future work

### Importer UX
- **Multi-size baking from one TTF** (see above) - currently only
  produces a single `.font` file per TTF import.
- **Codepoint range UI** - default ASCII (32-126) covers Latin-1; need
  a way to pick Extended Latin, Greek/Cyrillic, CJK subsets, or full
  Unicode without editing the importer.
- **Atlas dim hinting** - the importer auto-picks based on glyph count
  but offers no override. Large fonts may want larger atlases; small
  fonts can use smaller ones.

### Service unification
- **`.fontfamily` manifest resource** (deferred, see above) - the
  optional one-entry-per-family layer over multiple `.font` files.
- **`IFontService.LoadFont` on the interface?** - currently each impl
  has its own LoadFont signature (TrueType takes pixel height in
  options; Baked reads height from the resource). Either lift a
  common form into IFontService or accept that LoadFont stays
  backend-specific.

### Engine UI bootstrap
- **Editor's Roboto bootstrap should use a pre-baked `.font`** -
  currently still loads `fonts/roboto/Roboto-Regular.ttf` via
  TrueTypeFontService. Once a `Roboto.font` (or `.fontfamily`) is
  shipped under `builtin://`, the editor can switch to
  BakedFontService and the editor binary stops needing
  `TrueTypeFonts.Initialize` for its own UI.
- **EngineApplication likewise** - default font load could move to
  the baked path.

### Field-effect / advanced rendering
- **SDF / MSDF font support** - the current pipeline is bitmap atlas
  only. Signed-distance-field fonts scale smoothly at runtime and
  largely solve the size-quantization problem baked fonts have today.
  Would slot in as a second `IFontAtlasBaker` (MSDFFontAtlasBaker)
  paired with a fragment shader that resolves the distance field at
  render time. Out of scope for the current pass.
- **Color / emoji font support** - COLR/CPAL or sbix tables aren't
  currently exposed by the parser. Would need both parser changes
  (decode color glyphs) and atlas / shader changes (multi-layer or
  sRGB pre-multiplied alpha).

### Test coverage
- **BakedFontService integration tests** - existing tests cover
  pure-data BakedFont and FontResource round-trip but don't exercise
  the service layer (cache by FamilyName@PixelHeight, atlas-texture
  retrieval, default-font tracking).
- **TrueTypeFontService VFS-routed loading tests** - existing TTF
  tests use the direct-disk LoadFromFile path. Add coverage for the
  mount-based path now that it's the primary entry point.
