using System;
using System.Collections;

namespace Sedulous.GUI;

/// Manages keyboard focus and tab navigation for a GUIContext.
public class FocusManager
{
	private GUIContext mContext;
	private ElementHandle<UIElement> mFocusedElement;
	private ElementHandle<UIElement> mCapturedElement;

	/// Creates a FocusManager for the specified context.
	public this(GUIContext context)
	{
		mContext = context;
		mFocusedElement = .Invalid;
		mCapturedElement = .Invalid;
	}

	/// The currently focused element (null if deleted or none).
	public UIElement FocusedElement => mFocusedElement.TryResolve();

	/// The element that has captured mouse input (null if deleted or none).
	public UIElement CapturedElement => mCapturedElement.TryResolve();

	/// Sets focus to the specified element.
	/// If the element is null, clears focus.
	public void SetFocus(UIElement element)
	{
		let currentFocused = mFocusedElement.TryResolve();

		if (currentFocused == element)
			return;

		// Don't focus non-focusable elements
		if (element != null && !element.IsFocusable)
			return;

		// Clear old focus
		if (currentFocused != null)
		{
			currentFocused.IsFocused = false;
		}

		mFocusedElement = element;

		// Set new focus
		if (element != null)
		{
			element.IsFocused = true;
		}
	}

	/// Clears focus from all elements.
	public void ClearFocus()
	{
		SetFocus(null);
	}

	/// Captures mouse input for the specified element.
	/// While captured, the element receives all mouse events regardless of position.
	public void SetCapture(UIElement element)
	{
		mCapturedElement = element;
	}

	/// Releases mouse capture.
	public void ReleaseCapture()
	{
		mCapturedElement = .Invalid;
	}

	/// Moves focus to the next focusable element in tab order.
	public void FocusNext()
	{
		MoveFocus(forward: true);
	}

	/// Moves focus to the previous focusable element in tab order.
	public void FocusPrevious()
	{
		MoveFocus(forward: false);
	}

	/// Moves focus in the specified direction.
	private void MoveFocus(bool forward)
	{
		// Collect all focusable elements
		let focusable = scope List<UIElement>();
		CollectFocusableElements(mContext.RootElement, focusable);

		if (focusable.Count == 0)
			return;

		// Sort by TabIndex
		focusable.Sort(scope (a, b) => a.TabIndex <=> b.TabIndex);

		// Find current focused index
		int currentIndex = -1;
		let currentFocused = mFocusedElement.TryResolve();
		if (currentFocused != null)
		{
			currentIndex = focusable.IndexOf(currentFocused);
		}

		// Calculate next index
		int nextIndex;
		if (forward)
		{
			nextIndex = (currentIndex + 1) % focusable.Count;
		}
		else
		{
			nextIndex = currentIndex - 1;
			if (nextIndex < 0)
				nextIndex = focusable.Count - 1;
		}

		SetFocus(focusable[nextIndex]);
	}

	/// Recursively collects all focusable elements.
	private void CollectFocusableElements(UIElement element, List<UIElement> focusable)
	{
		if (element == null || element.Visibility != .Visible)
			return;

		// Check if this element is focusable and a tab stop
		if (element.IsFocusable && element.IsTabStop)
		{
			// For Controls, also check if effectively enabled
			if (let control = element as Control)
			{
				if (control.IsEffectivelyEnabled)
					focusable.Add(element);
			}
			else
			{
				// Non-Control UIElements that are focusable (uncommon but allowed)
				focusable.Add(element);
			}
		}

		// Recurse into visual children using polymorphic access
		let childCount = element.VisualChildCount;
		for (int i = 0; i < childCount; i++)
		{
			let child = element.GetVisualChild(i);
			if (child != null)
				CollectFocusableElements(child, focusable);
		}
	}

	/// Called when an element is about to be deleted.
	/// Clears focus/capture if they reference the element.
	public void OnElementDeleted(UIElementId elementId)
	{
		if (mFocusedElement.Id == elementId)
			mFocusedElement = .Invalid;
		if (mCapturedElement.Id == elementId)
			mCapturedElement = .Invalid;
	}
}
