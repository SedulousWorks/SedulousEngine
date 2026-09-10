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

/// A list adapter test double: a mutable count of hundred by thirty items.
class SimpleListAdapter : ListAdapterBase
{
	public int32 Count = 0;

	public this(int32 count)
	{
		Count = count;
	}

	public override int32 ItemCount => Count;
	public override View CreateView(int32 viewType) => new TestView(100.0f, 30.0f);
	public override void BindView(View view, int32 position) {}
}

/// A tree adapter test double: three roots, of which the first has two children (10 and 11)
/// and the second has one (20). Anything numbered ten or above is at depth one.
class SimpleTreeAdapter : ITreeAdapter
{
	public int32 RootCount => 3;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1)
			return 3;
		if (nodeId == 0)
			return 2;
		if (nodeId == 1)
			return 1;
		return 0;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (parentId == -1)
			return childIndex; // the roots: 0, 1, 2
		if (parentId == 0)
			return 10 + childIndex; // 10, 11
		if (parentId == 1)
			return 20 + childIndex; // 20
		return -1;
	}

	public int32 GetDepth(int32 nodeId) => (nodeId >= 10) ? 1 : 0;

	public bool HasChildren(int32 nodeId) => (nodeId == 0) || (nodeId == 1);

	public View CreateView(int32 viewType) => new TestView(100.0f, 30.0f);

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded) {}

	public int32 GetItemViewType(int32 nodeId) => 0;

	public void SetObserver(ITreeAdapterObserver observer) {}
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
