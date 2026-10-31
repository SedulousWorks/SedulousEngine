using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Tooltip timing and placement.
///
/// The delays and the owner resolution are what make tooltips usable rather than
/// infuriating, so they are covered here.
class TooltipTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 800, 600);
		root.Bounds = .(0, 0, 800, 600);
	}

	/// A view that builds its own tooltip content, and can decline to.
	private class TipView : TestView, ITooltipProvider
	{
		public bool Provides = true;
		public int BuildCount = 0;

		public this(float width, float height) : base(width, height) {}

		public override ITooltipProvider AsTooltipProvider() => this;

		public View CreateTooltipContent()
		{
			BuildCount++;
			return Provides ? new TestView(80, 20) : null;
		}
	}

	/// The same, but a CONTAINER, for the owner resolution case.
	private class TipGroup : TestGroup, ITooltipProvider
	{
		public override ITooltipProvider AsTooltipProvider() => this;
		public View CreateTooltipContent() => new TestView(80, 20);
	}

	// ---- Timing -----------------------------------------------------------------------------

	/// Nothing appears until the pointer has RESTED. A tooltip that appeared instantly would
	/// flicker its way across a toolbar.
	[Test]
	public static void ATooltipWaitsForTheShowDelay()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let tooltips = context.Tooltips;

		let view = new TipView(100, 50);
		root.AddView(view);

		tooltips.OnHoverChanged(view);
		Test.Assert(!tooltips.IsShowing);

		context.BeginFrame(0.2f);
		Test.Assert(!tooltips.IsShowing, "not yet");

		context.BeginFrame(0.4f); // past the half second default
		Test.Assert(tooltips.IsShowing);
		Test.Assert(root.GetPopupLayer().PopupCount == 1);
	}

	/// And it takes itself away again, so a tooltip cannot sit over the work indefinitely.
	[Test]
	public static void ATooltipHidesItselfAfterTheAutoHideDelay()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let tooltips = context.Tooltips;

		let view = new TipView(100, 50);
		root.AddView(view);

		tooltips.OnHoverChanged(view);
		context.BeginFrame(0.6f);
		Test.Assert(tooltips.IsShowing);

		context.BeginFrame(5.1f);
		Test.Assert(!tooltips.IsShowing);
		Test.Assert(root.GetPopupLayer().PopupCount == 0);
	}

	/// Moving to a DIFFERENT owner hides what was up and restarts the clock.
	[Test]
	public static void MovingToAnotherOwnerRestartsTheClock()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let tooltips = context.Tooltips;

		let first = new TipView(100, 50);
		let second = new TipView(100, 50);
		root.AddView(first);
		root.AddView(second);

		tooltips.OnHoverChanged(first);
		context.BeginFrame(0.6f);
		Test.Assert(tooltips.IsShowing);

		tooltips.OnHoverChanged(second);
		Test.Assert(!tooltips.IsShowing, "hidden at once");

		context.BeginFrame(0.2f);
		Test.Assert(!tooltips.IsShowing, "and waiting again from the start");
		context.BeginFrame(0.4f);
		Test.Assert(tooltips.IsShowing);
	}

	// ---- Owner resolution -------------------------------------------------------------------

	/// The owner is the nearest ANCESTOR with tooltip content, not the leaf the hit test found.
	///
	/// A container carrying one tooltip for all its children would otherwise never show it, and
	/// moving between those children would restart the timer every time.
	[Test]
	public static void TheOwnerIsTheNearestAncestorWithContent()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let tooltips = context.Tooltips;

		let row = new TipGroup();
		root.AddView(row);
		let leftChild = new TestView(80, 40);
		let rightChild = new TestView(80, 40);
		row.AddView(leftChild);
		row.AddView(rightChild);

		tooltips.OnHoverChanged(leftChild); // the LEAF, as a hit test would report
		context.BeginFrame(0.6f);
		Test.Assert(tooltips.IsShowing, "the row's tooltip");

		// Moving to a sibling of the same owner must not restart anything.
		tooltips.OnHoverChanged(rightChild);
		Test.Assert(tooltips.IsShowing, "still up");
	}

	/// A view with only TOOLTIP TEXT and no provider gets a label built for it.
	[Test]
	public static void AViewWithOnlyTooltipTextGetsALabel()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let tooltips = context.Tooltips;

		let view = new TestView(100, 50);
		view.TooltipText.Set("Explain this");
		root.AddView(view);

		tooltips.OnHoverChanged(view);
		context.BeginFrame(0.6f);

		Test.Assert(tooltips.IsShowing);
		Test.Assert(root.GetPopupLayer().PopupCount == 1);
	}

	/// A PROVIDER wins over the text, so a view that builds its own content is never reduced to
	/// its plain string.
	[Test]
	public static void AProviderBeatsThePlainText()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let view = new TipView(100, 50);
		view.TooltipText.Set("plain");
		root.AddView(view);

		context.Tooltips.OnHoverChanged(view);
		context.BeginFrame(0.6f);

		Test.Assert(view.BuildCount == 1, "the provider was asked");
		Test.Assert(context.Tooltips.IsShowing);
	}

	/// Hovering something with NO tooltip anywhere above it shows nothing.
	[Test]
	public static void AViewWithNoTooltipOwnerShowsNothing()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let tooltips = context.Tooltips;

		let plain = new TestView(100, 50);
		root.AddView(plain);

		tooltips.OnHoverChanged(plain);
		context.BeginFrame(1.0f);

		Test.Assert(!tooltips.IsShowing);
	}

	/// A provider answering null suppresses the tooltip entirely, which is how a view says
	/// "not here, not now" without giving up its tooltip everywhere else.
	[Test]
	public static void AProviderThatDeclinesSuppressesTheTooltip()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let tooltips = context.Tooltips;

		let view = new TipView(100, 50);
		view.Provides = false;
		root.AddView(view);

		tooltips.OnHoverChanged(view);
		context.BeginFrame(0.6f);

		Test.Assert(view.BuildCount == 1, "it was asked");
		Test.Assert(!tooltips.IsShowing, "and declined");
	}

	// ---- Dismissal --------------------------------------------------------------------------

	[Test]
	public static void AClickHidesTheTooltip()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let tooltips = context.Tooltips;

		let view = new TipView(100, 50);
		root.AddView(view);

		tooltips.OnHoverChanged(view);
		context.BeginFrame(0.6f);
		Test.Assert(tooltips.IsShowing);

		tooltips.OnMouseDown();
		Test.Assert(!tooltips.IsShowing);
	}

	/// A view going away takes its pending tooltip with it, so the timer cannot fire onto
	/// something that has gone.
	[Test]
	public static void RemovingTheHoveredViewCancelsThePendingTooltip()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let tooltips = context.Tooltips;

		let view = new TipView(100, 50);
		view.AddRef();
		defer view.ReleaseRef();
		root.AddView(view);

		tooltips.OnHoverChanged(view);
		root.RemoveView(view);

		context.BeginFrame(1.0f);
		Test.Assert(!tooltips.IsShowing);
	}

	/// A tooltip does NOT take focus. Appearing mid typing it would otherwise clear the
	/// editor's focus and take its completion popup down with it.
	[Test]
	public static void ATooltipNeverDisturbsTheFocus()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let editor = new TestView(100, 50);
		editor.IsFocusable = true;
		editor.IsTabStop = true;
		root.AddView(editor);
		focus.SetFocus(editor, .Keyboard);

		let view = new TipView(100, 50);
		root.AddView(view);
		context.Tooltips.OnHoverChanged(view);
		context.BeginFrame(0.6f);
		Test.Assert(context.Tooltips.IsShowing);

		Test.Assert(focus.FocusedView == editor, "focus untouched");
		Test.Assert(focus.FocusStackDepth == 0, "and nothing was saved to restore");
	}

	/// An ordinary tooltip is NOT hit testable: it must not stand between the pointer and the
	/// thing it is describing. An interactive one is.
	[Test]
	public static void OnlyAnInteractiveTooltipIsHitTestable()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let plain = new TipView(100, 50);
		root.AddView(plain);
		context.Tooltips.OnHoverChanged(plain);
		context.BeginFrame(0.6f);
		let layer = root.GetPopupLayer();
		UITest.LayoutPass(context, root);
		// Nothing in the layer answers a hit, since the only popup declines to.
		Test.Assert(layer.HitTest(.(5, 5)) == null);

		context.Tooltips.OnMouseDown();

		let interactive = new TipView(100, 50);
		interactive.IsTooltipInteractive = true;
		root.AddView(interactive);
		context.Tooltips.OnHoverChanged(interactive);
		context.BeginFrame(0.6f);
		UITest.LayoutPass(context, root);

		Test.Assert(layer.HitTest(.(5, 5)) != null, "an interactive one can be reached");
	}

	/// Nothing ANYWHERE in an ordinary tooltip answers a hit, its content included.
	///
	/// Hit test visibility is self only, which the tool float layers rely on, so clearing it
	/// on the tooltip view alone still left the CONTENT catching the pointer between the
	/// cursor and the thing being described. The probe sweeps the layer rather than guessing
	/// where the tooltip was placed.
	[Test]
	public static void AnOrdinaryTooltipPassesThePointerThroughItsWholeSubtree()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let plain = new TipView(100, 50);
		root.AddView(plain);
		context.Tooltips.OnHoverChanged(plain);
		context.BeginFrame(0.6f);
		let layer = root.GetPopupLayer();
		UITest.LayoutPass(context, root);
		Test.Assert(context.Tooltips.IsShowing, "the tooltip is up");

		for (int x = 0; x < 800; x += 10)
		{
			for (int y = 0; y < 600; y += 10)
				Test.Assert(layer.HitTest(.(x, y)) == null, "nothing in it catches the pointer");
		}

		// The interactive case is a real target, so SOMETHING in the same sweep answers.
		context.Tooltips.OnMouseDown();
		let interactive = new TipView(100, 50);
		interactive.IsTooltipInteractive = true;
		root.AddView(interactive);
		context.Tooltips.OnHoverChanged(interactive);
		context.BeginFrame(0.6f);
		UITest.LayoutPass(context, root);

		var reached = false;
		for (int x = 0; (x < 800) && !reached; x += 10)
		{
			for (int y = 0; y < 600; y += 10)
			{
				if (layer.HitTest(.(x, y)) != null)
				{
					reached = true;
					break;
				}
			}
		}
		Test.Assert(reached, "an interactive one is reachable");
	}
}
