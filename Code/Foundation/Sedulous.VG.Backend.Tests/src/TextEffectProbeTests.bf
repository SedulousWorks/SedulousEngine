using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.DistanceField.Baker;
using Sedulous.Fonts.TrueType;
using Sedulous.Image;
using Sedulous.RHI.TestSupport;
using Sedulous.VG;
using internal Sedulous.VG.Backend.Tests;

namespace Sedulous.VG.Backend.Tests;

/// Text effects on the GPU: a distance-field 'I' (one rectangle) baked at 48 px and drawn at
/// that size, so a pixel of the text is a texel of the bake. In an Encoded canvas a byte is
/// coverage, so a row's coverage sums to the widths it crosses: an outline adds its width each
/// side of the stem and leaves the stem as it was; a hard shadow lands its offset away.
class TextEffectProbeTests
{
	private const float cStemX = 40.0f;
	private const float cBaseline = 90.0f;
	private const uint32 cSize = VGSceneRenderer.Size;

	/// A row's coverage summed, of one channel.
	private static float RowCoverage(CapturedImage image, uint32 y, int channel)
	{
		float sum = 0;
		for (uint32 x < cSize)
			sum += (float)image.At(x, y)[channel] / 255.0f;
		return sum;
	}

	/// The last column (or row) along a line where a channel passes half.
	private static int32 LastInked(CapturedImage image, bool alongRow, uint32 line, int channel)
	{
		int32 last = -1;
		for (uint32 i < cSize)
		{
			if ((alongRow ? image.At(i, line) : image.At(line, i))[channel] > 127)
				last = (int32)i;
		}
		return last;
	}

	[Test]
	public static void ADistanceFieldOutlinesWidthAndAShadowsOffsetInPixels()
	{
		let path = scope String();
		if (!BakedFontProbeTests.FindTestFont(path))
			return;
		var options = FontLoadOptions.DistanceField();
		options.PixelHeight = 48.0f;
		let parser = scope TrueTypeFontParser();
		Test.Assert(parser.ParseFromFile(path, options) case .Ok(let font));
		defer delete font;
		let baker = scope DistanceFieldFontAtlasBaker();
		Test.Assert(baker.Bake(font, options) case .Ok(let atlas));
		defer delete atlas;
		let texture = scope OwnedImageData(atlas.Width, atlas.Height, .RGBA8, atlas.PixelData, .Linear);
		Test.Assert(atlas.TryGetRegion(atlas.GlyphFor((int32)'I'), let region));
		let capTop = -region.OffsetY - (float)options.Padding - 1.0f;
		let middle = (uint32)(cBaseline - capTop * 0.5f);

		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
		{
			let fixture = scope VGProbeFixture(kind);
			if (!fixture.Ready)
				continue;
			CapturedImage Draw(TextEffects effects)
			{
				return VGSceneRenderer.RenderScene(fixture, scope (context) =>
					{
						context.SetTextEffects(effects);
						context.DrawText("I", atlas, texture, .(cStemX, cBaseline), .(0.0f, 1.0f, 0.0f, 1.0f));
					}, 1, .Encoded);
			}

			let plain = Draw(.());
			defer delete plain;
			var outlined = TextEffects();
			outlined.OutlineWidth = 1.5f;
			outlined.OutlineColor = .(1.0f, 0.0f, 0.0f, 1.0f);
			let outline = Draw(outlined);
			defer delete outline;
			Test.Assert((plain != null) && plain.Valid && (outline != null) && outline.Valid, "the scenes rendered");

			let stem = RowCoverage(plain, middle, 1);
			let stemOutlined = RowCoverage(outline, middle, 1);
			let ring = RowCoverage(outline, middle, 0);
			let detail = scope $"{kind}: stem {stem} px, outlined {stemOutlined} px, outline {ring} px across";
			Test.Assert(stem > 3.0f, detail);
			Test.Assert(Math.Abs(stemOutlined - stem) < 0.5f, detail); // drawn as it was, over the outline
			Test.Assert(Math.Abs(ring - 3.0f) < 0.6f, detail); // 1.5 px each side

			var shadowed = TextEffects();
			shadowed.ShadowOffset = .(5.0f, 3.0f);
			shadowed.ShadowColor = .(0.0f, 0.0f, 1.0f, 1.0f);
			let shadow = Draw(shadowed);
			defer delete shadow;
			Test.Assert((shadow != null) && shadow.Valid);
			let stemRight = LastInked(shadow, true, middle, 1);
			let shadowRight = LastInked(shadow, true, middle, 2);
			let stemColumn = (uint32)(stemRight - 1);
			let stemBottom = LastInked(shadow, false, stemColumn, 1);
			let shadowBottom = LastInked(shadow, false, stemColumn + 5, 2);
			let edges = scope $"{kind}: right edges {stemRight}/{shadowRight}, bottoms {stemBottom}/{shadowBottom}";
			Test.Assert(stemRight >= 0, edges);
			Test.Assert(shadowRight - stemRight == 5, edges);
			Test.Assert(shadowBottom - stemBottom == 3, edges);
		}
	}
}
