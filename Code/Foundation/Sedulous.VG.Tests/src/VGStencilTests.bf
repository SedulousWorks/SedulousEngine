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

	private static Path Square(float x0, float y0, float x1, float y1)
	{
		let builder = scope PathBuilder();
		AppendRect(builder, x0, y0, x1 - x0, y1 - y0);
		return builder.ToPath();
	}

	/// The device bounds of a command's vertices.
	private static Rectangle CommandBounds(VGBatch batch, VGCommand command)
	{
		var min = Float2(float.MaxValue, float.MaxValue);
		var max = Float2(-float.MaxValue, -float.MaxValue);
		for (int i < command.IndexCount)
		{
			let p = batch.Vertices[(int)batch.Indices[command.StartIndex + i]].Position;
			min = .(Min(min.X, p.X), Min(min.Y, p.Y));
			max = .(Max(max.X, p.X), Max(max.Y, p.Y));
		}
		return .(min.X, min.Y, max.X - min.X, max.Y - min.Y);
	}

	/// Clips NEST: a clip path inside another writes its winding only inside the outer mask
	/// and applies over the OUTER's bounds, which zeroes the outer-only pixels; popping it
	/// clears the mask and rebuilds the outer.
	[Test]
	public static void AClipPathInsideAnotherIntersectsItAndPoppingRestoresTheOuter()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);
		let outer = Square(0, 0, 20, 20);
		defer delete outer;
		let inner = Square(10, 10, 30, 30);
		defer delete inner;
		let fill = Square(0, 0, 30, 30);
		defer delete fill;

		context.PushClipPath(outer);
		context.PushClipPath(inner);
		context.FillPath(fill, .Red, .NonZero, false);
		context.PopClipPath();
		context.FillPath(fill, .Blue, .NonZero, false);
		context.PopClipPath();
		context.FillPath(fill, .Green, .NonZero, false);

		let batch = context.GetBatch();
		// The outer's write and apply; the inner's write (CLIPPED: only inside the outer mask)
		// and apply over the OUTER's bounds; red; the pop: clear, the outer's write and apply
		// again; blue; clear; green.
		Test.Assert(batch.Commands.Count == 11, scope $"{batch.Commands.Count} commands");
		Test.Assert(batch.Commands[0].FillPhase == .StencilWrite);
		Test.Assert(batch.Commands[0].ClipMode == .None);
		Test.Assert(batch.Commands[1].FillPhase == .ClipApply);
		Test.Assert(batch.Commands[2].FillPhase == .StencilWrite);
		Test.Assert(batch.Commands[2].ClipMode == .Stencil);
		Test.Assert(batch.Commands[3].FillPhase == .ClipApply);
		let apply = CommandBounds(batch, batch.Commands[3]);
		Test.Assert(Near(apply.X, 0.0f) && Near(apply.Width, 20.0f), "over the outer's bounds");
		Test.Assert(batch.Commands[4].ClipMode == .Stencil, "red, inside both");
		Test.Assert(batch.Commands[5].FillPhase == .ClipClear);
		Test.Assert(batch.Commands[6].FillPhase == .StencilWrite);
		Test.Assert(batch.Commands[6].ClipMode == .None, "the outer rebuilt");
		Test.Assert(batch.Commands[7].FillPhase == .ClipApply);
		Test.Assert(batch.Commands[8].ClipMode == .Stencil, "blue, inside the outer");
		Test.Assert(batch.Commands[9].FillPhase == .ClipClear);
		Test.Assert(batch.Commands[10].ClipMode == .None, "green, unclipped");
	}

	/// A clip rect inside a clip path applies both: the draw is stencil tested AND scissored,
	/// so a scrolled list inside a rounded panel keeps its corners.
	[Test]
	public static void AClipRectInsideAClipPathAppliesBoth()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);
		let clip = Square(0, 0, 40, 40);
		defer delete clip;

		context.PushClipPath(clip);
		context.PushClipRect(.(5, 5, 10, 10));
		context.FillPath(clip, .Red, .NonZero, false);
		context.PopClip();
		context.FillPath(clip, .Blue, .NonZero, false);
		context.PopClipPath();

		let batch = context.GetBatch();
		Test.Assert(batch.Commands.Count == 5, scope $"{batch.Commands.Count} commands");
		let red = batch.Commands[2];
		Test.Assert(red.ClipMode == .Stencil);
		Test.Assert(red.Scissored);
		Test.Assert(Near(red.ClipRect.X, 5.0f) && Near(red.ClipRect.Width, 10.0f));
		let blue = batch.Commands[3];
		Test.Assert(blue.ClipMode == .Stencil);
		Test.Assert(!blue.Scissored);
	}

	/// Without a stencil, a nested clip path's scissor is the intersection, and popping it goes
	/// back to the outer's rather than dropping every clip.
	[Test]
	public static void WithoutStencilANestedClipPathsScissorPopsBackToTheOuter()
	{
		let context = scope VGContext();
		let outer = Square(0, 0, 20, 20);
		defer delete outer;
		let inner = Square(10, 10, 30, 30);
		defer delete inner;
		let fill = Square(0, 0, 30, 30);
		defer delete fill;

		context.PushClipPath(outer);
		context.PushClipPath(inner);
		context.FillPath(fill, .Red, .NonZero, false);
		context.PopClipPath();
		context.FillPath(fill, .Blue, .NonZero, false);
		context.PopClipPath();
		context.FillPath(fill, .Green, .NonZero, false);

		let batch = context.GetBatch();
		Test.Assert(batch.Commands.Count == 3);
		Test.Assert(batch.Commands[0].ClipMode == .Scissor);
		Test.Assert(Near(batch.Commands[0].ClipRect.X, 10.0f) && Near(batch.Commands[0].ClipRect.Width, 10.0f), "the intersection");
		Test.Assert(batch.Commands[1].ClipMode == .Scissor);
		Test.Assert(Near(batch.Commands[1].ClipRect.X, 0.0f) && Near(batch.Commands[1].ClipRect.Width, 20.0f), "the outer again");
		Test.Assert(batch.Commands[2].ClipMode == .None);
	}
}
