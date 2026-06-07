namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Container view that manages a list of child views. Provides padding,
/// child add/remove/insert, and default measure/layout/hit-test behavior.
public class ViewGroup : View
{
	private List<View> mChildren = new .() ~ delete _;

	// === Padding ===

	public Property<Thickness> Padding = new .(.()) ~ delete _;

	protected override void InitializePropertyOwners()
	{
		base.InitializePropertyOwners();
		Padding.SetOwner(this);
	}

	/// Bounds after subtracting padding.
	public RectangleF ContentBounds
	{
		get
		{
			let p = Padding.Value;
			return .(
				p.Left, p.Top,
				Math.Max(0, Width - p.TotalHorizontal),
				Math.Max(0, Height - p.TotalVertical)
			);
		}
	}

	// === Child management ===

	public int ChildCount => mChildren.Count;

	public View GetChildAt(int index) => mChildren[index];

	/// Override to include non-logical visual children (e.g. scrollbars).
	public virtual int VisualChildCount => mChildren.Count;

	/// Override to return non-logical visual children.
	public virtual View GetVisualChild(int index) => mChildren[index];

	/// Adds a child view with optional layout params. Returns this for chaining.
	public virtual ViewGroup AddView(View child, LayoutParams lp = null)
	{
		// Remove from previous parent if any.
		if (child.[Friend]mParent != null)
		{
			if (let prevParent = child.[Friend]mParent as ViewGroup)
				prevParent.RemoveView(child, false);
		}

		child.[Friend]mParent = this;
		if (lp != null)
		{
			delete child.LayoutParams;
			child.LayoutParams = lp;
		}
		mChildren.Add(child);

		// Propagate context.
		if (Context != null)
			Context.AttachView(child);

		InvalidateLayout();
		return this;
	}

	/// Removes a child view, optionally deleting it.
	public void RemoveView(View child, bool deleteChild = false)
	{
		let index = mChildren.IndexOf(child);
		if (index < 0) return;

		if (Context != null)
			Context.DetachView(child);

		child.[Friend]mParent = null;
		mChildren.RemoveAt(index);

		InvalidateLayout();

		if (deleteChild)
			delete child;
	}

	/// Removes all children, optionally deleting them.
	public void RemoveAllViews(bool deleteChildren = false)
	{
		for (let child in mChildren)
		{
			if (Context != null)
				Context.DetachView(child);

			child.[Friend]mParent = null;

			if (deleteChildren)
				delete child;
		}
		mChildren.Clear();
		InvalidateLayout();
	}

	/// Inserts a child at a specific index.
	public void InsertView(View child, int index, LayoutParams lp = null)
	{
		if (child.[Friend]mParent != null)
		{
			if (let prevParent = child.[Friend]mParent as ViewGroup)
				prevParent.RemoveView(child, false);
		}

		child.[Friend]mParent = this;
		if (lp != null)
		{
			delete child.LayoutParams;
			child.LayoutParams = lp;
		}
		mChildren.Insert(index, child);

		if (Context != null)
			Context.AttachView(child);

		InvalidateLayout();
	}

	/// Creates default layout params for children that don't have any.
	/// Override in layout subclasses to return their specific LayoutParams type.
	public virtual LayoutParams CreateDefaultLayoutParams()
	{
		return new LayoutParams();
	}

	// === Measurement ===

	/// Default: wraps to largest child + padding.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		let p = Padding.Value;
		let inner = constraints.Deflate(p);

		float maxW = 0, maxH = 0;
		for (int i = 0; i < ChildCount; i++)
		{
			let child = mChildren[i];
			if (child.Visibility.Value == .Gone) continue;

			child.Measure(inner);
			maxW = Math.Max(maxW, child.MeasuredSize.X);
			maxH = Math.Max(maxH, child.MeasuredSize.Y);
		}

		MeasuredSize = .(
			constraints.ConstrainWidth(maxW + p.TotalHorizontal),
			constraints.ConstrainHeight(maxH + p.TotalVertical)
		);
	}

	// === Hit testing ===

	/// Tests children in reverse draw order (topmost first), then self.
	public override View HitTest(Vector2 localPoint)
	{
		if (!IsInteractionEnabled.Value || Visibility.Value != .Visible)
			return null;

		if (localPoint.X < 0 || localPoint.Y < 0 ||
			localPoint.X >= Width || localPoint.Y >= Height)
			return null;

		// Test visual children in reverse order.
		for (int i = VisualChildCount - 1; i >= 0; i--)
		{
			let child = GetVisualChild(i);
			if (child == null || !child.IsInteractionEnabled.Value || child.Visibility.Value != .Visible)
				continue;

			var childLocal = Vector2(localPoint.X - child.Bounds.X, localPoint.Y - child.Bounds.Y);

			// Apply inverse ViewTransform if present.
			if (!child.Transform.Value.IsIdentity)
			{
				let t = child.Transform.Value;
				childLocal.X -= t.Translation.X;
				childLocal.Y -= t.Translation.Y;
				// TODO: full inverse rotation/scale for non-trivial transforms.
			}

			let hit = child.HitTest(childLocal);
			if (hit != null) return hit;
		}

		if (!IsHitTestVisible.Value)
			return null;

		return this;
	}

	// === Drawing ===

	/// Draws all visual children with transform, opacity, and clipping.
	protected void DrawChildren(/*UIDrawContext ctx*/)
	{
		for (int i = 0; i < VisualChildCount; i++)
		{
			let child = GetVisualChild(i);
			if (child == null || child.Visibility.Value != .Visible)
				continue;

			// TODO: PushState, translate, apply transform, opacity, clip, draw, PopState.
			// Requires UIDrawContext (Phase C).
			child.OnDraw();
		}
	}

	// === Destructor ===

	public ~this()
	{
		for (let child in mChildren)
		{
			child.[Friend]mParent = null;
			delete child;
		}
	}
}
