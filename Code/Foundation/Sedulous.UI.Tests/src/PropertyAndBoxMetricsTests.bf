using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Property, the observable value controls expose, and BoxMetrics, the one resolved chrome
/// every measure and arrange converges on.
class PropertyAndBoxMetricsTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	// ---- Property ---------------------------------------------------------------------------

	[Test]
	public static void APropertyStartsAtItsInitialOrDefaultValue()
	{
		let initialised = scope Property<float>(42.0f);
		Test.Assert(initialised.Value == 42.0f);

		let defaulted = scope Property<int32>();
		Test.Assert(defaulted.Value == 0);
	}

	[Test]
	public static void SettingAValueFiresChangedWithTheNewValue()
	{
		let property = scope Property<float>(0.0f);
		var received = -1.0f;
		property.Changed.Add(new [&received](value) => { received = value; });

		property.Value = 100.0f;

		Test.Assert(received == 100.0f);
	}

	/// Setting the SAME value fires nothing. A control that re-asserts its state every frame
	/// must not cost a layout pass every frame.
	[Test]
	public static void SettingTheSameValueFiresNothing()
	{
		let property = scope Property<int32>(42);
		var fireCount = 0;
		property.Changed.Add(new [&fireCount](value) => { fireCount++; });

		property.Value = 42;
		Test.Assert(fireCount == 0);

		property.Value = 1;
		property.Value = 2;
		property.Value = 3;
		Test.Assert(fireCount == 3, "three real changes");
	}

	/// SetSilent updates without notifying, which is what a binding uses to echo a value back
	/// to a source that already knows: reporting it would look like a change and loop.
	[Test]
	public static void SetSilentUpdatesWithoutNotifying()
	{
		let property = scope Property<float>(0.0f);
		var fireCount = 0;
		property.Changed.Add(new [&fireCount](value) => { fireCount++; });

		property.SetSilent(100.0f);

		Test.Assert(property.Value == 100.0f);
		Test.Assert(fireCount == 0);
	}

	[Test]
	public static void AOneWayBindingPushesForwardOnly()
	{
		let source = scope Property<float>(0.0f);
		let target = scope Property<float>(0.0f);
		source.BindTo(target);

		source.Value = 50.0f;
		Test.Assert(target.Value == 50.0f);

		target.Value = 99.0f;
		Test.Assert(source.Value == 50.0f, "the reverse does not propagate");
	}

	/// A two way binding updates both directions, and the loop guard is what stops the pair
	/// bouncing forever the first time either side moves.
	[Test]
	public static void ATwoWayBindingUpdatesBothDirectionsWithoutLooping()
	{
		let a = scope Property<int32>(0);
		let b = scope Property<int32>(0);
		a.BindTwoWay(b);

		a.Value = 10;
		Test.Assert(b.Value == 10);

		b.Value = 20;
		Test.Assert(a.Value == 20);

		a.Value = 42;
		Test.Assert(a.Value == 42);
		Test.Assert(b.Value == 42);
	}

	[Test]
	public static void APropertyWorksForAnyComparableType()
	{
		let flag = scope Property<bool>(false);
		var received = false;
		flag.Changed.Add(new [&received](value) => { received = value; });

		flag.Value = true;

		Test.Assert(received == true);
		Test.Assert(flag.Value == true);
	}

	// ---- BoxMetrics -------------------------------------------------------------------------

	private static void MakeTree(out UIContext context, out RootView root,
		float width = 800, float height = 600)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, width, height);
	}

	/// A bordered drawable reports its border as padding, which is how a background's own
	/// chrome reaches the layout without every control knowing about it.
	[Test]
	public static void ABorderedDrawableReportsItsBorderAsPadding()
	{
		let drawable = new RoundedRectDrawable(Color(1, 1, 1, 1), 4.0f, Color(0, 0, 0, 1), 2.0f);
		defer drawable.ReleaseRef();

		let padding = drawable.DrawablePadding;

		Test.Assert(padding.Left == 2.0f);
		Test.Assert(padding.Top == 2.0f);
		Test.Assert(padding.Right == 2.0f);
		Test.Assert(padding.Bottom == 2.0f);
	}

	/// The three padding channels MAX merge per side, so a padding declared through any of them
	/// takes effect rather than one silently winning. The border resolves separately and adds.
	[Test]
	public static void TheThreePaddingChannelsMaxMergePerSide()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		root.AddView(group);

		group.Padding = .(10, 1, 1, 1); // the FIELD channel, wide on the left
		group.SetStyle(.Padding, Thickness(2, 8, 2, 2)); // the STYLE channel, wide on top
		// The DRAWABLE channel, three everywhere.
		group.SetStyle(.Background,
			new RoundedRectDrawable(Color(1, 1, 1, 1), 0.0f, Color(0, 0, 0, 1), 3.0f));
		group.SetStyle(.BorderWidth, 5.0f);

		let metrics = group.ResolveBoxMetrics();

		Test.Assert(metrics.Padding.Left == 10.0f, "the field won the left");
		Test.Assert(metrics.Padding.Top == 8.0f, "the style won the top");
		Test.Assert(metrics.Padding.Right == 3.0f, "the drawable won the right");
		Test.Assert(metrics.Padding.Bottom == 3.0f);
		Test.Assert(metrics.Border.Left == 5.0f);

		let chrome = metrics.Chrome;
		Test.Assert(chrome.Left == 15.0f, "padding plus border");
		Test.Assert(chrome.Top == 13.0f);
	}

	/// A stylesheet declared padding on a CONTAINER has to reach its measure. Raptor's case
	/// uses Panel; a plain group is the same measure path without the control.
	[Test]
	public static void StyleDeclaredPaddingGrowsAContainersMeasure()
	{
		MakeTree(let context, let root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		root.AddView(group);
		group.SetStyle(.Padding, Thickness(7, 7, 7, 7));

		let child = new TestView(50.0f, 20.0f);
		group.AddView(child);
		// Measured LOOSE on purpose: the root's tight constraints would stretch the group and
		// hide the chrome entirely.
		group.Measure(BoxConstraints.Loose(400, 300));

		Test.Assert(group.MeasuredSize.X == 50.0f + 14.0f);
		Test.Assert(group.MeasuredSize.Y == 20.0f + 14.0f);
	}

	/// Border is layout participating, as in the CSS border box: a bordered container is larger
	/// by its border, so content no longer sits on the border line.
	[Test]
	public static void ABorderedBackgroundReservesContentSpace()
	{
		MakeTree(let context, let root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let plain = new ViewGroup();
		let bordered = new ViewGroup();
		root.AddView(plain);
		root.AddView(bordered);
		bordered.SetStyle(.Background,
			new RoundedRectDrawable(Color(1, 1, 1, 1), 0.0f, Color(0, 0, 0, 1), 2.0f));

		plain.AddView(new TestView(50.0f, 20.0f));
		bordered.AddView(new TestView(50.0f, 20.0f));

		plain.Measure(BoxConstraints.Loose(400, 300));
		bordered.Measure(BoxConstraints.Loose(400, 300));

		Test.Assert(bordered.MeasuredSize.X == plain.MeasuredSize.X + 4.0f);
		Test.Assert(bordered.MeasuredSize.Y == plain.MeasuredSize.Y + 4.0f);
	}

	// ---- Acceptance: the same rules in every container ----------------------------------------

	private static TestView FixedChild()
	{
		let view = new TestView(10.0f, 10.0f);
		var layout = LayoutStyle();
		layout.Width = .(SizeSpec.Fixed(Unit.Dp(100.0f)), true);
		layout.Height = .(SizeSpec.Fixed(Unit.Dp(40.0f)), true);
		view.SetLayout(layout);
		return view;
	}

	/// A fixed size is honoured in EVERY container, not only the frame it was first written
	/// for: the base Measure handles it, so no container has to remember to.
	[Test]
	public static void AFixedSizeIsHonouredInEveryContainer()
	{
		MakeTree(let context, let root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let dock = new DockLayout();
		let flow = new FlowLayout();
		let grid = new GridLayout();
		let group = new TestGroup();
		root.AddView(dock);
		root.AddView(flow);
		root.AddView(grid);
		root.AddView(group);

		let inDock = FixedChild();
		let inFlow = FixedChild();
		let inGrid = FixedChild();
		let inGroup = FixedChild();
		dock.AddView(inDock);
		flow.AddView(inFlow);
		grid.AddView(inGrid);
		group.AddView(inGroup);
		UITest.LayoutPass(context, root);

		Test.Assert(inDock.MeasuredSize.X == 100.0f);
		Test.Assert(inFlow.MeasuredSize.X == 100.0f);
		Test.Assert(inGrid.MeasuredSize.X == 100.0f);
		Test.Assert(inGroup.MeasuredSize.X == 100.0f);
		Test.Assert(inDock.MeasuredSize.Y == 40.0f);
	}

	/// A flow row advances by the MARGIN box, so a margined child does not overlap the next.
	[Test]
	public static void AFlowAdvancesByTheMarginBox()
	{
		MakeTree(let context, let root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let flow = new FlowLayout();
		root.AddView(flow);

		let margined = new TestView(50.0f, 20.0f);
		var layout = LayoutStyle();
		layout.Margin = .(Thickness(5, 5, 5, 5), true);
		margined.SetLayout(layout);
		let plain = new TestView(50.0f, 20.0f);
		flow.AddView(margined);
		flow.AddView(plain);
		UITest.LayoutPass(context, root);

		Test.Assert(margined.Bounds.X == 5.0f, "the border box is inset by the margin");
		Test.Assert(margined.Bounds.Y == 5.0f);
		Test.Assert(plain.Bounds.X >= 60.0f, "after the whole margin box, not overlapping it");
	}

	/// A fill style leaf in a grid cell gets BOUNDED constraints. Handed an unbounded maximum
	/// it would measure to it and blow the track out to the float ceiling.
	[Test]
	public static void AFillStyleLeafInAGridCellStaysBounded()
	{
		MakeTree(let context, let root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let grid = new GridLayout();
		root.AddView(grid);

		let filling = new TestView(FloatMax, 2.0f);
		var layout = LayoutStyle();
		layout.Width = .(SizeSpec.Match(), true);
		filling.SetLayout(layout);
		grid.AddView(filling);
		UITest.LayoutPass(context, root);

		Test.Assert(filling.MeasuredSize.X <= 400.0f);
		Test.Assert(grid.MeasuredSize.X <= 400.0f);
	}
}
