using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// The base of the retained mode view hierarchy.
///
/// This carries View's identity, geometry, flags, tree links and coordinate conversion;
/// the style cascade, measure and arrange, invalidation and transitions are in the
/// partial files beside it.
///
/// Ref counted: a parent owns its children by reference, and the back pointers here are
/// borrowed.
class View : RefCounted, IPropertyOwner
{
	// ---- Identity ------------------------------------------------------------------------------

	public readonly ViewId Id = ViewId.Create();
	/// Optional, for debugging and lookup. Empty means none. Also what an `#id` selector
	/// matches.
	public String Name = new .() ~ delete _;
	public List<String> StyleClasses = new .() ~ DeleteContainerAndItems!(_);

	// ---- Layout state --------------------------------------------------------------------------

	public Float2 MeasuredSize = .Zero;
	public Rectangle Bounds = .();

	public float Width => Bounds.Width;
	public float Height => Bounds.Height;

	// ---- Visibility and interaction --------------------------------------------------------

	public Visibility Visibility = .Visible;
	public bool IsEnabled = true;
	public bool IsInteractionEnabled = true;
	public bool IsHitTestVisible = true;
	public bool IsFocusable = false;
	public bool IsTabStop = false;
	public int32 TabIndex = 0;
	public bool ClipsContent = false;
	public bool WantsArrowKeys = false;
	/// Tab normally drives focus traversal BEFORE dispatch and never reaches a view. A view
	/// that edits tab characters, such as a code editor, sets this to see Tab in OnKeyDown
	/// first; traversal stays the fallback when the view leaves the event unhandled.
	public bool WantsTabKey = false;
	public bool IsPendingDeletion = false;

	// ---- Tooltip -------------------------------------------------------------------------------

	/// Empty means no tooltip, unless the view provides its own content.
	public String TooltipText = new .() ~ delete _;
	public TooltipPlacement TooltipPlacement = .Bottom;
	/// Keeps the tooltip hit testable, so it can be hovered and clicked.
	public bool IsTooltipInteractive = false;

	// ---- Directional focus overrides. Null uses the spatial picker. ----------------------------

	public ViewId? NextFocusUp = null;
	public ViewId? NextFocusDown = null;
	public ViewId? NextFocusLeft = null;
	public ViewId? NextFocusRight = null;

	// ---- Visual --------------------------------------------------------------------------------

	public float Opacity = 1.0f;
	public ViewTransform Transform = .();
	/// The sheet's `transform` about its transform-origin, as the view was last drawn
	/// (RefreshStyleTransform): what TransformMatrix puts inside the Transform field's.
	private Transform2D mStyleMatrix = .();

	/// The transform the view is drawn and hit tested with, from its own space to its box in the
	/// parent's: its Transform field (about its Origin: rotated, scaled, then moved), with the
	/// sheet's `transform` about its transform-origin inside it, as the view was last drawn.
	public Transform2D TransformMatrix
	{
		get
		{
			var m = Transform2D();
			if (!Transform.IsIdentity)
			{
				let originX = Width * Transform.Origin.X;
				let originY = Height * Transform.Origin.Y;
				m.Translate(Transform.Translation.X + originX, Transform.Translation.Y + originY);
				m.Scale(Transform.Scale.X, Transform.Scale.Y);
				m.Rotate(Transform.Rotation);
				m.Translate(-originX, -originY);
			}
			if (!mStyleMatrix.IsIdentity)
				m.Combine(mStyleMatrix);
			return m;
		}
	}

	/// Composes the sheet's `transform` and `transform-origin` (a transition's or an
	/// animation's values while one runs) for TransformMatrix; DrawChildren calls it before
	/// drawing the view.
	public void RefreshStyleTransform()
	{
		if (!HasStyleWinner(.Transform) && (ActiveTransitionCount == 0) && !HasAnimations)
		{
			mStyleMatrix = .();
			return;
		}
		let styled = ResolveStyle(.Transform).AsTransform;
		if ((styled == null) || styled.IsIdentity)
		{
			mStyleMatrix = .();
			return;
		}
		let dpi = Math.Max(RootDpiScale(Root()), 0.01f);
		let size = Float2(Width, Height);
		// Composed now, while the list the resolve answered (a scratch's, mid transition) holds.
		let composed = styled.Compose(size, dpi);
		let origin = ResolveStyle(.TransformOrigin).AsPoint;
		let originX = (origin != null) ? origin.X.Resolve(dpi, size.X, 0.0f) : (size.X * 0.5f);
		let originY = (origin != null) ? origin.Y.Resolve(dpi, size.Y, 0.0f) : (size.Y * 0.5f);
		var m = Transform2D();
		m.Translate(originX, originY);
		m.Combine(composed);
		m.Translate(-originX, -originY);
		mStyleMatrix = m;
	}
	public CursorType Cursor = .Default;

	// ---- Tree ----------------------------------------------------------------------------------

	/// BORROWED: the parent owns this view, not the other way about.
	public View Parent = null;
	/// BORROWED. Null until the view is attached to a tree.
	public UIContext Context = null;

	public bool IsAttached => Context != null;

	/// The RootView this view belongs to, found by walking up. Null when detached from one.
	public RootView Root()
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

	protected bool mNeedsRedraw = true;

	public this() {}

	// ---- Cursor --------------------------------------------------------------------------------

	/// The cursor at a point inside this view, defaulting to the whole view's Cursor.
	///
	/// A view with internal regions wanting different pointers, such as a code editor's gutter
	/// against its text area, overrides THIS rather than writing to Cursor from hover events.
	public virtual CursorType CursorAt(Float2 localPoint) => Cursor;

	/// Walks the parent chain from this view, answering the first cursor that is not Default,
	/// each view judged at the SAME screen point.
	public CursorType EffectiveCursor(Float2 screenPoint)
	{
		var view = this;
		while (view != null)
		{
			let cursor = view.CursorAt(view.ScreenToLocal(screenPoint));
			if (cursor != .Default)
				return cursor;
			view = view.Parent;
		}
		return .Default;
	}

	// ---- Coordinates ---------------------------------------------------------------------------

	/// A point of this view in its parent's space: through its TransformMatrix, as DrawChildren
	/// draws it, and its Bounds.
	public Float2 LocalToParent(Float2 local)
	{
		let point = TransformMatrix.Apply(local);
		return .(point.X + Bounds.X, point.Y + Bounds.Y);
	}

	/// The inverse of LocalToParent: a point of the parent's space in this view's. A transform
	/// that flattens the view (a zero scale) maps nothing back; the point stays where it fell.
	public Float2 ParentToLocal(Float2 parentPoint)
	{
		let point = Float2(parentPoint.X - Bounds.X, parentPoint.Y - Bounds.Y);
		let m = TransformMatrix;
		return m.IsIdentity ? point : m.Inverse().Apply(point);
	}

	/// A point of this view in its root's space, through every view's bounds and transform.
	public Float2 LocalToScreen(Float2 local)
	{
		var result = local;
		for (var view = this; view != null; view = view.Parent)
			result = view.LocalToParent(result);
		return result;
	}

	/// The dpi scale of the root a view sits under, and one when it is unparented.
	///
	/// On View rather than ViewGroup, which is where the callers are. Callers that DIVIDE
	/// by it clamp it themselves: a root reporting nought is a host bug rather than
	/// something to paper over silently everywhere.
	protected static float RootDpiScale(RootView root) => (root != null) ? root.DpiScale : 1.0f;

	/// Device pixels per layout unit where this view's box is drawn: the root's DPI times the
	/// uniform scales of the views above it. Layout rounds the box to this grid.
	public float DeviceUnitScale()
	{
		var scale = 1.0f;
		View top = this;
		for (var above = Parent; above != null; above = above.Parent)
		{
			// A turn, a skew or an uneven scale has no one grid to round to: those keep the DPI's.
			if (above.TransformMatrix.UniformScale(let uniform))
				scale *= uniform;
			top = above;
		}
		return Math.Max(RootDpiScale(top as RootView) * scale, 0.01f);
	}

	/// The inverse of LocalToScreen, applied from the root down.
	public Float2 ScreenToLocal(Float2 screen) =>
		ParentToLocal((Parent != null) ? Parent.ScreenToLocal(screen) : screen);

	// ---- Deferred mutation ---------------------------------------------------------------------

	/// Queues this view for removal from its parent at the next safe point, which is what a
	/// handler running inside its own view has to use.
	public void QueueRemove()
	{
		if ((Context == null) || IsPendingDeletion)
			return;
		Context.MutationQueue.QueueDelete(this);
	}

	/// The same thing.
	///
	/// Both names are kept. A `deleteChild` flag would only be advisory: under reference
	/// counted ownership, dropping the tree's reference frees the view unless something
	/// else holds one, whichever name was used.
	public void QueueDestroy() => QueueRemove();

	// ---- User data -----------------------------------------------------------------------------

	/// Arbitrary data hung off a view by key. NON owning: the caller keeps it alive.
	private Dictionary<String, void*> mUserData = new .() ~ DeleteDictionaryAndKeys!(_);

	public void SetUserData(StringView key, void* data)
	{
		if (mUserData.TryGetAlt(key, let existingKey, ?))
		{
			mUserData[existingKey] = data;
			return;
		}
		mUserData[new String(key)] = data;
	}

	public void* GetUserData(StringView key)
	{
		if (mUserData.TryGetValueAlt(key, let data))
			return data;
		return null;
	}

	public T* GetUserData<T>(StringView key) => (T*)GetUserData(key);

	// ---- Property changes ------------------------------------------------------------------

	/// A property DECLARES its own damage, so a visual only one skips the relayout and
	/// everything else takes the safe path.
	public void OnPropertyChanged(InvalidationKind kind)
	{
		if (kind == .Visual)
			InvalidateVisual();
		else
			Invalidate();
	}

	// ---- Input events, bubble phase --------------------------------------------------------

	public virtual void OnMouseDown(MouseEventArgs e) {}
	public virtual void OnMouseUp(MouseEventArgs e) {}
	public virtual void OnMouseMove(MouseEventArgs e) {}
	public virtual void OnMouseWheel(MouseWheelEventArgs e) {}
	public virtual void OnMouseEnter() {}
	public virtual void OnMouseLeave() {}
	public virtual void OnKeyDown(KeyEventArgs e) {}
	public virtual void OnKeyUp(KeyEventArgs e) {}
	public virtual void OnTextInput(TextInputEventArgs e) {}
	public virtual void OnFocusGained() {}
	public virtual void OnFocusLost() {}
	/// Focus moved, by keys, a pad or code, onto a view somewhere below this one: a scroller
	/// brings it into view. Called on each ancestor, nearest first.
	public virtual void OnDescendantFocused(View focused) {}

	// ---- Input events, capture phase, root to target before the target sees it -------------

	public virtual void OnMouseDownCapture(MouseEventArgs e) {}
	public virtual void OnMouseUpCapture(MouseEventArgs e) {}
	public virtual void OnMouseMoveCapture(MouseEventArgs e) {}
	public virtual void OnMouseWheelCapture(MouseWheelEventArgs e) {}
	public virtual void OnKeyDownCapture(KeyEventArgs e) {}
	public virtual void OnKeyUpCapture(KeyEventArgs e) {}
	public virtual void OnTextInputCapture(TextInputEventArgs e) {}

	// ---- Style classes -------------------------------------------------------------------------

	public bool HasClass(StringView name)
	{
		for (let styleClass in StyleClasses)
		{
			if (styleClass == name)
				return true;
		}
		return false;
	}

	// ---- Effective state -----------------------------------------------------------------------

	/// Enabled only if this view AND every ancestor is: disabling a panel disables everything
	/// inside it without touching the children.
	public bool IsEffectivelyEnabled()
	{
		var view = this;
		while (view != null)
		{
			if (!view.IsEnabled)
				return false;
			view = view.Parent;
		}
		return true;
	}

	/// Whether this view is actually ON SCREEN: visible itself, visible all the way up, and
	/// the chain reaching a RootView.
	///
	/// A DETACHED subtree answers false however visible its own views are, because the walk
	/// runs off the top without meeting a root. That is what separates this from Visibility,
	/// which is only what this one view asked for.
	public bool IsEffectivelyVisible()
	{
		var view = this;
		while (view != null)
		{
			if (view.Visibility != .Visible)
				return false;
			if (view is RootView)
				return true;
			view = view.Parent;
		}
		return false;
	}

	/// Whether this view or any descendant holds keyboard focus.
	///
	/// Walked UPWARD from the focused view rather than downward over the subtree: the focused
	/// view is one registry lookup away and the parent chain is short, where a descendant
	/// search would visit everything.
	public bool IsFocusWithin()
	{
		if (Context == null)
			return false;

		var focused = Context.GetFocusManager().FocusedView;
		while (focused != null)
		{
			if (focused.Id == Id)
				return true;
			focused = focused.Parent;
		}
		return false;
	}

	/// Whether the pointer is over this view.
	public bool IsHovered() =>
		(Context != null) && (Context.GetInputManager().HoveredId == Id);

	/// Whether this view holds keyboard focus.
	public bool IsFocused() =>
		(Context != null) && (Context.GetFocusManager().FocusedId == Id);

	/// Whether this view's focus VISUAL should draw.
	///
	/// A text editing view always shows its border and caret: you have to see where typing
	/// goes however focus arrived. Everything else draws the ring only for keyboard acquired
	/// focus, so pointer and programmatic focus are held without lighting up.
	public bool IsFocusVisible()
	{
		if (!IsFocused())
			return false;
		if (WantsTextInput())
			return true;
		return Context.GetFocusManager().Source == .Keyboard;
	}

	/// The current visual state, for drawable and theme lookups.
	public virtual ControlState GetControlState()
	{
		var state = ControlState.Normal;
		if (!IsEffectivelyEnabled())
			state |= .Disabled;
		if (IsFocusVisible())
			state |= .Focused;
		if (IsHovered())
			state |= .Hover;
		return state;
	}

	// ---- Draw ----------------------------------------------------------------------------------

	public bool NeedsRedraw => mNeedsRedraw;
	public void ClearRedrawFlag() => mNeedsRedraw = false;

	/// A layout affecting change: the host re-measures, re-lays out and redraws.
	///
	/// The SAFE default for any mutation, since almost anything can move geometry.
	public void Invalidate()
	{
		mNeedsRedraw = true;
		if (Context != null)
			Context.MarkNeedsLayout();
	}

	/// A visual only change: a hover tint, a press, a focus ring, a caret. Redraws WITHOUT the
	/// whole tree relayout, so use it only where geometry provably cannot change.
	public void InvalidateVisual()
	{
		mNeedsRedraw = true;
		if (Context != null)
			Context.MarkNeedsRedraw();
	}

	public virtual float GetBaseline() => -1.0f;
	public virtual void OnDraw(UIDrawContext ctx) {}

	// ---- Content -----------------------------------------------------------------------------

	/// A view that draws one other view as its content without holding it as a child (a
	/// ContentButton, a ToggleButton) answers it here, so a search by name and markup reach it
	/// without naming the control types. None by default. BORROWED.
	public virtual View ContentChild => null;

	/// Takes `content` as that content, CONSUMING the caller's reference; false for a view that
	/// has none to take, which leaves the reference with the caller.
	public virtual bool SetContentChild(View content) => false;

	// ---- Hit testing -------------------------------------------------------------------------

	/// Whether a pointer over this view is the UI's to take, not the game's: a control that
	/// answers it (focusable ones: buttons, sliders, fields, lists), a scroll view with room to
	/// scroll, a screen that shields what is below. A plain layout box filling the screen (a
	/// HUD's) is not, so a game under a pass-through HUD still gets its taps and clicks.
	public virtual bool TakesPointer => IsFocusable;

	/// The view at a point given in THIS view's coordinates, or null when the point misses.
	///
	/// A leaf answers itself when the point is inside its box. The three gates are separate on
	/// purpose: interaction and visibility disqualify the SUBTREE, while IsHitTestVisible
	/// disqualifies only this view, which is what lets a container pass the pointer through to
	/// whatever is behind it while its children stay clickable.
	public virtual View HitTest(Float2 localPoint)
	{
		if (!IsInteractionEnabled || (Visibility != .Visible))
			return null;

		if ((localPoint.X < 0) || (localPoint.Y < 0)
			|| (localPoint.X >= Width) || (localPoint.Y >= Height))
			return null;

		if (!IsHitTestVisible)
			return null;

		return this;
	}

	// ---- Gamepad and directional activation ----------------------------------------------------

	/// Activated, by a gamepad's confirm button or Return on the focused view.
	public virtual void OnActivate() {}

	/// Cancelled, by a gamepad's back button or Escape. BUBBLES by default, so a dialog can
	/// answer for a control inside it that does not care.
	public virtual void OnCancel()
	{
		if (Parent != null)
			Parent.OnCancel();
	}

	// ---- Capability queries --------------------------------------------------------------------
	// A view says what it can do by overriding these to answer itself, which is how the tree is
	// searched without a downcast at every level.

	public virtual IAcceleratorHandler AsAcceleratorHandler() => null;
	public virtual ITooltipProvider AsTooltipProvider() => null;
	public virtual IDragSource AsDragSource() => null;
	public virtual IDropTarget AsDropTarget() => null;
	/// Whether a left press on this view starts a drag of its own (a scrollbar's thumb, a
	/// slider's), so no drag source above it may take the gesture: a scrollbar laid over a
	/// draggable tree's rows scrolls the tree, never drags a row.
	public virtual bool OwnsPressDrag => false;

	/// Whether this view wants platform text input while it holds focus. A text editing
	/// control overrides this to true, and the shell bridge starts and stops the window's
	/// text input accordingly.
	public virtual bool WantsTextInput() => false;
}
