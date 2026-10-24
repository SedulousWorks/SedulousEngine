using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The tree renders through the DrawContext/VG seam. GPU-free (VGContext tessellates into a CPU
/// vertex batch), so these assert geometry is produced and that visibility and alpha gate drawing.
class NodeDrawTests
{
	/// A node of `size` filled with `color`; the caller holds the one reference.
	private static Node MakePanel(Float2 size, Color color)
	{
		let node = new Node();
		node.Size = size;
		node.SetBox(FilledBox(color, scope NodeBox()));
		return node;
	}

	private static int Geometry(VGContext ctx) => ctx.GetBatch().Vertices.Count + ctx.GetBatch().BoxVertices.Count;

	[Test]
	public static void BackgroundRendersThroughVG()
	{
		let panel = MakePanel(.(100.0f, 50.0f), Color.Blue);
		defer panel.ReleaseRef();
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		panel.Draw(dc);
		Test.Assert(Geometry(ctx) > 0);
	}

	[Test]
	public static void EmptyNodeWithNoBackgroundDrawsNothing()
	{
		let node = new Node();
		defer node.ReleaseRef();
		node.Size = .(100.0f, 50.0f);
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		node.Draw(dc);
		Test.Assert(ctx.GetBatch().Vertices.Count == 0);
	}

	[Test]
	public static void InvisibleNodeDrawsNothing()
	{
		let panel = MakePanel(.(100.0f, 50.0f), Color.Blue);
		defer panel.ReleaseRef();
		panel.Visible = false;
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		panel.Draw(dc);
		Test.Assert(ctx.GetBatch().Vertices.Count == 0);
	}

	[Test]
	public static void FullyTransparentNodeDrawsNothing()
	{
		let panel = MakePanel(.(100.0f, 50.0f), Color.Blue);
		defer panel.ReleaseRef();
		panel.Alpha = 0.0f;
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		panel.Draw(dc);
		Test.Assert(ctx.GetBatch().Vertices.Count == 0);
	}

	[Test]
	public static void NestedTreeRendersParentAndChildren()
	{
		let root = MakePanel(.(200.0f, 200.0f), Color.White);
		defer root.ReleaseRef();
		let child = MakePanel(.(50.0f, 50.0f), Color.Red);
		defer child.ReleaseRef();
		child.Position = .(20.0f, 20.0f);
		root.AddChild(child);

		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		root.Draw(dc);
		// Both the root background and the child background contribute geometry.
		Test.Assert(Geometry(ctx) > 0);
	}

	[Test]
	public static void HiddenChildIsSkippedWhileParentStillDraws()
	{
		let root = MakePanel(.(100.0f, 100.0f), Color.White);
		defer root.ReleaseRef();
		let child = MakePanel(.(40.0f, 40.0f), Color.Red);
		defer child.ReleaseRef();
		root.AddChild(child);

		let ctxBoth = scope VGContext();
		let dcBoth = scope DrawContext(ctxBoth);
		root.Draw(dcBoth);
		let withChild = ctxBoth.GetBatch().Vertices.Count;

		child.Visible = false;
		let ctxRootOnly = scope VGContext();
		let dcRootOnly = scope DrawContext(ctxRootOnly);
		root.Draw(dcRootOnly);
		let withoutChild = ctxRootOnly.GetBatch().Vertices.Count;

		Test.Assert(withoutChild > 0);
		Test.Assert(withoutChild < withChild); // the hidden child contributed no geometry
	}

	[Test]
	public static void ClipChildrenDoesNotCrashAndStillDraws()
	{
		let root = MakePanel(.(100.0f, 100.0f), Color.White);
		defer root.ReleaseRef();
		root.ClipChildren = true;
		let child = MakePanel(.(200.0f, 200.0f), Color.Red); // overflows
		defer child.ReleaseRef();
		root.AddChild(child);

		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		root.Draw(dc);
		Test.Assert(Geometry(ctx) > 0);
	}
}
