namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class VisualChildTests
{
	[Test]
	public static void View_HasNoVisualChildren()
	{
		let view = scope ColorView();
		Test.Assert(view.VisualChildCount == 0);
		Test.Assert(view.GetVisualChild(0) == null);
	}

	[Test]
	public static void ViewGroup_VisualChildren_MatchLogical()
	{
		let ctx = scope UIContext();
		let layout = new LinearLayout();
		ctx.Root.AddView(layout);

		let a = new ColorView();
		let b = new ColorView();
		layout.AddView(a);
		layout.AddView(b);

		Test.Assert(layout.VisualChildCount == 2);
		Test.Assert(layout.GetVisualChild(0) === a);
		Test.Assert(layout.GetVisualChild(1) === b);
	}

	[Test]
	public static void ScrollView_VisualChildren_IncludeScrollbars()
	{
		let ctx = scope UIContext();
		ctx.SetViewportSize(200, 100);

		let sv = new ScrollView();
		ctx.Root.AddView(sv);

		let content = new ColorView();
		content.PreferredHeight = 500;
		sv.AddView(content, new LayoutParams() { Width = LayoutParams.MatchParent, Height = 500 });

		ctx.DoLayout();

		// 1 logical child + 2 scrollbar slots = 3 visual children.
		// Both scrollbars are always returned (never null) — visibility
		// controlled via .Visible / .Gone, not by returning null.
		Test.Assert(sv.VisualChildCount == 3);
		Test.Assert(sv.GetVisualChild(0) === content);
		Test.Assert(sv.GetVisualChild(1) != null); // V bar (always present)
		Test.Assert(sv.GetVisualChild(2) != null); // H bar (always present)
		Test.Assert(sv.GetVisualChild(1).Visibility == .Visible);  // V bar visible (content overflows)
		Test.Assert(sv.GetVisualChild(2).Visibility == .Gone);     // H bar hidden (no horizontal overflow)
	}

	[Test]
	public static void ScrollView_ScrollbarRegisteredInContext()
	{
		let ctx = scope UIContext();
		ctx.SetViewportSize(200, 100);

		let sv = new ScrollView();
		ctx.Root.AddView(sv);

		let content = new ColorView();
		content.PreferredHeight = 500;
		sv.AddView(content, new LayoutParams() { Width = LayoutParams.MatchParent, Height = 500 });

		ctx.DoLayout();

		// The visible scrollbar should be registered (findable by ViewId).
		let vBar = sv.GetVisualChild(sv.ChildCount);
		if (vBar != null)
		{
			let found = ctx.GetElementById(vBar.Id);
			Test.Assert(found === vBar);
		}
	}

	[Test]
	public static void ForEachVisualChild_IteratesAll()
	{
		let ctx = scope UIContext();
		let layout = new LinearLayout();
		ctx.Root.AddView(layout);

		layout.AddView(new ColorView());
		layout.AddView(new ColorView());
		layout.AddView(new ColorView());

		int count = 0;
		layout.ForEachVisualChild(scope [&count](child) => { count++; });
		Test.Assert(count == 3);
	}
}
