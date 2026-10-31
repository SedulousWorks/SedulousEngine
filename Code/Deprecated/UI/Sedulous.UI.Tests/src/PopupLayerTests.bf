using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The overlay layer: popup lifetime, modality, click outside dismissal, and the focus scope an
/// open popup becomes.
class PopupLayerTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 800, 600);
	}

	private static TestView MakeView(float width = 50.0f, float height = 30.0f) =>
		new TestView(width, height);

	private static TestView Focusable(float width = 50.0f, float height = 30.0f)
	{
		let view = new TestView(width, height);
		view.IsFocusable = true;
		view.IsTabStop = true;
		return view;
	}

	/// Records that it was told about a close, and which popup closed.
	private class TestPopupOwner : IPopupOwner
	{
		public bool Notified = false;
		public View ClosedPopup = null;

		public void OnPopupClosed(View popup)
		{
			Notified = true;
			ClosedPopup = popup;
		}

		/// Not a view, so the cascade treats it as outside every popup.
		public View OwnerView => null;
	}

	// ---- The layer on its root ----------------------------------------------------------------

	/// The layer is created on FIRST ACCESS and kept last, so it draws over everything and hit
	/// tests before everything, however many children are added afterwards.
	[Test]
	public static void TheLayerIsCreatedOnDemandAndStaysLast()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		Test.Assert(root.PeekPopupLayer == null, "not created just by existing");

		let layer = root.GetPopupLayer();
		Test.Assert(layer != null);
		Test.Assert(root.PeekPopupLayer == layer);

		root.AddView(MakeView());
		Test.Assert(root.GetChildAt(root.ChildCount - 1) == layer);

		root.AddView(MakeView());
		Test.Assert(root.GetChildAt(root.ChildCount - 1) == layer, "still last");
	}

	// ---- Showing and closing --------------------------------------------------------------------

	[Test]
	public static void ShowingAndClosingMoveTheCount()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let layer = root.GetPopupLayer();

		let popup = MakeView();
		popup.AddRef(); // held past the close
		defer popup.ReleaseRef();

		layer.ShowPopup(popup, null, 10, 10);
		Test.Assert(layer.PopupCount == 1);

		layer.ClosePopup(popup);
		Test.Assert(layer.PopupCount == 0);
	}

	/// A closed popup is UNREGISTERED, so nothing can resolve its id afterwards.
	[Test]
	public static void AClosedPopupIsUnregistered()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let layer = root.GetPopupLayer();

		let popup = MakeView();
		popup.AddRef();
		defer popup.ReleaseRef();
		let id = popup.Id;

		layer.ShowPopup(popup, null, 10, 10);
		Test.Assert(context.GetViewById(id) == popup);

		layer.ClosePopup(popup);
		Test.Assert(context.GetViewById(id) == null);
	}

	[Test]
	public static void TheOwnerIsToldWhichPopupClosed()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let layer = root.GetPopupLayer();
		let owner = scope TestPopupOwner();

		let popup = MakeView();
		popup.AddRef();
		defer popup.ReleaseRef();

		layer.ShowPopup(popup, owner, 10, 10);
		layer.ClosePopup(popup);

		Test.Assert(owner.Notified);
		Test.Assert(owner.ClosedPopup == popup);
	}

	/// Closing EVERY popup is what a root leaving its window needs: a detached root gets no
	/// input and no ticks, so an open menu would freeze and still be showing on its return.
	[Test]
	public static void CloseAllPopupsEmptiesTheLayer()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let layer = root.GetPopupLayer();

		layer.ShowPopup(MakeView(), null, 10, 10);
		layer.ShowPopup(MakeView(), null, 30, 30);
		layer.ShowPopup(MakeView(), null, 50, 50);
		Test.Assert(layer.PopupCount == 3);

		layer.CloseAllPopups();

		Test.Assert(layer.PopupCount == 0);
	}

	// ---- Modality -----------------------------------------------------------------------------

	[Test]
	public static void AModalPopupIsReportedAsOne()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let layer = root.GetPopupLayer();

		let popup = MakeView();
		layer.ShowPopup(popup, null, 10, 10, true, true);

		Test.Assert(layer.HasModalPopup);
		Test.Assert(layer.TopmostModalPopup == popup);
	}

	/// A modal BLOCKS the background: a click outside it reaches the layer, not the content
	/// underneath.
	[Test]
	public static void AModalBlocksTheBackgroundFromBeingHit()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let background = MakeView(800, 600);
		root.AddView(background);
		let layer = root.GetPopupLayer();
		layer.ShowPopup(MakeView(), null, 10, 10, true, true);
		UITest.LayoutPass(context, root);

		let hit = root.HitTest(.(700, 500)); // outside the popup, over the background

		Test.Assert(hit != background, "the modal swallowed it");
	}

	// ---- Click outside --------------------------------------------------------------------------

	[Test]
	public static void ClickingOutsideClosesADismissablePopup()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let layer = root.GetPopupLayer();

		layer.ShowPopup(MakeView(), null, 10, 10, true);
		Test.Assert(layer.PopupCount == 1);

		Test.Assert(layer.HandleClickOutside(null, 0), "the left button consumed it");
		Test.Assert(layer.PopupCount == 0);
	}

	/// A popup that opted OUT of click dismissal stays open, and nothing was consumed.
	[Test]
	public static void APopupThatDoesNotDismissOnClickStaysOpen()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let layer = root.GetPopupLayer();

		layer.ShowPopup(MakeView(), null, 10, 10, false);

		Test.Assert(!layer.HandleClickOutside(null, 0));
		Test.Assert(layer.PopupCount == 1);
	}

	/// A RIGHT click that dismisses is not consumed: it should still reach what is underneath,
	/// so dismissing a menu and opening a context menu there is one gesture.
	[Test]
	public static void ARightClickDismissesWithoutBeingConsumed()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let layer = root.GetPopupLayer();

		layer.ShowPopup(MakeView(), null, 10, 10, true);

		Test.Assert(!layer.HandleClickOutside(null, 1), "dismissed, but not consumed");
		Test.Assert(layer.PopupCount == 0);
	}

	// ---- Focus --------------------------------------------------------------------------------

	/// Opening a focus taking popup DISPLACES the focus, and closing gives it back.
	[Test]
	public static void OpeningTakesFocusAndClosingGivesItBack()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let view = Focusable();
		root.AddView(view);
		focus.SetFocus(view);

		let layer = root.GetPopupLayer();
		let popup = MakeView();
		popup.AddRef();
		defer popup.ReleaseRef();
		layer.ShowPopup(popup, null, 10, 10);

		Test.Assert(focus.FocusedView == null, "the popup displaced it");
		Test.Assert(focus.FocusStackDepth == 1);

		layer.ClosePopup(popup);

		Test.Assert(focus.FocusedView == view);
		Test.Assert(focus.FocusStackDepth == 0);
	}

	/// A popup that does NOT take focus leaves it alone. A tooltip appearing mid typing must
	/// not clear the editor's focus and take its completion popup down with it.
	[Test]
	public static void APopupThatDoesNotTakeFocusLeavesItAlone()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let view = Focusable();
		root.AddView(view);
		focus.SetFocus(view);

		root.GetPopupLayer().ShowPopup(MakeView(), null, 10, 10, true, false, true, false);

		Test.Assert(focus.FocusedView == view, "untouched");
		Test.Assert(focus.FocusStackDepth == 0);
	}

	/// Tab is TRAPPED inside an open focus taking popup. That is two things at once: the
	/// keyboard cannot reach background controls through a modal's own backdrop, and popup
	/// content is reachable at all, since popups are not children and a root walk never finds
	/// them.
	[Test]
	public static void TabIsTrappedInsideAnOpenPopup()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let background = Focusable();
		root.AddView(background);

		let popup = new ViewGroup();
		popup.AddRef();
		defer popup.ReleaseRef();
		let inner = Focusable();
		let alsoInner = Focusable();
		popup.AddView(inner);
		popup.AddView(alsoInner);

		let layer = root.GetPopupLayer();
		layer.ShowPopup(popup, null, 10, 10, true, true, false);
		UITest.LayoutPass(context, root);

		focus.FocusNext();
		Test.Assert((focus.FocusedView == inner) || (focus.FocusedView == alsoInner));

		focus.FocusNext();
		focus.FocusNext();
		Test.Assert((focus.FocusedView == inner) || (focus.FocusedView == alsoInner),
			"cycled within the popup");
		Test.Assert(focus.FocusedView != background);

		layer.ClosePopup(popup);
		focus.FocusNext();
		Test.Assert(focus.FocusedView == background, "the scope is gone");
	}

	/// Closing OUT OF ORDER never cross restores: each popup gives back only what it saved.
	[Test]
	public static void ClosingOutOfOrderNeverCrossRestoresFocus()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let baseView = Focusable();
		root.AddView(baseView);
		focus.SetFocus(baseView); // what the first popup will displace

		let layer = root.GetPopupLayer();
		let first = MakeView(100, 50);
		first.AddRef();
		defer first.ReleaseRef();
		layer.ShowPopup(first, null, 10, 10);

		let second = MakeView(100, 50);
		second.AddRef();
		defer second.ReleaseRef();
		layer.ShowPopup(second, null, 30, 30);

		// The FIRST closes first, out of order: it restores what IT saved.
		layer.ClosePopup(first);
		Test.Assert(focus.FocusedView == baseView);

		// And the second restores what IT saved, which was nothing.
		layer.ClosePopup(second);
		Test.Assert(focus.FocusedView == baseView, "not the first's entry a second time");
		Test.Assert(focus.FocusStackDepth == 0);
	}

	// ---- Layout -------------------------------------------------------------------------------

	/// A popup anchored LOW is clamped to what is left below it, rather than taking its full
	/// measured height and running off the layer with its tail unreachable.
	[Test]
	public static void APopupAnchoredLowIsClampedToTheSpaceBelowIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		UITest.LayoutPass(context, root);

		let popup = MakeView(100, 500); // it would measure five hundred tall
		root.GetPopupLayer().ShowPopup(popup, null, 10, 400);
		UITest.LayoutPass(context, root);

		Test.Assert(popup.Height == 200.0f, "only two hundred fit below four hundred");
	}

	/// A layer dying with a popup still open must clear that popup's Parent.
	///
	/// Popups live in the layer's ENTRIES rather than among its children, so a retained one - a
	/// menu bar's menu, a combo box's list - outlives the layer and would otherwise keep a
	/// Parent pointing into freed memory, which the next ShowPopup would follow.
	[Test]
	public static void ALayerDyingClearsItsOpenPopupsParent()
	{
		let popup = new TestView(50, 30);
		defer popup.ReleaseRef();

		{
			let layer = new PopupLayer();
			defer layer.ReleaseRef();

			// AddRef because ShowPopup consumes, and this popup outlives the layer.
			popup.AddRef();
			layer.ShowPopup(popup, null, 10, 10, false, false, false, false);
			Test.Assert(popup.Parent == layer);
		}

		Test.Assert(popup.Parent == null, "the layer died with the popup still open");
	}
}
