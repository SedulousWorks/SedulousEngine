namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Container view that manages a list of child views.
/// Subclasses implement OnMeasure/OnLayout to arrange children
/// (FlexLayout, GridLayout, DockLayout, etc.).
public class ViewGroup : View
{
	private List<View> mChildren = new .();

	/// Padding inside this container (space between edges and children).
	public Thickness Padding;

	/// Number of logical children.
	public int ChildCount => mChildren.Count;

	/// Gets the logical child at the given index.
	public View GetChildAt(int index) => mChildren[index];

	/// Number of visual children (logical + internal auxiliary views like scrollbars).
	/// Subclasses override to append internal views.
	public virtual int VisualChildCount => mChildren.Count;

	/// Gets a visual child at the given index.
	/// Indices 0..ChildCount-1 are logical children; beyond that are internal views.
	public virtual View GetVisualChild(int index) => (index < mChildren.Count) ? mChildren[index] : null;

	/// Adds a child view with optional layout params. Returns this for fluent chaining.
	public virtual ViewGroup AddView(View child, LayoutParams lp = null)
	{
		if (child == null || child == this || mChildren.Contains(child))
			return this;

		// Remove from previous parent
		if (child.Parent != null)
		{
			if (let oldParent = child.Parent as ViewGroup)
				oldParent.RemoveView(child, false);
		}

		if (lp != null)
		{
			delete child.LayoutParams;
			child.LayoutParams = lp;
		}
		else if (child.LayoutParams == null)
		{
			child.LayoutParams = CreateDefaultLayoutParams();
		}

		child.Parent = this;
		if (Context != null)
			Context.AttachView(child);
		else
			child.Context = null;
		mChildren.Add(child);
		Invalidate();
		return this;
	}

	/// Removes a child view. If deleteChild is true, the child is disposed and deleted.
	public void RemoveView(View child, bool deleteChild = false)
	{
		if (child == null || !mChildren.Contains(child))
			return;

		if (child.Context != null)
			child.Context.DetachView(child);
		mChildren.Remove(child);
		child.Parent = null;
		Invalidate();

		if (deleteChild)
			delete child;
	}

	/// Removes all children.
	public void RemoveAllViews(bool deleteChildren = false)
	{
		for (let child in mChildren)
		{
			if (child.Context != null)
				child.Context.DetachView(child);
			child.Parent = null;
			if (deleteChildren)
				delete child;
		}
		mChildren.Clear();
		Invalidate();
	}

	/// Inserts a child at a specific index. Used by RootView to maintain PopupLayer as last child.
	public void InsertView(View child, int index, LayoutParams lp = null)
	{
		if (child == null || child == this || mChildren.Contains(child))
			return;

		// Remove from previous parent
		if (child.Parent != null)
		{
			if (let oldParent = child.Parent as ViewGroup)
				oldParent.RemoveView(child, false);
		}

		if (lp != null)
		{
			delete child.LayoutParams;
			child.LayoutParams = lp;
		}
		else if (child.LayoutParams == null)
		{
			child.LayoutParams = CreateDefaultLayoutParams();
		}

		child.Parent = this;
		if (Context != null)
			Context.AttachView(child);
		else
			child.Context = null;

		let clampedIndex = Math.Clamp(index, 0, mChildren.Count);
		mChildren.Insert(clampedIndex, child);
		Invalidate();
	}

	/// Content bounds (after padding).
	public RectangleF ContentBounds
	{
		get => .(
			Padding.Left,
			Padding.Top,
			Math.Max(0, Width - Padding.Left - Padding.Right),
			Math.Max(0, Height - Padding.Top - Padding.Bottom)
		);
	}

	/// Creates a default LayoutParams for children added without one.
	/// Subclasses override to return their own LayoutParams type.
	protected virtual LayoutParams CreateDefaultLayoutParams()
	{
		return new LayoutParams();
	}

	/// Build child constraints from parent constraints and the child's LayoutParams SizeSpec.
	/// Accounts for used space (padding, margin, consumed space).
	///   Fixed -> tight constraint at the resolved pixel size
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

	/// Default measure: wraps to the largest child + padding.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		let inner = constraints.Deflate(Padding);
		float maxW = 0, maxH = 0;

		for (let child in mChildren)
		{
			if (child.Visibility == .Gone)
				continue;
			child.Measure(inner);
			maxW = Math.Max(maxW, child.MeasuredSize.X);
			maxH = Math.Max(maxH, child.MeasuredSize.Y);
		}

		MeasuredSize = .(
			constraints.ConstrainWidth(maxW + Padding.Left + Padding.Right),
			constraints.ConstrainHeight(maxH + Padding.Top + Padding.Bottom)
		);
	}

	/// Default draw: draws each child with bounds offset, opacity, and render transform.
	/// Uses a single PushState/PopState pair per child, matching current UI's DrawChildren pattern.
	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);
	}

	protected void DrawChildren(UIDrawContext ctx)
	{
		let count = VisualChildCount;
		for (int i = 0; i < count; i++)
		{
			let child = GetVisualChild(i);
			if (child == null || child.Visibility != .Visible)
				continue;

			// Single PushState wraps translate + transform + opacity + clip + draw.
			ctx.VG.PushState();
			ctx.VG.Translate(child.Bounds.X, child.Bounds.Y);

			// Apply view transform around the child's transform origin.
			if (!child.Transform.IsIdentity)
			{
				let ox = child.Width * child.Transform.Origin.X;
				let oy = child.Height * child.Transform.Origin.Y;

				if (child.Transform.Translation.X != 0 || child.Transform.Translation.Y != 0)
					ctx.VG.Translate(child.Transform.Translation.X, child.Transform.Translation.Y);

				if (child.Transform.Rotation != 0 || child.Transform.Scale.X != 1 || child.Transform.Scale.Y != 1)
				{
					ctx.VG.Translate(ox, oy);

					if (child.Transform.Scale.X != 1 || child.Transform.Scale.Y != 1)
						ctx.VG.Scale(child.Transform.Scale.X, child.Transform.Scale.Y);

					if (child.Transform.Rotation != 0)
						ctx.VG.Rotate(child.Transform.Rotation);

					ctx.VG.Translate(-ox, -oy);
				}
			}

			// Apply opacity.
			if (child.Opacity < 1.0f)
				ctx.VG.PushOpacity(child.Opacity);

			if (child.ClipsContent)
				ctx.PushClip(.(0, 0, child.Width, child.Height));

			child.OnDraw(ctx);

			if (ctx.DebugSettings.AnyEnabled)
				UIDebugOverlay.DrawOverlays(ctx, child);

			if (child.ClipsContent)
				ctx.PopClip();

			if (child.Opacity < 1.0f)
				ctx.VG.PopOpacity();

			ctx.VG.PopState();
		}
	}

	// === Hit testing (reverse order - topmost visual child first) ===

	public override View HitTest(Vector2 localPoint)
	{
		// IsInteractionEnabled blocks the entire subtree.
		if (!IsInteractionEnabled || Visibility != .Visible)
			return null;

		// Outside our bounds - no hit.
		if (localPoint.X < 0 || localPoint.Y < 0 ||
			localPoint.X >= Width || localPoint.Y >= Height)
			return null;

		// Test visual children in reverse order (last drawn = topmost).
		let count = VisualChildCount;
		for (int i = count - 1; i >= 0; i--)
		{
			let child = GetVisualChild(i);
			if (child == null || child.Visibility != .Visible || !child.IsInteractionEnabled)
				continue;

			// Translate point into child's local space.
			var childLocal = Vector2(localPoint.X - child.Bounds.X, localPoint.Y - child.Bounds.Y);

			// Apply inverse ViewTransform if present.
			if (!child.Transform.IsIdentity)
			{
				let ox = child.Width * child.Transform.Origin.X;
				let oy = child.Height * child.Transform.Origin.Y;

				// Undo translation.
				childLocal.X -= child.Transform.Translation.X;
				childLocal.Y -= child.Transform.Translation.Y;

				// Undo origin-relative scale and rotation.
				childLocal.X -= ox;
				childLocal.Y -= oy;

				if (child.Transform.Rotation != 0)
				{
					let cos = Math.Cos(-child.Transform.Rotation);
					let sin = Math.Sin(-child.Transform.Rotation);
					let rx = childLocal.X * cos - childLocal.Y * sin;
					let ry = childLocal.X * sin + childLocal.Y * cos;
					childLocal.X = rx;
					childLocal.Y = ry;
				}

				if (child.Transform.Scale.X != 0 && child.Transform.Scale.Y != 0)
				{
					childLocal.X /= child.Transform.Scale.X;
					childLocal.Y /= child.Transform.Scale.Y;
				}

				childLocal.X += ox;
				childLocal.Y += oy;
			}

			let hit = child.HitTest(childLocal);
			if (hit != null)
				return hit;
		}

		// No child hit - return this container if it's a hit target.
		if (!IsHitTestVisible)
			return null;

		return this;
	}

	public ~this()
	{
		// Delete all children, then the list itself.
		// DetachView must run before delete so OnViewDeleted fires
		// (clears tooltip targets, focus, shortcuts, etc.) while memory is valid.
		if (mChildren != null)
		{
			for (let child in mChildren)
			{
				if (child.Context != null)
					child.Context.DetachView(child);
				child.Parent = null;
				delete child;
			}
			delete mChildren;
		}
	}
}
