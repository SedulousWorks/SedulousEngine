using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Manages input routing for a GUIContext.
/// Routes mouse and keyboard events to the appropriate UI elements.
public class InputManager
{
	private GUIContext mContext;
	private ElementHandle<UIElement> mHoveredElement;
	private Vector2 mLastMousePosition;

	// Double-click tracking
	private double mLastClickTime;
	private float mLastClickX;
	private float mLastClickY;
	private MouseButton mLastClickButton;
	private int32 mClickCount;

	/// Maximum time between clicks for a double/multi-click (in seconds).
	public const double DoubleClickTime = 0.5;

	/// Maximum distance between clicks for a double/multi-click (in pixels).
	public const float DoubleClickDistance = 4.0f;

	/// Creates an InputManager for the specified context.
	public this(GUIContext context)
	{
		mContext = context;
		mHoveredElement = .Invalid;
	}

	/// The element currently under the mouse cursor (null if deleted or none).
	public UIElement HoveredElement => mHoveredElement.TryResolve();

	/// The last known mouse position.
	public Vector2 LastMousePosition => mLastMousePosition;

	/// Process a mouse move event.
	public void ProcessMouseMove(float x, float y)
	{
		mLastMousePosition = .(x, y);

		// Update drag operation if in progress
		let dragManager = mContext.DragDropManager;
		if (dragManager != null && (dragManager.IsDragging || dragManager.IsDragPending))
		{
			dragManager.UpdateDrag(.(x, y));
		}

		// If there's a capture, route to captured element
		let captured = mContext.FocusManager?.CapturedElement;
		if (captured != null)
		{
			let args = scope MouseEventArgs(x, y);
			InvokeMouseMove(captured, args);
			return;
		}

		// Hit test to find element under cursor (coordinates are already logical)
		let hitElement = mContext.HitTestLogical(x, y);

		// Get current hovered element (may be null if deleted)
		let currentHovered = mHoveredElement.TryResolve();

		// Handle enter/leave
		if (hitElement != currentHovered)
		{
			// Leave old element (only if still valid)
			if (currentHovered != null)
			{
				let leaveArgs = scope MouseEventArgs(x, y);
				InvokeMouseLeave(currentHovered, leaveArgs);
			}

			mHoveredElement = hitElement;

			// Enter new element
			if (hitElement != null)
			{
				let enterArgs = scope MouseEventArgs(x, y);
				InvokeMouseEnter(hitElement, enterArgs);
			}
		}

		// Send move event
		if (hitElement != null)
		{
			let args = scope MouseEventArgs(x, y);
			InvokeMouseMove(hitElement, args);
		}
	}

	/// Process a mouse button down event.
	public void ProcessMouseDown(float x, float y, MouseButton button, KeyModifiers modifiers = .None)
	{
		mLastMousePosition = .(x, y);

		// Calculate click count for double/multi-click detection
		let currentTime = mContext.TotalTime;
		let timeSinceLastClick = currentTime - mLastClickTime;
		let dx = x - mLastClickX;
		let dy = y - mLastClickY;
		let distance = Math.Sqrt(dx * dx + dy * dy);

		if (button == mLastClickButton &&
			timeSinceLastClick < DoubleClickTime &&
			distance < DoubleClickDistance)
		{
			mClickCount++;
		}
		else
		{
			mClickCount = 1;
		}

		// Update tracking state
		mLastClickTime = currentTime;
		mLastClickX = x;
		mLastClickY = y;
		mLastClickButton = button;

		// If there's a capture, route to captured element
		let captured = mContext.FocusManager?.CapturedElement;
		if (captured != null)
		{
			let args = scope MouseButtonEventArgs(x, y, button, modifiers);
			args.ClickCount = mClickCount;
			InvokeMouseDown(captured, args);
			return;
		}

		let hitElement = mContext.HitTestLogical(x, y);

		// Refresh hover state to match the hit test result.
		// ProcessMouseMove (which normally maintains hover) only runs when
		// the mouse physically moves. Without this, hover can become stale
		// between clicks, causing Button.OnMouseUp's IsHovered check to fail.
		UpdateHover(x, y, hitElement);

		if (hitElement != null)
		{
			let args = scope MouseButtonEventArgs(x, y, button, modifiers);
			args.ClickCount = mClickCount;
			InvokeMouseDown(hitElement, args);

			// If clicked element is not focusable and didn't handle the event
			// (e.g., Label focusing its target), clear focus
			if (!hitElement.IsFocusable && !args.Handled)
			{
				mContext.FocusManager?.ClearFocus();
			}
		}
		else
		{
			// Clicked on empty space - clear focus
			mContext.FocusManager?.ClearFocus();
		}
	}

	/// Process a mouse button up event.
	public void ProcessMouseUp(float x, float y, MouseButton button, KeyModifiers modifiers = .None)
	{
		mLastMousePosition = .(x, y);

		// End drag operation if left button released while dragging
		let dragManager = mContext.DragDropManager;
		if (button == .Left && dragManager != null && (dragManager.IsDragging || dragManager.IsDragPending))
		{
			dragManager.EndDrag(.(x, y));
			return;  // Drag handled the mouse up
		}

		// If there's a capture, route to captured element
		let captured = mContext.FocusManager?.CapturedElement;
		if (captured != null)
		{
			let args = scope MouseButtonEventArgs(x, y, button, modifiers);
			InvokeMouseUp(captured, args);
			return;
		}

		let hitElement = mContext.HitTestLogical(x, y);
		UpdateHover(x, y, hitElement);
		if (hitElement != null)
		{
			let args = scope MouseButtonEventArgs(x, y, button, modifiers);
			InvokeMouseUp(hitElement, args);
		}
	}

	/// Process a mouse wheel event.
	public void ProcessMouseWheel(float x, float y, float delta, KeyModifiers modifiers = .None)
	{
		mLastMousePosition = .(x, y);

		let hitElement = mContext.HitTestLogical(x, y);
		if (hitElement != null)
		{
			let args = scope MouseWheelEventArgs(x, y, delta, modifiers);
			InvokeMouseWheel(hitElement, args);
		}
	}

	/// Process a key down event.
	/// Returns true if the event was handled.
	public bool ProcessKeyDown(KeyCode key, KeyModifiers modifiers)
	{
		// Handle Tab navigation (but not Ctrl+Tab which controls use for tab cycling)
		if (key == .Tab && !modifiers.HasFlag(.Ctrl))
		{
			// If modal is active, use modal's focus trapping
			if (mContext.ModalManager?.HasModal == true)
			{
				if (mContext.ModalManager.HandleTabNavigation(modifiers.HasFlag(.Shift)))
					return true;
			}

			// Normal Tab navigation
			if (modifiers.HasFlag(.Shift))
				mContext.FocusManager?.FocusPrevious();
			else
				mContext.FocusManager?.FocusNext();
			return true;
		}

		// Handle Alt key and Alt+letter for accelerators (global - works without control focused)
		if (key == .LeftAlt || key == .RightAlt || modifiers.HasFlag(.Alt))
		{
			// Try to route to any IAcceleratorHandler in the visual tree
			if (TryRouteToAcceleratorHandlers(key, modifiers))
				return true;
		}

		// Route to focused element
		let focused = mContext.FocusManager?.FocusedElement;
		if (focused != null)
		{
			let args = scope KeyEventArgs(key, modifiers);
			InvokeKeyDown(focused, args);
			return args.Handled;
		}

		return false;
	}

	/// Attempts to route an accelerator key event to handlers in the visual tree.
	/// Returns true if a handler processed the event.
	private bool TryRouteToAcceleratorHandlers(KeyCode key, KeyModifiers modifiers)
	{
		if (mContext.RootElement == null)
			return false;

		// Find and try accelerator handlers in the visual tree
		return TryAcceleratorHandlers(mContext.RootElement, key, modifiers);
	}

	/// Recursively searches for IAcceleratorHandler implementers and tries to handle the key.
	private bool TryAcceleratorHandlers(UIElement element, KeyCode key, KeyModifiers modifiers)
	{
		// Check if this element implements IAcceleratorHandler
		if (let handler = element as IAcceleratorHandler)
		{
			if (handler.HandleAccelerator(key, modifiers))
				return true;
		}

		// Recurse to children
		let childCount = element.VisualChildCount;
		for (int i = 0; i < childCount; i++)
		{
			let child = element.GetVisualChild(i);
			if (child != null)
			{
				if (TryAcceleratorHandlers(child, key, modifiers))
					return true;
			}
		}

		return false;
	}

	/// Process a key up event.
	/// Returns true if the event was handled.
	public bool ProcessKeyUp(KeyCode key, KeyModifiers modifiers)
	{
		let focused = mContext.FocusManager?.FocusedElement;
		if (focused != null)
		{
			let args = scope KeyEventArgs(key, modifiers);
			InvokeKeyUp(focused, args);
			return args.Handled;
		}
		return false;
	}

	/// Process a text input event.
	public void ProcessTextInput(char32 character)
	{
		let focused = mContext.FocusManager?.FocusedElement;
		if (focused != null)
		{
			let args = scope TextInputEventArgs(character);
			InvokeTextInput(focused, args);
		}
	}

	/// Called when an element is about to be deleted.
	/// Clears hover state if necessary.
	public void OnElementDeleted(UIElementId elementId)
	{
		if (mHoveredElement.Id == elementId)
			mHoveredElement = .Invalid;
	}

	// === Hover state management ===

	/// Updates hover enter/leave state to match the given hit element.
	/// Called from ProcessMouseDown/Up to keep IsHovered current even
	/// when the mouse hasn't physically moved (no ProcessMouseMove call).
	private void UpdateHover(float x, float y, UIElement hitElement)
	{
		let currentHovered = mHoveredElement.TryResolve();
		if (hitElement != currentHovered)
		{
			if (currentHovered != null)
			{
				let leaveArgs = scope MouseEventArgs(x, y);
				InvokeMouseLeave(currentHovered, leaveArgs);
			}

			mHoveredElement = hitElement;

			if (hitElement != null)
			{
				let enterArgs = scope MouseEventArgs(x, y);
				InvokeMouseEnter(hitElement, enterArgs);
			}
		}
	}

	// === Internal event invocation ===
	// Control.OnMouseEnter/Leave already handles IsHovered/IsPressed state

	/// Converts screen coordinates in the event args to local coordinates relative to the element.
	private void ConvertToLocalCoordinates(UIElement element, MouseEventArgs args)
	{
		args.LocalX = args.ScreenX - element.ArrangedBounds.X;
		args.LocalY = args.ScreenY - element.ArrangedBounds.Y;
	}

	private void InvokeMouseEnter(UIElement element, MouseEventArgs args)
	{
		ConvertToLocalCoordinates(element, args);
		element.[Friend]OnMouseEnter(args);
	}

	private void InvokeMouseLeave(UIElement element, MouseEventArgs args)
	{
		ConvertToLocalCoordinates(element, args);
		element.[Friend]OnMouseLeave(args);
	}

	private void InvokeMouseMove(UIElement element, MouseEventArgs args)
	{
		ConvertToLocalCoordinates(element, args);
		element.[Friend]OnMouseMove(args);
	}

	private void InvokeMouseDown(UIElement element, MouseButtonEventArgs args)
	{
		ConvertToLocalCoordinates(element, args);
		element.[Friend]OnMouseDown(args);
	}

	private void InvokeMouseUp(UIElement element, MouseButtonEventArgs args)
	{
		ConvertToLocalCoordinates(element, args);
		element.[Friend]OnMouseUp(args);
	}

	private void InvokeMouseWheel(UIElement element, MouseWheelEventArgs args)
	{
		// Bubble the mouse wheel event up through ancestors until handled
		var current = element;
		while (current != null && !args.Handled)
		{
			ConvertToLocalCoordinates(current, args);
			current.[Friend]OnMouseWheel(args);
			current = current.Parent;
		}
	}

	private void InvokeKeyDown(UIElement element, KeyEventArgs args)
	{
		element.[Friend]OnKeyDown(args);
	}

	private void InvokeKeyUp(UIElement element, KeyEventArgs args)
	{
		element.[Friend]OnKeyUp(args);
	}

	private void InvokeTextInput(UIElement element, TextInputEventArgs args)
	{
		element.[Friend]OnTextInput(args);
	}
}
