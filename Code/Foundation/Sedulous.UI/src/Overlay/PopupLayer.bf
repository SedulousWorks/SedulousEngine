namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Central overlay manager. Always the last child of RootView (topmost for
/// drawing, first for hit-testing). Manages popup lifecycle, modal backdrops,
/// and click-outside dismissal.
///
/// Popups are not regular children - they are tracked via PopupEntry and
/// positioned/drawn/hit-tested independently of the normal layout system.
public class PopupLayer : ViewGroup
{
	private List<PopupEntry> mEntries = new .();

	// Reusable backdrop - not always attached as a child.
	private ModalBackdrop mBackdrop;

	/// Whether any modal popup is active.
	public bool HasModalPopup
	{
		get
		{
			for (let e in mEntries)
				if (e.IsModal) return true;
			return false;
		}
	}

	/// Number of active popups.
	public int PopupCount => mEntries.Count;

	/// Returns the topmost modal popup view, or null if no modals are active.
	public View TopmostModalPopup
	{
		get
		{
			for (int i = mEntries.Count - 1; i >= 0; i--)
				if (mEntries[i].IsModal) return mEntries[i].Popup;
			return null;
		}
	}

	// =================================================================
	// Show / Close
	// =================================================================

	/// Show a popup at an explicit position.
	public void ShowPopup(View popup, IPopupOwner owner, float x, float y,
		bool closeOnClickOutside = true, bool isModal = false, bool ownsView = true)
	{
		ShowPopupInternal(popup, owner, x, y, closeOnClickOutside, isModal, ownsView);
	}

	/// Show a popup using a position factory. The factory is called with an attempt
	/// index (0, 1, 2, ...) and should return candidate positions to try, or null
	/// to stop. The popup is attached and measured first, then the factory is called
	/// repeatedly until a position fits within the viewport or candidates are exhausted.
	/// If no candidate fits, the last candidate is used (clamped to viewport).
	///
	/// Example (dropdown below button, fallback above):
	///   layer.ShowPopup(menu, owner, new (attempt) => {
	///       switch (attempt) {
	///           case 0: return .(anchorX, anchorY + anchorH);  // below
	///           case 1: return .(anchorX, anchorY - menuH);    // above
	///           default: return null;
	///       }
	///   });
	public void ShowPopup(View popup, IPopupOwner owner,
		delegate Vector2?(int32 attempt) positionFactory,
		bool closeOnClickOutside = true, bool isModal = false, bool ownsView = true)
	{
		// Attach first so popup has context for measurement.
		ShowPopupInternal(popup, owner, 0, 0, closeOnClickOutside, isModal, ownsView);

		// Measure so we know popup size.
		let layerConstraints = BoxConstraints.Loose(Width, Height);
		popup.Measure(layerConstraints);
		let popupSize = popup.MeasuredSize;

		// Try candidates from factory.
		float bestX = 0, bestY = 0;
		bool placed = false;

		for (int32 attempt = 0; attempt < 16; attempt++)
		{
			let candidate = positionFactory(attempt);
			if (candidate == null)
				break;

			let pos = candidate.Value;
			bestX = pos.X;
			bestY = pos.Y;

			// Check if it fits within the layer bounds.
			if (pos.X >= 0 && pos.Y >= 0 &&
				pos.X + popupSize.X <= Width &&
				pos.Y + popupSize.Y <= Height)
			{
				placed = true;
				break;
			}
		}

		// If nothing fit perfectly, clamp the last candidate to viewport.
		if (!placed)
		{
			bestX = Math.Clamp(bestX, 0, Math.Max(0, Width - popupSize.X));
			bestY = Math.Clamp(bestY, 0, Math.Max(0, Height - popupSize.Y));
		}

		// Update stored position.
		UpdatePopupPosition(popup, bestX, bestY);

		delete positionFactory;
	}

	private void ShowPopupInternal(View popup, IPopupOwner owner, float x, float y,
		bool closeOnClickOutside, bool isModal, bool ownsView)
	{
		let entry = new PopupEntry();
		entry.Popup = popup;
		entry.Owner = owner;
		entry.CloseOnClickOutside = closeOnClickOutside;
		entry.IsModal = isModal;
		entry.OwnsView = ownsView;
		entry.X = x;
		entry.Y = y;
		mEntries.Add(entry);

		// Add modal backdrop before the popup if this is the first modal.
		if (isModal && !HasModalExcept(entry))
		{
			if (mBackdrop == null)
				mBackdrop = new ModalBackdrop();
			if (mBackdrop.Parent == null)
				AddView(mBackdrop);
		}

		// Save and clear focus so the popup blocks keyboard input to underlying views.
		Context?.FocusManager.PushFocus();

		// Attach popup to the view tree so it gets a context (needed for measurement).
		popup.Parent = this;
		if (Context != null)
			Context.AttachView(popup);

		Invalidate();
	}

	/// Close a specific popup.
	public void ClosePopup(View popup)
	{
		// Cascade first: any popup whose IPopupOwner lives inside the popup
		// we're about to delete must close NOW, otherwise its Owner pointer
		// dangles into freed memory the next time we measure/lay out
		// (repro: ComboBox dropdown open inside a Dialog, then Cancel).
		CloseDependentPopups(popup);

		for (int i = 0; i < mEntries.Count; i++)
		{
			if (mEntries[i].Popup === popup)
			{
				let entry = mEntries[i];
				mEntries.RemoveAt(i);

				// Detach from tree.
				if (popup.Context != null)
					popup.Context.DetachView(popup);
				popup.Parent = null;

				// Notify owner.
				entry.Owner?.OnPopupClosed(popup);

				// Delete if owned.
				if (entry.OwnsView)
					delete popup;

				delete entry;

				// Restore focus from stack.
				Context?.FocusManager.PopFocus();

				// Remove backdrop if no more modals.
				if (!HasModalPopup && mBackdrop != null && mBackdrop.Parent != null)
					RemoveView(mBackdrop, false); // don't delete - reuse

				Invalidate();
				return;
			}
		}
	}

	/// Close all popups with CloseOnClickOutside (topmost first).
	/// Called by InputManager when a click lands outside all popups.
	/// Returns true if any popup was closed (LMB consumed).
	public bool HandleClickOutside(int32 button)
	{
		bool closed = false;
		while (true)
		{
			bool found = false;
			for (int i = mEntries.Count - 1; i >= 0; i--)
			{
				if (mEntries[i].CloseOnClickOutside)
				{
					ClosePopup(mEntries[i].Popup);
					closed = true;
					found = true;
					break; // restart - list changed
				}
			}
			if (!found) break;
		}
		// LMB consumed if we closed something; RMB continues.
		return closed && button == 0;
	}

	/// Update the position of an existing popup (e.g., centering after measurement).
	public void UpdatePopupPosition(View popup, float x, float y)
	{
		for (let entry in mEntries)
		{
			if (entry.Popup === popup)
			{
				entry.X = x;
				entry.Y = y;
				Invalidate();
				return;
			}
		}
	}

	// =================================================================
	// Layout - position popups at their stored coordinates
	// =================================================================

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// PopupLayer fills whatever space it's given.
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(constraints.MaxHeight));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		// Backdrop fills the whole layer.
		if (mBackdrop != null && mBackdrop.Parent != null)
			mBackdrop.Layout(0, 0, width, height);

		// Layout each popup at its stored position.
		let layerConstraints = BoxConstraints.Loose(width, height);
		for (let entry in mEntries)
		{
			let popup = entry.Popup;
			popup.Measure(layerConstraints);
			popup.Layout(entry.X, entry.Y, popup.MeasuredSize.X, popup.MeasuredSize.Y);
		}
	}

	// =================================================================
	// Hit testing - three-state
	// =================================================================

	public override View HitTest(Vector2 localPoint)
	{
		// Pass through when empty.
		if (mEntries.Count == 0 && (mBackdrop == null || mBackdrop.Parent == null))
			return null;

		// Hit-test popups in reverse order (topmost first).
		for (int i = mEntries.Count - 1; i >= 0; i--)
		{
			let entry = mEntries[i];
			let popup = entry.Popup;
			let popupLocal = Vector2(localPoint.X - entry.X, localPoint.Y - entry.Y);
			if (popupLocal.X >= 0 && popupLocal.Y >= 0 &&
				popupLocal.X < popup.Width && popupLocal.Y < popup.Height)
			{
				let hit = popup.HitTest(popupLocal);
				if (hit != null) return hit;
			}
		}

		// If modal, block input to underlying content.
		if (HasModalPopup)
			return this;

		// No popups hit, no modal - pass through.
		return null;
	}

	// =================================================================
	// Drawing - backdrop then popups in order
	// =================================================================

	public override void OnDraw(UIDrawContext ctx)
	{
		// Draw backdrop if present.
		if (mBackdrop != null && mBackdrop.Parent != null && mBackdrop.Visibility == .Visible)
		{
			ctx.VG.PushState();
			ctx.VG.Translate(mBackdrop.Bounds.X, mBackdrop.Bounds.Y);
			mBackdrop.OnDraw(ctx);
			ctx.VG.PopState();
		}

		// Draw popups in order (first = bottom, last = top).
		for (let entry in mEntries)
		{
			let popup = entry.Popup;
			if (popup.Visibility != .Visible) continue;

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

	// =================================================================
	// Internal
	// =================================================================

	private bool HasModalExcept(PopupEntry except)
	{
		for (let e in mEntries)
			if (e !== except && e.IsModal) return true;
		return false;
	}

	/// Close any popups whose owner lives inside `parent`'s subtree.
	/// Restart the scan after each close because the entry list mutates.
	private void CloseDependentPopups(View parent)
	{
		while (true)
		{
			View toClose = null;
			for (let entry in mEntries)
			{
				if (entry.Owner == null) continue;
				let ownerView = entry.Owner.OwnerView;
				if (ownerView == null) continue;
				if (IsDescendant(ownerView, parent))
				{
					toClose = entry.Popup;
					break;
				}
			}
			if (toClose == null) break;
			ClosePopup(toClose);
		}
	}

	private static bool IsDescendant(View child, View ancestor)
	{
		var p = child;
		while (p != null)
		{
			if (p === ancestor) return true;
			p = p.Parent;
		}
		return false;
	}

	// =================================================================
	// Destructor
	// =================================================================

	public ~this()
	{
		// Clean up popup entries - detach non-owned, delete owned.
		// Must happen before ViewGroup's destructor deletes mChildren.
		if (mEntries != null)
		{
			for (let e in mEntries)
			{
				if (!e.OwnsView && e.Popup != null && e.Popup.Parent == this)
				{
					e.Popup.Parent = null;
				}
				else if (e.OwnsView && e.Popup != null)
				{
					e.Popup.Parent = null;
					e.Popup.Context = null;
					delete e.Popup;
				}
				delete e;
			}
			delete mEntries;
			mEntries = null;
		}

		// Delete backdrop only if not currently a child
		// (ViewGroup's destructor handles children).
		if (mBackdrop != null && mBackdrop.Parent != this)
			delete mBackdrop;
	}
}
