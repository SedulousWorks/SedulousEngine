using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// The drawing surface: what a call appends, and when the batch is cut.
class VGContextTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// The white texel sits at index zero, which is what lets a solid draw share the
	/// textured pipeline.
	[Test]
	public static void TheWhiteTextureSitsAtIndexZero()
	{
		let context = scope VGContext();
		let batch = context.GetBatch();

		Test.Assert(batch.Textures.Count == 1);
		Test.Assert(batch.Textures[0] != null);
		Test.Assert(batch.Textures[0].Width == 1);
		Test.Assert(batch.Textures[0].Height == 1);
	}

	[Test]
	public static void FillingARectProducesGeometryAndACommand()
	{
		let context = scope VGContext();
		context.FillRect(.(10, 10, 100, 50), .Red);

		let batch = context.GetBatch();
		Test.Assert(!batch.IsEmpty);
		Test.Assert(batch.Commands.Count == 1);
		Test.Assert(batch.Commands[0].TextureIndex == 0, "the solid passthrough");
		Test.Assert(batch.Commands[0].IndexCount == batch.Indices.Count);
	}

	/// An axis aligned rectangle is snapped and drawn WITHOUT a fringe, because an edge on
	/// a pixel boundary is already crisp.
	[Test]
	public static void AnAxisAlignedRectIsSnappedAndFringeless()
	{
		let context = scope VGContext();
		context.FillRect(.(10.3f, 10.7f, 100.2f, 50.4f), .Red);

		let batch = context.GetBatch();
		Test.Assert(batch.Vertices.Count == 4, "four corners, no fringe ring");
		for (let vertex in batch.Vertices)
		{
			Test.Assert(vertex.Coverage == 1.0f);
			Test.Assert(Near(vertex.Position.X, Round(vertex.Position.X)), "on the pixel grid");
			Test.Assert(Near(vertex.Position.Y, Round(vertex.Position.Y)));
		}
	}

	/// With snapping off it goes through the tessellator and gets its fringe.
	[Test]
	public static void SnappingCanBeTurnedOff()
	{
		let context = scope VGContext();
		context.SetPixelSnapEnabled(false);
		Test.Assert(!context.PixelSnapEnabled);

		context.FillRect(.(10.3f, 10.7f, 100.2f, 50.4f), .Red);

		let batch = context.GetBatch();
		Test.Assert(batch.Vertices.Count == 8, "an inner ring and an outer one");
	}

	/// A rotated transform is not axis aligned, so snapping does not apply and the shape
	/// keeps its analytic edges.
	[Test]
	public static void ARotatedRectIsNotSnapped()
	{
		let context = scope VGContext();
		context.Rotate(0.3f);
		context.FillRect(.(10, 10, 100, 50), .Red);

		let batch = context.GetBatch();
		Test.Assert(batch.Vertices.Count == 8);
	}

	[Test]
	public static void StrokingARectProducesOutput()
	{
		let context = scope VGContext();
		context.StrokeRect(.(10, 10, 100, 50), .Blue, 2.0f);

		let batch = context.GetBatch();
		Test.Assert(!batch.IsEmpty);
		// Four snapped bars, each a quad.
		Test.Assert(batch.Vertices.Count == 16);
	}

	[Test]
	public static void TheShapeHelpersAllProduceGeometry()
	{
		let context = scope VGContext();
		context.FillCircle(.(50, 50), 25, .Red);
		context.FillEllipse(.(50, 50), 30, 10, .Red);
		context.FillRegularPolygon(.(50, 50), 25, 6, .Red);
		context.FillStar(.(50, 50), 25, 10, 5, .Red);
		context.FillRoundedRect(.(0, 0, 100, 50), 8.0f, .Red);
		context.StrokeCircle(.(50, 50), 25, .Blue);
		context.StrokeEllipse(.(50, 50), 30, 10, .Blue);
		context.StrokeRoundedRect(.(0, 0, 100, 50), 8.0f, .Blue);
		context.DrawLine(.(0, 0), .(50, 70), .Blue);

		Test.Assert(!context.GetBatch().IsEmpty);
	}

	/// A rounded rect with no radius is a rectangle, which takes the crisper path.
	[Test]
	public static void AZeroRadiusRoundedRectIsARect()
	{
		let context = scope VGContext();
		context.FillRoundedRect(.(0, 0, 100, 50), CornerRadii(0.0f), .Red);

		Test.Assert(context.GetBatch().Vertices.Count == 4);
	}

	[Test]
	public static void APolygonNeedsThreePoints()
	{
		let context = scope VGContext();
		context.FillPolygon(scope Float2[](.(0, 0), .(10, 0)), .Red);
		Test.Assert(context.GetBatch().IsEmpty);

		context.FillPolygon(scope Float2[](.(0, 0), .(10, 0), .(5, 10)), .Red);
		Test.Assert(!context.GetBatch().IsEmpty);
	}

	// ---- transform ----

	/// The transform is BAKED into the emitted vertices, so a renderer never sees one.
	[Test]
	public static void TheTransformIsBakedIntoTheVertices()
	{
		let context = scope VGContext();
		context.Translate(100, 200);
		context.SetPixelSnapEnabled(false);
		context.FillRect(.(0, 0, 10, 10), .Red);

		let batch = context.GetBatch();
		var minX = FloatMax;
		for (let vertex in batch.Vertices)
			minX = Min(minX, vertex.Position.X);

		Test.Assert(minX > 90.0f, "moved by the translation");
	}

	[Test]
	public static void TheStateStackSavesAndRestoresTheTransform()
	{
		let context = scope VGContext();
		let identity = context.GetTransform();

		context.PushState();
		context.Translate(50, 50);
		context.Rotate(1.0f);
		context.Scale(2, 2);
		Test.Assert(!(context.GetTransform() == identity));

		context.PopState();
		Test.Assert(context.GetTransform() == identity);
	}

	/// An unbalanced pop leaves the state alone rather than faulting.
	[Test]
	public static void AnUnbalancedPopIsHarmless()
	{
		let context = scope VGContext();
		context.PopState();
		context.PopClip();
		context.PopOpacity();
		Test.Assert(context.Opacity == 1.0f);
	}

	// ---- clipping ----

	[Test]
	public static void AClipRectRidesTheCommand()
	{
		let context = scope VGContext();
		context.PushClipRect(.(0, 0, 50, 50));
		context.FillRect(.(10, 10, 100, 100), .Red);

		let batch = context.GetBatch();
		Test.Assert(batch.Commands[0].ClipMode == .Scissor);
		Test.Assert(batch.Commands[0].ClipRect.Width == 50.0f);
	}

	/// A nested clip can only SHRINK the visible region, so it is intersected rather than
	/// replaced.
	[Test]
	public static void ANestedClipIntersects()
	{
		let context = scope VGContext();
		context.PushClipRect(.(0, 0, 100, 100));
		context.PushClipRect(.(50, 50, 100, 100));
		context.FillRect(.(0, 0, 200, 200), .Red);

		let batch = context.GetBatch();
		let clip = batch.Commands[0].ClipRect;
		Test.Assert(Near(clip.X, 50.0f) && Near(clip.Y, 50.0f));
		Test.Assert(Near(clip.Width, 50.0f), "the overlap of the two");
	}

	[Test]
	public static void PoppingAClipRestoresTheOuterOne()
	{
		let context = scope VGContext();
		context.PushClipRect(.(0, 0, 100, 100));
		context.PushClipRect(.(50, 50, 10, 10));
		context.PopClip();
		context.FillRect(.(0, 0, 200, 200), .Red);

		let batch = context.GetBatch();
		Test.Assert(Near(batch.Commands[0].ClipRect.Width, 100.0f));

		context.PopClip();
		context.FillRect(.(0, 0, 200, 200), .Red);
		let after = context.GetBatch();
		Test.Assert(after.Commands[after.Commands.Count - 1].ClipMode == .None);
	}

	/// The visibility query is what lets a caller skip tessellating geometry the scissor
	/// would discard anyway.
	[Test]
	public static void VisibilityTracksTheScissor()
	{
		let context = scope VGContext();
		Test.Assert(context.IsRectVisible(.(1000, 1000, 10, 10)), "no clip, everything shows");

		context.PushClipRect(.(0, 0, 100, 100));
		Test.Assert(context.IsRectVisible(.(10, 10, 10, 10)));
		Test.Assert(context.IsRectVisible(.(90, 90, 50, 50)), "partly inside still counts");
		Test.Assert(!context.IsRectVisible(.(200, 200, 10, 10)));

		// A degenerate clip shows nothing at all.
		context.PushClipRect(.(0, 0, 0, 0));
		Test.Assert(!context.IsRectVisible(.(10, 10, 10, 10)));
	}

	/// A transformed rect is the bounds of its four corners: two opposite corners alone swap
	/// under a rotation or a flip, giving a negative size.
	[Test]
	public static void VisibilityAndAClipRectHoldUnderARotationOrAFlip()
	{
		let context = scope VGContext();
		context.PushClipRect(.(0, 0, 100, 100));

		// Turned half way round about (50, 50): the box stays where it was, its corners
		// swapped. The last call applies to points first.
		context.PushState();
		context.Translate(50.0f, 50.0f);
		context.Rotate(Math.PI_f);
		context.Translate(-50.0f, -50.0f);
		Test.Assert(context.IsRectVisible(.(40, 40, 20, 20)));
		Test.Assert(!context.IsRectVisible(.(-300, 40, 20, 20)), "turned to x = 380");
		Test.Assert(context.IsRectVisible(.(90, 40, 20, 20)), "turned to straddle the left edge");
		context.PopState();

		// Flipped: a rect clip pushed inside keeps a positive size.
		context.PushState();
		context.Translate(100.0f, 0.0f);
		context.Scale(-1.0f, 1.0f);
		context.PushClipRect(.(10, 10, 30, 30)); // at x 60 to 90 once flipped
		Test.Assert(context.IsRectVisible(.(20, 20, 5, 5)));
		Test.Assert(!context.IsRectVisible(.(70, 20, 5, 5)));
		context.PopClip();
		context.PopState();
	}

	// ---- opacity ----

	[Test]
	public static void OpacityScalesTheVertexAlpha()
	{
		let context = scope VGContext();
		context.PushOpacity(0.5f);
		context.FillRect(.(0, 0, 10, 10), .(1, 0, 0, 1));

		let batch = context.GetBatch();
		Test.Assert(Near(batch.Vertices[0].Color.A, 0.5f));
		Test.Assert(batch.Vertices[0].Color.R == 1.0f, "only the alpha moved");
	}

	/// Nesting MULTIPLIES, so two halves give a quarter.
	[Test]
	public static void NestedOpacityMultiplies()
	{
		let context = scope VGContext();
		context.PushOpacity(0.5f);
		context.PushOpacity(0.5f);
		Test.Assert(Near(context.Opacity, 0.25f));

		context.PopOpacity();
		Test.Assert(Near(context.Opacity, 0.5f));
	}

	/// It is clamped, so a caller cannot brighten by asking for more than one.
	[Test]
	public static void OpacityIsClamped()
	{
		let context = scope VGContext();
		context.PushOpacity(4.0f);
		Test.Assert(context.Opacity == 1.0f);

		context.PushOpacity(-1.0f);
		Test.Assert(context.Opacity == 0.0f);
	}

	// ---- batching ----

	/// A blend mode is a property of the DRAW rather than of a vertex, so changing it cuts
	/// the batch.
	[Test]
	public static void ABlendModeChangeCutsTheBatch()
	{
		let context = scope VGContext();
		context.FillRect(.(0, 0, 10, 10), .Red);
		context.SetBlendMode(.Additive);
		context.FillRect(.(20, 0, 10, 10), .Red);

		let batch = context.GetBatch();
		Test.Assert(batch.Commands.Count == 2);
		Test.Assert(batch.Commands[0].BlendMode == .Normal);
		Test.Assert(batch.Commands[1].BlendMode == .Additive);
	}

	/// Setting the same mode again does not, or every draw would be its own command.
	[Test]
	public static void SettingTheSameModeDoesNotCutTheBatch()
	{
		let context = scope VGContext();
		context.FillRect(.(0, 0, 10, 10), .Red);
		context.SetBlendMode(.Normal);
		context.FillRect(.(20, 0, 10, 10), .Red);

		Test.Assert(context.GetBatch().Commands.Count == 1);
	}

	[Test]
	public static void AGradientSpreadChangeCutsTheBatch()
	{
		let context = scope VGContext();
		context.FillRect(.(0, 0, 10, 10), .Red);
		context.SetGradientSpread(.Repeat);
		context.FillRect(.(20, 0, 10, 10), .Red);

		let batch = context.GetBatch();
		Test.Assert(batch.Commands.Count == 2);
		Test.Assert(batch.Commands[1].GradientSpread == .Repeat);
	}

	// ---- the immediate mode path ----

	[Test]
	public static void TheImmediatePathFillsWhatWasBuilt()
	{
		let context = scope VGContext();
		context.BeginPath();
		context.MoveTo(0, 0);
		context.LineTo(10, 0);
		context.LineTo(10, 10);
		context.ClosePath();
		Test.Assert(context.CurrentPoint == Float2(0, 0), "the close returned the pen");
		context.Fill(.Red);

		Test.Assert(!context.GetBatch().IsEmpty);
	}

	/// An empty path draws nothing rather than emitting a degenerate command.
	[Test]
	public static void AnEmptyImmediatePathDrawsNothing()
	{
		let context = scope VGContext();
		context.BeginPath();
		context.Fill(.Red);
		context.Stroke(.Blue);
		Test.Assert(context.GetBatch().IsEmpty);
	}

	/// Beginning again discards what was there.
	[Test]
	public static void BeginningAgainDiscardsThePreviousPath()
	{
		let context = scope VGContext();
		context.BeginPath();
		context.MoveTo(0, 0);
		context.LineTo(100, 100);
		context.BeginPath();
		context.Stroke(.Blue);
		Test.Assert(context.GetBatch().IsEmpty);
	}

	// ---- images ----

	[Test]
	public static void DrawingAnImageRegistersItAndSwitchesCommand()
	{
		let context = scope VGContext();
		let image = scope OwnedImageData(4, 4, .RGBA8, .(), .Linear);

		context.FillRect(.(0, 0, 10, 10), .Red);
		context.DrawImage(image, Float2(0, 0));

		let batch = context.GetBatch();
		Test.Assert(batch.Textures.Count == 2, "the white one and this");
		Test.Assert(batch.Commands.Count == 2);
		Test.Assert(batch.Commands[0].TextureIndex == 0);
		Test.Assert(batch.Commands[1].TextureIndex == 1);
	}

	/// The same image twice reuses its slot rather than appending it again.
	[Test]
	public static void TheSameImageReusesItsSlot()
	{
		let context = scope VGContext();
		let image = scope OwnedImageData(4, 4, .RGBA8, .(), .Linear);

		context.DrawImage(image, Float2(0, 0));
		context.DrawImage(image, Float2(20, 0));

		let batch = context.GetBatch();
		Test.Assert(batch.Textures.Count == 2);
		Test.Assert(batch.Commands.Count == 1, "one command, no state change between them");
	}

	[Test]
	public static void ANullImageDrawsNothing()
	{
		let context = scope VGContext();
		context.DrawImage((ImageData)null, Float2(0, 0));
		context.DrawImage((ImageData)null, Rectangle(0, 0, 10, 10));
		Test.Assert(context.GetBatch().IsEmpty);
	}

	/// A snapped image lands on the pixel grid, so every instance samples the same texels
	/// rather than smearing differently.
	[Test]
	public static void ASnappedImageLandsOnThePixelGrid()
	{
		let context = scope VGContext();
		let image = scope OwnedImageData(4, 4, .RGBA8, .(), .Linear);

		context.DrawImageSnapped(image, .(10.3f, 20.7f, 4, 4), .(0, 0, 4, 4));

		let batch = context.GetBatch();
		for (let vertex in batch.Vertices)
		{
			Test.Assert(Near(vertex.Position.X, Round(vertex.Position.X)));
			Test.Assert(Near(vertex.Position.Y, Round(vertex.Position.Y)));
		}
	}

	/// A nine slice emits nine quads: the corners keep their size and the rest stretches.
	[Test]
	public static void ANineSliceEmitsNineQuads()
	{
		let context = scope VGContext();
		let image = scope OwnedImageData(16, 16, .RGBA8, .(), .Linear);

		var slices = NineSlice();
		slices.Left = 4;
		slices.Top = 4;
		slices.Right = 4;
		slices.Bottom = 4;

		context.DrawNineSlice(image, .(0, 0, 100, 100), .(0, 0, 16, 16), slices, .White);

		let batch = context.GetBatch();
		Test.Assert(batch.Vertices.Count == 36, "nine quads of four");
		Test.Assert(batch.Indices.Count == 54);
	}

	// ---- clearing ----

	[Test]
	public static void ClearingResetsAndReseedsTheWhiteTexture()
	{
		let context = scope VGContext();
		let image = scope OwnedImageData(4, 4, .RGBA8, .(), .Linear);

		context.PushOpacity(0.5f);
		context.PushClipRect(.(0, 0, 10, 10));
		context.SetBlendMode(.Additive);
		context.DrawImage(image, Float2(0, 0));

		context.Clear();
		let batch = context.GetBatch();

		Test.Assert(batch.IsEmpty);
		Test.Assert(batch.Textures.Count == 1, "reseeded with white at index zero");
		Test.Assert(context.Opacity == 1.0f);
		Test.Assert(context.IsRectVisible(.(1000, 1000, 1, 1)), "the clip went with it");
	}

	/// A card's thumbnail with rounded corners: the picture is cut to the rounded rect (no
	/// opaque vertex in a corner's cut-away), each vertex samples the texel of its place in the
	/// dest rect (worked out before the transform), the fringe clamps to the source, and no
	/// radius is the plain image quad.
	[Test]
	public static void DrawImageRoundedMapsTheTextureOntoARoundedRectCutAtItsCorners()
	{
		let context = scope VGContext();
		let texture = scope OwnedImageData(200, 100, .RGBA8, .(), .Linear);
		let dest = Rectangle(10.0f, 20.0f, 100.0f, 50.0f);
		let src = Rectangle(100.0f, 0.0f, 100.0f, 100.0f); // the right half of the texture
		context.PushState();
		context.Translate(5.0f, 0.0f);
		context.DrawImageRounded(texture, dest, src, .(10.0f));
		context.PopState();

		let batch = context.GetBatch();
		Test.Assert((batch.Textures.Count == 2) && (batch.Textures[1] == texture));
		Test.Assert(batch.CommandCount == 1);
		Test.Assert(batch.GetCommand(0).TextureIndex == 1);
		Test.Assert(batch.Vertices.Count > 4);

		var sawLeftEdge = false;
		for (let v in batch.Vertices)
		{
			let x = v.Position.X - 5.0f; // back to the dest rect's space
			let y = v.Position.Y;
			Test.Assert((v.TexCoord.X >= 0.5f - 1e-4f) && (v.TexCoord.X <= 1.0f + 1e-4f), "inside the source half, the fringe clamped");
			Test.Assert((v.TexCoord.Y >= -1e-4f) && (v.TexCoord.Y <= 1.0f + 1e-4f));
			if (v.Coverage < 1.0f)
				continue;
			// An opaque vertex lies inside the rounded rect: in the top left corner, within the
			// radius of the corner's centre.
			if ((x < 20.0f) && (y < 30.0f))
			{
				let dx = x - 20.0f;
				let dy = y - 30.0f;
				Test.Assert(dx * dx + dy * dy <= 10.0f * 10.0f + 0.5f);
			}
			if ((x < 11.0f) && (y >= 29.0f) && (y <= 61.0f)) // the left edge, inset half a fringe
			{
				sawLeftEdge = true;
				Test.Assert(Near(v.TexCoord.X, 0.5f + (x - 10.0f) / 200.0f, 0.001f));
				Test.Assert(Near(v.TexCoord.Y, (y - 20.0f) / 50.0f, 0.001f));
			}
		}
		Test.Assert(sawLeftEdge);

		let square = scope VGContext();
		square.DrawImageRounded(texture, dest, src, .(0.0f));
		Test.Assert(square.GetBatch().Vertices.Count == 4);

		Test.Assert(CornerRadii(3.0f) == CornerRadii(3.0f));
		Test.Assert(CornerRadii(3.0f) != CornerRadii(3.0f, 3.0f, 3.0f, 4.0f));
	}

	// ---- text ----

	/// An atlas whose glyphs are not their codepoints: 'A' is glyph 7 and 'B' has none, as a
	/// font's own glyph ids are.
	class GlyphIdAtlas : IFontAtlas
	{
		/// A distance-field atlas when asked (effects read its range): 4 texels, one texel a pixel.
		public AtlasMode AtlasMode = .Coverage;
		public override AtlasMode Mode => AtlasMode;
		public override float DistanceFieldRange => (AtlasMode == .DistanceField) ? 4.0f : 0.0f;
		public override uint32 Width => 64;
		public override uint32 Height => 64;
		public override Span<uint8> PixelData => .();
		public override Float2 WhitePixelUV => .(0.5f, 0.5f);
		public override int32 GlyphFor(int32 codepoint) => (codepoint == (int32)'A') ? 7 : -1;
		public override bool Contains(int32 glyph) => glyph == 7;

		public override bool TryGetRegion(int32 glyph, out AtlasRegion region)
		{
			region = (glyph == 7) ? .(0, 0, 8, 8, 0.0f, -8.0f, 10.0f) : .();
			return glyph == 7;
		}

		public override bool GetGlyphQuad(int32 glyph, ref float cursorX, float cursorY, out GlyphQuad quad)
		{
			quad = .();
			if (glyph != 7)
				return false;
			quad = .(cursorX, cursorY - 8.0f, cursorX + 8.0f, cursorY, 0, 0, 0.125f, 0.125f);
			cursorX += 10.0f;
			return true;
		}

		public override bool GetGlyphQuadAt(int32 glyph, float x, float y, out GlyphQuad quad)
		{
			var cursor = x;
			return GetGlyphQuad(glyph, ref cursor, y, out quad);
		}
	}

	[Test]
	public static void UnshapedTextDrawsEachCodepointsGlyphByTheAtlassGlyphId()
	{
		let atlas = scope GlyphIdAtlas();
		let texture = scope OwnedImageData(64, 64, .RGBA8, .(), .Linear);
		let context = scope VGContext();
		context.DrawText("AAB", atlas, texture, .(0.0f, 20.0f), .White);
		// Two quads (glyph 7 twice); 'B' has no glyph and draws nothing.
		int quads = 0;
		for (let command in context.GetBatch().Commands)
			quads += command.IndexCount / 6;
		Test.Assert(quads == 2, scope $"{quads} quads");
	}

	/// The first vertex of each quad of a batch, in draw order.
	private static void QuadCorners(VGBatch batch, List<VGVertex> outCorners)
	{
		outCorners.Clear();
		for (int i = 0; (i + 3) < batch.Vertices.Count; i += 4)
			outCorners.Add(batch.Vertices[i]);
	}

	[Test]
	public static void TextEffectsDrawAShadowAGlowAndAnOutlineUnderTheGlyphs()
	{
		let atlas = scope GlyphIdAtlas();
		atlas.AtlasMode = .DistanceField;
		let texture = scope OwnedImageData(64, 64, .RGBA8, .(), .Linear);
		let context = scope VGContext();
		var effects = TextEffects();
		effects.ShadowOffset = .(3.0f, 2.0f);
		effects.ShadowBlur = 1.0f;
		effects.ShadowColor = .(0.0f, 0.0f, 1.0f, 1.0f);
		effects.GlowRadius = 1.0f;
		effects.GlowColor = .(0.0f, 1.0f, 0.0f, 1.0f);
		effects.OutlineWidth = 1.0f;
		effects.OutlineColor = .(1.0f, 0.0f, 0.0f, 1.0f);
		context.SetTextEffects(effects);
		context.DrawText("A", atlas, texture, .(10.0f, 20.0f), .White);

		let quads = scope List<VGVertex>();
		QuadCorners(context.GetBatch(), quads);
		Test.Assert(quads.Count == 4);
		// One texel a pixel over a 4-texel range: a pixel is a quarter of the field's unit.
		// The shadow: offset, blurred over a pixel, its edge where the glyph's is.
		Test.Assert(Near(quads[0].Position.X, 13.0f));
		Test.Assert(Near(quads[0].Position.Y, 14.0f));
		Test.Assert(Near(quads[0].Color.B, 1.0f));
		Test.Assert(Near(quads[0].Effect.X, 0.0f));
		Test.Assert(Near(quads[0].Effect.Y, 0.25f));
		// The glow: full at the edge, gone a pixel past it (centred half a pixel out).
		Test.Assert(Near(quads[1].Position.X, 10.0f));
		Test.Assert(Near(quads[1].Color.G, 1.0f));
		Test.Assert(Near(quads[1].Effect.X, 0.125f));
		Test.Assert(Near(quads[1].Effect.Y, 0.25f));
		// The outline: the edge moved a pixel out, sharp.
		Test.Assert(Near(quads[2].Color.R, 1.0f));
		Test.Assert(Near(quads[2].Effect.X, 0.25f));
		Test.Assert(Near(quads[2].Effect.Y, 0.0f));
		// The glyphs last, as without effects.
		Test.Assert(Near(quads[3].Position.X, 10.0f));
		Test.Assert(Near(quads[3].Effect.X, 0.0f));
		Test.Assert(Near(quads[3].Effect.Y, 0.0f));
	}

	[Test]
	public static void ATextEffectWiderThanTheFieldHoldsIsScaledDownToFit()
	{
		let atlas = scope GlyphIdAtlas();
		atlas.AtlasMode = .DistanceField;
		let texture = scope OwnedImageData(64, 64, .RGBA8, .(), .Linear);
		let context = scope VGContext();
		var effects = TextEffects();
		effects.OutlineWidth = 6.0f; // 1.5 field units; the field ends half a unit past the edge
		context.SetTextEffects(effects);
		context.DrawText("A", atlas, texture, .(0.0f, 20.0f), .White);
		let quads = scope List<VGVertex>();
		QuadCorners(context.GetBatch(), quads);
		Test.Assert(quads.Count == 2);
		Test.Assert(Near(quads[0].Effect.X, 0.49f, 0.001f));
	}

	[Test]
	public static void ACoverageFontDrawsOnlyAShadowsOffsetCopyAndEffectsAreState()
	{
		let atlas = scope GlyphIdAtlas(); // coverage: no field to grow or soften
		let texture = scope OwnedImageData(64, 64, .RGBA8, .(), .Linear);
		let context = scope VGContext();
		var effects = TextEffects();
		effects.ShadowOffset = .(2.0f, 2.0f);
		effects.ShadowBlur = 3.0f;
		effects.ShadowColor = .(0.0f, 0.0f, 0.0f, 1.0f);
		effects.OutlineWidth = 1.0f;
		effects.GlowRadius = 2.0f;
		context.PushState();
		context.SetTextEffects(effects);
		context.DrawText("A", atlas, texture, .(0.0f, 20.0f), .White);
		let quads = scope List<VGVertex>();
		QuadCorners(context.GetBatch(), quads);
		Test.Assert(quads.Count == 2, "the shadow, then the glyph");
		Test.Assert(Near(quads[0].Position.X, 2.0f));
		Test.Assert(Near(quads[0].Effect.Y, 0.0f));
		context.PopState();
		Test.Assert(!context.TextEffects.Any);
		context.DrawText("A", atlas, texture, .(0.0f, 40.0f), .White);
		QuadCorners(context.GetBatch(), quads);
		Test.Assert(quads.Count == 3, "one more: the glyph alone");
	}
}
