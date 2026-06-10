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
	// Storage is an internal `StyleSheet` (lazy, RefCounted). All
	// refcount mgmt for `DrawableRef` values reuses `StyleRule.Set` /
	// `StyleRule.Remove` from the styling subsystem - the View
	// doesn't duplicate it. The inline sheet's rules use empty
	// selectors (element-level) or pseudo-element-only selectors
	// (part-level); `StyleSheet.Resolve` short-circuits on any match
	// from the inline sheet, treating it as specificity infinity.

	private StyleSheet mInlineSheet;
	private StyleSheet mLocalStyleSheet;

	/// Internal access to the inline sheet. Returned non-owning -
	/// don't Release.
	public StyleSheet InlineSheet => mInlineSheet;

	/// Optional scoped `StyleSheet` that applies to this view and its
	/// descendants. Ref-counted (mirrors `UIContext.StyleSheet`) - the
	/// setter AddRefs the new value and Releases the previous one;
	/// destruction releases the held ref. Multiple views can safely
	/// share the same `LocalStyleSheet` instance.
	///
	/// Resolution wiring (ancestor-chain walk before the context sheet)
	/// lands in sub-phase F. This phase just exposes the property and
	/// its lifecycle.
	public StyleSheet LocalStyleSheet
	{
		get => mLocalStyleSheet;
		set
		{
			if (mLocalStyleSheet === value) return;
			value?.AddRef();
			mLocalStyleSheet?.ReleaseRef();
			mLocalStyleSheet = value;
			Invalidate();
		}
	}

	/// True if any inline overrides are set on this view.
	public bool HasAnyInlineStyles => mInlineSheet != null && !mInlineSheet.IsEmpty;

	private StyleSheet EnsureInlineSheet()
	{
		if (mInlineSheet == null)
			mInlineSheet = new StyleSheet();
		return mInlineSheet;
	}

	/// Return the view's inline `StyleSheet`, creating it if necessary.
	/// Public counterpart to `EnsureInlineSheet` for callers that need
	/// to register drawables or rules with the inline sheet directly
	/// (notably the inline-style markup parser).
	public StyleSheet GetOrCreateInlineSheet() => EnsureInlineSheet();

	/// Sets an inline override for `prop`. Overwrites any existing
	/// inline value for the same property, releasing the previous
	/// drawable if one was stored. The view consumes the caller's
	/// drawable ref when `value` is a `DrawableRef` - for AddRef
	/// semantics use the `SetStyle(prop, drawable, consumeRef: false)`
	/// overload.
	public void SetInlineStyle(StyleProperty prop, StyleValue value)
	{
		let rule = EnsureInlineSheet().GetOrCreateInlineElementRule();
		switch (value)
		{
		case .ColorVal(let c):     rule.Set(prop, c);
		case .FloatVal(let f):     rule.Set(prop, f);
		case .ThicknessVal(let t): rule.Set(prop, t);
		case .BoolVal(let b):      rule.Set(prop, b);
		case .DrawableRef(let d):  rule.Set(prop, d, consumeRef: true);
		case .StringRef(let s):    rule.Set(prop, StringView(s));
		case .None:                rule.Remove(prop);
		}
		Invalidate();
	}

	/// Returns the inline override for `prop`, or `.None` if not set.
	/// Drawable values are borrowed - do not Release.
	public StyleValue GetInlineStyle(StyleProperty prop)
	{
		if (mInlineSheet == null) return .None;
		let rule = mInlineSheet.FindInlineElementRule();
		if (rule == null) return .None;
		return rule.GetValue(prop) ?? .None;
	}

	/// True if an inline override exists for `prop`.
	public bool HasInlineStyle(StyleProperty prop)
	{
		if (mInlineSheet == null) return false;
		let rule = mInlineSheet.FindInlineElementRule();
		if (rule == null) return false;
		return rule.GetValue(prop) != null;
	}

	/// Removes a single inline override. Releases the drawable if the
	/// value was a `DrawableRef`. No-op if not set.
	public void ClearInlineStyle(StyleProperty prop)
	{
		if (mInlineSheet == null) return;
		let rule = mInlineSheet.FindInlineElementRule();
		if (rule == null) return;
		if (rule.Remove(prop))
			Invalidate();
	}

	/// Removes every inline override on this view (element + pseudo-element).
	/// Releases every owned drawable.
	public void ClearInlineStyles()
	{
		if (mInlineSheet == null || mInlineSheet.IsEmpty) return;
		// Releasing the whole sheet is the simplest way to drop every
		// rule (and every drawable AddRef'd by those rules). A fresh
		// sheet is reallocated on the next set.
		mInlineSheet.ReleaseRef();
		mInlineSheet = null;
		Invalidate();
	}

	/// Sets an inline override for a pseudo-element (e.g., "thumb") on
	/// this view. Composite controls use this to override sub-part
	/// styles without going through a context StyleSheet rule. Consumes
	/// the caller's drawable ref on `DrawableRef` values; overwriting
	/// an existing entry releases the previous drawable.
	public void SetInlinePartStyle(StringView part, StyleProperty prop, StyleValue value)
	{
		let rule = EnsureInlineSheet().GetOrCreateInlinePartRule(part);
		switch (value)
		{
		case .ColorVal(let c):     rule.Set(prop, c);
		case .FloatVal(let f):     rule.Set(prop, f);
		case .ThicknessVal(let t): rule.Set(prop, t);
		case .BoolVal(let b):      rule.Set(prop, b);
		case .DrawableRef(let d):  rule.Set(prop, d, consumeRef: true);
		case .StringRef(let s):    rule.Set(prop, StringView(s));
		case .None:                rule.Remove(prop);
		}
		Invalidate();
	}

	/// Returns the inline pseudo-element override, or `.None`.
	/// Drawable values are borrowed - do not Release.
	public StyleValue GetInlinePartStyle(StringView part, StyleProperty prop)
	{
		if (mInlineSheet == null) return .None;
		let rule = mInlineSheet.FindInlinePartRule(part);
		if (rule == null) return .None;
		return rule.GetValue(prop) ?? .None;
	}

	/// True if an inline pseudo-element override exists.
	public bool HasInlinePartStyle(StringView part, StyleProperty prop)
	{
		if (mInlineSheet == null) return false;
		let rule = mInlineSheet.FindInlinePartRule(part);
		if (rule == null) return false;
		return rule.GetValue(prop) != null;
	}

	/// Removes one inline pseudo-element override. Releases the
	/// drawable if the value was a `DrawableRef`. No-op if not set.
	public void ClearInlinePartStyle(StringView part, StyleProperty prop)
	{
		if (mInlineSheet == null) return;
		let rule = mInlineSheet.FindInlinePartRule(part);
		if (rule == null) return;
		if (rule.Remove(prop))
			Invalidate();
	}

	// === SetStyle convenience overloads ===
	//
	// Public write API for inline overrides. Mirrors `StyleRule.Set`
	// in shape (one overload per StyleValue kind). The Drawable
	// overload exposes the same `consumeRef` flag as
	// `StyleRule.Set` / `StyleSheet.OwnDrawable`; the default here is
	// `consumeRef: true` because the typical view-side pattern is
	// `panel.SetStyle(.Background, new ColorDrawable(...))` - a
	// one-liner that hands the new drawable's ref to the view.

	public void SetStyle(StyleProperty prop, Color color)
	{
		EnsureInlineSheet().GetOrCreateInlineElementRule().Set(prop, color);
		Invalidate();
	}

	public void SetStyle(StyleProperty prop, float value)
	{
		EnsureInlineSheet().GetOrCreateInlineElementRule().Set(prop, value);
		Invalidate();
	}

	public void SetStyle(StyleProperty prop, Thickness value)
	{
		EnsureInlineSheet().GetOrCreateInlineElementRule().Set(prop, value);
		Invalidate();
	}

	public void SetStyle(StyleProperty prop, bool value)
	{
		EnsureInlineSheet().GetOrCreateInlineElementRule().Set(prop, value);
		Invalidate();
	}

	public void SetStyle(StyleProperty prop, Drawable drawable, bool consumeRef = true)
	{
		EnsureInlineSheet().GetOrCreateInlineElementRule().Set(prop, drawable, consumeRef: consumeRef);
		Invalidate();
	}

	public void SetStyle(StyleProperty prop, StringView value)
	{
		EnsureInlineSheet().GetOrCreateInlineElementRule().Set(prop, value);
		Invalidate();
	}

	public void SetPartStyle(StringView part, StyleProperty prop, Color color)
	{
		EnsureInlineSheet().GetOrCreateInlinePartRule(part).Set(prop, color);
		Invalidate();
	}

	public void SetPartStyle(StringView part, StyleProperty prop, float value)
	{
		EnsureInlineSheet().GetOrCreateInlinePartRule(part).Set(prop, value);
		Invalidate();
	}

	public void SetPartStyle(StringView part, StyleProperty prop, Thickness value)
	{
		EnsureInlineSheet().GetOrCreateInlinePartRule(part).Set(prop, value);
		Invalidate();
	}

	public void SetPartStyle(StringView part, StyleProperty prop, bool value)
	{
		EnsureInlineSheet().GetOrCreateInlinePartRule(part).Set(prop, value);
		Invalidate();
	}

	public void SetPartStyle(StringView part, StyleProperty prop, Drawable drawable, bool consumeRef = true)
	{
		EnsureInlineSheet().GetOrCreateInlinePartRule(part).Set(prop, drawable, consumeRef: consumeRef);
		Invalidate();
	}

	public void SetPartStyle(StringView part, StyleProperty prop, StringView value)
	{
		EnsureInlineSheet().GetOrCreateInlinePartRule(part).Set(prop, value);
		Invalidate();
	}

	// === Style resolution helpers ===
	//
	// `ResolveStyle` is the public orchestrator for style resolution.
	// The walk:
	//   1. Inline sheet on THIS view (specificity infinity).
	//   2. Ancestor chain (self -> root) - consult each `LocalStyleSheet`.
	//      "Not found" on an ancestor's local sheet falls through to
	//      the next ancestor; each sheet contributes only what it
	//      defines.
	//   3. Context sheet on the active UIContext.
	//   4. For inheritable properties (TextColor, FontSize): recurse
	//      the whole algorithm from Parent.
	//
	// Each StyleSheet's `Resolve` is a per-sheet primitive (just walks
	// its rules); the orchestrator threads them together. Pseudo-
	// element resolution still goes through `ResolvePartStyle`, which
	// currently consults only the context sheet (sub-phase G adds the
	// ancestor walk for pseudo-elements).

	/// Resolve a style property. Returns `.None` if no inline, local,
	/// or context rule matches and the property isn't inheritable.
	public StyleValue ResolveStyle(StyleProperty prop)
	{
		// 1. Inline sheet on this view.
		if (mInlineSheet != null)
		{
			let r = mInlineSheet.Resolve(this, prop);
			if (!(r case .None)) return r;
		}

		// 2. Walk ancestor chain (self -> root) consulting LocalStyleSheets.
		var anc = this;
		while (anc != null)
		{
			if (anc.mLocalStyleSheet != null)
			{
				let r = anc.mLocalStyleSheet.Resolve(this, prop);
				if (!(r case .None)) return r;
			}
			anc = anc.Parent;
		}

		// 3. Context sheet.
		let ctxSheet = Context?.StyleSheet;
		if (ctxSheet != null)
		{
			let r = ctxSheet.Resolve(this, prop);
			if (!(r case .None)) return r;
		}

		// 4. Inheritable property: recurse from parent through the whole
		// algorithm (so the parent's inline + locals + context are all
		// consulted).
		if (StyleInheritance.IsInheritable(prop) && Parent != null)
			return Parent.ResolveStyle(prop);

		return .None;
	}

	/// Resolve a Color style property with fallback default.
	public Color ResolveStyleColor(StyleProperty prop, Color defaultVal = .White)
	{
		if (let c = ResolveStyle(prop).AsColor) return c;
		return defaultVal;
	}

	/// Resolve a float style property with fallback default.
	public float ResolveStyleFloat(StyleProperty prop, float defaultVal = 0)
	{
		if (let f = ResolveStyle(prop).AsFloat) return f;
		return defaultVal;
	}

	/// Resolve a Thickness style property with fallback default.
	public Thickness ResolveStyleThickness(StyleProperty prop, Thickness defaultVal = .())
	{
		if (let t = ResolveStyle(prop).AsThickness) return t;
		return defaultVal;
	}

	/// Resolve a Drawable style property. Returns null if not found.
	public Drawable ResolveStyleDrawable(StyleProperty prop)
		=> ResolveStyle(prop).AsDrawable;

	/// Resolve a string style property. Returns `defaultVal` (as a
	/// `StringView`) if not found.
	public StringView ResolveStyleString(StyleProperty prop, StringView defaultVal = default)
	{
		if (let s = ResolveStyle(prop).AsString) return s;
		return defaultVal;
	}

	/// Resolve the effective font family for this view. Walks the
	/// cascade for `.FontFamily` and falls back to the active
	/// IFontService's default family when nothing is set. Returned
	/// view is borrowed - do not delete.
	public StringView ResolveStyleFontFamily()
	{
		if (let s = ResolveStyle(.FontFamily).AsString) return s;
		return Context?.FontService?.DefaultFontFamily ?? default(StringView);
	}

	/// Resolve the effective font family, preferring an explicit
	/// per-instance override when set and non-empty. Controls that
	/// expose a typed `FontFamily` property feed it in here.
	public StringView ResolveStyleFontFamily(String instanceOverride)
	{
		if (instanceOverride != null && instanceOverride.Length > 0)
			return instanceOverride;
		return ResolveStyleFontFamily();
	}

	// === Pseudo-element (part) style resolution ===
	//
	// Mirror of `ResolveStyle` for pseudo-elements: inline (this view)
	// -> ancestor `LocalStyleSheet`s -> context. No inheritance recursion
	// - pseudo-element rules don't inherit through the view tree.

	/// Resolve a style property for a named sub-part of this control.
	/// `partState` is the part's interaction state (e.g. thumb hovered).
	public StyleValue ResolvePartStyle(StringView part, StyleProperty prop, ControlState partState)
	{
		// 1. Inline sheet on this view.
		if (mInlineSheet != null)
		{
			let r = mInlineSheet.ResolvePart(this, part, prop, partState);
			if (!(r case .None)) return r;
		}

		// 2. Walk ancestor chain (self -> root) consulting LocalStyleSheets.
		var anc = this;
		while (anc != null)
		{
			if (anc.mLocalStyleSheet != null)
			{
				let r = anc.mLocalStyleSheet.ResolvePart(this, part, prop, partState);
				if (!(r case .None)) return r;
			}
			anc = anc.Parent;
		}

		// 3. Context sheet.
		let ctxSheet = Context?.StyleSheet;
		if (ctxSheet != null)
		{
			let r = ctxSheet.ResolvePart(this, part, prop, partState);
			if (!(r case .None)) return r;
		}

		return .None;
	}

	public Drawable ResolvePartDrawable(StringView part, StyleProperty prop, ControlState partState)
		=> ResolvePartStyle(part, prop, partState).AsDrawable;

	public Color ResolvePartColor(StringView part, StyleProperty prop, ControlState partState, Color defaultVal = .White)
	{
		if (let c = ResolvePartStyle(part, prop, partState).AsColor) return c;
		return defaultVal;
	}

	public float ResolvePartFloat(StringView part, StyleProperty prop, ControlState partState, float defaultVal = 0)
	{
		if (let f = ResolvePartStyle(part, prop, partState).AsFloat) return f;
		return defaultVal;
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

		mInlineSheet?.ReleaseRef();
		mLocalStyleSheet?.ReleaseRef();
	}
}
