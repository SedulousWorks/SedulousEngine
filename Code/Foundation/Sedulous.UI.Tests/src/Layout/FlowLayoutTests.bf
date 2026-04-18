namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class FlowLayoutTests
{
	[Test]
	public static void Flow_WrapsToNextLine()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(200, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		root.AddView(flow);

		// 3 children × 80px wide = 240px > 200px viewport -> wraps after 2.
		for (int i = 0; i < 3; i++)
		{
			let child = new ColorView();
			child.PreferredWidth = 80;
			child.PreferredHeight = 30;
			flow.AddView(child);
		}

		ctx.UpdateRootView(root);

		let c0 = flow.GetChildAt(0);
		let c1 = flow.GetChildAt(1);
		let c2 = flow.GetChildAt(2);

		// First two on row 1, third on row 2.
		Test.Assert(c0.Bounds.Y == c1.Bounds.Y);  // same row
		Test.Assert(c2.Bounds.Y > c0.Bounds.Y);   // wrapped
	}
}
