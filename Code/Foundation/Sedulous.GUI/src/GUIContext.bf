using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// Debug visualization settings for the GUI system.
public struct DebugSettings
{
	/// Draw bounds around each element (blue).
	public bool ShowLayoutBounds;
	/// Visualize margin areas (orange).
	public bool ShowMargins;
	/// Visualize padding areas (green).
	public bool ShowPadding;
	/// Highlight the focused element (yellow).
	public bool ShowFocused;
	/// Highlight hovered element (cyan).
	public bool ShowHovered;
	/// Show hit test regions (magenta).
	public bool ShowHitTestBounds;

	/// Default settings with all debug options disabled.
	public static DebugSettings Default => .();

	/// Settings with layout bounds enabled.
	public static DebugSettings WithBounds => .() { ShowLayoutBounds = true };

	/// Settings with all options enabled.
	public static DebugSettings All => .()
	{
		ShowLayoutBounds = true,
		ShowMargins = true,
		ShowPadding = true,
		ShowFocused = true,
		ShowHovered = true,
		ShowHitTestBounds = true
	};
}

/// Central context that owns and manages the UI system.
/// All UI elements belong to a context, and services are registered here.
public class GUIContext
{
	// Element registry - maps IDs to elements for safe handle resolution
	private Dictionary<UIElementId, UIElement> mElementRegistry = new .() ~ delete _;

	// Root element of the UI tree
	private UIElement mRootElement;

	// Mutation queue for deferred tree modifications
	private MutationQueue mMutationQueue = new .() ~ delete _;

	// Input and focus management
	private InputManager mInputManager ~ delete _;
	private FocusManager mFocusManager ~ delete _;

	// Layout state
	private bool mLayoutDirty = true;
	private float mViewportWidth;
	private float mViewportHeight;

	// Timing
	private double mTotalTime;
	private float mDeltaTime;

	// Debug settings
	private DebugSettings mDebugSettings;

	// Theming
	private ITheme mTheme ~ delete _;
	private EventAccessor<delegate void(ITheme)> mThemeChanged = new .() ~ delete _;

	// Service registry (services are not owned - callers retain ownership)
	private Dictionary<Type, Object> mServices = new .() ~ delete _;

	// Clipboard (not owned - caller retains ownership)
	private IClipboard mClipboard;

	// UI scaling
	private float mScaleFactor = 1.0f;

	// Popup layer (for dropdowns, menus, tooltips)
	private PopupLayer mPopupLayer = new .() ~ delete _;

	// Tooltip service
	private TooltipService mTooltipService ~ delete _;

	// Modal manager
	private ModalManager mModalManager ~ delete _;

	// Drag drop manager
	private DragDropManager mDragDropManager ~ delete _;

	// Animation manager
	private AnimationManager mAnimationManager ~ delete _;

	public ~this()
	{
		// Process any pending mutations (e.g., queued deletes from ClearItems)
		// so they don't leak. This must happen before field destructors delete the queue.
		mMutationQueue.Process(this);

		// Close all popups before field destructors run.
		// PopupLayer extends Container whose mChildren uses DeleteContainerAndItems.
		// Popup elements are owned by their creators in the UI tree, not by PopupLayer.
		// CloseAllPopups() removes them from the children list (without deleting them)
		// so Container's destructor won't double-delete them.
		mPopupLayer.CloseAllPopups();
	}

	/// Creates a new GUIContext.
	public this()
	{
		mInputManager = new InputManager(this);
		mFocusManager = new FocusManager(this);
		mTheme = new DarkTheme();
		mPopupLayer.OnAttachedToContext(this);
		mTooltipService = new TooltipService(this);
		mModalManager = new ModalManager(this);
		mDragDropManager = new DragDropManager(this);
		mAnimationManager = new AnimationManager(this);

		// Register services for access via GetService<T>()
		RegisterService(mModalManager);
		RegisterService(mDragDropManager);
		RegisterService(mAnimationManager);
	}

	/// The current theme.
	public ITheme Theme
	{
		get => mTheme;
		set
		{
			if (mTheme == value)
				return;

			if (mTheme != null)
				delete mTheme;

			mTheme = value;
			mThemeChanged.[Friend]Invoke(mTheme);
			InvalidateLayout();
		}
	}

	/// Event fired when the theme changes.
	/// Handlers receive the new theme as a parameter.
	public EventAccessor<delegate void(ITheme)> ThemeChanged => mThemeChanged;

	/// The root element of the UI tree.
	public UIElement RootElement
	{
		get => mRootElement;
		set
		{
			if (mRootElement == value)
				return;

			// Detach old root
			if (mRootElement != null)
			{
				mRootElement.OnDetachedFromContext();
			}

			mRootElement = value;

			// Attach new root
			if (mRootElement != null)
			{
				mRootElement.OnAttachedToContext(this);
			}

			InvalidateLayout();
		}
	}

	/// The mutation queue for deferred tree modifications.
	public MutationQueue MutationQueue => mMutationQueue;

	/// The input manager for this context.
	public InputManager InputManager => mInputManager;

	/// The focus manager for this context.
	public FocusManager FocusManager => mFocusManager;

	/// The cursor that should be displayed based on the hovered element.
	/// The application is responsible for actually setting the system cursor.
	public CursorType CurrentCursor => mInputManager?.HoveredElement?.EffectiveCursor ?? .Default;

	/// The current viewport width.
	public float ViewportWidth => mViewportWidth;

	/// The current viewport height.
	public float ViewportHeight => mViewportHeight;

	/// Total elapsed time in seconds.
	public double TotalTime => mTotalTime;

	/// Time since last frame in seconds.
	public float DeltaTime => mDeltaTime;

	/// Debug visualization settings.
	public ref DebugSettings DebugSettings => ref mDebugSettings;

	/// The popup layer for showing dropdowns, menus, and tooltips.
	public PopupLayer PopupLayer => mPopupLayer;

	/// The tooltip service for managing tooltip display.
	public TooltipService TooltipService => mTooltipService;

	/// The modal manager for managing modal dialogs.
	public ModalManager ModalManager => mModalManager;

	/// The drag drop manager for this context.
	public DragDropManager DragDropManager => mDragDropManager;

	/// The animation manager for this context.
	public AnimationManager AnimationManager => mAnimationManager;

	/// UI scale factor (default 1.0). Affects all layout and rendering.
	/// Valid range: 0.5 to 3.0
	public float ScaleFactor
	{
		get => mScaleFactor;
		set
		{
			let clamped = Math.Clamp(value, 0.5f, 3.0f);
			if (mScaleFactor != clamped)
			{
				mScaleFactor = clamped;
				InvalidateLayout();
			}
		}
	}

	// === Service Registry ===

	/// Registers a service instance.
	/// The service will be owned by the context and deleted when the context is destroyed.
	public void RegisterService<T>(T service) where T : class
	{
		mServices[typeof(T)] = service;
	}

	/// Gets a registered service.
	/// Returns Ok with the service if found, Err otherwise.
	public Result<T> GetService<T>() where T : class
	{
		if (mServices.TryGetValue(typeof(T), let service))
			return .Ok((T)service);
		return .Err;
	}

	/// Checks if a service is registered.
	public bool HasService<T>() where T : class
	{
		return mServices.ContainsKey(typeof(T));
	}

	// === Clipboard ===

	/// The registered clipboard service.
	/// Returns null if no clipboard has been registered.
	public IClipboard Clipboard => mClipboard;

	/// Registers a clipboard implementation.
	/// The clipboard is not owned by the context - the caller retains ownership.
	public void RegisterClipboard(IClipboard clipboard)
	{
		mClipboard = clipboard;
	}

	// === Element Registry ===

	/// Registers an element in the registry.
	/// Called automatically when elements are attached to the context.
	public void RegisterElement(UIElement element)
	{
		if (element == null)
			return;
		mElementRegistry[element.Id] = element;
	}

	/// Unregisters an element from the registry.
	/// Called automatically when elements are detached or deleted.
	public void UnregisterElement(UIElementId elementId)
	{
		mElementRegistry.Remove(elementId);
	}

	/// Unregisters an element from the registry.
	/// Children are handled automatically by their destructors when the parent is deleted.
	public void UnregisterElementTree(UIElement element)
	{
		if (element == null)
			return;

		mElementRegistry.Remove(element.Id);
	}

	/// Gets an element by its ID.
	/// Returns null if the element doesn't exist.
	public UIElement GetElementById(UIElementId id)
	{
		if (mElementRegistry.TryGetValue(id, let element))
			return element;
		return null;
	}

	/// Gets an element by ID and casts to the specified type.
	/// Returns null if not found or wrong type.
	public T GetElementById<T>(UIElementId id) where T : UIElement
	{
		return GetElementById(id) as T;
	}

	// === Viewport ===

	/// Sets the viewport size.
	public void SetViewportSize(float width, float height)
	{
		if (mViewportWidth != width || mViewportHeight != height)
		{
			mViewportWidth = width;
			mViewportHeight = height;
			InvalidateLayout();
		}
	}

	// === Layout ===

	/// Marks the layout as needing recalculation.
	public void InvalidateLayout()
	{
		mLayoutDirty = true;
	}

	/// Updates the layout if needed.
	private void UpdateLayout()
	{
		if (!mLayoutDirty || mRootElement == null)
			return;

		// Scale the viewport for measurement (layout happens in unscaled coordinates)
		let scaledWidth = mViewportWidth / mScaleFactor;
		let scaledHeight = mViewportHeight / mScaleFactor;

		// Measure pass
		let constraints = SizeConstraints.FromMaximum(scaledWidth, scaledHeight);
		mRootElement.Measure(constraints);

		// Arrange pass
		let viewport = RectangleF(0, 0, scaledWidth, scaledHeight);
		mRootElement.Arrange(viewport);

		// Layout popup layer (uses full viewport)
		if (mPopupLayer.HasPopups)
		{
			mPopupLayer.Measure(constraints);
			mPopupLayer.Arrange(viewport);
		}

		mLayoutDirty = false;
	}

	// === Update ===

	/// Updates the UI system. Call once per frame.
	/// @param deltaTime Time since last frame in seconds.
	/// @param totalTime Total elapsed time in seconds.
	public void Update(float deltaTime, double totalTime)
	{
		mDeltaTime = deltaTime;
		mTotalTime = totalTime;

		// Process any pending mutations first (add/remove children)
		mMutationQueue.Process(this);

		// Update layout after mutations are applied
		UpdateLayout();

		// Update tooltip service (show/hide based on hover timing)
		mTooltipService?.Update(totalTime);

		// Update active popups (context menu submenu timers, etc.)
		mPopupLayer.Update(totalTime);

		// Update animations
		mAnimationManager?.Update(deltaTime);
	}

	// === Rendering ===

	/// Renders the UI tree.
	public void Render(DrawContext ctx)
	{
		if (mRootElement == null)
			return;

		// Apply scale transform if not 1.0
		if (mScaleFactor != 1.0f)
		{
			ctx.PushState();
			ctx.Scale(mScaleFactor, mScaleFactor);
		}

		mRootElement.Render(ctx);

		// Render modal backdrop if needed
		mModalManager?.RenderBackdrop(ctx);

		// Render popups on top
		if (mPopupLayer.HasPopups)
			mPopupLayer.Render(ctx);

		// Render drag adorner on top of everything
		mDragDropManager?.Render(ctx);

		// Debug visualization
		if (mDebugSettings.ShowLayoutBounds || mDebugSettings.ShowMargins ||
			mDebugSettings.ShowPadding || mDebugSettings.ShowFocused ||
			mDebugSettings.ShowHovered || mDebugSettings.ShowHitTestBounds)
		{
			RenderDebugOverlay(ctx);
		}

		if (mScaleFactor != 1.0f)
			ctx.PopState();
	}

	/// Renders debug visualization overlay.
	private void RenderDebugOverlay(DrawContext ctx)
	{
		if (mRootElement == null)
			return;

		RenderElementDebug(ctx, mRootElement);
	}

	/// Recursively renders debug visualization for an element and its children.
	private void RenderElementDebug(DrawContext ctx, UIElement element)
	{
		if (element.Visibility == .Collapsed)
			return;

		let bounds = element.ArrangedBounds;

		// Layout bounds (blue)
		if (mDebugSettings.ShowLayoutBounds)
		{
			ctx.DrawRect(bounds, Color(0, 120, 215, 255), 2.0f);
		}

		// Margins (orange)
		if (mDebugSettings.ShowMargins && !element.Margin.IsZero)
		{
			let margin = element.Margin;
			// Top margin
			if (margin.Top > 0)
				ctx.FillRect(.(bounds.X, bounds.Y - margin.Top, bounds.Width, margin.Top), Color(255, 165, 0, 80));
			// Bottom margin
			if (margin.Bottom > 0)
				ctx.FillRect(.(bounds.X, bounds.Y + bounds.Height, bounds.Width, margin.Bottom), Color(255, 165, 0, 80));
			// Left margin
			if (margin.Left > 0)
				ctx.FillRect(.(bounds.X - margin.Left, bounds.Y, margin.Left, bounds.Height), Color(255, 165, 0, 80));
			// Right margin
			if (margin.Right > 0)
				ctx.FillRect(.(bounds.X + bounds.Width, bounds.Y, margin.Right, bounds.Height), Color(255, 165, 0, 80));
		}

		// Padding (green)
		if (mDebugSettings.ShowPadding && !element.Padding.IsZero)
		{
			let padding = element.Padding;
			let inner = RectangleF(
				bounds.X + padding.Left,
				bounds.Y + padding.Top,
				bounds.Width - padding.TotalHorizontal,
				bounds.Height - padding.TotalVertical
			);
			// Top padding
			if (padding.Top > 0)
				ctx.FillRect(.(bounds.X, bounds.Y, bounds.Width, padding.Top), Color(0, 200, 0, 80));
			// Bottom padding
			if (padding.Bottom > 0)
				ctx.FillRect(.(bounds.X, inner.Y + inner.Height, bounds.Width, padding.Bottom), Color(0, 200, 0, 80));
			// Left padding
			if (padding.Left > 0)
				ctx.FillRect(.(bounds.X, inner.Y, padding.Left, inner.Height), Color(0, 200, 0, 80));
			// Right padding
			if (padding.Right > 0)
				ctx.FillRect(.(inner.X + inner.Width, inner.Y, padding.Right, inner.Height), Color(0, 200, 0, 80));
		}

		// Focused highlight (yellow)
		if (mDebugSettings.ShowFocused && element == mFocusManager?.FocusedElement)
		{
			ctx.DrawRect(bounds, Color(255, 255, 0, 255), 2.0f);
		}

		// Hovered highlight (cyan)
		if (mDebugSettings.ShowHovered && element == mInputManager?.HoveredElement)
		{
			ctx.DrawRect(bounds, Color(0, 255, 255, 200), 2.0f);
		}

		// Hit test bounds (magenta)
		if (mDebugSettings.ShowHitTestBounds)
		{
			ctx.DrawRect(bounds, Color(255, 0, 255, 150), 1.0f);
		}

		// Recurse to children
		let childCount = element.VisualChildCount;
		for (int i = 0; i < childCount; i++)
		{
			let child = element.GetVisualChild(i);
			if (child != null)
				RenderElementDebug(ctx, child);
		}
	}

	// === Hit Testing ===

	/// Performs hit testing at the given screen coordinates.
	/// Coordinates are automatically inverse-scaled by the ScaleFactor.
	/// Returns the topmost element at that position, or null.
	public UIElement HitTest(float x, float y)
	{
		// Inverse-scale input coordinates to match layout coordinates
		let scaledX = x / mScaleFactor;
		let scaledY = y / mScaleFactor;
		let point = Vector2(scaledX, scaledY);

		// Check popup layer first (popups are always on top)
		if (mPopupLayer.HasPopups)
		{
			let popupHit = mPopupLayer.HitTest(point);
			if (popupHit != null)
				return popupHit;
		}

		if (mRootElement == null)
			return null;

		return mRootElement.HitTest(point);
	}

	/// Performs hit testing at the given logical coordinates.
	/// Use this when coordinates are already in logical space (already scaled).
	/// Returns the topmost element at that position, or null.
	public UIElement HitTestLogical(float x, float y)
	{
		let point = Vector2(x, y);

		// Check popup layer first (popups are always on top)
		if (mPopupLayer.HasPopups)
		{
			let popupHit = mPopupLayer.HitTest(point);
			if (popupHit != null)
				return popupHit;
		}

		if (mRootElement == null)
			return null;

		return mRootElement.HitTest(point);
	}

	// === Deletion ===

	/// Queues an element for deletion.
	/// The element will be removed from its parent and deleted at the end of the frame.
	/// Safe to call from event handlers.
	public void QueueDelete(UIElement element)
	{
		mMutationQueue.QueueDelete(element);
	}

	/// Queues an action to be executed at the end of the frame.
	/// Useful for deferring operations that would cause use-after-free if executed immediately.
	public void QueueAction(delegate void() action)
	{
		mMutationQueue.QueueAction(action);
	}

	/// Called when an element is about to be deleted.
	/// Notifies input and focus managers to clear references.
	public void OnElementDeleted(UIElementId elementId)
	{
		mInputManager?.OnElementDeleted(elementId);
		mFocusManager?.OnElementDeleted(elementId);
		mDragDropManager?.OnElementDeleted(elementId);
	}

	// === Input Processing ===

	/// Process a mouse move event.
	/// Coordinates are automatically inverse-scaled by the ScaleFactor.
	public void ProcessMouseMove(float x, float y)
	{
		mInputManager?.ProcessMouseMove(x / mScaleFactor, y / mScaleFactor);
	}

	/// Process a mouse button down event.
	/// Coordinates are automatically inverse-scaled by the ScaleFactor.
	public void ProcessMouseDown(float x, float y, MouseButton button, KeyModifiers modifiers = .None)
	{
		let scaledX = x / mScaleFactor;
		let scaledY = y / mScaleFactor;

		// Handle click-outside-to-close for popups (both LMB and RMB)
		if (mPopupLayer.HasPopups)
		{
			let point = Vector2(scaledX, scaledY);
			if (mPopupLayer.HandleClickOutside(point))
			{
				// A popup was closed
				if (button == .Left)
				{
					// For LMB, don't process further (prevents click from going to underlying elements)
					return;
				}
				// For RMB, continue processing so a new context menu can open
			}
		}

		mInputManager?.ProcessMouseDown(scaledX, scaledY, button, modifiers);
	}

	/// Process a mouse button up event.
	/// Coordinates are automatically inverse-scaled by the ScaleFactor.
	public void ProcessMouseUp(float x, float y, MouseButton button, KeyModifiers modifiers = .None)
	{
		mInputManager?.ProcessMouseUp(x / mScaleFactor, y / mScaleFactor, button, modifiers);
	}

	/// Process a mouse wheel event.
	/// Coordinates are automatically inverse-scaled by the ScaleFactor.
	public void ProcessMouseWheel(float x, float y, float delta, KeyModifiers modifiers = .None)
	{
		mInputManager?.ProcessMouseWheel(x / mScaleFactor, y / mScaleFactor, delta, modifiers);
	}

	/// Process a key down event.
	/// Returns true if the event was handled by the GUI.
	public bool ProcessKeyDown(KeyCode key, KeyModifiers modifiers = .None)
	{
		return mInputManager?.ProcessKeyDown(key, modifiers) ?? false;
	}

	/// Process a key up event.
	/// Returns true if the event was handled by the GUI.
	public bool ProcessKeyUp(KeyCode key, KeyModifiers modifiers = .None)
	{
		return mInputManager?.ProcessKeyUp(key, modifiers) ?? false;
	}

	/// Process a text input event.
	public void ProcessTextInput(char32 character)
	{
		mInputManager?.ProcessTextInput(character);
	}
}
