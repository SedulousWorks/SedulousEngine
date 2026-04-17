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

	// === Context attachment ===
	public UIContext Context { get; internal set; }
	public bool IsPendingDeletion { get; internal set; }
	public bool IsAttached => Context != null;

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

	// === Input stubs (wired up in Phase 3) ===

	public virtual void OnMouseDown(/*MouseEventArgs e*/) { }
	public virtual void OnMouseUp(/*MouseEventArgs e*/) { }
	public virtual void OnMouseMove(/*MouseEventArgs e*/) { }
	public virtual void OnKeyDown(/*KeyEventArgs e*/) { }

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
}
