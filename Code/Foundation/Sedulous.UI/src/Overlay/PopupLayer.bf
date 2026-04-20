namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

/// Entry tracking a single popup in the layer.
public class PopupEntry
{
	public View Popup;
	public IPopupOwner Owner;
	public bool CloseOnClickOutside;
	public bool IsModal;
	public bool OwnsView;       // true = delete on close; false = detach only
	public float X, Y;
}

/// Central overlay manager. Rendered as the last child of RootView
/// (always on top for drawing and hit-testing). Manages popup
/// lifecycle, modal backdrops, and click-outside dismissal.
public class PopupLayer : ViewGroup
{
	private List<PopupEntry> mEntries = new .() ~ {
		// Detach non-owned popups BEFORE ViewGroup's destructor runs
		// (otherwise ViewGroup would delete them as children).
		for (let e in _)
		{
			if (!e.OwnsView && e.Popup != null && e.Popup.Parent == this)
			{
				e.Popup.Parent = null;
				// Don't call DetachSubtree here - context may already be gone.
			}
			else if (e.OwnsView && e.Popup != null)
			{
				delete e.Popup;
			}
			delete e;
		}
		delete _;
	};

	// Not `~ delete _` - if backdrop is a child, ViewGroup's mChildren
	// destructor handles it. If detached, we delete in ~this.
	private ModalBackdrop mBackdrop;

	public ~this()
	{
		// Delete backdrop only if it's NOT currently a child
		// (ViewGroup's mChildren destructor handles children).
		if (mBackdrop != null && mBackdrop.Parent != this)
			delete mBackdrop;
	}

	public bool HasModalPopup
	{
		get
		{
			for (let e in mEntries)
				if (e.IsModal) return true;
			return false;
		}
	}

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

	/// Show a popup at the given position.
	public void ShowPopup(View popup, IPopupOwner owner, float x, float y,
		bool closeOnClickOutside = true, bool isModal = false, bool ownsView = true)
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

		// Save and clear focus so the popup blocks keyboard input
		// to the underlying view. Focus restores on ClosePopup.
		Context?.FocusManager.PushFocus();

		popup.Parent = this;
		if (Context != null)
			ViewGroup.AttachSubtree(popup, Context);

		InvalidateLayout();
	}

	/// Close a specific popup.
	public void ClosePopup(View popup)
	{
		for (int i = 0; i < mEntries.Count; i++)
		{
			if (mEntries[i].Popup === popup)
			{
				let entry = mEntries[i];
				mEntries.RemoveAt(i);

				// Detach from tree.
				if (Context != null)
					ViewGroup.DetachSubtree(popup);
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

				InvalidateLayout();
				return;
			}
		}
	}

	/// Close all popups with CloseOnClickOutside (topmost first).
	/// Called by InputManager when a click lands outside all popups.
	/// No coordinate check - the caller already determined the click
	/// didn't hit any popup via hit-testing.
	public bool HandleClickOutside(MouseButton button)
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
		return closed && button == .Left;
	}

	/// Update the position of an existing popup (for centering after measurement).
	public void UpdatePopupPosition(View popup, float x, float y)
	{
		for (let entry in mEntries)
		{
			if (entry.Popup === popup)
			{
				entry.X = x;
				entry.Y = y;
				InvalidateLayout();
				return;
			}
		}
	}

	// === Layout: position popups at their stored coordinates ===

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		// Backdrop fills the whole layer.
		if (mBackdrop != null && mBackdrop.Parent != null)
			mBackdrop.Layout(0, 0, right - left, bottom - top);

		for (let entry in mEntries)
		{
			let popup = entry.Popup;
			popup.Measure(.AtMost(right - left), .AtMost(bottom - top));
			popup.Layout(entry.X, entry.Y, popup.MeasuredSize.X, popup.MeasuredSize.Y);
		}
	}

	// === Hit testing: three-state ===

	public override View HitTest(Vector2 localPoint)
	{
		if (mEntries.Count == 0 && (mBackdrop == null || mBackdrop.Parent == null))
			return null; // pass through when empty

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

		return null; // pass through
	}

	// === Drawing: backdrop then popups in order ===

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
			popup.OnDraw(ctx);
			ctx.VG.PopState();
		}
	}

	private bool HasModalExcept(PopupEntry except)
	{
		for (let e in mEntries)
			if (e !== except && e.IsModal) return true;
		return false;
	}
}
