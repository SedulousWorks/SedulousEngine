using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// UINode / UIWidget: padding and content bounds, and the CSS identity surface (tag, id, classes).
class WidgetTests
{
	[Test]
	public static void UINodePaddingInsetsTheContentBounds()
	{
		let n = new UINode();
		defer n.ReleaseRef();
		n.Size = .(100.0f, 80.0f);
		n.Padding = Thickness(5.0f, 10.0f, 15.0f, 20.0f);
		let content = n.ContentBounds;
		Test.Assert(content == Rect(5.0f, 10.0f, 80.0f, 50.0f)); // 100-5-15, 80-10-20
	}

	[Test]
	public static void UINodeOverLargePaddingClampsToZeroNotNegative()
	{
		let n = new UINode();
		defer n.ReleaseRef();
		n.Size = .(20.0f, 20.0f);
		n.Padding = Thickness(30.0f);
		let content = n.ContentBounds;
		Test.Assert(content.Width == 0.0f);
		Test.Assert(content.Height == 0.0f);
	}

	[Test]
	public static void UIWidgetTagAndId()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		Test.Assert(w.Tag.Length == 0);
		w.Tag = "button";
		w.Id = "ok";
		Test.Assert(w.Tag == "button");
		Test.Assert(w.Id == "ok");
	}

	[Test]
	public static void UIWidgetStyleClassesAddRemoveToggle()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		Test.Assert(w.ClassCount == 0);

		w.AddClass("primary");
		w.AddClass("large");
		w.AddClass("primary"); // duplicate ignored
		Test.Assert(w.ClassCount == 2);
		Test.Assert(w.HasClass("primary"));
		Test.Assert(w.HasClass("large"));
		Test.Assert(!w.HasClass("small"));

		w.RemoveClass("large");
		Test.Assert(!w.HasClass("large"));
		Test.Assert(w.ClassCount == 1);

		w.ToggleClass("active");
		Test.Assert(w.HasClass("active"));
		w.ToggleClass("active");
		Test.Assert(!w.HasClass("active"));
	}

	[Test]
	public static void UIWidgetMarginAndInheritedPadding()
	{
		let w = new UIWidget();
		defer w.ReleaseRef();
		w.Margin = Thickness(4.0f);
		Test.Assert(w.Margin.Left == 4.0f);
		w.Padding = Thickness(2.0f); // inherited from UINode
		Test.Assert(w.Padding.Top == 2.0f);
	}

	[Test]
	public static void UINodeItsStatesFollowThePointerTheFocusAndBeingEnabled()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let w = new UINode();
		defer w.ReleaseRef();
		w.Size = .(100.0f, 100.0f);
		w.TabFocusable = true; // a click focuses what takes focus
		root.AddChild(w);
		let d = root.EventDispatcher;

		// Hover then leave (before any click, so no focus yet).
		d.InjectMouseMove(.(50.0f, 50.0f)); // over w
		Test.Assert(w.Hovered);
		d.InjectMouseMove(.(150.0f, 150.0f)); // off w
		Test.Assert(!w.Hovered);

		// Press and release (a click focuses the node).
		d.InjectMouseMove(.(50.0f, 50.0f));
		d.InjectMouseDown(.(50.0f, 50.0f), .Left);
		Test.Assert(w.Pressed);
		d.InjectMouseUp(.(50.0f, 50.0f), .Left);
		Test.Assert(!w.Pressed);
		Test.Assert(w.Hovered);

		// Leave while focused, from the click.
		d.InjectMouseMove(.(150.0f, 150.0f));
		Test.Assert(!w.Hovered);
		Test.Assert(w.IsFocused);

		w.Enabled = false;
		Test.Assert(!w.IsTreeEnabled);
	}
}
