namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Base class for all UI2 views. A view is a rectangular element that can
/// measure itself, be positioned by a parent, and draw itself.
public abstract class View : IPropertyOwner
{
	// === Identity ===

	/// Unique identifier for safe tracking by managers (Input, Focus, DragDrop).
	public readonly ViewId Id = ViewId.Create();

	/// Optional debug/lookup name.
	public String Name;

	/// Style classes for stylesheet matching (CSS class equivalent).
	/// Multiple classes allowed. Use AddClass/RemoveClass/HasClass helpers.
	public List<String> StyleClasses = new .() ~ DeleteContainerAndItems!(_);

	// === Layout state ===

	/// Size computed by OnMeasure. Set during the measure pass.
	public Vector2 MeasuredSize;

	/// Final position and size in parent-relative coordinates. Set during layout pass.
	public RectangleF Bounds;

	/// Convenience accessors for Bounds dimensions.
	public float Width => Bounds.Width;
	public float Height => Bounds.Height;

	/// Layout parameters (owned by the view, set by parent container).
	public LayoutParams LayoutParams;

	// === Visibility & interaction ===

	/// Controls whether and how this view participates in layout and drawing.
	public Visibility Visibility = .Visible;

	/// Whether this view responds to user interaction (e.g. button clicks, text input).
	/// A disabled view is still visible and hit-testable; controls should use this to
	/// render a disabled visual state.
	public bool IsEnabled = true;

	/// Whether this view and its entire subtree can receive input.
	/// When false, HitTest returns null for this view and all descendants.
	/// Use to disable interaction on a whole panel (e.g. loading overlay, disabled pane).
	public bool IsInteractionEnabled = true;

	/// Whether this view is a valid hit-test target. When false, the view itself
	/// won't be returned from HitTest, but its children are still tested.
	/// Use for layout containers that should pass through clicks to children.
	public bool IsHitTestVisible = true;

	/// Whether this view can receive keyboard focus.
	public bool IsFocusable = false;

	/// Whether this view participates in tab navigation.
	public bool IsTabStop = false;

	/// Tab order within the parent. Lower values are visited first.
	public int32 TabIndex = 0;

	/// Whether child content is clipped to this view's bounds during drawing.
	public bool ClipsContent = false;

	// === Directional focus ===

	/// Explicit override for directional focus navigation. When set,
	/// FocusManager.MoveFocus uses this instead of the spatial picker.
	public ViewId? NextFocusUp;
	public ViewId? NextFocusDown;
	public ViewId? NextFocusLeft;
	public ViewId? NextFocusRight;

	/// When true, arrow keys go to this view's OnKeyDown instead of
	/// moving directional focus. EditText and NumericField override to true.
	public bool WantsArrowKeys;

	/// Set by MutationQueue.QueueDelete to prevent double-delete.
	public bool IsPendingDeletion;

	// === Visual ===

	/// Opacity (0 = fully transparent, 1 = fully opaque).
	/// Composes multiplicatively with parent opacity during drawing.
	public float Opacity = 1.0f;

	/// Post-layout transform (translate, rotate, scale). Does not affect layout,
	/// but is accounted for during drawing and hit testing.
	public ViewTransform Transform = .Identity;

	// === Tooltip ===

	/// Tooltip text shown after hover delay. Null/empty = no tooltip.
	public String TooltipText;

	/// Where the tooltip appears relative to this view.
	public TooltipPlacement TooltipPlacement = .Bottom;

	/// Whether the tooltip stays visible and interactive when hovered.
	public bool IsTooltipInteractive;

	// === Cursor ===

	/// Cursor type to display when this view is hovered.
	/// Set to .Default to inherit from the parent chain.
	public CursorType Cursor = .Default;

	/// Effective cursor - walks the parent chain, returning the first non-Default value.
	public CursorType EffectiveCursor
	{
		get
		{
			var v = this;
			while (v != null)
			{
				if (v.Cursor != .Default)
					return v.Cursor;
				v = v.Parent;
			}
			return .Default;
		}
	}

	// === Tree ===

	/// Parent view (null for root). Set by ViewGroup on AddView/RemoveView.
	public View Parent { get; set; }

	/// UI context this view is attached to. Propagated from root on attach.
	public UIContext Context { get; set; }

	/// Whether this view is part of a context-connected tree.
	public bool IsAttached => Context != null;

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
				view = view.Parent;
			}
			return null;
		}
	}

	// === User data ===

	private Dictionary<String, Object> mUserData;

	/// Stores arbitrary data by key. Lazily allocates storage.
	public void SetUserData(StringView key, Object data)
	{
		if (mUserData == null)
			mUserData = new .();
		mUserData[new String(key)] = data;
	}

	/// Retrieves stored data by key. Returns null if not set.
	public Object GetUserData(StringView key)
	{
		if (mUserData == null)
			return null;
		if (mUserData.TryGetValue(scope String(key), let val))
			return val;
		return null;
	}

	/// Typed retrieval.
	public T GetUserData<T>(StringView key) where T : class
	{
		return GetUserData(key) as T;
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
			view = view.Parent;
		}
		return result;
	}

	/// Converts screen (root-relative) coordinates to local coordinates.
	/// Note: This uses layout Bounds only and does not account for ViewTransform
	/// (translation, rotation, scale). This is correct for normal use because
	/// mouse events go through HitTest first, which applies inverse transforms
	/// to identify the hit target. For views with non-identity transforms, the
	/// coordinates will be relative to the untransformed layout position - this
	/// matches the local coordinate space that OnDraw receives.
	public Vector2 ScreenToLocal(Vector2 screen)
	{
		var result = screen;
		var view = this;
		while (view != null)
		{
			result.X -= view.Bounds.X;
			result.Y -= view.Bounds.Y;
			view = view.Parent;
		}
		return result;
	}

	// === Draw invalidation ===

	private bool mNeedsRedraw = true;

	/// Marks this view as needing a redraw.
	public void Invalidate()
	{
		mNeedsRedraw = true;
		if (Context != null)
			Context.MarkNeedsRedraw();
	}

	/// IPropertyOwner: called when a Property<T> value changes.
	public virtual void OnPropertyChanged(InvalidationKind kind)
	{
		if (kind == .Layout)
			Invalidate(); // TODO: separate layout invalidation when supported
		else
			Invalidate();
	}

	/// Whether this view needs to be redrawn.
	public bool NeedsRedraw => mNeedsRedraw;

	/// Clears the redraw flag (called after drawing).
	public void ClearRedrawFlag() { mNeedsRedraw = false; }

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
	}

	// === Virtual methods - override in subclasses ===

	/// Compute desired size given constraints. Set MeasuredSize.
	protected virtual void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(0), constraints.ConstrainHeight(0));
	}

	/// Position children within the layout bounds.
	protected virtual void OnLayout(float left, float top, float width, float height) { }

	/// Draw this view. Called during the draw pass.
	public virtual void OnDraw(UIDrawContext ctx) { }

	/// Returns the text baseline offset, or -1 if not applicable.
	public virtual float GetBaseline() => -1;

	/// Returns the current visual state of this view for drawable/theme lookups.
	/// Override in controls with additional states (e.g., Button adds Pressed).
	public virtual ControlState GetControlState()
	{
		var state = ControlState.Normal;
		if (!IsEffectivelyEnabled) state |= .Disabled;
		if (IsFocused) state |= .Focused;
		if (IsHovered) state |= .Hover;
		return state;
	}

	// === Inline styles ===
	//
	// Per-property overrides set directly on this view, the CSS
	// `style="..."` analogue. An inline value wins over every
	// rule-based match (inline is specificity infinity).
	//
	// Storage is lazily allocated: a view with no inline overrides pays
	// only one pointer of overhead. The pseudo-element map is separate
	// and likewise lazy.
	//
	// Resolution wiring lands in sub-phase B; this phase just exposes
	// the data + API so callers and tests can be written against it.

	private Dictionary<StyleProperty, StyleValue> mInlineStyles;
	private List<(String Part, StyleProperty Prop, StyleValue Value)> mInlinePartStyles;
	private List<Drawable> mOwnedInlineDrawables;

	/// True if any inline overrides are set on this view.
	public bool HasAnyInlineStyles =>
		(mInlineStyles != null && mInlineStyles.Count > 0) ||
		(mInlinePartStyles != null && mInlinePartStyles.Count > 0);

	/// Sets an inline override for `prop`. Overwrites any existing
	/// inline value for the same property.
	public void SetInlineStyle(StyleProperty prop, StyleValue value)
	{
		if (mInlineStyles == null)
			mInlineStyles = new .();
		mInlineStyles[prop] = value;
		Invalidate();
	}

	/// Returns the inline override for `prop`, or `.None` if not set.
	public StyleValue GetInlineStyle(StyleProperty prop)
	{
		if (mInlineStyles == null) return .None;
		if (mInlineStyles.TryGetValue(prop, let value)) return value;
		return .None;
	}

	/// True if an inline override exists for `prop`.
	public bool HasInlineStyle(StyleProperty prop)
	{
		if (mInlineStyles == null) return false;
		return mInlineStyles.ContainsKey(prop);
	}

	/// Removes a single inline override. No-op if not set.
	public void ClearInlineStyle(StyleProperty prop)
	{
		if (mInlineStyles == null) return;
		if (mInlineStyles.Remove(prop))
			Invalidate();
	}

	/// Removes every inline override on this view (element + pseudo-element).
	public void ClearInlineStyles()
	{
		bool changed = false;
		if (mInlineStyles != null && mInlineStyles.Count > 0)
		{
			mInlineStyles.Clear();
			changed = true;
		}
		if (mInlinePartStyles != null && mInlinePartStyles.Count > 0)
		{
			for (let entry in mInlinePartStyles)
				delete entry.Part;
			mInlinePartStyles.Clear();
			changed = true;
		}
		if (changed) Invalidate();
	}

	/// Sets an inline override for a pseudo-element (e.g., "thumb") on
	/// this view. Composite controls use this to override sub-part
	/// styles without going through a StyleSheet rule.
	public void SetInlinePartStyle(StringView part, StyleProperty prop, StyleValue value)
	{
		if (mInlinePartStyles == null)
			mInlinePartStyles = new .();

		// Update in place if the (part, prop) pair already has an entry.
		for (int i = 0; i < mInlinePartStyles.Count; i++)
		{
			let entry = mInlinePartStyles[i];
			if (entry.Prop == prop && StringView(entry.Part) == part)
			{
				mInlinePartStyles[i] = (entry.Part, prop, value);
				Invalidate();
				return;
			}
		}

		mInlinePartStyles.Add((new String(part), prop, value));
		Invalidate();
	}

	/// Returns the inline pseudo-element override, or `.None`.
	public StyleValue GetInlinePartStyle(StringView part, StyleProperty prop)
	{
		if (mInlinePartStyles == null) return .None;
		for (let entry in mInlinePartStyles)
		{
			if (entry.Prop == prop && StringView(entry.Part) == part)
				return entry.Value;
		}
		return .None;
	}

	/// True if an inline pseudo-element override exists.
	public bool HasInlinePartStyle(StringView part, StyleProperty prop)
	{
		if (mInlinePartStyles == null) return false;
		for (let entry in mInlinePartStyles)
		{
			if (entry.Prop == prop && StringView(entry.Part) == part)
				return true;
		}
		return false;
	}

	/// Removes one inline pseudo-element override. No-op if not set.
	public void ClearInlinePartStyle(StringView part, StyleProperty prop)
	{
		if (mInlinePartStyles == null) return;
		for (int i = 0; i < mInlinePartStyles.Count; i++)
		{
			let entry = mInlinePartStyles[i];
			if (entry.Prop == prop && StringView(entry.Part) == part)
			{
				delete entry.Part;
				mInlinePartStyles.RemoveAt(i);
				Invalidate();
				return;
			}
		}
	}

	/// Take ownership of a drawable assigned as an inline style value.
	/// The view deletes the drawable on destruction. Mirrors
	/// `StyleSheet.OwnDrawable`. Use when the drawable was constructed
	/// inline by the caller (e.g., `new ColorDrawable(.Red)`); skip when
	/// the drawable is already owned elsewhere (e.g., by a StyleSheet
	/// via `OwnColor` / `OwnDrawable`).
	public void OwnInlineDrawable(Drawable drawable)
	{
		if (drawable == null) return;
		if (mOwnedInlineDrawables == null)
			mOwnedInlineDrawables = new .();
		mOwnedInlineDrawables.Add(drawable);
	}

	// === Style resolution helpers ===

	/// Resolve a style property from the active StyleSheet.
	/// Returns .None if no StyleSheet is set or no match found.
	public StyleValue ResolveStyle(StyleProperty prop)
	{
		let sheet = Context?.StyleSheet;
		if (sheet == null) return .None;
		return sheet.Resolve(this, prop);
	}

	/// Resolve a Color style property with fallback default.
	public Color ResolveStyleColor(StyleProperty prop, Color defaultVal = .White)
	{
		let sheet = Context?.StyleSheet;
		if (sheet == null) return defaultVal;
		return sheet.ResolveColor(this, prop, defaultVal);
	}

	/// Resolve a float style property with fallback default.
	public float ResolveStyleFloat(StyleProperty prop, float defaultVal = 0)
	{
		let sheet = Context?.StyleSheet;
		if (sheet == null) return defaultVal;
		return sheet.ResolveFloat(this, prop, defaultVal);
	}

	/// Resolve a Thickness style property with fallback default.
	public Thickness ResolveStyleThickness(StyleProperty prop, Thickness defaultVal = .())
	{
		let sheet = Context?.StyleSheet;
		if (sheet == null) return defaultVal;
		return sheet.ResolveThickness(this, prop, defaultVal);
	}

	/// Resolve a Drawable style property. Returns null if not found.
	public Drawable ResolveStyleDrawable(StyleProperty prop)
	{
		let sheet = Context?.StyleSheet;
		if (sheet == null) return null;
		return sheet.ResolveDrawable(this, prop);
	}

	// === Pseudo-element (part) style resolution ===

	/// Resolve a style property for a named sub-part of this control.
	/// partState is the part's interaction state (e.g., thumb hovered).
	public StyleValue ResolvePartStyle(StringView part, StyleProperty prop, ControlState partState)
	{
		let sheet = Context?.StyleSheet;
		if (sheet == null) return .None;
		return sheet.ResolvePart(this, part, prop, partState);
	}

	public Drawable ResolvePartDrawable(StringView part, StyleProperty prop, ControlState partState)
	{
		let sheet = Context?.StyleSheet;
		if (sheet == null) return null;
		return sheet.ResolvePartDrawable(this, part, prop, partState);
	}

	public Color ResolvePartColor(StringView part, StyleProperty prop, ControlState partState, Color defaultVal = .White)
	{
		let sheet = Context?.StyleSheet;
		if (sheet == null) return defaultVal;
		return sheet.ResolvePartColor(this, part, prop, partState, defaultVal);
	}

	public float ResolvePartFloat(StringView part, StyleProperty prop, ControlState partState, float defaultVal = 0)
	{
		let sheet = Context?.StyleSheet;
		if (sheet == null) return defaultVal;
		return sheet.ResolvePartFloat(this, part, prop, partState, defaultVal);
	}

	// === Hit testing ===

	/// Returns this view (or a descendant) at the given local-space point, or null.
	/// Override in ViewGroup to test children in reverse draw order.
	public virtual View HitTest(Vector2 localPoint)
	{
		if (!IsInteractionEnabled || Visibility != .Visible)
			return null;

		if (localPoint.X < 0 || localPoint.Y < 0 ||
			localPoint.X >= Width || localPoint.Y >= Height)
			return null;

		if (!IsHitTestVisible)
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
				if (!v.IsEnabled) return false;
				v = v.Parent;
			}
			return true;
		}
	}

	/// True if this view is currently hovered.
	public bool IsHovered => Context?.InputManager?.HoveredId == Id;

	/// True if this view currently has keyboard focus.
	public bool IsFocused => Context?.FocusManager?.FocusedId == Id;

	/// True if this view or any descendant has keyboard focus.
	public bool IsFocusWithin
	{
		get
		{
			if (Context?.FocusManager == null) return false;
			let focusedView = Context.FocusManager.FocusedView;
			if (focusedView == null) return false;
			var v = focusedView;
			while (v != null)
			{
				if (v.Id == Id) return true;
				v = v.Parent;
			}
			return false;
		}
	}

	// === Input events (bubble phase — default) ===

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
	// Called during the capture walk (root -> target) before the event
	// reaches the target. Set e.Handled = true to prevent the event
	// from reaching the target or the bubble phase.

	public virtual void OnMouseDownCapture(MouseEventArgs e) { }
	public virtual void OnMouseUpCapture(MouseEventArgs e) { }
	public virtual void OnMouseMoveCapture(MouseEventArgs e) { }
	public virtual void OnMouseWheelCapture(MouseWheelEventArgs e) { }
	public virtual void OnKeyDownCapture(KeyEventArgs e) { }
	public virtual void OnKeyUpCapture(KeyEventArgs e) { }
	public virtual void OnTextInputCapture(TextInputEventArgs e) { }

	// === Gamepad / directional activation ===

	/// Called when the view is activated (Gamepad A / Enter on focused view).
	/// ButtonBase overrides to fire OnClick.
	public virtual void OnActivate() { }

	/// Called when cancel is pressed (Gamepad B / Escape on focused view).
	/// Default: bubbles to parent.
	public virtual void OnCancel()
	{
		Parent?.OnCancel();
	}

	// === Deferred mutation convenience ===

	/// Queue removal from parent (deferred to next drain point).
	/// View stays alive for reuse after removal.
	public void QueueRemove()
	{
		if (Context == null || IsPendingDeletion) return;
		IsPendingDeletion = true;
		Context.MutationQueue.QueueAction(new () =>
		{
			if (Parent != null)
				if (let parentGroup = Parent as ViewGroup)
					parentGroup.RemoveView(this, false);
			IsPendingDeletion = false;
		});
	}

	/// Queue removal from parent AND deletion (deferred to next drain point).
	/// After this call the view will be deleted - do not reference it.
	public void QueueDestroy()
	{
		if (Context == null || IsPendingDeletion) return;
		IsPendingDeletion = true;
		Context.MutationQueue.QueueAction(new () =>
		{
			if (Parent != null)
				if (let parentGroup = Parent as ViewGroup)
					parentGroup.RemoveView(this, true);
				else
					delete this;
			else
				delete this;
		});
	}

	/// Walk up the parent chain to find a ScrollView ancestor and scroll
	/// to make this view visible within it.
	public void ScrollIntoView()
	{
		var parent = Parent;
		while (parent != null)
		{
			if (let sv = parent as ScrollView)
			{
				sv.ScrollToView(this);
				return;
			}
			parent = parent.Parent;
		}
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

	// === Destructor ===

	public ~this()
	{
		delete Name;
		delete TooltipText;
		delete LayoutParams;

		if (mUserData != null)
		{
			for (let kv in mUserData)
				delete kv.key;
			delete mUserData;
		}

		delete mInlineStyles;
		if (mInlinePartStyles != null)
		{
			for (let entry in mInlinePartStyles)
				delete entry.Part;
			delete mInlinePartStyles;
		}
		if (mOwnedInlineDrawables != null)
		{
			for (let d in mOwnedInlineDrawables)
				delete d;
			delete mOwnedInlineDrawables;
		}
	}
}
