using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Tests;

/// The debug overlays: turned on through the context, and every flag draws.
class DebugOverlayTests
{
	private static int VerticesDrawn(UIContext context, RootView root)
	{
		let vg = scope VGContext();
		context.DrawRootView(root, vg);
		// Paths and analytic boxes.
		return vg.GetBatch().Vertices.Count + vg.GetBatch().BoxVertices.Count;
	}

	/// DrawRootView built its draw context without the debug settings, so no overlay could be
	/// turned on through it; ShowZOrder and ShowTabOrder drew nothing even when passed directly.
	[Test]
	public static void TheContextsSettingsReachTheDrawAndEveryFlagDraws()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 300, 100);

		let column = new FlexLayout();
		column.Direction = .Vertical;
		for (int i < 2)
		{
			let stop = new TestView(100, 30);
			stop.IsFocusable = true;
			stop.IsTabStop = true;
			column.AddView(stop);
		}
		root.AddView(column);
		UITest.LayoutPass(context, root);

		let plain = VerticesDrawn(context, root);
		for (int flag < 4)
		{
			context.DebugDraw = .();
			switch (flag)
			{
			case 0: context.DebugDraw.ShowBounds = true;
			case 1: context.DebugDraw.ShowZOrder = true;
			case 2: context.DebugDraw.ShowTabOrder = true;
			default:
				column.SetStyle(.Padding, Thickness(4)); // the sheet's padding, not the field's
				context.DebugDraw.ShowPadding = true;
			}
			let drawn = VerticesDrawn(context, root);
			Test.Assert(drawn > plain, scope $"flag {flag}: {drawn} vertices, {plain} plain");
		}

		context.DebugDraw = .();
		Test.Assert(VerticesDrawn(context, root) == plain, "off again: nothing extra");
	}
}
