using System;
using System.Collections;
using Sedulous.Core;
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
}
