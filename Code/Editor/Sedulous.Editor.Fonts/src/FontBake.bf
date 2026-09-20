using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Fonts;
using Sedulous.Fonts.Coverage.Baker;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Editor.Fonts;

/// The preview bake itself, off any thread: reads the source and bakes a coverage atlas
/// (expanded to RGBA8) or a distance field one (its median decoded to alpha so it reads as
/// glyphs rather than a field).
static class FontBake
{
	public static void Run(FontBakeRequest request, FontBakeOutcome outcome)
	{
		outcome.Generation = request.Generation;
		outcome.Size = request.Size;
		if (!request.Valid)
			return;
		let bytes = scope List<uint8>();
		if (!(ReadFile(request.Path, bytes) case .Ok))
			return;
		var options = request.DistanceField ? FontLoadOptions.DistanceField() : FontLoadOptions.Default();
		options.PixelHeight = request.Size;
		options.FirstCodepoint = request.FirstCodepoint;
		options.LastCodepoint = request.LastCodepoint;
		options.AtlasWidth = request.AtlasWidth;
		options.AtlasHeight = request.AtlasHeight;
		if (request.DistanceField)
			BakeDistanceField(bytes, options, outcome);
		else
			BakeCoverage(bytes, options, outcome);
	}

	private static void BakeCoverage(List<uint8> bytes, FontLoadOptions options, FontBakeOutcome outcome)
	{
		if (!(FontBaker.Bake(bytes, options) case .Ok(let data)))
			return;
		defer delete data;
		outcome.Glyphs = CountGlyphs(data.Atlas, options);
		outcome.Image = FontAtlasTexture.ExpandR8ToRGBA8(data.Atlas);
	}

	private static void BakeDistanceField(List<uint8> bytes, FontLoadOptions options, FontBakeOutcome outcome)
	{
		let copy = new List<uint8>(); // the font takes it
		copy.AddRange(bytes);
		let font = scope TrueTypeFont();
		if (font.Initialize(copy, options.PixelHeight) != .Success)
			return;
		if (!(FontAtlasBakerFactory.Bake(font, options) case .Ok(let atlas)))
			return;
		defer delete atlas;
		outcome.Glyphs = CountGlyphs(atlas, options);
		let field = atlas.PixelData;
		let decoded = new List<uint8>(); // handed to the image
		decoded.Resize(field.Length);
		for (int px = 0; px + 3 < field.Length; px += 4)
		{
			let r = field[px];
			let g = field[px + 1];
			let b = field[px + 2];
			let med = Math.Max(Math.Min(r, g), Math.Min(Math.Max(r, g), b));
			let alpha = Math.Clamp(((int32)med - 112) * 8, 0, 255);
			decoded[px] = 255;
			decoded[px + 1] = 255;
			decoded[px + 2] = 255;
			decoded[px + 3] = (uint8)alpha;
		}
		outcome.Image = new OwnedImageData(atlas.Width, atlas.Height, .RGBA8, decoded, .Linear);
	}

	private static int CountGlyphs(IFontAtlas atlas, FontLoadOptions options)
	{
		int glyphs = 0;
		for (int32 cp = options.FirstCodepoint; cp <= options.LastCodepoint; cp++)
		{
			if (atlas.Contains(cp))
				glyphs++;
		}
		return glyphs;
	}
}
