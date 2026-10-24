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
}
