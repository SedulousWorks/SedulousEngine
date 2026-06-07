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
		else if (child.LayoutParams == null)
		{
			child.LayoutParams = CreateDefaultLayoutParams();
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
		else if (child.LayoutParams == null)
		{
			child.LayoutParams = CreateDefaultLayoutParams();
		}
		mChildren.Insert(index, child);

		if (Context != null)
			Context.AttachView(child);

		InvalidateLayout();
	}

	/// Creates default layout params for children that don't have any.
	/// Override in layout subclasses to return their specific LayoutParams type.
	protected virtual LayoutParams CreateDefaultLayoutParams()
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

	/// Builds child constraints from parent constraints + child's LayoutParams.
	///   Fixed -> tight constraint at resolved unit value
	///   Match -> tight constraint at available space
	///   Wrap  -> loose constraint (min=0, max=available)
	protected static BoxConstraints MakeChildConstraints(BoxConstraints parent, View child, float usedW = 0, float usedH = 0)
	{
		let lp = child.LayoutParams;
		let margin = (lp != null) ? lp.Margin : Thickness();
		let dpiScale = child.Root?.DpiScale ?? 1.0f;

		let availW = Math.Max(0, parent.MaxWidth - usedW - margin.TotalHorizontal);
		let availH = Math.Max(0, parent.MaxHeight - usedH - margin.TotalVertical);

		let widthSpec = (lp != null) ? lp.Width : SizeSpec.Wrap;
		let heightSpec = (lp != null) ? lp.Height : SizeSpec.Wrap;

		float minW, maxW, minH, maxH;

		switch (widthSpec)
		{
		case .Fixed(let unit):
			let w = unit.Resolve(dpiScale);
			minW = w; maxW = w;
		case .Match:
			minW = availW; maxW = availW;
		case .Wrap:
			minW = 0; maxW = availW;
		}

		switch (heightSpec)
		{
		case .Fixed(let unit):
			let h = unit.Resolve(dpiScale);
			minH = h; maxH = h;
		case .Match:
			minH = availH; maxH = availH;
		case .Wrap:
			minH = 0; maxH = availH;
		}

		return BoxConstraints(minW, maxW, minH, maxH);
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
	protected void DrawChildren(UIDrawContext ctx)
	{
		for (int i = 0; i < VisualChildCount; i++)
		{
			let child = GetVisualChild(i);
			if (child == null || child.Visibility.Value != .Visible)
				continue;

			ctx.VG.PushState();
			ctx.VG.Translate(child.Bounds.X, child.Bounds.Y);

			if (!child.Transform.Value.IsIdentity)
			{
				let t = child.Transform.Value;
				let ox = child.Width * t.Origin.X;
				let oy = child.Height * t.Origin.Y;
				ctx.VG.Translate(ox + t.Translation.X, oy + t.Translation.Y);
				ctx.VG.Scale(t.Scale.X, t.Scale.Y);
				ctx.VG.Rotate(t.Rotation);
				ctx.VG.Translate(-ox, -oy);
			}

			if (child.Opacity.Value < 1.0f)
				ctx.VG.PushOpacity(child.Opacity.Value);

			if (child.ClipsContent.Value)
				ctx.PushClip(.(0, 0, child.Width, child.Height));

			child.OnDraw(ctx);

			if (child.ClipsContent.Value)
				ctx.PopClip();
			if (child.Opacity.Value < 1.0f)
				ctx.VG.PopOpacity();

			ctx.VG.PopState();
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
