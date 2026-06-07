namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

using internal Sedulous.GUI;

/// Base class for all GUI views. A view is a rectangular element that can
/// measure itself, be positioned by a parent, and draw itself.
///
/// All externally-settable state is exposed as Property<T> for uniform
/// change notification, invalidation, and markup binding.
public abstract class View
{
	// === Identity ===

	/// Unique identifier for safe tracking by managers.
	public readonly ViewId Id = ViewId.Create();

	/// Indirection wrapper for safe external references.
	/// handle.View is set to null immediately on deletion.
	/// Owned by ViewHandleRegistry, not by this view.
	public readonly ViewHandle Handle;

	/// User-assigned name (CSS id equivalent). Unique per UIContext.
	/// Setting this registers/unregisters in UIContext.NameRegistry.
	public Property<String> Name = new .(null) ~ delete _;

	/// User-assigned style classes (CSS class equivalent).
	public List<String> StyleClasses = new .() ~ DeleteContainerAndItems!(_);

	// === Layout state (not Property<T> — set by layout engine) ===

	/// Size computed by OnMeasure. Only set by subclasses in OnMeasure.
	public Vector2 MeasuredSize { get; protected set; }

	/// Final position and size in parent-relative coordinates. Set by Layout().
	public RectangleF Bounds { get; protected set; }

	/// Convenience accessors.
	public float Width => Bounds.Width;
	public float Height => Bounds.Height;

	/// Layout parameters (owned by the view, set by parent container).
	public LayoutParams LayoutParams ~ delete _;

	// === Visibility & interaction ===

	public Property<Visibility> Visibility = new .(.Visible) ~ delete _;
	public Property<bool> IsEnabled = new .(true) ~ delete _;
	public Property<bool> IsInteractionEnabled = new .(true) ~ delete _;
	public Property<bool> IsHitTestVisible = new .(true) ~ delete _;
	public Property<bool> IsFocusable = new .(false) ~ delete _;
	public Property<bool> IsTabStop = new .(false) ~ delete _;
	public Property<int32> TabIndex = new .(0) ~ delete _;
	public Property<bool> ClipsContent = new .(false) ~ delete _;

	/// Set by QueueDestroy to prevent double-delete.
	public bool IsPendingDeletion;

	// === Visual ===

	public Property<float> Opacity = new .(1.0f, .Visual) ~ delete _;
	public Property<ViewTransform> Transform = new .(.Identity) ~ delete _;

	// === Tooltip ===

	public Property<String> TooltipText = new .(null, .Visual) ~ delete _;
	public Property<TooltipPlacement> TooltipPlacement = new .(.Bottom, .Visual) ~ delete _;
	public Property<bool> IsTooltipInteractive = new .(false, .Visual) ~ delete _;

	// === Cursor ===

	public Property<CursorType> Cursor = new .(.Default, .Visual) ~ delete _;

	/// Effective cursor - walks the parent chain, returning the first non-Default value.
	public CursorType EffectiveCursor
	{
		get
		{
			var v = this;
			while (v != null)
			{
				if (v.Cursor.Value != .Default)
					return v.Cursor.Value;
				v = v.Parent;
			}
			return .Default;
		}
	}

	// === Focus (directional) ===

	public ViewId? NextFocusUp;
	public ViewId? NextFocusDown;
	public ViewId? NextFocusLeft;
	public ViewId? NextFocusRight;

	/// When true, arrow keys go to this view's OnKeyDown instead of
	/// moving directional focus. EditText and NumericField override to true.
	public bool WantsArrowKeys;

	// === Tree ===

	private View mParent;
	private UIContext mContext;

	public View Parent => mParent;
	public UIContext Context => mContext;
	public bool IsAttached => mContext != null;

	/// The RootView this view belongs to. Walks up the parent chain.
	public RootView Root
	{
		get
		{
			var view = this;
			while (view != null)
			{
				if (let root = view as RootView)
					return root;
				view = view.mParent;
			}
			return null;
		}
	}

	// === Constructor ===

	public this()
	{
		Handle = ViewHandleRegistry.Create(this);
		InitializePropertyOwners();
	}

	/// Registers all Property<T> fields with this view as owner.
	/// Called from constructor. Subclasses should override and call base
	/// to register their own properties.
	protected virtual void InitializePropertyOwners()
	{
		Name.SetOwner(this, .Visual);
		Visibility.SetOwner(this);
		IsEnabled.SetOwner(this);
		IsInteractionEnabled.SetOwner(this);
		IsHitTestVisible.SetOwner(this);
		IsFocusable.SetOwner(this);
		IsTabStop.SetOwner(this);
		TabIndex.SetOwner(this);
		ClipsContent.SetOwner(this);
		Opacity.SetOwner(this, .Visual);
		Transform.SetOwner(this, .Visual);
		TooltipText.SetOwner(this, .Visual);
		TooltipPlacement.SetOwner(this, .Visual);
		IsTooltipInteractive.SetOwner(this, .Visual);
		Cursor.SetOwner(this, .Visual);
	}

	// === Coordinate conversion ===

	/// Converts local coordinates to screen (root-relative) coordinates.
	public Vector2 LocalToScreen(Vector2 local)
	{
		var result = local;
		var view = this;
		while (view != null)
		{
			result.X += view.Bounds.X;
			result.Y += view.Bounds.Y;
			view = view.mParent;
		}
		return result;
	}

	/// Converts screen (root-relative) coordinates to local coordinates.
	public Vector2 ScreenToLocal(Vector2 screen)
	{
		var result = screen;
		var view = this;
		while (view != null)
		{
			result.X -= view.Bounds.X;
			result.Y -= view.Bounds.Y;
			view = view.mParent;
		}
		return result;
	}

	// === Draw invalidation ===

	private bool mNeedsRedraw = true;
	private bool mNeedsLayout = true;

	public void Invalidate()
	{
		mNeedsRedraw = true;
		if (mContext != null)
			mContext.MarkNeedsRedraw();
	}

	public void InvalidateLayout()
	{
		mNeedsLayout = true;
		mNeedsRedraw = true;
		if (mContext != null)
			mContext.MarkNeedsLayout();
	}

	public bool NeedsRedraw => mNeedsRedraw;
	public bool NeedsLayout => mNeedsLayout;

	public void ClearRedrawFlag() { mNeedsRedraw = false; }
	public void ClearLayoutFlag() { mNeedsLayout = false; }

	/// Called by Property<T> when a property value changes.
	protected internal virtual void OnPropertyChanged(Object property, InvalidationKind kind)
	{
		if (kind == .Layout)
			InvalidateLayout();
		else
			Invalidate();

		// Handle Name changes: update NameRegistry.
		if (property === Name && mContext != null)
		{
			mContext.UnregisterName(this);
			mContext.RegisterName(this);
		}
	}

	// === Layout ===

	/// Measures this view given parent constraints. Sets MeasuredSize.
	public void Measure(BoxConstraints constraints)
	{
		OnMeasure(constraints);
	}

	/// Positions this view at the given bounds (parent-relative).
	public void Layout(float x, float y, float width, float height)
	{
		Bounds = .(x, y, width, height);
		OnLayout(x, y, width, height);
		mNeedsLayout = false;
	}

	// === Virtual methods ===

	/// Compute desired size given constraints. Set MeasuredSize.
	protected virtual void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(0), constraints.ConstrainHeight(0));
	}

	/// Position children within the layout bounds.
	protected virtual void OnLayout(float left, float top, float width, float height) { }

	/// Draw this view.
	public virtual void OnDraw(/*UIDrawContext ctx*/) { }

	/// Returns the text baseline offset, or -1 if not applicable.
	public virtual float GetBaseline() => -1;

	/// Returns the current visual state for drawable/theme lookups.
	/// Controls override to add Pressed, Checked, etc.
	public virtual ControlState GetControlState()
	{
		var state = ControlState.Normal;
		if (!IsEffectivelyEnabled) state |= .Disabled;
		if (IsFocused) state |= .Focused;
		if (IsHovered) state |= .Hover;
		return state;
	}

	// === Hit testing ===

	/// Returns this view (or a descendant) at the given local-space point, or null.
	public virtual View HitTest(Vector2 localPoint)
	{
		if (!IsInteractionEnabled.Value || Visibility.Value != .Visible)
			return null;

		if (localPoint.X < 0 || localPoint.Y < 0 ||
			localPoint.X >= Width || localPoint.Y >= Height)
			return null;

		if (!IsHitTestVisible.Value)
			return null;

		return this;
	}

	// === Effective state ===

	/// True if this view and all ancestors are enabled.
	public bool IsEffectivelyEnabled
	{
		get
		{
			var v = this;
			while (v != null)
			{
				if (!v.IsEnabled.Value) return false;
				v = v.mParent;
			}
			return true;
		}
	}

	/// True if this view is currently hovered (checked via InputManager).
	public bool IsHovered
	{
		get
		{
			// TODO: wire to InputManager in Phase F.
			return false;
		}
	}

	/// True if this view currently has keyboard focus (checked via FocusManager).
	public bool IsFocused
	{
		get
		{
			// TODO: wire to FocusManager in Phase F.
			return false;
		}
	}

	/// True if this view or any descendant has keyboard focus.
	public bool IsFocusWithin
	{
		get
		{
			// TODO: wire to FocusManager in Phase F.
			return false;
		}
	}

	// === Input events (bubble phase) ===

	public virtual void OnMouseDown(MouseEventArgs e) { }
	public virtual void OnMouseUp(MouseEventArgs e) { }
	public virtual void OnMouseMove(MouseEventArgs e) { }
	public virtual void OnMouseWheel(MouseWheelEventArgs e) { }
	public virtual void OnMouseEnter() { }
	public virtual void OnMouseLeave() { }
	public virtual void OnKeyDown(KeyEventArgs e) { }
	public virtual void OnKeyUp(KeyEventArgs e) { }
	public virtual void OnTextInput(TextInputEventArgs e) { }
	public virtual void OnFocusGained() { }
	public virtual void OnFocusLost() { }

	// === Input events (capture phase) ===

	public virtual void OnMouseDownCapture(MouseEventArgs e) { }
	public virtual void OnMouseUpCapture(MouseEventArgs e) { }
	public virtual void OnMouseMoveCapture(MouseEventArgs e) { }
	public virtual void OnMouseWheelCapture(MouseWheelEventArgs e) { }
	public virtual void OnKeyDownCapture(KeyEventArgs e) { }
	public virtual void OnKeyUpCapture(KeyEventArgs e) { }
	public virtual void OnTextInputCapture(TextInputEventArgs e) { }

	// === Gamepad / directional activation ===

	/// Called when the view is activated (Gamepad A / Enter).
	/// ButtonBase overrides to fire OnClick.
	public virtual void OnActivate() { }

	/// Called when cancel is pressed (Gamepad B / Escape).
	/// Default: bubbles to parent.
	public virtual void OnCancel()
	{
		mParent?.OnCancel();
	}

	// === Style class helpers ===

	public void AddClass(StringView name)
	{
		for (let cls in StyleClasses)
			if (StringView(cls) == name)
				return;
		StyleClasses.Add(new String(name));
		Invalidate();
	}

	public void RemoveClass(StringView name)
	{
		for (int i = 0; i < StyleClasses.Count; i++)
		{
			if (StringView(StyleClasses[i]) == name)
			{
				delete StyleClasses[i];
				StyleClasses.RemoveAt(i);
				Invalidate();
				return;
			}
		}
	}

	public bool HasClass(StringView name)
	{
		for (let cls in StyleClasses)
			if (StringView(cls) == name)
				return true;
		return false;
	}

	public void ToggleClass(StringView name)
	{
		if (HasClass(name))
			RemoveClass(name);
		else
			AddClass(name);
	}

	// === Deferred mutation ===

	/// Queue removal from parent (deferred to frame end).
	public void QueueRemove()
	{
		if (mContext == null || IsPendingDeletion) return;
		IsPendingDeletion = true;
		mContext.QueueMutation(new () =>
		{
			if (mParent != null)
				if (let parentGroup = mParent as ViewGroup)
					parentGroup.RemoveView(this, false);
			IsPendingDeletion = false;
		});
	}

	/// Queue removal from parent AND deletion (deferred to frame end).
	public void QueueDestroy()
	{
		if (mContext == null || IsPendingDeletion) return;
		IsPendingDeletion = true;
		Handle.Invalidate(); // null out immediately
		mContext.QueueMutation(new () =>
		{
			if (mParent != null)
				if (let parentGroup = mParent as ViewGroup)
					parentGroup.RemoveView(this, true);
				else
					delete this;
			else
				delete this;
		});
	}

	// === Destructor ===

	public ~this()
	{
		// Null out the handle immediately. The handle object itself is
		// owned by ViewHandleRegistry and purged at frame end.
		Handle.Invalidate();
	}
}
