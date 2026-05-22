using System;
using System.IO;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.Baked;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Fonts.Resources;

/// Font as a loadable resource.
///
/// Holds owned `BakedFont` + `BakedFontAtlas` instances. The on-disk format
/// is metadata (this serializer) + an atlas pixel sidecar at
/// `<locator>.bin` - mirrors how TextureResource stores pixels. A shipped
/// game loads via `FontResourceManager`; no runtime stb_truetype dependency.
public class FontResource : Resource
{
	public override ResourceType ResourceType => .("font");
	public override int32 SerializationVersion => 1;

	private BakedFont mFont ~ if (_ != null) delete _;
	private BakedFontAtlas mAtlas ~ if (_ != null) delete _;
	private FontLoadOptions mOptions;

	/// IFont accessor for consumers that don't care it's baked.
	public IFont Font => mFont;
	/// IFontAtlas accessor for consumers that don't care it's baked.
	public IFontAtlas Atlas => mAtlas;

	/// Baked-specific accessors for the editor (atlas viewer iterates glyph
	/// regions, counts glyphs, etc.).
	public BakedFont BakedFont => mFont;
	public BakedFontAtlas BakedAtlas => mAtlas;

	/// The options used to bake this font. Stored for reference; rebuilding
	/// the atlas at runtime would need the original TTF + importer.
	public FontLoadOptions Options
	{
		get => mOptions;
		set => mOptions = value;
	}

	public bool IsValid => mFont != null && mAtlas != null;

	public this() { }

	public this(BakedFont font, BakedFontAtlas atlas, FontLoadOptions options)
	{
		mFont = font;
		mAtlas = atlas;
		mOptions = options;
	}

	/// Replace the owned BakedFont. Takes ownership; deletes any existing.
	public void SetFont(BakedFont font)
	{
		if (mFont != null) delete mFont;
		mFont = font;
	}

	/// Replace the owned BakedFontAtlas. Takes ownership; deletes any existing.
	public void SetAtlas(BakedFontAtlas atlas)
	{
		if (mAtlas != null) delete mAtlas;
		mAtlas = atlas;
	}

	/// Writes the atlas pixel buffer to a stream. Companion to
	/// `WriteToStream` (which writes metadata only) - the importer calls
	/// both, the resource manager loads both. Mirrors the TextureResource
	/// pattern.
	public Result<void> WriteAtlasPixelsToStream(Stream stream)
	{
		if (mAtlas == null) return .Err;
		let pixels = mAtlas.PixelData;
		if (pixels.Length == 0) return .Ok; // empty atlas; nothing to write
		if (stream.TryWrite(pixels) case .Err)
			return .Err;
		return .Ok;
	}

	/// Reloads the font resource in place. Clears the existing
	/// `BakedFont` and `BakedFontAtlas` and re-reads metadata from the
	/// serializer without replacing those instances - outside references
	/// (text renderers, glyph caches) stay valid. The atlas pixel
	/// sidecar must be re-applied by the manager after this returns.
	public override Result<void, ResourceLoadError> Reload(Serializer s)
	{
		if (mFont != null) mFont.ClearForReload();
		if (mAtlas != null) mAtlas.ClearForReload();

		let result = Serialize(s);
		if (result != .Ok)
			return .Err(.InvalidFormat);
		return .Ok;
	}

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (s.IsWriting)
		{
			if (mFont == null || mAtlas == null)
				return .InvalidData;
		}
		else
		{
			// Reading - reuse the existing instances on reload (cleared
			// by Reload() before Serialize), allocate on first load.
			// Outside references (text renderers, glyph caches) stay
			// valid across hot-reload.
			if (mFont == null) mFont = new BakedFont();
			if (mAtlas == null) mAtlas = new BakedFontAtlas();
		}

		// --- Top-level options (capture the import settings for reference). ---
		s.Float("pixelHeight",   ref mOptions.PixelHeight);
		s.Int32("firstCodepoint", ref mOptions.FirstCodepoint);
		s.Int32("lastCodepoint",  ref mOptions.LastCodepoint);
		s.UInt32("atlasWidth",    ref mOptions.AtlasWidth);
		s.UInt32("atlasHeight",   ref mOptions.AtlasHeight);

		// --- Font metadata. ---
		var familyName = scope String();
		if (s.IsWriting) familyName.Set(mFont.FamilyName);
		s.String("familyName", familyName);

		var ascent = s.IsWriting ? mFont.Metrics.Ascent : 0f;
		var descent = s.IsWriting ? mFont.Metrics.Descent : 0f;
		var lineGap = s.IsWriting ? mFont.Metrics.LineGap : 0f;
		var mPxH = s.IsWriting ? mFont.Metrics.PixelHeight : 0f;
		var mScale = s.IsWriting ? mFont.Metrics.Scale : 1f;

		s.Float("ascent",      ref ascent);
		s.Float("descent",     ref descent);
		s.Float("lineGap",     ref lineGap);
		s.Float("metricsPxH",  ref mPxH);
		s.Float("metricsScale", ref mScale);

		// --- Atlas dimensions + white-pixel UV. ---
		var atlasW = s.IsWriting ? mAtlas.Width  : 0u;
		var atlasH = s.IsWriting ? mAtlas.Height : 0u;
		s.UInt32("atlasW", ref atlasW);
		s.UInt32("atlasH", ref atlasH);

		var whiteU = s.IsWriting ? mAtlas.WhitePixelUV.U : 0f;
		var whiteV = s.IsWriting ? mAtlas.WhitePixelUV.V : 0f;
		s.Float("whiteU", ref whiteU);
		s.Float("whiteV", ref whiteV);

		// --- Glyph table. One array entry per baked glyph: codepoint + info
		// + atlas region. We iterate the font's glyph dictionary so the
		// serialized order matches what's in memory.
		int32 glyphCount = s.IsWriting ? (int32)mFont.Glyphs.Count : 0;
		s.BeginArray("glyphs", ref glyphCount);
		if (s.IsWriting)
		{
			for (let kv in mFont.Glyphs)
			{
				s.BeginObject("");
				var codepoint = kv.key;
				var info = kv.value;
				s.Int32("cp",   ref codepoint);
				s.Int32("gIdx", ref info.GlyphIndex);
				s.Float("advW", ref info.AdvanceWidth);
				s.Float("lsb",  ref info.LeftSideBearing);
				s.Float("bx",   ref info.BoundingBox.X);
				s.Float("by",   ref info.BoundingBox.Y);
				s.Float("bw",   ref info.BoundingBox.Width);
				s.Float("bh",   ref info.BoundingBox.Height);
				s.Bool ("hb",   ref info.HasBitmap);

				var region = AtlasRegion();
				mAtlas.TryGetRegion(codepoint, out region);
				s.UInt16("rx",  ref region.X);
				s.UInt16("ry",  ref region.Y);
				s.UInt16("rw",  ref region.Width);
				s.UInt16("rh",  ref region.Height);
				s.Float ("rox", ref region.OffsetX);
				s.Float ("roy", ref region.OffsetY);
				s.Float ("rax", ref region.AdvanceX);
				s.EndObject();
			}
		}
		else
		{
			for (int32 i = 0; i < glyphCount; i++)
			{
				s.BeginObject("");
				int32 codepoint = 0;
				GlyphInfo info = .();
				s.Int32("cp",   ref codepoint);
				s.Int32("gIdx", ref info.GlyphIndex);
				s.Float("advW", ref info.AdvanceWidth);
				s.Float("lsb",  ref info.LeftSideBearing);
				s.Float("bx",   ref info.BoundingBox.X);
				s.Float("by",   ref info.BoundingBox.Y);
				s.Float("bw",   ref info.BoundingBox.Width);
				s.Float("bh",   ref info.BoundingBox.Height);
				s.Bool ("hb",   ref info.HasBitmap);
				info.Codepoint = codepoint;

				AtlasRegion region = .();
				s.UInt16("rx",  ref region.X);
				s.UInt16("ry",  ref region.Y);
				s.UInt16("rw",  ref region.Width);
				s.UInt16("rh",  ref region.Height);
				s.Float ("rox", ref region.OffsetX);
				s.Float ("roy", ref region.OffsetY);
				s.Float ("rax", ref region.AdvanceX);

				mFont.SetGlyph(codepoint, info);
				mAtlas.SetRegion(codepoint, region);
				s.EndObject();
			}
		}
		s.EndArray();

		// --- Kerning pairs. Packed key (first << 32 | second) + adjustment. ---
		int32 kernCount = s.IsWriting ? (int32)mFont.Kerning.Count : 0;
		s.BeginArray("kerning", ref kernCount);
		if (s.IsWriting)
		{
			for (let kv in mFont.Kerning)
			{
				s.BeginObject("");
				var packed = kv.key;
				var adj = kv.value;
				s.Int64("p", ref packed);
				s.Float("a", ref adj);
				s.EndObject();
			}
		}
		else
		{
			for (int32 i = 0; i < kernCount; i++)
			{
				s.BeginObject("");
				int64 packed = 0;
				float adj = 0;
				s.Int64("p", ref packed);
				s.Float("a", ref adj);
				let first = (int32)(packed >> 32);
				let second = (int32)(packed & 0xFFFFFFFF);
				mFont.SetKerning(first, second, adj);
				s.EndObject();
			}
		}
		s.EndArray();

		// On reading, finalize the in-memory baked instances with the
		// metadata we've populated. The atlas's pixel buffer is filled
		// either here with zeros (so dimensions are valid even with no
		// sidecar) or replaced by the resource manager with the real
		// bytes after this returns.
		if (s.IsReading)
		{
			mFont.SetFamilyName(familyName);
			mFont.SetPixelHeight(mPxH);
			mFont.SetMetrics(.(ascent, descent, lineGap, mPxH, mScale));
			mAtlas.SetWhitePixelUV(whiteU, whiteV);
			// Atlas dims also captured in mOptions so the manager knows how
			// much pixel data to expect in the sidecar.
			mOptions.AtlasWidth = atlasW;
			mOptions.AtlasHeight = atlasH;
			// Reserve a zeroed pixel buffer at the recorded dimensions; the
			// manager will overwrite it via SetPixels once the sidecar is
			// read. Tests that skip the sidecar still get a usable atlas
			// (width/height match) with blank pixels.
			let placeholder = new uint8[(int)atlasW * (int)atlasH];
			mAtlas.SetPixels(atlasW, atlasH, placeholder);
		}

		return .Ok;
	}
}
