using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Information about an active modal.
public class ModalInfo
{
	/// The modal element.
	public UIElement Modal;
	/// Whether to show a backdrop behind the modal.
	public bool ShowBackdrop;
	/// Previously focused element to restore focus when modal closes.
	public ElementHandle<UIElement> PreviousFocus;

	public this(UIElement modal, bool showBackdrop, UIElement previousFocus)
	{
		Modal = modal;
		ShowBackdrop = showBackdrop;
		PreviousFocus = previousFocus;
	}
}

/// Manages modal dialogs including backdrop rendering and focus trapping.
public class ModalManager
{
	// Stack of active modals
	private List<ModalInfo> mModalStack ~ {
		for (let info in _)
			delete info;
		delete _;
	};

	// Appearance
	private Color mBackdropColor = Color(0, 0, 0, 128);

	// Owning context
	private GUIContext mContext;

	/// Creates a ModalManager for the given context.
	public this(GUIContext context)
	{
		mContext = context;
		mModalStack = new .();
	}

	/// Whether there are any active modals.
	public bool HasModal => mModalStack.Count > 0;

	/// Number of active modals.
	public int ModalCount => mModalStack.Count;

	/// The backdrop color (default: semi-transparent black).
	public Color BackdropColor
	{
		get => mBackdropColor;
		set => mBackdropColor = value;
	}

	/// The backdrop opacity (modifies alpha of BackdropColor).
	public float BackdropOpacity
	{
		get => mBackdropColor.A / 255.0f;
		set
		{
			let alpha = (uint8)(Math.Clamp(value, 0, 1) * 255);
			mBackdropColor = Color(mBackdropColor.R, mBackdropColor.G, mBackdropColor.B, alpha);
		}
	}

	/// Pushes a modal onto the stack.
	/// The modal will receive focus and input will be blocked from reaching elements behind it.
	public void PushModal(UIElement modal, bool showBackdrop = true)
	{
		if (modal == null)
			return;

		// Check if already modal
		for (let info in mModalStack)
		{
			if (info.Modal == modal)
				return;
		}

		// Save current focus
		let previousFocus = mContext.FocusManager?.FocusedElement;

		let info = new ModalInfo(modal, showBackdrop, previousFocus);
		mModalStack.Add(info);

		// Measure modal to get its size for centering
		let constraints = SizeConstraints.FromMaximum(mContext.ViewportWidth, mContext.ViewportHeight);
		modal.Measure(constraints);
		let modalSize = modal.DesiredSize;

		// Calculate centered position
		let centeredX = (mContext.ViewportWidth - modalSize.Width) / 2;
		let centeredY = (mContext.ViewportHeight - modalSize.Height) / 2;

		// Show via popup layer (modal popups don't close on click-outside)
		// Use zero-height anchor rect at the centered position - PopupLayer places popup at anchor.Bottom
		let anchorRect = RectangleF(centeredX, centeredY, 0, 0);
		mContext.PopupLayer.ShowPopup(modal, null, anchorRect, false);

		// Focus the modal
		if (modal.IsFocusable)
			mContext.FocusManager?.SetFocus(modal);
		else
		{
			// Find first focusable element in modal
			let firstFocusable = FindFirstFocusable(modal);
			if (firstFocusable != null)
				mContext.FocusManager?.SetFocus(firstFocusable);
		}
	}

	/// Pops a specific modal from the stack.
	public void PopModal(UIElement modal)
	{
		for (int i = mModalStack.Count - 1; i >= 0; i--)
		{
			if (mModalStack[i].Modal == modal)
			{
				let info = mModalStack[i];
				mModalStack.RemoveAt(i);

				// Close the popup
				mContext.PopupLayer.ClosePopup(modal);

				// Restore focus
				let previousFocus = info.PreviousFocus.TryResolve();
				if (previousFocus != null)
					mContext.FocusManager?.SetFocus(previousFocus);
				else
					mContext.FocusManager?.ClearFocus();

				delete info;
				break;
			}
		}
	}

	/// Pops all modals from the stack.
	public void PopAllModals()
	{
		while (mModalStack.Count > 0)
		{
			let info = mModalStack.PopBack();
			mContext.PopupLayer.ClosePopup(info.Modal);
			delete info;
		}
		mContext.FocusManager?.ClearFocus();
	}

	/// Gets the topmost modal.
	public UIElement GetTopmostModal()
	{
		if (mModalStack.Count == 0)
			return null;
		return mModalStack[^1].Modal;
	}

	/// Renders the backdrop for modals.
	/// Call this before rendering popups if any modals have showBackdrop=true.
	public void RenderBackdrop(DrawContext ctx)
	{
		if (mModalStack.Count == 0)
			return;

		// Check if any modal wants a backdrop
		bool hasBackdrop = false;
		for (let info in mModalStack)
		{
			if (info.ShowBackdrop)
			{
				hasBackdrop = true;
				break;
			}
		}

		if (hasBackdrop)
		{
			let backdropRect = RectangleF(0, 0, mContext.ViewportWidth, mContext.ViewportHeight);
			ctx.FillRect(backdropRect, mBackdropColor);
		}
	}

	/// Handles Tab key to trap focus within the topmost modal.
	/// Returns true if Tab was handled.
	public bool HandleTabNavigation(bool shift)
	{
		if (mModalStack.Count == 0)
			return false;

		let modal = mModalStack[^1].Modal;
		let focusables = scope List<UIElement>();
		CollectFocusables(modal, focusables);

		if (focusables.Count == 0)
			return true;  // Block Tab but nothing to focus

		let currentFocus = mContext.FocusManager?.FocusedElement;
		int currentIndex = -1;
		for (int i = 0; i < focusables.Count; i++)
		{
			if (focusables[i] == currentFocus)
			{
				currentIndex = i;
				break;
			}
		}

		int nextIndex;
		if (shift)
			nextIndex = currentIndex <= 0 ? focusables.Count - 1 : currentIndex - 1;
		else
			nextIndex = currentIndex >= focusables.Count - 1 ? 0 : currentIndex + 1;

		mContext.FocusManager?.SetFocus(focusables[nextIndex]);
		return true;
	}

	/// Collects focusable elements within a container.
	private void CollectFocusables(UIElement element, List<UIElement> result)
	{
		if (element.Visibility != .Visible)
			return;

		if (element.IsFocusable && element.IsTabStop)
			result.Add(element);

		let childCount = element.VisualChildCount;
		for (int i = 0; i < childCount; i++)
		{
			let child = element.GetVisualChild(i);
			if (child != null)
				CollectFocusables(child, result);
		}
	}

	/// Finds the first focusable element in a container.
	private UIElement FindFirstFocusable(UIElement element)
	{
		if (element.Visibility != .Visible)
			return null;

		if (element.IsFocusable && element.IsTabStop)
			return element;

		let childCount = element.VisualChildCount;
		for (int i = 0; i < childCount; i++)
		{
			let child = element.GetVisualChild(i);
			if (child != null)
			{
				let found = FindFirstFocusable(child);
				if (found != null)
					return found;
			}
		}

		return null;
	}
}
