using System;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Analytic boxes (VGContext.DrawBox): one quad of box vertices per box, their fill and border
/// from one signed distance in the box shader.
class VGBoxTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	private static Path Square(float x0, float y0, float x1, float y1)
	{
		let builder = scope PathBuilder();
		builder.MoveTo(x0, y0);
		builder.LineTo(x1, y0);
		builder.LineTo(x1, y1);
		builder.LineTo(x0, y1);
		builder.Close();
		return builder.ToPath();
	}

	/// The stride the box pipeline's vertex layout declares, and the shader's attribute offsets.
	[Test]
	public static void ABoxVertexIsEightyEightBytes()
	{
		Test.Assert(sizeof(VGBoxVertex) == VGBoxVertex.SizeInBytes);
		Test.Assert(VGBoxVertex.SizeInBytes == 88);
		Test.Assert(offsetof(VGBoxVertex, Radii) == 24);
		Test.Assert(offsetof(VGBoxVertex, Fill) == 56);
		Test.Assert(offsetof(VGBoxVertex, BorderColor) == 72);
	}

	/// Six box vertices to a box in a Box command, batched with the next box when nothing came
	/// between, and in draw order with other geometry when something did.
	[Test]
	public static void AnAnalyticBoxIsSixBoxVerticesBatchedWithTheNextBox()
	{
		let context = scope VGContext();
		context.SetAnalyticBoxes(true);
		context.DrawBox(.(10, 20, 40, 30), .(6.0f), .Red, .(2.0f), .Blue);
		context.DrawBox(.(60, 20, 10, 10), .(), .Green);
		let other = Square(0, 0, 5, 5);
		defer delete other;
		context.FillPath(other, .White, .NonZero, false);
		context.DrawBox(.(80, 20, 10, 10), .(), .Green);

		let batch = context.GetBatch();
		Test.Assert(batch.BoxVertices.Count == 18);
		Test.Assert(batch.Commands.Count == 3);
		Test.Assert(batch.Commands[0].DrawMode == .Box, "the first two boxes, one command");
		Test.Assert(batch.Commands[0].StartIndex == 0);
		Test.Assert(batch.Commands[0].IndexCount == 12);
		Test.Assert(batch.Commands[1].DrawMode != .Box, "the path, in order");
		Test.Assert(batch.Commands[2].DrawMode == .Box);
		Test.Assert(batch.Commands[2].StartIndex == 12);
		Test.Assert(batch.Commands[2].IndexCount == 6);

		// The first box: its size, radii and borders in every vertex, in device units (it
		// snapped: an identity transform keeps whole pixel edges), and its quad a pixel larger.
		let v = batch.BoxVertices[0];
		Test.Assert(Near(v.HalfSize.X, 20.0f) && Near(v.HalfSize.Y, 15.0f));
		Test.Assert(Near(v.Radii.X, 6.0f));
		Test.Assert(Near(v.Borders.W, 2.0f));
		Test.Assert(Near(v.Fill.R, 1.0f));
		Test.Assert(Near(v.BorderColor.B, 1.0f));
		var min = Float2(1.0e9f, 1.0e9f);
		var max = Float2(-1.0e9f, -1.0e9f);
		for (int i < 6)
		{
			let p = batch.BoxVertices[i].Position;
			min = .(Min(min.X, p.X), Min(min.Y, p.Y));
			max = .(Max(max.X, p.X), Max(max.Y, p.Y));
		}
		Test.Assert(Near(min.X, 9.0f) && Near(max.X, 51.0f));
		Test.Assert(Near(min.Y, 19.0f) && Near(max.Y, 51.0f));
	}

	/// A box's radii are clamped to half its short side, and a scaled box snaps in device units.
	[Test]
	public static void ABoxsRadiiAreClampedAndAScaledBoxSnapsInDeviceUnits()
	{
		let context = scope VGContext();
		context.SetAnalyticBoxes(true);
		context.Scale(2.0f, 2.0f);
		context.DrawBox(.(1.2f, 1.2f, 10, 6), .(20.0f), .Red, .(1.0f), .Blue);

		let batch = context.GetBatch();
		Test.Assert(batch.BoxVertices.Count == 6);
		let v = batch.BoxVertices[0];
		Test.Assert(Near(v.HalfSize.X, 10.0f), "2.4..22.4 in device units, snapped to 2..22");
		Test.Assert(Near(v.HalfSize.Y, 6.0f));
		Test.Assert(Near(v.Radii.X, 6.0f), "clamped to half the short side (3), doubled");
		Test.Assert(Near(v.Borders.X, 2.0f), "a unit border, two device pixels");
	}

	/// A box's borders on a scaled canvas are whole device pixels, at least one: a game UI at a
	/// reference resolution keeps crisp borders rather than sub pixel blurs.
	[Test]
	public static void ABoxsBordersOnAScaledCanvasAreWholeDevicePixels()
	{
		let context = scope VGContext();
		context.SetAnalyticBoxes(true);
		context.Scale(0.48f, 0.48f);
		context.DrawBox(.(100, 100, 200, 100), .(), .Red, .(2.0f, 1.0f, 5.0f, 0.0f), .Blue);

		let batch = context.GetBatch();
		Test.Assert(batch.BoxVertices.Count == 6);
		let v = batch.BoxVertices[0];
		Test.Assert(Near(v.Borders.X, 1.0f), "2 x 0.48 = 0.96: one pixel");
		Test.Assert(Near(v.Borders.Y, 1.0f), "1 x 0.48: still one, never thinner");
		Test.Assert(Near(v.Borders.Z, 2.0f), "5 x 0.48 = 2.4: two");
		Test.Assert(Near(v.Borders.W, 0.0f), "none stays none");
	}

	/// Without analytic boxes, DrawBox tessellates its fill and border, and makes no box vertices
	/// a renderer without the box shaders could not draw.
	[Test]
	public static void WithoutAnalyticBoxesDrawBoxTessellates()
	{
		let context = scope VGContext();
		context.DrawBox(.(10, 10, 40, 30), .(6.0f), .Red, .(2.0f), .Blue);

		let batch = context.GetBatch();
		Test.Assert(batch.BoxVertices.IsEmpty);
		Test.Assert(!batch.Commands.IsEmpty);
		for (let command in batch.Commands)
			Test.Assert(command.DrawMode != .Box);
		Test.Assert(batch.Vertices.Count > 8, "the rounded fill and the ring");
	}

	/// With analytic boxes on, a rounded fill is one box, exact at its corners.
	[Test]
	public static void ARoundedFillIsABox()
	{
		let context = scope VGContext();
		context.SetAnalyticBoxes(true);
		context.FillRoundedRect(.(10, 10, 40, 20), 6.0f, .Red);

		let batch = context.GetBatch();
		Test.Assert(batch.BoxVertices.Count == 6);
		Test.Assert((batch.Commands.Count == 1) && (batch.Commands[0].DrawMode == .Box));
		Test.Assert(batch.Vertices.IsEmpty, "nothing tessellated");
		Test.Assert(Near(batch.BoxVertices[0].Radii.X, 6.0f));
		Test.Assert(Near(batch.BoxVertices[0].Borders.X, 0.0f), "no border");
	}

	/// A stroke centred on a rounded rect is a box grown by half its width, its border the
	/// stroke's width, its corners grown with it, and no fill.
	[Test]
	public static void ARoundedStrokeIsABorderOnAGrownBox()
	{
		let context = scope VGContext();
		context.SetAnalyticBoxes(true);
		context.StrokeRoundedRect(.(10, 10, 40, 20), 6.0f, .Blue, 2.0f);

		let batch = context.GetBatch();
		Test.Assert(batch.BoxVertices.Count == 6);
		let v = batch.BoxVertices[0];
		Test.Assert(Near(v.HalfSize.X, 21.0f) && Near(v.HalfSize.Y, 11.0f), "grown by one on each side");
		Test.Assert(Near(v.Radii.X, 7.0f), "the corner grown with it");
		Test.Assert(Near(v.Borders.X, 2.0f) && Near(v.Borders.W, 2.0f));
		Test.Assert(Near(v.Fill.A, 0.0f), "no fill");
		Test.Assert(Near(v.BorderColor.B, 1.0f));
	}
}
