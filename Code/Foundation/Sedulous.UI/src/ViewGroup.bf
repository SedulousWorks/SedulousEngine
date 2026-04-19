namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

/// A View that holds children. Layout strategy is determined by concrete
/// subclasses (LinearLayout, FrameLayout, GridLayout, etc.).
public class ViewGroup : View
{
	private List<View> mChildren = new .() ~ {
		for (let child in _) delete child;
		delete _;
	};

	public Thickness Padding;

	public int ChildCount => mChildren.Count;

	public View GetChildAt(int index) => mChildren[index];

	// Visual children = logical children by default.
	// Subclasses with internal views (ScrollView, etc.) override to append them.
	public override int VisualChildCount => mChildren.Count;
	public override View GetVisualChild(int index) => mChildren[index];

	/// Add a child with optional layout params. If lp is null,
	/// CreateDefaultLayoutParams() provides the default for this ViewGroup.
	public virtual void AddView(View child, LayoutParams lp = null)
	{
		if (child.Parent != null)
			if (let parentGroup = child.Parent as ViewGroup)
				parentGroup.RemoveChildInternal(child, false);

		child.Parent = this;

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

		if (Context != null)
			AttachSubtree(child, Context);

		InvalidateLayout();
	}

	/// Insert a child at a specific index. Used by RootView to keep
	/// PopupLayer as the last child.
	public void InsertView(View child, int index, LayoutParams lp = null)
	{
		if (child.Parent != null)
			if (let parentGroup = child.Parent as ViewGroup)
				parentGroup.RemoveChildInternal(child, false);

		child.Parent = this;

		if (lp != null)
		{
			delete child.LayoutParams;
			child.LayoutParams = lp;
		}
		else if (child.LayoutParams == null)
		{
			child.LayoutParams = CreateDefaultLayoutParams();
		}

		let clampedIndex = Math.Min(index, mChildren.Count);
		mChildren.Insert(clampedIndex, child);

		if (Context != null)
			AttachSubtree(child, Context);

		InvalidateLayout();
	}

	/// Override to intercept mouse events before they reach children.
	/// Return true to consume the event (children won't receive it).
	/// Used by ScrollView to initiate drag-to-scroll.
	public virtual bool OnInterceptMouseEvent(MouseEventArgs e) => false;

	/// Remove a child. If dispose is true (default), the child is deleted.
	public virtual void RemoveView(View child, bool dispose = true)
	{
		RemoveChildInternal(child, dispose);
	}

	/// Detach a child without deleting it. Equivalent to RemoveView(child, false).
	/// Used by docking system when moving views between parents.
	public void DetachView(View child)
	{
		RemoveChildInternal(child, false);
	}

	/// Remove and delete all children.
	public void RemoveAllViews()
	{
		while (mChildren.Count > 0)
		{
			let child = mChildren[mChildren.Count - 1];
			RemoveChildInternal(child, true);
		}
	}

	private void RemoveChildInternal(View child, bool dispose)
	{
		let idx = mChildren.IndexOf(child);
		if (idx < 0) return;

		if (Context != null)
			DetachSubtree(child);

		child.Parent = null;
		mChildren.RemoveAt(idx);

		if (dispose)
			delete child;

		InvalidateLayout();
	}

	/// Override to provide the correct LayoutParams subclass for this ViewGroup.
	public virtual LayoutParams CreateDefaultLayoutParams()
	{
		return new LayoutParams();
	}

	// === Measure / Layout default ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		// Default: wrap to content (max of children)
		float maxW = 0, maxH = 0;
		for (let child in mChildren)
		{
			if (child.Visibility == .Gone) continue;
			child.Measure(wSpec, hSpec);
			maxW = Math.Max(maxW, child.MeasuredSize.X);
			maxH = Math.Max(maxH, child.MeasuredSize.Y);
		}
		MeasuredSize = .(wSpec.Resolve(maxW + Padding.TotalHorizontal),
						 hSpec.Resolve(maxH + Padding.TotalVertical));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		// Default: just draw children in order. Subclasses can override
		// to draw a background before children.
		DrawChildren(ctx);
	}

	protected void DrawChildren(UIDrawContext ctx)
	{
		// Iterate visual children (includes internal auxiliary views like scrollbars).
		let count = VisualChildCount;
		for (int i = 0; i < count; i++)
		{
			let child = GetVisualChild(i);
			if (child == null || child.Visibility != .Visible)
				continue;

			// Translate to child's local coordinate space.
			ctx.VG.PushState();
			ctx.VG.Translate(child.Bounds.X, child.Bounds.Y);

			// Apply render transform around the child's transform origin.
			if (child.RenderTransform != Matrix.Identity)
			{
				let ox = child.Width * child.RenderTransformOrigin.X;
				let oy = child.Height * child.RenderTransformOrigin.Y;
				ctx.VG.Translate(ox, oy);
				let current = ctx.VG.GetTransform();
				ctx.VG.SetTransform(child.RenderTransform * current);
				ctx.VG.Translate(-ox, -oy);
			}

			// Apply alpha opacity.
			if (child.Alpha < 1.0f)
				ctx.VG.PushOpacity(child.Alpha);

			if (child.ClipsContent)
				ctx.PushClip(.(0, 0, child.Width, child.Height));

			child.OnDraw(ctx);

			if (ctx.DebugSettings.AnyEnabled)
				UIDebugOverlay.DrawOverlays(ctx, child);

			if (child.ClipsContent)
				ctx.PopClip();

			if (child.Alpha < 1.0f)
				ctx.VG.PopOpacity();

			ctx.VG.PopState();
		}
	}

	// === Hit testing (reverse order — topmost visual child first, matching draw order) ===

	public override View HitTest(Vector2 localPoint)
	{
		// IsInteractionEnabled blocks the entire subtree (like disabling a panel).
		if (!IsInteractionEnabled || Visibility != .Visible)
			return null;

		if (localPoint.X < 0 || localPoint.Y < 0 ||
			localPoint.X >= Width || localPoint.Y >= Height)
			return null;

		// Always test children — even if this container isn't a hit target.
		let count = VisualChildCount;
		for (int i = count - 1; i >= 0; i--)
		{
			let child = GetVisualChild(i);
			if (child == null || child.Visibility != .Visible || !child.IsInteractionEnabled)
				continue;

			// Translate point into child's local space.
			var childLocal = Vector2(localPoint.X - child.Bounds.X, localPoint.Y - child.Bounds.Y);

			// Apply inverse RenderTransform if the child has one.
			if (child.RenderTransform != Matrix.Identity)
			{
				let ox = child.Width * child.RenderTransformOrigin.X;
				let oy = child.Height * child.RenderTransformOrigin.Y;

				// The draw transform is: translate(ox,oy) * RenderTransform * translate(-ox,-oy)
				// Inverse: translate(ox,oy) * inverse(RenderTransform) * translate(-ox,-oy)
				Matrix invTransform;
				if (Matrix.TryInvert(child.RenderTransform, out invTransform))
				{
					// Shift to origin, apply inverse, shift back.
					let px = childLocal.X - ox;
					let py = childLocal.Y - oy;
					childLocal.X = px * invTransform.M11 + py * invTransform.M21 + invTransform.M41 + ox;
					childLocal.Y = px * invTransform.M12 + py * invTransform.M22 + invTransform.M42 + oy;
				}
			}

			let hit = child.HitTest(childLocal);
			if (hit != null)
				return hit;
		}

		// IsHitTestVisible gates only this view — children were already tested above.
		return IsHitTestVisible ? this : null;
	}

	// === Layout helpers ===

	/// Measure a child using this ViewGroup's constraints and padding.
	protected void MeasureChild(View child, MeasureSpec parentWSpec, MeasureSpec parentHSpec)
	{
		let lp = child.LayoutParams ?? CreateDefaultLayoutParams();
		let childW = MakeChildMeasureSpec(parentWSpec, Padding.TotalHorizontal, lp.Width);
		let childH = MakeChildMeasureSpec(parentHSpec, Padding.TotalVertical, lp.Height);
		child.Measure(childW, childH);
	}

	/// Measure a child accounting for used space (margins + already-consumed space).
	protected void MeasureChildWithMargins(View child, MeasureSpec parentWSpec, float usedW, MeasureSpec parentHSpec, float usedH)
	{
		let lp = child.LayoutParams ?? CreateDefaultLayoutParams();
		let childW = MakeChildMeasureSpec(parentWSpec, Padding.TotalHorizontal + lp.Margin.TotalHorizontal + usedW, lp.Width);
		let childH = MakeChildMeasureSpec(parentHSpec, Padding.TotalVertical + lp.Margin.TotalVertical + usedH, lp.Height);
		child.Measure(childW, childH);
	}

	// === Layout utility ===

	/// Build a child MeasureSpec from the parent spec, used space, and
	/// LayoutParams size. Shared by all layout subclasses.
	protected static MeasureSpec MakeChildMeasureSpec(MeasureSpec parentSpec, float used, float childSize)
	{
		let available = Math.Max(0, parentSpec.Size - used);

		if (childSize >= 0) // exact pixel size
			return .Exactly(childSize);

		if (childSize == Sedulous.UI.LayoutParams.MatchParent)
		{
			switch (parentSpec.Mode)
			{
			case .Exactly:     return .Exactly(available);
			case .AtMost:      return .AtMost(available);
			case .Unspecified: return .Unspecified();
			}
		}

		// WrapContent
		switch (parentSpec.Mode)
		{
		case .Exactly, .AtMost: return .AtMost(available);
		case .Unspecified:       return .Unspecified();
		}
	}

	// === Context attachment propagation ===

	public override void OnAttachedToContext(UIContext ctx)
	{
		base.OnAttachedToContext(ctx);
		// Attach all visual children (includes logical + internal auxiliary views).
		let count = VisualChildCount;
		for (int i = 0; i < count; i++)
		{
			let child = GetVisualChild(i);
			if (child != null)
				AttachSubtree(child, ctx);
		}
	}

	public override void OnDetachedFromContext()
	{
		let count = VisualChildCount;
		for (int i = 0; i < count; i++)
		{
			let child = GetVisualChild(i);
			if (child != null)
				DetachSubtree(child);
		}
		base.OnDetachedFromContext();
	}

	internal static void AttachSubtree(View view, UIContext ctx)
	{
		view.Context = ctx;

		// Find owning RootView by walking up the parent chain.
		var v = view;
		while (v != null)
		{
			if (let root = v as RootView)
			{
				view.Root = root;
				break;
			}
			v = v.Parent;
		}

		ctx.RegisterElement(view);
		view.OnAttachedToContext(ctx);
	}

	internal static void DetachSubtree(View view)
	{
		let ctx = view.Context;
		view.OnDetachedFromContext();
		if (ctx != null)
			ctx.UnregisterElement(view);
		view.Context = null;
		view.Root = null;
	}
}
