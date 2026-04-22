using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Represents an active popup with its owner and position.
public class PopupInfo
{
	/// The popup element.
	public UIElement Popup;
	/// The owner element that opened this popup.
	public UIElement Owner;
	/// The anchor bounds (where the popup is anchored to).
	public RectangleF AnchorBounds;
	/// Whether clicking outside should close the popup.
	public bool CloseOnClickOutside = true;

	public this(UIElement popup, UIElement owner, RectangleF anchorBounds)
	{
		Popup = popup;
		Owner = owner;
		AnchorBounds = anchorBounds;
	}
}

/// Overlay container for popups (dropdowns, menus, tooltips).
/// Popups are rendered above all other content and receive input first.
public class PopupLayer : Container
{
	// Active popups (ordered by z-order, last is topmost)
	private List<PopupInfo> mPopups = new .() ~ {
		for (let info in _)
			delete info;
		delete _;
	};

	/// Creates a new PopupLayer.
	public this()
	{
		// PopupLayer itself is not focusable
		IsFocusable = false;
		IsTabStop = false;
	}

	/// Returns whether there are any active popups.
	public bool HasPopups => mPopups.Count > 0;

	/// Number of active popups.
	public int PopupCount => mPopups.Count;

	/// Updates all active popups (for timers, animations, etc.).
	public void Update(double totalTime)
	{
		for (let info in mPopups)
		{
			// Update context menus for submenu hover timing
			if (let contextMenu = info.Popup as ContextMenu)
				contextMenu.Update(totalTime);
		}
	}

	/// Shows a popup anchored to the specified bounds.
	/// The popup will be positioned below the anchor if space permits, otherwise above.
	public void ShowPopup(UIElement popup, UIElement owner, RectangleF anchorBounds, bool closeOnClickOutside = true)
	{
		if (popup == null)
			return;

		// Check if popup is already shown
		for (let info in mPopups)
		{
			if (info.Popup == popup)
				return;
		}

		let info = new PopupInfo(popup, owner, anchorBounds);
		info.CloseOnClickOutside = closeOnClickOutside;
		mPopups.Add(info);

		AddChild(popup);
		InvalidateLayout();
	}

	/// Closes a specific popup.
	/// Note: The popup is NOT deleted - ownership remains with the caller.
	public void ClosePopup(UIElement popup)
	{
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			if (mPopups[i].Popup == popup)
			{
				let info = mPopups[i];
				let owner = info.Owner;
				mPopups.RemoveAt(i);
				RemoveChild(popup, false);  // Don't delete - caller owns popup

				// Notify owner if it implements IPopupOwner
				if (let popupOwner = owner as IPopupOwner)
					popupOwner.OnPopupClosed(popup);

				// Also notify popup itself if it implements IPopupOwner (for Flyout, etc.)
				if (popup != owner)
				{
					if (let popupSelf = popup as IPopupOwner)
						popupSelf.OnPopupClosed(popup);
				}

				delete info;
				InvalidateLayout();
				break;
			}
		}
	}

	/// Closes all popups.
	/// Note: Popups are NOT deleted - ownership remains with the callers.
	public void CloseAllPopups()
	{
		for (let info in mPopups)
		{
			let owner = info.Owner;
			let popup = info.Popup;
			RemoveChild(popup, false);  // Don't delete - caller owns popup

			// Notify owner if it implements IPopupOwner
			if (let popupOwner = owner as IPopupOwner)
				popupOwner.OnPopupClosed(popup);

			// Also notify popup itself if it implements IPopupOwner
			if (popup != owner)
			{
				if (let popupSelf = popup as IPopupOwner)
					popupSelf.OnPopupClosed(popup);
			}

			delete info;
		}
		mPopups.Clear();
		InvalidateLayout();
	}

	/// Closes popups owned by the specified element.
	/// Note: Popups are NOT deleted - ownership remains with the owner.
	public void ClosePopupsOwnedBy(UIElement owner)
	{
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			if (mPopups[i].Owner == owner)
			{
				let info = mPopups[i];
				let popup = info.Popup;
				mPopups.RemoveAt(i);
				RemoveChild(popup, false);  // Don't delete - caller owns popup

				// Notify owner if it implements IPopupOwner
				if (let popupOwner = owner as IPopupOwner)
					popupOwner.OnPopupClosed(popup);

				// Also notify popup itself if it implements IPopupOwner
				if (popup != owner)
				{
					if (let popupSelf = popup as IPopupOwner)
						popupSelf.OnPopupClosed(popup);
				}

				delete info;
			}
		}
		InvalidateLayout();
	}

	/// Returns whether the specified element is within a popup.
	public bool IsInPopup(UIElement element)
	{
		var current = element;
		while (current != null)
		{
			for (let info in mPopups)
			{
				if (info.Popup == current)
					return true;
			}
			current = current.Parent;
		}
		return false;
	}

	/// Gets popup info for an element if it's a popup.
	public PopupInfo GetPopupInfo(UIElement popup)
	{
		for (let info in mPopups)
		{
			if (info.Popup == popup)
				return info;
		}
		return null;
	}

	/// Handles click outside popup - returns true if a popup was closed.
	/// Closes entire menu chains when clicking outside (not just the topmost popup).
	public bool HandleClickOutside(Vector2 point)
	{
		if (mPopups.Count == 0)
			return false;

		// First, check if click is inside ANY popup
		for (let info in mPopups)
		{
			let hitResult = info.Popup.HitTest(point);
			if (hitResult != null)
				return false;  // Click is inside a popup, don't close anything
		}

		// Click is outside all popups - close all that have CloseOnClickOutside
		// We need to collect them first since ClosePopup modifies the list
		List<UIElement> toClose = scope .();
		for (let info in mPopups)
		{
			if (info.CloseOnClickOutside)
				toClose.Add(info.Popup);
		}

		for (let popup in toClose)
		{
			ClosePopup(popup);
		}

		return toClose.Count > 0;
	}

	// === Layout ===

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		for (let info in mPopups)
		{
			let popup = info.Popup;
			if (popup.Visibility == .Collapsed)
				continue;

			let desired = popup.DesiredSize;
			let anchor = info.AnchorBounds;

			// Position popup below anchor by default
			float x = anchor.X;
			float y = anchor.Bottom;

			// Clamp to viewport bounds
			let viewportWidth = contentBounds.Width;
			let viewportHeight = contentBounds.Height;

			// If popup goes off right edge, align to right edge of anchor
			if (x + desired.Width > viewportWidth)
				x = Math.Max(0, anchor.Right - desired.Width);

			// If popup goes off bottom, position above anchor
			if (y + desired.Height > viewportHeight)
				y = Math.Max(0, anchor.Top - desired.Height);

			// Final clamp
			x = Math.Max(0, Math.Min(x, viewportWidth - desired.Width));
			y = Math.Max(0, Math.Min(y, viewportHeight - desired.Height));

			popup.Arrange(.(x, y, desired.Width, desired.Height));
		}
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (mPopups.Count == 0)
			return null;

		// Test popups in reverse order (topmost first)
		for (int i = mPopups.Count - 1; i >= 0; i--)
		{
			let popup = mPopups[i].Popup;
			if (popup.Visibility != .Visible)
				continue;

			let hit = popup.HitTest(point);
			if (hit != null)
				return hit;
		}

		// If we have popups but click was outside all of them,
		// still return this layer to prevent clicks going through
		return null;  // Let GUIContext handle click-outside
	}
}
