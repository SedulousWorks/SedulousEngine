using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The floating tool window. The bare cases run with no context at all; the clamping ones need
/// only an absolute layout inside a measured root, since the clamp runs from layout rather than
/// from a captured pointer.
class FloatingPanelTests
{
	private static bool Near(float a, float b, float tolerance = 0.01f) => Abs(a - b) <= tolerance;

	/// A root with an absolute layout in it, which is the only host a floating panel works in.
	private class Bed
	{
		public UIContext Context = new .();
		public RootView Root = new .();
		public AbsoluteLayout Host = new .();

		public this()
		{
			Root.ViewportSize = .(800, 600);
			Context.AddRootView(Root);
			Root.AddView(Host);
		}

		public ~this()
		{
			Root.ReleaseRef();
			delete Context;
		}

		/// TWICE, deliberately. The first pass lays the panel out where it was asked to go and
		/// runs the clamp, which corrects the placement and marks damage; the second applies the
		/// correction to Bounds. That is exactly the in-app flow, where the clamp's invalidation
		/// schedules the next frame.
		public void RunLayout(float width, float height)
		{
			Root.ViewportSize = .(width, height);
			Context.BeginFrame(0.016f);
			Root.Measure(BoxConstraints.Tight(width, height));
			Root.Layout(0, 0, width, height);
			Root.Measure(BoxConstraints.Tight(width, height));
			Root.Layout(0, 0, width, height);
		}
	}

	private static FloatingPanel Place(Bed bed, StringView title, float left, float top)
	{
		let panel = new FloatingPanel(title);
		LayoutStyle placement = .();
		placement.Left = left;
		placement.Top = top;
		bed.Host.AddView(panel, placement);
		return panel;
	}

	[Test]
	public static void ItConstructsExpanded()
	{
		let panel = new FloatingPanel("Brush");
		defer panel.ReleaseRef();

		Test.Assert(!panel.IsCollapsed);
		Test.Assert(panel.Title == "Brush");
	}

	[Test]
	public static void CollapsingTogglesAndIsIdempotent()
	{
		let panel = new FloatingPanel("Tools");
		defer panel.ReleaseRef();

		panel.SetCollapsed(true);
		Test.Assert(panel.IsCollapsed);
		panel.SetCollapsed(true);
		Test.Assert(panel.IsCollapsed);
		panel.SetCollapsed(false);
		Test.Assert(!panel.IsCollapsed);
	}

	[Test]
	public static void CollapsingHidesTheContent()
	{
		let panel = new FloatingPanel("P");
		defer panel.ReleaseRef();

		let body = new Label("body");
		body.AddRef();
		defer body.ReleaseRef();
		panel.SetContent(body);

		Test.Assert(body.Visibility == .Visible);
		panel.SetCollapsed(true);
		Test.Assert(body.Visibility == .Gone);
		panel.SetCollapsed(false);
		Test.Assert(body.Visibility == .Visible);
	}

	/// Content set INTO a collapsed panel arrives hidden, so it never flashes for a frame.
	[Test]
	public static void ContentSetWhileCollapsedStartsHidden()
	{
		let panel = new FloatingPanel("P");
		defer panel.ReleaseRef();
		panel.SetCollapsed(true);

		let body = new Label("body");
		body.AddRef();
		defer body.ReleaseRef();
		panel.SetContent(body);

		Test.Assert(body.Visibility == .Gone);
	}

	[Test]
	public static void SwappingContentAndTheSettersAreSafe()
	{
		let panel = new FloatingPanel("P");
		defer panel.ReleaseRef();

		panel.SetContent(new Label("a"));
		panel.SetContent(null);
		Test.Assert(panel.Content == null);

		panel.SetTitle("New Title");
		Test.Assert(panel.Title == "New Title");
		panel.SetPreferredContentSize(320.0f, 240.0f);
		Test.Assert(!panel.IsCollapsed);
	}

	[Test]
	public static void CloseNotifiesSubscribers()
	{
		let panel = new FloatingPanel("P");
		defer panel.ReleaseRef();

		var closed = 0;
		panel.OnClose.Add(new [&closed]() => { closed++; });
		panel.OnClose();
		Test.Assert(closed == 1);
	}

	/// An absolute layout does NOT clamp an overflowing child, so the panel's own clamp is the
	/// only thing keeping it on screen.
	[Test]
	public static void LayoutClampsThePanelInsideItsParent()
	{
		let bed = scope Bed();
		let panel = Place(bed, "Tools", 1000.0f, 900.0f);

		bed.RunLayout(800, 600);

		Test.Assert(panel.Width > 0.0f);
		Test.Assert(panel.Height > 0.0f);
		Test.Assert(Near(panel.Bounds.X, 800.0f - panel.Width));
		Test.Assert(Near(panel.Bounds.Y, 600.0f - panel.Height));
	}

	[Test]
	public static void NegativePlacementClampsToTheOrigin()
	{
		let bed = scope Bed();
		let panel = Place(bed, "P", -120.0f, -45.0f);

		bed.RunLayout(800, 600);

		Test.Assert(Near(panel.Bounds.X, 0.0f));
		Test.Assert(Near(panel.Bounds.Y, 0.0f));
	}

	/// A REGRESSION GATE: a viewport that shrinks, the bottom dock expanding upward say, must
	/// pull the panel back inside rather than leave it behind the new edge.
	[Test]
	public static void ThePanelFollowsAShrinkingParentBackInside()
	{
		let bed = scope Bed();
		let panel = Place(bed, "Brush", 500.0f, 350.0f);

		bed.RunLayout(800, 600);
		Test.Assert(Near(panel.Bounds.X, 500.0f), "it fits, so it stays put");
		Test.Assert(Near(panel.Bounds.Y, 350.0f));

		bed.RunLayout(600, 420);
		Test.Assert(Near(panel.Bounds.X, 600.0f - panel.Width));
		Test.Assert(Near(panel.Bounds.Y, 420.0f - panel.Height));
	}

	/// Collapsed, the panel is only its header tall, so it clamps flush to the bottom at a
	/// LOWER position than a full height one could reach.
	[Test]
	public static void ACollapsedPanelClampsAgainstItsHeaderHeight()
	{
		let bed = scope Bed();
		let panel = Place(bed, "P", 0.0f, 900.0f);

		bed.RunLayout(800, 600);
		let expandedY = panel.Bounds.Y;

		panel.SetCollapsed(true);
		LayoutStyle placement = panel.Layout;
		placement.Top = 900.0f;
		panel.SetLayout(placement);
		bed.RunLayout(800, 600);

		Test.Assert(Near(panel.Bounds.Y, 600.0f - panel.Height));
		Test.Assert(panel.Bounds.Y > expandedY);
	}

	/// A REGRESSION GATE on the resize band's width. A band as wide as the drawn grip would
	/// claim the outer few pixels of hosted content, which is where a property grid's scroll bar
	/// lives. The edges claim only the content inset; the bottom right corner keeps a larger
	/// square, the convention for a window grip, and safe because a corner is dead space.
	[Test]
	public static void TheResizeBandStaysInsideTheBorderInset()
	{
		let panel = new FloatingPanel("Band");
		defer panel.ReleaseRef();

		// A child filling the body is the discriminator: a point the band does not claim falls
		// through to it.
		let content = new View();
		content.AddRef();
		defer content.ReleaseRef();
		content.IsHitTestVisible = true;
		panel.SetContent(content);

		panel.Measure(BoxConstraints.Tight(300.0f, 200.0f));
		panel.Layout(0, 0, 300.0f, 200.0f);

		Test.Assert(panel.HitTest(.(292.0f, 120.0f)) == content, "eight pixels in is content");
		Test.Assert(panel.HitTest(.(297.0f, 120.0f)) == panel, "inside the inset resizes");
		Test.Assert(panel.HitTest(.(150.0f, 197.0f)) == panel, "and so does the bottom inset");
		Test.Assert(panel.HitTest(.(290.0f, 190.0f)) == panel, "the corner reaches further in");
		Test.Assert(panel.HitTest(.(290.0f, 120.0f)) == content,
			"the same distance in on a plain edge is not the corner");
	}
}
