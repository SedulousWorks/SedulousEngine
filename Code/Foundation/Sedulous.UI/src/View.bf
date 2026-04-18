namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Base class for all UI elements. Carries identity, layout state, and
/// virtual hooks for measurement, layout, drawing, and input.
public class View
{
	// === Identity (set on construction, never changes) ===
	public ViewId Id { get; private set; }
	public String Name ~ delete _;
	public String StyleId ~ delete _;

	// === Tree (raw pointers — parent owns children) ===
	public View Parent { get; internal set; }
	public LayoutParams LayoutParams ~ delete _;

	// === Layout state ===
	public RectangleF Bounds;                  // final position+size in parent-local coords
	public Vector2 MeasuredSize;               // result of last Measure
	private bool mLayoutDirty = true;
	private bool mMeasureDirty = true;

	// === Flags ===
	public Visibility Visibility = .Visible;
	public bool IsEnabled = true;
	public bool IsFocusable;
	public bool IsTabStop = true;
	public int32 TabIndex;
	public bool ClipsContent;
	public bool IsHitTestVisible = true;

	// === Visual properties ===
	private float mAlpha = 1.0f;
	public float Alpha { get => mAlpha; set => mAlpha = Math.Clamp(value, 0, 1); }

	/// Tooltip text shown after hover delay. Empty = no tooltip.
	public String TooltipText ~ delete _;
	/// Where the tooltip appears relative to this view.
	public TooltipPlacement TooltipPlacement = .Bottom;
	/// When true, the tooltip stays visible when hovered and its content
	/// is interactive (clickable links, selectable text, etc.).
	public bool IsTooltipInteractive;

	/// Render transform applied around RenderTransformOrigin during draw.
	public Matrix RenderTransform = Matrix.Identity;
	/// Normalized origin for render transform (0,0 = top-left, 0.5,0.5 = center).
	public Vector2 RenderTransformOrigin = .(0.5f, 0.5f);

	// === Context attachment ===
	public UIContext Context { get; internal set; }
	public bool IsPendingDeletion { get; internal set; }
	public bool IsAttached => Context != null;

	// === Cursor ===
	public CursorType Cursor = .Default;

	/// Effective cursor — walks parent chain, returning first non-Default.
	public CursorType EffectiveCursor
	{
		get
		{
			var v = this;
			while (v != null)
			{
				if (v.Cursor != .Default) return v.Cursor;
				v = v.Parent;
			}
			return .Default;
		}
	}

	public float Width => Bounds.Width;
	public float Height => Bounds.Height;

	public this()
	{
		Id = ViewId.Generate();
	}

	// === Lifecycle hooks ===

	public virtual void OnAttachedToContext(UIContext ctx) { }
	public virtual void OnDetachedFromContext() { }

	// === Layout ===

	/// Measure this view given width/height constraints.
	public void Measure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		OnMeasure(wSpec, hSpec);
		mMeasureDirty = false;
	}

	/// Layout this view at the given position and size (parent-local coords).
	public void Layout(float x, float y, float w, float h)
	{
		Bounds = .(x, y, Math.Max(0, w), Math.Max(0, h));
		OnLayout(x, y, x + w, y + h);
		mLayoutDirty = false;
	}

	/// Override to compute desired size. Set MeasuredSize.
	protected virtual void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		MeasuredSize = .(wSpec.Resolve(0), hSpec.Resolve(0));
	}

	/// Override to position children (ViewGroup subclasses).
	protected virtual void OnLayout(float left, float top, float right, float bottom) { }

	/// Override to return text baseline offset, or -1 for no baseline.
	public virtual float GetBaseline() => -1;

	public void InvalidateLayout()
	{
		mLayoutDirty = true;
		mMeasureDirty = true;
	}

	public void InvalidateVisual() { }

	public bool IsLayoutDirty => mLayoutDirty;

	// === Visual children ===
	// Distinguishes logical children (the public Children list managed by
	// ViewGroup) from visual children (everything that draws, hit-tests,
	// and attaches to context — including internal views like scrollbars).
	// Base View has no visual children. ViewGroup overrides to return its
	// logical children. Controls with internal views (ScrollView, etc.)
	// override to append their auxiliary views.

	/// Number of visual children. Override in ViewGroup and controls
	/// with internal auxiliary views.
	public virtual int VisualChildCount => 0;

	/// Get a visual child by index. Override alongside VisualChildCount.
	public virtual View GetVisualChild(int index) => null;

	/// Iterate all visual children.
	public void ForEachVisualChild(delegate void(View child) action)
	{
		let count = VisualChildCount;
		for (int i = 0; i < count; i++)
		{
			let child = GetVisualChild(i);
			if (child != null)
				action(child);
		}
	}

	// === Drawing ===

	/// Override to draw this view's content.
	public virtual void OnDraw(UIDrawContext ctx) { }

	// === Hit testing ===

	/// Returns this view (or a child) at the given local-space point, or null.
	public virtual View HitTest(Vector2 localPoint)
	{
		if (!IsHitTestVisible || Visibility != .Visible)
			return null;

		if (localPoint.X >= 0 && localPoint.Y >= 0 &&
			localPoint.X < Width && localPoint.Y < Height)
			return this;

		return null;
	}

	// === Input events ===

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

	/// True if the mouse is currently over this view.
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

	// === Coordinate conversion ===

	/// Convert screen-space coordinates to this view's local coordinates.
	/// Walks up the parent chain, subtracting bounds and applying inverse
	/// RenderTransform at each level.
	public Vector2 ToLocal(Vector2 screenPoint)
	{
		var x = screenPoint.X;
		var y = screenPoint.Y;
		var v = this;
		while (v != null && v.Parent != null)
		{
			x -= v.Bounds.X;
			y -= v.Bounds.Y;

			if (v.RenderTransform != Matrix.Identity)
			{
				let ox = v.Width * v.RenderTransformOrigin.X;
				let oy = v.Height * v.RenderTransformOrigin.Y;
				Matrix invTransform;
				if (Matrix.TryInvert(v.RenderTransform, out invTransform))
				{
					let px = x - ox;
					let py = y - oy;
					x = px * invTransform.M11 + py * invTransform.M21 + invTransform.M41 + ox;
					y = px * invTransform.M12 + py * invTransform.M22 + invTransform.M42 + oy;
				}
			}

			v = v.Parent;
		}
		return .(x, y);
	}

	// === Scrolling ===

	/// Walk up to find the nearest ScrollView ancestor and scroll to make
	/// this view's bounds visible.
	public void ScrollIntoView()
	{
		var v = Parent;
		while (v != null)
		{
			if (let sv = v as ScrollView)
			{
				// Compute this view's position relative to the ScrollView.
				float relX = Bounds.X, relY = Bounds.Y;
				var p = Parent;
				while (p != null && p !== sv)
				{
					relX += p.Bounds.X;
					relY += p.Bounds.Y;
					p = p.Parent;
				}

				// Adjust scroll so this view is visible.
				if (relY < sv.ScrollY)
					sv.ScrollTo(sv.ScrollX, relY);
				else if (relY + Height > sv.ScrollY + sv.Height)
					sv.ScrollTo(sv.ScrollX, relY + Height - sv.Height);

				if (relX < sv.ScrollX)
					sv.ScrollTo(relX, sv.ScrollY);
				else if (relX + Width > sv.ScrollX + sv.Width)
					sv.ScrollTo(relX + Width - sv.Width, sv.ScrollY);

				return;
			}
			v = v.Parent;
		}
	}

	// === Deferred mutation convenience ===

	/// Queue removal from parent (deferred to next drain point).
	/// Sets IsPendingDeletion immediately.
	public void QueueRemove()
	{
		if (Context == null || IsPendingDeletion) return;
		IsPendingDeletion = true;
		Context.MutationQueue.QueueAction(new () =>
		{
			if (Parent != null)
				if (let parentGroup = Parent as ViewGroup)
					parentGroup.RemoveView(this, false);
		});
	}

	/// Queue destruction (removal + delete, deferred to next drain point).
	/// Sets IsPendingDeletion immediately.
	public void QueueDestroy()
	{
		if (Context == null || IsPendingDeletion) return;
		IsPendingDeletion = true;
		Context.MutationQueue.QueueAction(new () =>
		{
			if (Parent != null)
				if (let parentGroup = Parent as ViewGroup)
					parentGroup.RemoveView(this, true);
		});
	}

	/// Queue focus change (deferred to next drain point).
	public void QueueFocus()
	{
		if (Context == null || IsPendingDeletion) return;
		let ctx = Context;
		let viewId = Id;
		ctx.MutationQueue.QueueAction(new [&]() =>
		{
			let view = ctx.GetElementById(viewId);
			if (view != null)
				ctx.FocusManager.SetFocus(view);
		});
	}
}
