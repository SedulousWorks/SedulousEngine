using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// The overlay layer: always the LAST child of a RootView, so it draws on top and hit tests
/// first.
///
/// Popups are NOT ordinary children. They are tracked as entries, positioned, drawn and hit
/// tested independently, which is what lets a menu sit anywhere over the tree without its
/// anchor's clipping or layout applying to it.
class PopupLayer : ViewGroup
{
	private List<PopupEntry> mEntries = new .() ~ ReleaseEntries(_);
	/// OWNED, created on first modal and reused.
	private ModalBackdrop mBackdrop ~ _?.ReleaseRef();

	public this() {}

	public ~this()
	{
		// Popups live in the entry list, NOT in mChildren, so ~ViewGroup's back pointer clear
		// never sees them. A popup held elsewhere, a menu bar's persistent menu or a combo's
		// dropdown, would keep a dangling Parent into this freed layer and the next ShowPopup
		// would dereference it.
		//
		// No OnPopupClosed and no focus restore here: the whole layer is dying with its root,
		// and there is nothing left to give focus back to.
		for (let entry in mEntries)
		{
			let popup = entry.Popup;
			if (popup == null)
				continue;
			if (popup.Context != null)
				popup.Context.DetachView(popup);
			if (popup.Parent == this)
				popup.Parent = null;
		}
	}

	private static void ReleaseEntries(List<PopupEntry> entries)
	{
		for (let entry in entries)
			entry.Popup?.ReleaseRef();
		delete entries;
	}

	// ---- Queries ------------------------------------------------------------------------------

	public int PopupCount => mEntries.Count;

	public bool HasModalPopup
	{
		get
		{
			for (let entry in mEntries)
			{
				if (entry.IsModal)
					return true;
			}
			return false;
		}
	}

	public View TopmostModalPopup
	{
		get
		{
			for (int i = mEntries.Count - 1; i >= 0; i--)
			{
				if (mEntries[i].IsModal)
					return mEntries[i].Popup;
			}
			return null;
		}
	}

	/// The topmost popup that TOOK FOCUS when it opened: menus and dialogs, not tooltips.
	///
	/// While one is open it IS the keyboard focus scope, which both traps the keyboard inside a
	/// modal and makes popup content reachable by Tab at all: popups are attached but are not
	/// ViewGroup children, so a walk from the root never finds them.
	public View TopmostFocusScopePopup
	{
		get
		{
			for (int i = mEntries.Count - 1; i >= 0; i--)
			{
				if (mEntries[i].PushedFocus)
					return mEntries[i].Popup;
			}
			return null;
		}
	}

	// ---- Showing ------------------------------------------------------------------------------

	/// Shows a popup at a position. CONSUMES the caller's reference.
	public void ShowPopup(View popup, IPopupOwner owner, float x, float y,
		bool closeOnClickOutside = true, bool isModal = false, bool ownsView = true,
		bool takesFocus = true)
	{
		ShowPopupInternal(popup, owner, x, y, closeOnClickOutside, isModal, ownsView, takesFocus);
	}

	/// Shows a popup, trying candidate positions until one FITS.
	///
	/// The factory is called with 0, 1, 2 and so on and answers null to stop. The popup is
	/// attached and measured first, since where it fits depends on how big it is; if nothing
	/// fits, the last candidate is clamped into the layer.
	public void ShowPopup(View popup, IPopupOwner owner, delegate Float2?(int32) positionFactory,
		bool closeOnClickOutside = true, bool isModal = false, bool ownsView = true,
		bool takesFocus = true)
	{
		ShowPopupInternal(popup, owner, 0, 0, closeOnClickOutside, isModal, ownsView, takesFocus);

		popup.Measure(BoxConstraints.Loose(Width, Height));
		let size = popup.MeasuredSize;

		var bestX = 0.0f;
		var bestY = 0.0f;
		var placed = false;
		for (int32 attempt = 0; attempt < 16; attempt++)
		{
			let candidate = positionFactory(attempt);
			if (candidate == null)
				break;

			bestX = candidate.Value.X;
			bestY = candidate.Value.Y;
			if ((bestX >= 0) && (bestY >= 0)
				&& ((bestX + size.X) <= Width) && ((bestY + size.Y) <= Height))
			{
				placed = true;
				break;
			}
		}

		if (!placed)
		{
			bestX = Clamp(bestX, 0.0f, Max(0.0f, Width - size.X));
			bestY = Clamp(bestY, 0.0f, Max(0.0f, Height - size.Y));
		}

		UpdatePopupPosition(popup, bestX, bestY);
	}

	public void UpdatePopupPosition(View popup, float x, float y)
	{
		for (int i < mEntries.Count)
		{
			if (mEntries[i].Popup != popup)
				continue;

			var entry = mEntries[i];
			entry.X = x;
			entry.Y = y;
			mEntries[i] = entry;
			Invalidate();
			return;
		}
	}

	// ---- Closing ------------------------------------------------------------------------------

	/// Closes one popup, and anything that depended on it.
	public void ClosePopup(View popup)
	{
		// Cascade first: a popup whose owner lives INSIDE the one being closed must go first,
		// or its owner pointer would dangle on the next layout.
		CloseDependentPopups(popup);

		for (int i < mEntries.Count)
		{
			if (mEntries[i].Popup != popup)
				continue;

			let entry = mEntries[i];
			mEntries.RemoveAt(i);

			if (popup.Context != null)
				popup.Context.DetachView(popup);
			popup.Parent = null;

			if (entry.Owner != null)
				entry.Owner.OnPopupClosed(popup);

			if (entry.PushedFocus && (Context != null))
			{
				// Restores what THIS popup displaced, and validates as it goes: a no op if the
				// target died, was disabled or was hidden meanwhile.
				Context.GetFocusManager().RestoreFocus(entry.SavedFocusEntry);
			}

			if (!HasModalPopup && (mBackdrop != null) && (mBackdrop.Parent != null))
			{
				// RemoveView releases the tree's reference and the field keeps its own, so
				// nothing has to be added back first.
				RemoveView(mBackdrop);
			}

			// Released LAST, so everything above ran while the popup was certainly alive.
			popup.ReleaseRef();
			Invalidate();
			return;
		}
	}

	/// Closes EVERY popup, topmost first.
	///
	/// What a root leaving its window needs: a detached root gets no input and no ticks, so an
	/// open menu would freeze and still be showing when the root came back.
	public void CloseAllPopups()
	{
		while (!mEntries.IsEmpty)
			ClosePopup(mEntries[mEntries.Count - 1].Popup);
	}

	/// Closes the popups stacked ABOVE whichever one contains the hit view, topmost first.
	///
	/// A hit outside every popup closes all the dismissable ones. Answers whether the click was
	/// consumed, which is true only for the left button: a right click that dismisses a menu
	/// should still reach what is underneath to open a context menu there.
	public bool HandleClickOutside(View hitView, int32 button)
	{
		var hitPopupIndex = -1;
		var view = hitView;
		while (view != null)
		{
			if (view.Parent == this)
			{
				for (int i < mEntries.Count)
				{
					if (mEntries[i].Popup == view)
					{
						hitPopupIndex = (int)i;
						break;
					}
				}
				break;
			}
			view = view.Parent;
		}

		var closed = false;
		while (true)
		{
			var found = false;
			// Restarted after each close: closing one cascades and mutates the list.
			for (int i = mEntries.Count - 1; i > hitPopupIndex; i--)
			{
				if (!mEntries[i].CloseOnClickOutside)
					continue;

				ClosePopup(mEntries[i].Popup);
				closed = true;
				found = true;
				break;
			}

			if (!found)
				break;
		}

		return closed && (button == 0);
	}

	// ---- Hit testing --------------------------------------------------------------------------

	/// Three outcomes: a popup was hit, a modal BLOCKS the click, or the layer passes it
	/// through to the tree underneath.
	public override View HitTest(Float2 localPoint)
	{
		if (mEntries.IsEmpty && ((mBackdrop == null) || (mBackdrop.Parent == null)))
			return null;

		// Topmost first.
		for (int i = mEntries.Count - 1; i >= 0; i--)
		{
			let entry = mEntries[i];
			let popup = entry.Popup;
			let popupLocal = Float2(localPoint.X - entry.X, localPoint.Y - entry.Y);
			if ((popupLocal.X < 0) || (popupLocal.Y < 0)
				|| (popupLocal.X >= popup.Width) || (popupLocal.Y >= popup.Height))
				continue;

			if (let hit = popup.HitTest(popupLocal))
				return hit;
		}

		// A modal swallows whatever it did not land on.
		if (HasModalPopup)
			return this;

		return null;
	}

	// ---- Draw ---------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		if ((mBackdrop != null) && (mBackdrop.Parent != null)
			&& (mBackdrop.Visibility == .Visible))
		{
			ctx.VG.PushState();
			ctx.VG.Translate(mBackdrop.Bounds.X, mBackdrop.Bounds.Y);
			mBackdrop.OnDraw(ctx);
			ctx.VG.PopState();
		}

		// In entry order, so a popup opened later draws over one opened earlier.
		for (let entry in mEntries)
		{
			let popup = entry.Popup;
			if (popup.Visibility != .Visible)
				continue;

			ctx.VG.PushState();
			ctx.VG.Translate(entry.X, entry.Y);
			if (popup.Opacity < 1.0f)
				ctx.VG.PushOpacity(popup.Opacity);

			popup.OnDraw(ctx);

			if (popup.Opacity < 1.0f)
				ctx.VG.PopOpacity();
			ctx.VG.PopState();
		}
	}

	// ---- Measure and arrange --------------------------------------------------------------------

	/// The layer fills its root: it is a surface for popups to sit on, not a box that shrinks
	/// to what is in it.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(constraints.MaxHeight));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if ((mBackdrop != null) && (mBackdrop.Parent != null))
			mBackdrop.Layout(0, 0, width, height);

		for (let entry in mEntries)
		{
			let popup = entry.Popup;
			popup.Measure(BoxConstraints.Loose(width, height));

			// Clamped to what is left BELOW the anchor. A popup placed low would otherwise take
			// its full measured height and run off the layer with its tail unreachable; a
			// scroll aware popup sees the smaller height and scrolls instead.
			let available = Max(0.0f, height - entry.Y);
			popup.Layout(entry.X, entry.Y, popup.MeasuredSize.X,
				Min(popup.MeasuredSize.Y, available));
		}
	}

	// ---- Internals ----------------------------------------------------------------------------

	private void ShowPopupInternal(View popup, IPopupOwner owner, float x, float y,
		bool closeOnClickOutside, bool isModal, bool ownsView, bool takesFocus)
	{
		if (popup == null)
			return;

		var entry = PopupEntry();
		entry.Popup = popup;
		entry.Owner = owner;
		entry.CloseOnClickOutside = closeOnClickOutside;
		entry.IsModal = isModal;
		entry.OwnsView = ownsView;
		entry.PushedFocus = takesFocus;
		entry.X = x;
		entry.Y = y;

		// A tooltip must NEVER disturb focus: appearing mid typing, it would otherwise clear
		// the editor's focus and take its completion popup down with it.
		if (takesFocus && (Context != null))
			entry.SavedFocusEntry = Context.GetFocusManager().SaveAndClearFocus();

		let hadModal = HasModalPopup;
		mEntries.Add(entry);

		if (isModal && !hadModal)
		{
			if (mBackdrop == null)
				mBackdrop = new ModalBackdrop();
			if (mBackdrop.Parent == null)
			{
				mBackdrop.AddRef(); // AddView consumes one; the layer keeps its own
				AddView(mBackdrop);
			}
		}

		popup.Parent = this;
		if (Context != null)
			Context.AttachView(popup);

		Invalidate();
	}

	/// Closes every popup whose owner lives inside a subtree, restarting after each because the
	/// list mutates under the walk.
	private void CloseDependentPopups(View parent)
	{
		while (true)
		{
			View toClose = null;
			for (let entry in mEntries)
			{
				if (entry.Owner == null)
					continue;

				let ownerView = entry.Owner.OwnerView;
				if ((ownerView != null) && IsDescendant(ownerView, parent))
				{
					toClose = entry.Popup;
					break;
				}
			}

			if (toClose == null)
				return;

			ClosePopup(toClose);
		}
	}

	private static bool IsDescendant(View child, View ancestor)
	{
		var current = child;
		while (current != null)
		{
			if (current == ancestor)
				return true;
			current = current.Parent;
		}
		return false;
	}
}
