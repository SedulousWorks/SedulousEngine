using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// FrameLayout: children stacked, each anchored by its own Gravity.
class FrameLayoutTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	[Test]
	public static void AChildWithNoGravitySitsAtTheTopLeft()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let frame = new FrameLayout();
		let child = new TestView(50, 30);
		frame.AddView(child);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(child.Bounds.X, 0));
		Test.Assert(Near(child.Bounds.Y, 0));
	}

	[Test]
	public static void GravityCentresTheChild()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let frame = new FrameLayout();
		let child = new TestView(100, 50);
		var layout = LayoutStyle();
		layout.Gravity = .Center;
		frame.AddView(child, layout);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(child.Bounds.X, 150));
		Test.Assert(Near(child.Bounds.Y, 125));
	}

	[Test]
	public static void GravityAnchorsToTheBottomRight()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let frame = new FrameLayout();
		let child = new TestView(80, 40);
		var layout = LayoutStyle();
		layout.Gravity = .Bottom | .Right;
		frame.AddView(child, layout);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(child.Bounds.X, 320));
		Test.Assert(Near(child.Bounds.Y, 260));
	}

	/// Fill OVERRIDES the measured size: the child takes the whole content box however small it
	/// asked to be.
	[Test]
	public static void GravityFillTakesTheWholeBox()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let frame = new FrameLayout();
		let child = new TestView(50, 30);
		var layout = LayoutStyle();
		layout.Gravity = .Fill;
		frame.AddView(child, layout);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(child.Width, 400));
		Test.Assert(Near(child.Height, 300));
	}

	[Test]
	public static void PaddingOffsetsWhereGravityPlaces()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let frame = new FrameLayout();
		frame.Padding = .(10, 20, 10, 20);
		let child = new TestView(50, 30);
		frame.AddView(child);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(child.Bounds.X, 10));
		Test.Assert(Near(child.Bounds.Y, 20));
	}

	/// Children STACK: each is anchored independently and none pushes another along.
	[Test]
	public static void ChildrenAreStackedNotFlowed()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let frame = new FrameLayout();
		let a = new TestView(100, 50);
		let b = new TestView(80, 40);
		var noGravity = LayoutStyle();
		noGravity.Gravity = .None;
		var centred = LayoutStyle();
		centred.Gravity = .Center;
		frame.AddView(a, noGravity);
		frame.AddView(b, centred);
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 0));
		Test.Assert(Near(b.Bounds.X, 160));
	}

	/// The scene editor's viewport pane: a vertical flex stacks a fixed toolbar over a growing
	/// frame whose Fill child is the 3D viewport and whose bottom right child is the preview.
	///
	/// The load bearing assertion is the Fill child's SCREEN origin, because that is exactly
	/// what the input surface region is built from. A nested Fill child whose screen origin is
	/// wrong puts picking and gizmo input in the wrong place while everything still LOOKS right.
	[Test]
	public static void ANestedFillChildInsideAGrowingFlexKeepsItsScreenOrigin()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let pane = new FlexLayout();
		pane.Direction = .Vertical;

		let toolbar = new TestView(0, 0);
		var toolbarLayout = LayoutStyle();
		toolbarLayout.Width = .(SizeSpec.Match(), true);
		toolbarLayout.Height = .(SizeSpec.Fixed(Unit.Px(30)), true);
		pane.AddView(toolbar, toolbarLayout);

		let frame = new FrameLayout();
		// Measures small, as the real viewport view does; Fill overrides it.
		let viewport = new TestView(256, 256);
		var viewportLayout = LayoutStyle();
		viewportLayout.Gravity = .Fill;
		frame.AddView(viewport, viewportLayout);

		let preview = new TestView(320, 204);
		var previewLayout = LayoutStyle();
		previewLayout.Gravity = .Bottom | .Right;
		previewLayout.Margin = .(Thickness(12, 12, 12, 12), true);
		frame.AddView(preview, previewLayout);

		var frameLayout = LayoutStyle();
		frameLayout.Width = .(SizeSpec.Match(), true);
		frameLayout.FlexGrow = .(1.0f, true);
		pane.AddView(frame, frameLayout);

		root.AddView(pane);
		UITest.LayoutPass(context, root);

		// The frame takes everything below the thirty unit toolbar, and Fill fills the frame.
		Test.Assert(Near(frame.Bounds.Y, 30));
		Test.Assert(Near(viewport.Width, 400));
		Test.Assert(Near(viewport.Height, 270));

		let origin = viewport.LocalToScreen(.(0, 0));
		Test.Assert(Near(origin.X, 0));
		Test.Assert(Near(origin.Y, 30), "the toolbar's height, not zero");

		// The preview sits bottom right inside the frame, inset by its margin, in SCREEN space.
		let previewOrigin = preview.LocalToScreen(.(0, 0));
		Test.Assert(Near(previewOrigin.X, 400 - 12 - 320));
		Test.Assert(Near(previewOrigin.Y, 30 + 270 - 12 - 204));
	}
}
