using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Stencil then cover: the fills ear clipping cannot get right, and path clipping.
class VGStencilTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static void AppendRect(PathBuilder builder, float x, float y, float w, float h,
		bool reversed = false)
	{
		builder.MoveTo(x, y);
		if (reversed)
		{
			builder.LineTo(x, y + h);
			builder.LineTo(x + w, y + h);
			builder.LineTo(x + w, y);
		}
		else
		{
			builder.LineTo(x + w, y);
			builder.LineTo(x + w, y + h);
			builder.LineTo(x, y + h);
		}
		builder.Close();
	}

	/// A square with a hole: two contours, which ear clipping cannot resolve under either
	/// rule.
	private static Path SquareWithHole()
	{
		let builder = scope PathBuilder();
		AppendRect(builder, 0, 0, 100, 100);
		AppendRect(builder, 25, 25, 50, 50, true);
		return builder.ToPath();
	}

	private static int CountPhase(VGBatch batch, VGFillPhase phase)
	{
		var count = 0;
		for (let command in batch.Commands)
		{
			if (command.FillPhase == phase)
				count++;
		}
		return count;
	}

	/// Off by default, so a host that never gave the renderer a stencil attachment keeps
	/// every fill on the direct tessellator.
	[Test]
	public static void StencilFillsAreOffByDefault()
	{
		let context = scope VGContext();
		Test.Assert(!context.StencilFills);

		let path = SquareWithHole();
		defer delete path;
		context.FillPath(path, .Red);

		let batch = context.GetBatch();
		Test.Assert(CountPhase(batch, .Direct) == batch.Commands.Count, "all direct");
	}

	/// A hole emits the two passes: a colour masked winding pass, then a cover.
	[Test]
	public static void AHoleEmitsWriteAndCover()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);

		let path = SquareWithHole();
		defer delete path;
		context.FillPath(path, .Red, .EvenOdd);

		let batch = context.GetBatch();
		Test.Assert(CountPhase(batch, .StencilWrite) == 1);
		Test.Assert(CountPhase(batch, .StencilCover) == 1);

		// The rule rides BOTH: the write accumulates and the cover resolves, and they must
		// agree about what inside means.
		for (let command in batch.Commands)
		{
			if (command.FillPhase != .Direct)
				Test.Assert(command.FillRule == .EvenOdd);
		}
	}

	/// A convex single contour keeps the direct path even with stencil on: the tessellator
	/// gets it right and the stencil would cost two extra passes.
	[Test]
	public static void AConvexContourKeepsTheDirectPath()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);

		let builder = scope PathBuilder();
		AppendRect(builder, 0, 0, 100, 100);
		let path = builder.ToPath();
		defer delete path;

		context.FillPath(path, .Red);

		let batch = context.GetBatch();
		Test.Assert(CountPhase(batch, .StencilWrite) == 0);
		Test.Assert(CountPhase(batch, .StencilCover) == 0);
	}

	/// A self intersecting star turns more than one revolution. The sign of its turns
	/// alone would call it convex, so the revolution count is what catches it.
	[Test]
	public static void ASelfIntersectingStarGoesThroughTheStencil()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);

		// A pentagram: five points visited in skipping order, so the outline crosses itself.
		let builder = scope PathBuilder();
		for (int32 i = 0; i < 5; i++)
		{
			let angle = -HalfPi + ((float)((i * 2) % 5) * TwoPi / 5.0f);
			let x = Cos(angle) * 50.0f;
			let y = Sin(angle) * 50.0f;
			if (i == 0)
				builder.MoveTo(x, y);
			else
				builder.LineTo(x, y);
		}
		builder.Close();
		let path = builder.ToPath();
		defer delete path;

		for (let rule in scope FillRule[](.NonZero, .EvenOdd))
		{
			context.Clear();
			context.FillPath(path, .Red, rule);
			let batch = context.GetBatch();
			Test.Assert(CountPhase(batch, .StencilWrite) == 1, "both rules need the stencil");
			Test.Assert(CountPhase(batch, .StencilCover) == 1);
		}
	}

	/// A concave but simple contour is one revolution with turns both ways, which the sign
	/// test catches on its own.
	[Test]
	public static void AConcaveContourGoesThroughTheStencil()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);

		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(100, 0);
		builder.LineTo(100, 50);
		builder.LineTo(50, 50);
		builder.LineTo(50, 100);
		builder.LineTo(0, 100);
		builder.Close();
		let path = builder.ToPath();
		defer delete path;

		context.FillPath(path, .Red);
		Test.Assert(CountPhase(context.GetBatch(), .StencilWrite) == 1);
	}

	/// The stencil passes are COLOUR MASKED, which the renderer knows from the phase. The
	/// winding fans carry white and the cover carries the real colour.
	[Test]
	public static void TheCoverCarriesTheColourAndTheWriteDoesNot()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);

		let path = SquareWithHole();
		defer delete path;
		context.FillPath(path, .(1, 0, 0, 1), .EvenOdd);

		let batch = context.GetBatch();
		for (let command in batch.Commands)
		{
			if (command.FillPhase != .StencilCover)
				continue;

			// The cover is exactly four corners.
			Test.Assert(command.IndexCount == 6);
			let firstVertex = batch.Indices[command.StartIndex];
			Test.Assert(batch.Vertices[(int)firstVertex].Color.R == 1.0f);
			Test.Assert(batch.Vertices[(int)firstVertex].Color.G == 0.0f);
		}
	}

	/// The stencil path respects the transform, and a later ordinary draw recovers rather
	/// than being stuck on the stencil state.
	[Test]
	public static void AStencilFillRespectsTheTransformAndLaterDrawsRecover()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);
		context.Translate(1000, 1000);

		let path = SquareWithHole();
		defer delete path;
		context.FillPath(path, .Red, .EvenOdd);

		let batch = context.GetBatch();
		for (let vertex in batch.Vertices)
			Test.Assert(vertex.Position.X > 900.0f, "moved by the translation");

		context.FillRect(.(0, 0, 10, 10), .Blue);
		let after = context.GetBatch();
		let last = after.Commands[after.Commands.Count - 1];
		Test.Assert(last.FillPhase == .Direct, "back to an ordinary draw");
		Test.Assert(last.TextureIndex == 0, "and back on the solid passthrough");
	}

	// ---- path clipping ----

	/// A path clip emits the winding pass and then the apply that converts it to the mask;
	/// popping clears the mask over the same bounds.
	[Test]
	public static void APathClipEmitsWriteApplyThenClear()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);

		let builder = scope PathBuilder();
		ShapeBuilder.BuildCircle(.(50, 50), 40, builder);
		let path = builder.ToPath();
		defer delete path;

		context.PushClipPath(path);
		context.FillRect(.(0, 0, 100, 100), .Red);
		context.PopClipPath();

		let batch = context.GetBatch();
		Test.Assert(CountPhase(batch, .StencilWrite) == 1);
		Test.Assert(CountPhase(batch, .ClipApply) == 1);
		Test.Assert(CountPhase(batch, .ClipClear) == 1);

		// The draw between them is marked as stencil clipped.
		var sawClippedDraw = false;
		for (let command in batch.Commands)
		{
			if ((command.FillPhase == .Direct) && (command.ClipMode == .Stencil))
				sawClippedDraw = true;
		}
		Test.Assert(sawClippedDraw);
	}

	/// The clip's OWN geometry must not be clipped by whatever was already active, or the
	/// stencil it writes would be cut by the previous clip.
	[Test]
	public static void TheClipGeometryIsNotItselfClipped()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);
		context.PushClipRect(.(0, 0, 10, 10));

		let builder = scope PathBuilder();
		ShapeBuilder.BuildCircle(.(50, 50), 40, builder);
		let path = builder.ToPath();
		defer delete path;
		context.PushClipPath(path);

		let batch = context.GetBatch();
		for (let command in batch.Commands)
		{
			if (command.FillPhase == .StencilWrite)
				Test.Assert(command.ClipMode == .None, "written unclipped");
		}
	}

	/// WITHOUT stencil support it degrades to a scissor of the path's bounds: coarse, but
	/// contained. Too much is drawn rather than the wrong thing.
	[Test]
	public static void WithoutStencilSupportAClipPathBecomesAScissor()
	{
		let context = scope VGContext();

		let builder = scope PathBuilder();
		ShapeBuilder.BuildCircle(.(50, 50), 40, builder);
		let path = builder.ToPath();
		defer delete path;

		context.PushClipPath(path);
		context.FillRect(.(0, 0, 200, 200), .Red);

		let batch = context.GetBatch();
		Test.Assert(CountPhase(batch, .StencilWrite) == 0);
		Test.Assert(batch.Commands[0].ClipMode == .Scissor);
		Test.Assert(Near(batch.Commands[0].ClipRect.Width, 80.0f, 1.0f), "the circle's bounds");
	}

	/// Popping a clip that was never pushed is harmless.
	[Test]
	public static void PoppingAnInactiveClipPathIsHarmless()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);
		context.PopClipPath();

		Test.Assert(context.GetBatch().Commands.IsEmpty);
	}

	/// A complex fill INSIDE a path clip keeps both stencil roles: the fill's own winding
	/// and cover, and the clip's mask.
	[Test]
	public static void AComplexFillInsideAClipKeepsBothRoles()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);

		let clipBuilder = scope PathBuilder();
		ShapeBuilder.BuildCircle(.(50, 50), 40, clipBuilder);
		let clip = clipBuilder.ToPath();
		defer delete clip;

		let path = SquareWithHole();
		defer delete path;

		context.PushClipPath(clip);
		context.FillPath(path, .Red, .EvenOdd);
		context.PopClipPath();

		let batch = context.GetBatch();
		Test.Assert(CountPhase(batch, .ClipApply) == 1);
		Test.Assert(CountPhase(batch, .ClipClear) == 1);
		// Two writes: the clip's and the fill's.
		Test.Assert(CountPhase(batch, .StencilWrite) == 2);
		Test.Assert(CountPhase(batch, .StencilCover) == 1);
	}
}
