using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// AbsoluteLayout, which places every child at an explicit offset, and FlowLayout, which wraps
/// children onto new lines like text.
class AbsoluteAndFlowLayoutTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static LayoutStyle At(float left, float top)
	{
		var layout = LayoutStyle();
		layout.Left = .(left, true);
		layout.Top = .(top, true);
		return layout;
	}

	// ---- AbsoluteLayout ---------------------------------------------------------------------

	[Test]
	public static void AnAbsoluteChildSitsAtItsExplicitPosition()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let group = new AbsoluteLayout();
		let child = new TestView(50, 30);
		group.AddView(child, At(100, 50));
		root.AddView(group);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(child.Bounds.X, 100));
		Test.Assert(Near(child.Bounds.Y, 50));
	}

	[Test]
	public static void AnUnpositionedAbsoluteChildSitsAtTheOrigin()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let group = new AbsoluteLayout();
		let child = new TestView(50, 30);
		group.AddView(child);
		root.AddView(group);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(child.Bounds.X, 0));
		Test.Assert(Near(child.Bounds.Y, 0));
	}

	/// The offset is measured from INSIDE the padding, not from the group's own edge.
	[Test]
	public static void AbsolutePaddingOffsetsEveryChild()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let group = new AbsoluteLayout();
		group.Padding = .(10, 20, 10, 20);
		let child = new TestView(50, 30);
		group.AddView(child, At(5, 5));
		root.AddView(group);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(child.Bounds.X, 15));
		Test.Assert(Near(child.Bounds.Y, 25));
	}

	/// Absolute placement does not RESIZE: the child keeps whatever it measured to.
	[Test]
	public static void AnAbsoluteChildKeepsItsMeasuredSize()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let group = new AbsoluteLayout();
		let child = new TestView(80, 45);
		group.AddView(child, At(50, 50));
		root.AddView(group);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(child.Width, 80));
		Test.Assert(Near(child.Height, 45));
	}

	[Test]
	public static void AbsoluteChildrenArePositionedIndependently()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let group = new AbsoluteLayout();
		let a = new TestView(50, 30);
		let b = new TestView(60, 40);
		group.AddView(a, At(10, 10));
		group.AddView(b, At(200, 100));
		root.AddView(group);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 10));
		Test.Assert(Near(a.Bounds.Y, 10));
		Test.Assert(Near(b.Bounds.X, 200));
		Test.Assert(Near(b.Bounds.Y, 100));
	}

	// ---- FlowLayout -------------------------------------------------------------------------

	[Test]
	public static void AHorizontalFlowKeepsChildrenOnOneLineWhileTheyFit()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.Y, b.Bounds.Y), "same line");
		Test.Assert(Near(b.Bounds.X, 50));
	}

	[Test]
	public static void AHorizontalFlowWrapsWhenItRunsOutOfWidth()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		let a = new TestView(150, 30);
		let b = new TestView(150, 30);
		let c = new TestView(150, 30);
		flow.AddView(a);
		flow.AddView(b);
		flow.AddView(c);
		root.AddView(flow);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.Y, b.Bounds.Y), "two fit on the first line");
		Test.Assert(c.Bounds.Y > a.Bounds.Y, "the third wrapped");
	}

	/// The line height is the TALLEST item on the line, and the spacing goes after it.
	[Test]
	public static void VerticalSpacingSeparatesFlowLines()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		flow.VSpacing = 8;
		let a = new TestView(250, 30);
		let b = new TestView(250, 40);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(b.Bounds.Y, 38), "thirty tall plus eight of spacing");
	}

	[Test]
	public static void AVerticalFlowStacksIntoOneColumnWhileItFits()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Vertical;
		let a = new TestView(50, 30);
		let b = new TestView(50, 40);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, b.Bounds.X), "same column");
		Test.Assert(Near(b.Bounds.Y, 30));
	}

	[Test]
	public static void AVerticalFlowWrapsIntoANewColumn()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Vertical;
		let a = new TestView(50, 150);
		let b = new TestView(50, 150);
		let c = new TestView(50, 150);
		flow.AddView(a);
		flow.AddView(b);
		flow.AddView(c);
		root.AddView(flow);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, b.Bounds.X));
		Test.Assert(c.Bounds.X > a.Bounds.X, "the third started a new column");
	}

	/// A Gone child takes no space at all, so the one after it closes right up.
	[Test]
	public static void AGoneChildIsSkippedByTheFlow()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		b.Visibility = .Gone;
		let c = new TestView(70, 30);
		flow.AddView(a);
		flow.AddView(b);
		flow.AddView(c);
		root.AddView(flow);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(c.Bounds.X, 50), "right after a, as if b were not there");
	}

	[Test]
	public static void FlowPaddingOffsetsTheContent()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		flow.Padding = .(10, 20, 10, 20);
		let a = new TestView(50, 30);
		flow.AddView(a);
		root.AddView(flow);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 10));
		Test.Assert(Near(a.Bounds.Y, 20));
	}

	[Test]
	public static void HorizontalSpacingSeparatesFlowItems()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flow = new FlowLayout();
		flow.Orientation = .Horizontal;
		flow.HSpacing = 10;
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		flow.AddView(a);
		flow.AddView(b);
		root.AddView(flow);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(b.Bounds.X, 60), "fifty wide plus ten of spacing");
	}
}
