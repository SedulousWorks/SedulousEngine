using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The window: a title-bar drag moves it, the grip resizes it (clamped to the minimum), title
/// clicks fall through to the draggable bar, and a press raises it to the front; a move or resize
/// reported when the press lets go, and a title bar handed to a drag source.
class WindowTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void DraggingTheTitleBarMovesTheWindow()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let win = new Window();
		defer win.ReleaseRef();
		win.Size = .(200.0f, 150.0f);
		win.Position = .(50.0f, 50.0f);
		win.TitleBarHeight = 28.0f;
		root.AddChild(win);
		let d = root.EventDispatcher;

		// Press on the title bar (world y ~ 60, within [50,78)), then drag by (+40,+30).
		d.InjectMouseDown(.(120.0f, 60.0f), .Left);
		d.InjectMouseMove(.(160.0f, 90.0f));
		Test.Assert(Near(win.Position.X, 90.0f));
		Test.Assert(Near(win.Position.Y, 80.0f));

		// Continue dragging; deltas accumulate.
		d.InjectMouseMove(.(170.0f, 90.0f));
		Test.Assert(Near(win.Position.X, 100.0f));
		d.InjectMouseUp(.(170.0f, 90.0f), .Left);
		d.InjectMouseMove(.(300.0f, 300.0f)); // no longer dragging
		Test.Assert(Near(win.Position.X, 100.0f));
	}

	[Test]
	public static void TitleClicksFallThroughTheCaptionToTheDraggableBar()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let win = new Window();
		defer win.ReleaseRef();
		win.Size = .(200.0f, 150.0f);
		win.Position = .(0.0f, 0.0f);
		win.Title = "Hello";
		root.AddChild(win);
		let d = root.EventDispatcher;

		// Press over where the caption sits (top-left of the title bar) and drag; the hit-test-
		// transparent Label must let the bar receive it, so the window still moves.
		d.InjectMouseDown(.(20.0f, 12.0f), .Left);
		d.InjectMouseMove(.(45.0f, 12.0f));
		Test.Assert(Near(win.Position.X, 25.0f));
	}

	[Test]
	public static void DraggingTheGripResizesClampedToTheMinimum()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let win = new Window();
		defer win.ReleaseRef();
		win.Size = .(200.0f, 150.0f);
		win.Position = .(0.0f, 0.0f);
		win.SetMinSize(.(120.0f, 80.0f));
		root.AddChild(win);
		let d = root.EventDispatcher;

		// Grip is a 14x14 square at the bottom-right: world ~ [186,200) x [136,150).
		d.InjectMouseDown(.(193.0f, 143.0f), .Left);
		d.InjectMouseMove(.(243.0f, 193.0f)); // +50, +50
		Test.Assert(Near(win.Size.X, 250.0f));
		Test.Assert(Near(win.Size.Y, 200.0f));

		// Shrink far past the minimum -> clamps.
		d.InjectMouseMove(.(0.0f, 0.0f));
		Test.Assert(Near(win.Size.X, 120.0f));
		Test.Assert(Near(win.Size.Y, 80.0f));
	}

	[Test]
	public static void RightToLeftItsTitleBarIsTheMirrorOfLeftToRightItsGripAtTheBottomLeft()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let win = new Window();
		defer win.ReleaseRef();
		win.Size = .(220.0f, 150.0f);
		win.TitleBarHeight = 28.0f;
		root.AddChild(win);
		root.UpdateLayout();
		let bar = win.TitleBar;
		Test.Assert(bar.ChildCount == 2); // the title, the close button
		let width = bar.Size.X;
		Float2[2] at = default;
		Float2[2] size = default;
		for (int i = 0; i < 2; ++i)
		{
			at[i] = bar.GetChildAt(i).Position;
			size[i] = bar.GetChildAt(i).Size;
		}
		Test.Assert(at[1].X + size[1].X < width - 1.0f); // the close button kept off the edge

		let grip = win.GetChildAt(win.ChildCount - 1); // over the content
		Test.Assert(grip.Cursor == .NwseResize);

		win.SetLayoutDirection(.RightToLeft);
		root.UpdateLayout();
		for (int i = 0; i < 2; ++i)
		{
			Test.Assert(Near(bar.GetChildAt(i).Position.X, width - at[i].X - size[i].X));
			Test.Assert(Near(bar.GetChildAt(i).Size.X, size[i].X));
		}
		// The grip at its bottom left, its cursor the way that corner resizes.
		Test.Assert(Near(grip.Position.X, 0.0f));
		Test.Assert(grip.Cursor == .NeswResize);
	}

	[Test]
	public static void ContentHostIsPlacedBelowTheTitleBarAndAddable()
	{
		let win = new Window();
		defer win.ReleaseRef();
		win.Size = .(200.0f, 150.0f);
		win.TitleBarHeight = 30.0f;

		let host = win.Content;
		Test.Assert(host != null);
		Test.Assert(Near(host.Size.X, 200.0f));
		Test.Assert(Near(host.Size.Y, 120.0f)); // 150 - 30

		let child = new UIWidget();
		defer child.ReleaseRef();
		child.Size = .(40.0f, 40.0f);
		host.AddChild(child);
		Test.Assert(host.ChildCount == 1);
	}

	[Test]
	public static void PressingTheTitleRaisesTheWindowToTheFront()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let a = new Window();
		defer a.ReleaseRef();
		let b = new Window();
		defer b.ReleaseRef();
		a.Size = .(200.0f, 150.0f);
		b.Size = .(200.0f, 150.0f);
		a.Position = .(0.0f, 0.0f);
		b.Position = .(300.0f, 0.0f); // separate, so the click hits only a
		root.AddChild(a);
		root.AddChild(b); // b is on top (last child)
		Test.Assert(root.GetChildAt(1) == b);

		let d = root.EventDispatcher;
		d.InjectMouseDown(.(20.0f, 12.0f), .Left); // press a's title
		Test.Assert(root.GetChildAt(1) == a); // a raised to front
		d.InjectMouseUp(.(20.0f, 12.0f), .Left);
	}

	[Test]
	public static void TheRightButtonDoesNotDragTheWindow()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let win = new Window();
		defer win.ReleaseRef();
		win.Size = .(200.0f, 150.0f);
		win.Position = .(50.0f, 50.0f);
		root.AddChild(win);
		let d = root.EventDispatcher;

		d.InjectMouseDown(.(120.0f, 60.0f), .Right); // right press on title
		d.InjectMouseMove(.(200.0f, 120.0f));
		Test.Assert(Near(win.Position.X, 50.0f)); // did not move
		Test.Assert(Near(win.Position.Y, 50.0f));
	}

	[Test]
	public static void TheCloseButtonClosesAWindowPlacedInATreeWhichOpensAgain()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let win = new Window();
		defer win.ReleaseRef();
		win.Size = .(200.0f, 150.0f);
		win.Position = .(50.0f, 50.0f);
		win.TitleBarHeight = 28.0f;
		int closed = 0;
		win.SetOnClose(new [&] () => { ++closed; });
		root.AddChild(win); // placed, as a page's markup or a host does, never opened
		root.UpdateLayout();

		Node close = null;
		for (var bar = win.FirstChild; (bar != null) && (close == null); bar = bar.NextSibling)
		{
			for (int i = 0; i < bar.ChildCount; ++i)
			{
				if (bar.GetChildAt(i) is WindowCloseButton)
					close = bar.GetChildAt(i);
			}
		}
		Test.Assert(close != null);
		Float2 Middle() => close.ConvertToWorldSpace(.(close.Size.X * 0.5f, close.Size.Y * 0.5f));
		let at = Middle();
		let d = root.EventDispatcher;
		d.InjectMouseDown(at, .Left);
		d.InjectMouseUp(at, .Left);
		Test.Assert(win.Parent == null);
		Test.Assert(closed == 1);

		win.Open(root); // and opens again where it was asked to
		Test.Assert(win.Parent == root);
		Test.Assert(win.IsOpen);
		root.UpdateLayout();
		d.InjectMouseDown(Middle(), .Left);
		d.InjectMouseUp(Middle(), .Left);
		Test.Assert(win.Parent == null);
		Test.Assert(closed == 2);
	}

	[Test]
	public static void OneHeldByItsTreeAloneClosesAndCallsBackNotFreedBeforeItDoes()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		int closed = 0;
		{
			let made = new Window();
			made.Size = .(200.0f, 150.0f);
			made.SetOnClose(new [&] () => { ++closed; });
			root.AddChild(made);
			made.Open(root);
			made.ReleaseRef();
		} // the tree holds it alone now, as a script's window
		Test.Assert(root.ChildCount == 1);
		let win = root.GetChildAt(0) as Window;
		Test.Assert(win != null);
		win.Close();
		Test.Assert(closed == 1);
		Test.Assert(root.ChildCount == 0);
	}

	[Test]
	public static void AMoveOrResizeTheUserMadeIsReportedOnceThePressLetsGoAHandedOverTitleBarStartsADragInstead()
	{
		let root = SceneFixtures.NewScene(600.0f, 400.0f);
		defer root.ReleaseRef();
		let win = new Window();
		defer win.ReleaseRef();
		win.Size = .(200.0f, 150.0f);
		win.Position = .(50.0f, 50.0f);
		root.AddChild(win);
		let d = root.EventDispatcher;
		int arranged = 0;
		win.SetOnUserArranged(new [&] () => { ++arranged; });

		d.InjectMouseDown(.(120.0f, 60.0f), .Left);
		d.InjectMouseMove(.(140.0f, 70.0f));
		d.InjectMouseMove(.(160.0f, 80.0f));
		Test.Assert(arranged == 0); // not each move
		d.InjectMouseUp(.(160.0f, 80.0f), .Left);
		Test.Assert(arranged == 1);
		d.InjectMouseDown(.(160.0f, 80.0f), .Left); // a press that moves nothing
		d.InjectMouseUp(.(160.0f, 80.0f), .Left);
		Test.Assert(arranged == 1);
		let grip = Float2(win.Position.X + 193.0f, win.Position.Y + 143.0f);
		d.InjectMouseDown(grip, .Left);
		d.InjectMouseMove(.(grip.X + 30.0f, grip.Y + 10.0f));
		d.InjectMouseUp(.(grip.X + 30.0f, grip.Y + 10.0f), .Left);
		Test.Assert(arranged == 2);
		Test.Assert(Near(win.Size.X, 230.0f));

		// Handed over: the title bar moves nothing itself; its drag source's drag starts past the threshold.
		let bar = win.TitleBar;
		Test.Assert(bar != null);
		bar.DragsItself = false;
		bool started = false;
		bar.SetDragSource(new [&] (r) =>
			{
				r.Payload.Type.Set("test/window");
				started = true;
				return true;
			});
		let at = Float2(win.Position.X + 40.0f, win.Position.Y + 10.0f);
		let was = win.Position;
		d.InjectMouseDown(at, .Left);
		d.InjectMouseMove(.(at.X + 20.0f, at.Y));
		Test.Assert(started);
		Test.Assert(d.IsDragging);
		Test.Assert(Near(win.Position.X, was.X));
		d.InjectKeyDown((uint32)KeyCode.Escape);
		d.InjectMouseUp(.(at.X + 20.0f, at.Y), .Left);
		Test.Assert(arranged == 2);
	}
}
