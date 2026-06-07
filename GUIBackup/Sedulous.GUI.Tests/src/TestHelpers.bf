namespace Sedulous.GUI.Tests;

using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// Minimal concrete View for testing. Has a fixed desired size.
class TestView : View
{
	public float DesiredWidth;
	public float DesiredHeight;

	public this(float w = 50, float h = 30)
	{
		DesiredWidth = w;
		DesiredHeight = h;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(DesiredWidth), constraints.ConstrainHeight(DesiredHeight));
	}
}

/// Minimal concrete ViewGroup for testing.
class TestGroup : ViewGroup
{
	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value != .Gone)
				child.Layout(0, 0, width, height);
		}
	}
}

/// Helper to set up a UIContext + RootView for tests.
static class TestSetup
{
	public static void Init(UIContext ctx, RootView root, float width = 800, float height = 600)
	{
		root.ViewportSize = .(width, height);
		ctx.AddRootView(root);
	}

	/// Run measure + layout on the root view.
	public static void Layout(UIContext ctx, RootView root)
	{
		ctx.BeginFrame(0.016f);
		let logical = root.LogicalSize;
		root.Measure(BoxConstraints.Tight(logical.X, logical.Y));
		root.Layout(0, 0, logical.X, logical.Y);
	}
}
