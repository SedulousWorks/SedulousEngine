using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// A concrete View with a fixed desired size, which is what most layout tests need: something
/// with a known measurement and nothing else going on.
class TestView : View
{
	public float DesiredWidth = 50.0f;
	public float DesiredHeight = 30.0f;

	public this() {}

	public this(float width, float height)
	{
		DesiredWidth = width;
		DesiredHeight = height;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(DesiredWidth),
			constraints.ConstrainHeight(DesiredHeight));
	}
}

/// A concrete ViewGroup that lays every child out to fill its whole box, so a test about
/// something OTHER than arrangement is not also testing an arrangement.
class TestGroup : ViewGroup
{
	public this() {}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility != .Gone)
				child.Layout(0, 0, width, height);
		}
	}
}

/// A context and root, both owned by the caller.
static class UITest
{
	public static void Init(UIContext context, RootView root, float width = 800.0f,
		float height = 600.0f)
	{
		root.ViewportSize = .(width, height);
		context.AddRootView(root);
	}

	/// One frame's worth of layout: drain the queue, then measure and arrange.
	public static void LayoutPass(UIContext context, RootView root)
	{
		context.BeginFrame(0.016f);
		context.UpdateRootView(root);
	}
}
