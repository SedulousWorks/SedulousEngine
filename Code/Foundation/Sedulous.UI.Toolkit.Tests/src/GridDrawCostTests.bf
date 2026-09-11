using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.VG;

namespace Sedulous.UI.Toolkit.Tests;

/// A draw cost probe for very large inspectors.
///
/// THE INCIDENT: a generic asset form with around thirteen hundred fields pushed past the
/// vector renderer's per frame vertex ceiling and blanked the whole window. Blank but still
/// interactive, which is the worst kind of broken, because nothing reports an error.
///
/// What is pinned here is that cost tracks the VIEWPORT rather than the content: rows scrolled
/// out of sight tessellate nothing, and a collapsed category costs neither draw nor measure.
///
/// HEADLESS, so there is no font service and text is excluded. On screen costs strictly more,
/// which makes the bound below conservative rather than optimistic.
class GridDrawCostTests
{
	private static int DrawOnce(RootView root)
	{
		let vg = scope VGContext();
		let draw = scope UIDrawContext(vg, 1.0f, null);
		root.OnDraw(draw);
		return vg.GetBatch().Vertices.Count;
	}

	private static PropertyGrid MakeGrid(int32 rows)
	{
		let grid = new PropertyGrid();
		for (int32 i = 0; i < rows; i++)
			grid.AddProperty(new FloatEditor(scope $"field{i}", 1.0));
		return grid;
	}

	[Test]
	public static void OffScreenRowsTessellateNoGeometry()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		root.ViewportSize = .(800, 600);
		context.AddRootView(root);

		// About twenty rows fit the viewport at the default row height.
		let small = MakeGrid(20);
		root.AddView(small);
		context.BeginFrame(0.016f);
		root.Measure(BoxConstraints.Tight(800, 600));
		root.Layout(0, 0, 800, 600);
		let smallVertices = DrawOnce(root);
		root.RemoveView(small);

		// The incident's size, in the same viewport. Only the same twenty rows are visible.
		let big = MakeGrid(1300);
		root.AddView(big);
		context.BeginFrame(0.016f);
		root.Measure(BoxConstraints.Tight(800, 600));
		root.Layout(0, 0, 800, 600);
		let bigVertices = DrawOnce(root);

		Test.Assert(smallVertices > 0);
		// Four times the visible cost is generous headroom for the scroll bar and partial rows.
		// WITHOUT culling the big grid draws around sixty five times the small one, so this
		// bound is nowhere near the real thing it is guarding against.
		Test.Assert(bigVertices < smallVertices * 4,
			scope $"1300 rows drew {bigVertices} vertices against {smallVertices} for 20");
	}

	/// The companion to culling: a collapsed category's rows are Gone, so they cost no MEASURE
	/// either. Draw culling alone would still leave layout walking every row every frame.
	[Test]
	public static void ADefaultCollapsedCategoryCostsNoLayoutOrDraw()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		root.ViewportSize = .(800, 600);
		context.AddRootView(root);

		let grid = new PropertyGrid();
		grid.SetCategoryDefaultCollapsed("bulk");
		grid.AddProperty(new FloatEditor("visible", 1.0));
		for (int32 i = 0; i < 1000; i++)
			grid.AddProperty(new FloatEditor(scope $"row{i}", 1.0, 0.0, 100.0, 1.0, 2, null, "bulk"));

		root.AddView(grid);
		context.BeginFrame(0.016f);
		root.Measure(BoxConstraints.Tight(800, 600));
		root.Layout(0, 0, 800, 600);
		let collapsedVertices = DrawOnce(root);
		root.RemoveView(grid);

		// The same shape with one row in the bulk category: an empty expander header plus the
		// one visible row. The other thousand must contribute essentially nothing.
		let tiny = new PropertyGrid();
		tiny.SetCategoryDefaultCollapsed("bulk");
		tiny.AddProperty(new FloatEditor("visible", 1.0));
		tiny.AddProperty(new FloatEditor("row", 1.0, 0.0, 100.0, 1.0, 2, null, "bulk"));

		root.AddView(tiny);
		context.BeginFrame(0.016f);
		root.Measure(BoxConstraints.Tight(800, 600));
		root.Layout(0, 0, 800, 600);
		let tinyVertices = DrawOnce(root);

		Test.Assert(collapsedVertices <= tinyVertices + 64,
			scope $"1000 collapsed rows drew {collapsedVertices} vertices against {tinyVertices} for 1");
	}
}
