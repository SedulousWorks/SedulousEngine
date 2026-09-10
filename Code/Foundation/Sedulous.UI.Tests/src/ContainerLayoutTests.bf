using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The BASE container's measure and arrange: the frame shaped default every layout
/// specialises, and the absolutely positioned children every one of them skips.
class ContainerLayoutTests
{
	private static void MakeTree(out UIContext context, out RootView root,
		float width = 200, float height = 100)
	{
		context = new UIContext();
		root = new RootView();
		root.ViewportSize = .(width, height);
		context.AddRootView(root);
		context.SetActiveInputRoot(root);
	}

	private static LayoutStyle Fixed(float width, float height)
	{
		var layout = LayoutStyle();
		layout.Width = .(SizeSpec.Fixed(Unit.Dp(width)), true);
		layout.Height = .(SizeSpec.Fixed(Unit.Dp(height)), true);
		return layout;
	}

	/// The default aggregation is the LARGEST margin box, not the sum: children stack in a
	/// frame rather than flowing.
	[Test]
	public static void AGroupWrapsToItsLargestChild()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		root.AddView(group);

		let small = new View();
		group.AddView(small, Fixed(20, 10));
		let large = new View();
		group.AddView(large, Fixed(50, 30));

		group.Measure(BoxConstraints.Loose(200, 100));

		Test.Assert(group.MeasuredSize.X == 50);
		Test.Assert(group.MeasuredSize.Y == 30);
	}

	/// The group's own padding is chrome: it grows the measured size and offsets the children.
	[Test]
	public static void PaddingGrowsTheGroupAndOffsetsItsChildren()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		group.Padding = .(5, 7, 5, 7);
		root.AddView(group);

		let child = new View();
		group.AddView(child, Fixed(20, 10));

		group.Measure(BoxConstraints.Loose(200, 100));
		Test.Assert(group.MeasuredSize.X == 30, "20 plus five each side");
		Test.Assert(group.MeasuredSize.Y == 24, "10 plus seven each side");

		group.Layout(0, 0, group.MeasuredSize.X, group.MeasuredSize.Y);
		Test.Assert(child.Bounds.X == 5);
		Test.Assert(child.Bounds.Y == 7);
	}

	/// The base group POSITIONS what it measures. Leaving children at the origin would be a
	/// measure and arrange asymmetry that every subclass would inherit.
	[Test]
	public static void TheBaseGroupPlacesTheChildrenItMeasured()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		root.AddView(group);
		let child = new View();
		group.AddView(child, Fixed(20, 10));

		group.Measure(BoxConstraints.Loose(200, 100));
		group.Layout(0, 0, 200, 100);

		Test.Assert(child.Bounds.Width == 20);
		Test.Assert(child.Bounds.Height == 10);
	}

	// ---- Absolute positioning ------------------------------------------------------------

	private static LayoutStyle Absolute(float width, float height)
	{
		var layout = Fixed(width, height);
		layout.Position = .(.Absolute, true);
		return layout;
	}

	/// An absolute child is placed from its NEAR insets, and an undeclared inset is nought
	/// from that edge.
	[Test]
	public static void AnAbsoluteChildIsPlacedFromItsNearInsets()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		root.AddView(group);

		var layout = Absolute(20, 10);
		layout.Left = .(30, true);
		layout.Top = .(15, true);
		let child = new View();
		group.AddView(child, layout);

		group.Measure(BoxConstraints.Tight(200, 100));
		group.Layout(0, 0, 200, 100);

		Test.Assert(child.Bounds.X == 30);
		Test.Assert(child.Bounds.Y == 15);
		Test.Assert(child.Bounds.Width == 20);
	}

	/// Right and Bottom anchor the FAR edge, so the child's own size decides where it starts.
	[Test]
	public static void AnAbsoluteChildAnchorsToTheFarEdge()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		root.AddView(group);

		var layout = Absolute(20, 10);
		layout.Right = .(30, true);
		layout.Bottom = .(15, true);
		let child = new View();
		group.AddView(child, layout);

		group.Measure(BoxConstraints.Tight(200, 100));
		group.Layout(0, 0, 200, 100);

		Test.Assert(child.Bounds.X == 200 - 30 - 20);
		Test.Assert(child.Bounds.Y == 100 - 15 - 10);
	}

	/// BOTH insets declared pins both edges: the child is exactly what is left between them,
	/// whatever size it asked for.
	[Test]
	public static void BothInsetsPinTheChildToTheRemainder()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		root.AddView(group);

		var layout = LayoutStyle();
		// No width spec at all: the pinning alone is what sizes it.
		layout.Position = .(.Absolute, true);
		layout.Left = .(10, true);
		layout.Right = .(30, true);
		let child = new View();
		group.AddView(child, layout);

		group.Measure(BoxConstraints.Tight(200, 100));
		group.Layout(0, 0, 200, 100);

		Test.Assert(child.Bounds.X == 10);
		Test.Assert(child.Bounds.Width == 160, "200 less both insets");
	}

	/// An absolute child is OUT OF FLOW: it never contributes to what the group wraps to.
	[Test]
	public static void AnAbsoluteChildDoesNotGrowTheGroup()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		root.AddView(group);

		let inFlow = new View();
		group.AddView(inFlow, Fixed(20, 10));

		var layout = Absolute(500, 400);
		layout.Left = .(0, true);
		layout.Top = .(0, true);
		let absolute = new View();
		group.AddView(absolute, layout);

		group.Measure(BoxConstraints.Loose(200, 100));

		Test.Assert(group.MeasuredSize.X == 20);
		Test.Assert(group.MeasuredSize.Y == 10);
	}

	/// A Gone child measures and arranges as nothing at all, where a Hidden one keeps its
	/// space.
	[Test]
	public static void AGoneChildTakesNoSpaceAndAHiddenOneKeepsIts()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new ViewGroup();
		root.AddView(group);

		let gone = new View();
		gone.Visibility = .Gone;
		group.AddView(gone, Fixed(80, 40));
		let hidden = new View();
		hidden.Visibility = .Hidden;
		group.AddView(hidden, Fixed(20, 10));

		group.Measure(BoxConstraints.Loose(200, 100));

		Test.Assert(group.MeasuredSize.X == 20);
		Test.Assert(group.MeasuredSize.Y == 10);
	}
}
