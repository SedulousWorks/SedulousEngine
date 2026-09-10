using System;
using System.Diagnostics;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.UI;

/// A view that holds children.
///
/// A child is OWNED by its parent: AddView takes the caller's reference and RemoveView drops
/// it, so dropping a group frees the subtree beneath it.
class ViewGroup : View
{
	public Thickness Padding = .();

	/// OWNED: the tree holds a reference to each child.
	private List<View> mChildren = new .() ~ ReleaseChildren(_);

	public this() {}

	public ~this()
	{
		// A destroyed group must not leave a child pointing back at it. RemoveView clears the
		// back pointer for children it detaches, but destruction just releases the array, so a
		// child still held elsewhere would keep a dangling Parent and the next AddView would
		// dereference freed memory trying to detach it from the old one.
		//
		// The context detach matters for the same reason: a still attached subtree destroyed
		// by dropping its owning reference would leave the registry and the focus and hover
		// tables holding views that have gone.
		for (let child in mChildren)
		{
			if (child == null)
				continue;
			if (child.Context != null)
				child.Context.DetachView(child);
			if (child.Parent == this)
				child.Parent = null;
		}
	}

	private static void ReleaseChildren(List<View> children)
	{
		for (let child in children)
			child.ReleaseRef();
		delete children;
	}

	public int ChildCount => mChildren.Count;
	public View GetChildAt(int index) => mChildren[index];

	/// The children this group DRAWS, which a control may make differ from the children it
	/// holds: a scroll view's scrollbars are visual children of the view, not content.
	public virtual int VisualChildCount => mChildren.Count;

	public virtual View GetVisualChild(int index) =>
		(index < mChildren.Count) ? mChildren[index] : null;

	/// The box inside the padding, in this group's own coordinates.
	public Rectangle ContentBounds => .(Padding.Left, Padding.Top,
		Max(0.0f, Width - Padding.Left - Padding.Right),
		Max(0.0f, Height - Padding.Top - Padding.Bottom));

	/// A descendant by name, searched depth first. Null when nothing matches.
	public View FindByName(StringView name)
	{
		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!child.Name.IsEmpty && (child.Name == name))
				return child;

			if (let childGroup = child as ViewGroup)
			{
				let found = childGroup.FindByName(name);
				if (found != null)
					return found;
			}
		}
		return null;
	}

	/// The same, cast to a type. Null when the name does not match or the match is not a T.
	public T FindByName<T>(StringView name) where T : View => FindByName(name) as T;

	// ---- Mutation ------------------------------------------------------------------------------

	/// Mutating the tree while it is being DRAWN corrupts the child walk in progress. Doing so
	/// during LAYOUT is legitimate, since that is where a virtualised list realises its rows.
	/// A draw phase mutation should go through the context's mutation queue.
	private void AssertNotDrawing()
	{
		Debug.Assert((Context == null) || (Context.CurrentPhase != .Drawing),
			"mutate the view tree outside the draw phase, or defer it through the mutation queue");
	}

	/// Adds a child, keeping its current layout style. CONSUMES the caller's reference.
	///
	/// REPARENTING transfers the old parent's reference instead: the caller of
	/// `newParent.AddView(existingChild)` holds nothing to give, so taking a reference across
	/// the detach is what keeps the count right. Without it the removal's release would drop
	/// the child by one, and where the old parent held the ONLY reference the child would be
	/// freed halfway through being adopted.
	public virtual ViewGroup AddView(View child)
	{
		AssertNotDrawing();
		if ((child == null) || (child == this))
			return this;
		if (mChildren.Contains(child))
			return this;

		if (let oldParent = child.Parent as ViewGroup)
		{
			child.AddRef();
			oldParent.RemoveView(child);
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

	/// Adds a child and sets its layout in one step. CONSUMES the caller's reference.
	public ViewGroup AddView(View child, LayoutStyle layout)
	{
		if (child != null)
			child.SetLayout(layout);
		return AddView(child);
	}

	/// Removes a child, releasing the tree's reference, which frees it unless something else
	/// holds one.
	public void RemoveView(View child)
	{
		AssertNotDrawing();
		if (child == null)
			return;

		for (int i < mChildren.Count)
		{
			if (mChildren[i] != child)
				continue;

			if (child.Context != null)
				child.Context.DetachView(child);
			child.Parent = null;
			mChildren.RemoveAt(i);
			Invalidate();
			// Released LAST, so the detach and the back pointer clear above run while the
			// view is certainly still alive.
			child.ReleaseRef();
			return;
		}
	}

	public void RemoveAllViews()
	{
		AssertNotDrawing();
		for (let child in mChildren)
		{
			if (child.Context != null)
				child.Context.DetachView(child);
			child.Parent = null;
			child.ReleaseRef();
		}
		mChildren.Clear();
		Invalidate();
	}

	/// CONSUMES the caller's reference. The index is clamped to the end.
	///
	/// Reparents by transferring the old parent's reference, as AddView does.
	public void InsertView(View child, int index)
	{
		AssertNotDrawing();
		if ((child == null) || (child == this))
			return;
		if (mChildren.Contains(child))
			return;

		if (let oldParent = child.Parent as ViewGroup)
		{
			child.AddRef();
			oldParent.RemoveView(child);
		}

		child.Parent = this;
		if (Context != null)
			Context.AttachView(child);
		else
			child.Context = null;

		mChildren.Insert(Math.Min(index, mChildren.Count), child);
		Invalidate();
	}

	/// CONSUMES the caller's reference.
	public void InsertView(View child, int index, LayoutStyle layout)
	{
		if (child != null)
			child.SetLayout(layout);
		InsertView(child, index);
	}

	/// Moves an EXISTING child to a new index, a pure reorder with no detach and reattach, so
	/// focus, hover and registration all survive it.
	public void MoveView(View child, int index)
	{
		if ((child == null) || mChildren.IsEmpty)
			return;

		// The order decides which child :first-child and :last-child match.
		if (Context != null)
			Context.InvalidateStyles();

		let current = mChildren.IndexOf(child);
		if (current < 0)
			return;

		let target = (index >= mChildren.Count) ? (mChildren.Count - 1) : Math.Max(index, 0);
		if (target == current)
			return;

		mChildren.RemoveAt(current);
		// Inserting at `target` AFTER the removal lands the child at exactly `target` whichever
		// direction it moved, the removal having already shifted the trailing entries.
		mChildren.Insert(target, child);
		Invalidate();
	}

	// ---- Hit testing -------------------------------------------------------------------------

	/// FRONT to back, which is the reverse of the draw order, so the child drawn last is the
	/// one the pointer finds first.
	public override View HitTest(Float2 localPoint)
	{
		if (!IsInteractionEnabled || (Visibility != .Visible))
			return null;

		if ((localPoint.X < 0) || (localPoint.Y < 0)
			|| (localPoint.X >= Width) || (localPoint.Y >= Height))
			return null;

		let order = scope List<View>();
		OrderedVisualChildren(order);
		for (int i = order.Count - 1; i >= 0; i--)
		{
			let child = order[i];
			if ((child == null) || (child.Visibility != .Visible) || !child.IsInteractionEnabled)
				continue;

			var childLocal = Float2(localPoint.X - child.Bounds.X, localPoint.Y - child.Bounds.Y);
			// The INVERSE render transform, so a transformed child is hit where it is drawn.
			// The draw path applies translate, then origin, scale, rotation, minus origin, so
			// this undoes them in the opposite order.
			if (!child.Transform.IsIdentity)
			{
				let originX = child.Width * child.Transform.Origin.X;
				let originY = child.Height * child.Transform.Origin.Y;
				childLocal.X -= child.Transform.Translation.X;
				childLocal.Y -= child.Transform.Translation.Y;
				childLocal.X -= originX;
				childLocal.Y -= originY;

				if (child.Transform.Rotation != 0.0f)
				{
					let c = Cos(-child.Transform.Rotation);
					let s = Sin(-child.Transform.Rotation);
					let rotatedX = childLocal.X * c - childLocal.Y * s;
					let rotatedY = childLocal.X * s + childLocal.Y * c;
					childLocal.X = rotatedX;
					childLocal.Y = rotatedY;
				}
				// A zero scale collapses the child to nothing, and dividing by it would put
				// the point at infinity rather than reporting a miss.
				if ((child.Transform.Scale.X != 0.0f) && (child.Transform.Scale.Y != 0.0f))
				{
					childLocal.X /= child.Transform.Scale.X;
					childLocal.Y /= child.Transform.Scale.Y;
				}
				childLocal.X += originX;
				childLocal.Y += originY;
			}

			if (let hit = child.HitTest(childLocal))
				return hit;
		}

		// The children were asked first, so a group that is not itself hit testable still lets
		// them be found: only the group's own box falls through to whatever is behind it.
		if (!IsHitTestVisible)
			return null;

		return this;
	}

	// ---- Draw --------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx) => DrawChildren(ctx);

	/// BACK to front: ascending z index, and child order within one z level.
	protected void DrawChildren(UIDrawContext ctx)
	{
		let order = scope List<View>();
		OrderedVisualChildren(order);
		for (let child in order)
		{
			if ((child == null) || (child.Visibility != .Visible))
				continue;

			// Clip culling. Under an active scissor, a scrolled list or anything inside a
			// clipping ancestor, a child whose bounds cannot meet the clip contributes
			// nothing, so its whole subtree is skipped and big scrolled content tessellates
			// its VIEWPORT rather than its row count.
			//
			// Deliberately conservative: only an identity transform, since a transform can
			// move content back into view, and only under an active clip, unclipped layers
			// keeping their freedom to draw out of bounds.
			if (child.Transform.IsIdentity && !ctx.IsRectVisible(child.Bounds))
				continue;

			ctx.VG.PushState();
			ctx.VG.Translate(child.Bounds.X, child.Bounds.Y);

			if (!child.Transform.IsIdentity)
			{
				let originX = child.Width * child.Transform.Origin.X;
				let originY = child.Height * child.Transform.Origin.Y;
				if ((child.Transform.Translation.X != 0) || (child.Transform.Translation.Y != 0))
					ctx.VG.Translate(child.Transform.Translation.X, child.Transform.Translation.Y);

				if ((child.Transform.Rotation != 0) || (child.Transform.Scale.X != 1)
					|| (child.Transform.Scale.Y != 1))
				{
					ctx.VG.Translate(originX, originY);
					if ((child.Transform.Scale.X != 1) || (child.Transform.Scale.Y != 1))
						ctx.VG.Scale(child.Transform.Scale.X, child.Transform.Scale.Y);
					if (child.Transform.Rotation != 0)
						ctx.VG.Rotate(child.Transform.Rotation);
					ctx.VG.Translate(-originX, -originY);
				}
			}

			if (child.Opacity < 1.0f)
				ctx.VG.PushOpacity(child.Opacity);

			// An OUTER box shadow sits under the child's own drawing and outside its clip; an
			// INSET one is drawn over the child, after OnDraw, inside it.
			let shadow = child.ResolveStyle(.BoxShadow).AsShadow;
			if ((shadow != null) && !shadow.Value.Inset)
				DrawBoxShadow(ctx, child, shadow.Value);

			let clips = child.EffectiveClipsContent;
			if (clips)
				ctx.PushClip(.(0, 0, child.Width, child.Height));

			let previousBlend = ctx.SetBlend(child.CurrentDrawBlend());
			child.OnDraw(ctx);
			ctx.SetBlend(previousBlend);

			if ((shadow != null) && shadow.Value.Inset)
				DrawBoxShadow(ctx, child, shadow.Value);

			if (ctx.DebugSettings.AnyEnabled)
				UIDebugOverlay.DrawOverlays(ctx, child);

			if (clips)
				ctx.PopClip();
			if (child.Opacity < 1.0f)
				ctx.VG.PopOpacity();
			ctx.VG.PopState();
		}
	}

	/// One box shadow for a child, the context already translated to the child's origin: the
	/// border box grown by the spread, moved by the offset, blurred, and rounded by the
	/// child's own corner radius plus the spread, which is what CSS does.
	private static void DrawBoxShadow(UIDrawContext ctx, View child, BoxShadow shadow)
	{
		let radius = Max(0.0f, child.ResolveStyleFloat(.CornerRadius, 0.0f));
		// An inset shadow's spread grows INWARD, so it shrinks the box rather than growing it.
		let spread = shadow.Inset ? -shadow.Spread : shadow.Spread;
		let rect = Rectangle(shadow.OffsetX - spread, shadow.OffsetY - spread,
			child.Width + 2.0f * spread, child.Height + 2.0f * spread);
		let cornerRadius = Max(0.0f, radius + spread);

		ctx.VG.FillBoxShadow(rect, CornerRadii(cornerRadius), shadow.Blur, shadow.Color,
			shadow.Inset);
	}

	/// The visual children in DRAW order: ascending z index, child order within a level.
	///
	/// Absent any non zero z index the child order is returned untouched, which is the common
	/// case and costs no sorting at all.
	protected void OrderedVisualChildren(List<View> outOrder)
	{
		let count = VisualChildCount;
		outOrder.Clear();
		var anyZ = false;
		for (int i < count)
		{
			let child = GetVisualChild(i);
			outOrder.Add(child);
			anyZ = anyZ || ((child != null) && (child.Layout.ZIndex.Value != 0));
		}

		if (!anyZ)
			return;

		// An insertion sort: sibling counts are small and the order is very nearly sorted
		// already. It is also STABLE, which is what keeps child order deciding ties.
		for (int i = 1; i < count; i++)
		{
			let view = outOrder[i];
			let z = (view != null) ? view.Layout.ZIndex.Value : 0;
			var j = i;
			while ((j > 0) && (ZIndexOf(outOrder[j - 1]) > z))
			{
				outOrder[j] = outOrder[j - 1];
				j--;
			}
			outOrder[j] = view;
		}
	}

	private static int32 ZIndexOf(View view) => (view != null) ? view.Layout.ZIndex.Value : 0;

	// ---- Measure and arrange -----------------------------------------------------------------

	/// Child constraints from the parent's available box and the child's own size spec.
	///
	/// The only decision left to the parent is whether a Match child FILLS what is available:
	/// a fixed size and the margin are already handled by the base Measure.
	protected static BoxConstraints AvailForChild(float availableWidth, float availableHeight,
		View child)
	{
		let layout = child.Layout;
		let fillWidth = layout.Width.Value.kind == .Match;
		let fillHeight = layout.Height.Value.kind == .Match;
		return .(fillWidth ? availableWidth : 0.0f, availableWidth,
			fillHeight ? availableHeight : 0.0f, availableHeight);
	}

	/// The default container measure, shaped like a frame layout: children measured loosely
	/// inside the content box and aggregated by the largest margin box.
	///
	/// The chrome comes from the MERGED metrics, so a stylesheet's padding and borders count
	/// on a plain group too rather than only on the controls that read them.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		let chrome = ResolveBoxMetrics().Chrome;
		let inner = constraints.Deflate(chrome);
		var maxWidth = 0.0f;
		var maxHeight = 0.0f;

		for (let child in mChildren)
		{
			if (!IsInFlow(child))
				continue;

			child.Measure(AvailForChild(inner.MaxWidth, inner.MaxHeight, child));
			let marginBox = child.MarginBoxSize;
			maxWidth = Max(maxWidth, marginBox.X);
			maxHeight = Max(maxHeight, marginBox.Y);
		}

		MeasuredSize = .(constraints.ConstrainWidth(maxWidth + chrome.TotalHorizontal),
			constraints.ConstrainHeight(maxHeight + chrome.TotalVertical));
	}

	/// The default container arrange: every child's margin box at the content origin.
	///
	/// The base group must POSITION the children it measures. Leaving them at the origin by
	/// omission would be a measure and arrange asymmetry, and a subclass that overrides only
	/// one of the two would inherit the mismatch.
	protected override void OnLayout(float left, float top, float width, float height)
	{
		let chrome = ResolveBoxMetrics().Chrome;
		for (let child in mChildren)
		{
			if (!IsInFlow(child))
				continue;

			let marginBox = child.MarginBoxSize;
			child.Layout(chrome.Left, chrome.Top, marginBox.X, marginBox.Y);
		}
	}

	protected override void RefreshChildEffectiveLayouts()
	{
		for (let child in mChildren)
			child.RefreshEffectiveLayout();
	}

	/// Measures the absolutely positioned children, which every container's OnMeasure skips,
	/// loosely inside the content box. Called by View.Measure after OnMeasure.
	protected override void MeasureAbsoluteChildren(float contentWidth, float contentHeight)
	{
		for (let child in mChildren)
		{
			if ((child.Visibility == .Gone) || (child.Layout.Position.Value != .Absolute))
				continue;

			let layout = child.Layout;
			// CSS shrink to fit: the available box is the content box less whatever insets are
			// declared on that axis. BOTH insets declared pins both edges, so the margin box is
			// exactly what is left between them.
			let availableWidth = Max(0.0f, contentWidth
				- (layout.Left.IsDeclared ? layout.Left.Value : 0.0f)
				- (layout.Right.IsDeclared ? layout.Right.Value : 0.0f));
			let availableHeight = Max(0.0f, contentHeight
				- (layout.Top.IsDeclared ? layout.Top.Value : 0.0f)
				- (layout.Bottom.IsDeclared ? layout.Bottom.Value : 0.0f));

			var constraints = AvailForChild(availableWidth, availableHeight, child);
			if (layout.Left.IsDeclared && layout.Right.IsDeclared)
			{
				constraints.MinWidth = availableWidth;
				constraints.MaxWidth = availableWidth;
			}
			if (layout.Top.IsDeclared && layout.Bottom.IsDeclared)
			{
				constraints.MinHeight = availableHeight;
				constraints.MaxHeight = availableHeight;
			}

			child.Measure(constraints);
		}
	}

	/// Places the absolutely positioned children against the content box from their insets:
	/// Left and Top, or Right and Bottom anchoring the far edge. An undeclared inset is nought
	/// from the NEAR edge. Called by View.Layout after OnLayout.
	protected override void LayoutAbsoluteChildren()
	{
		let chrome = ResolveBoxMetrics().Chrome;
		let contentWidth = Max(0.0f, Width - chrome.TotalHorizontal);
		let contentHeight = Max(0.0f, Height - chrome.TotalVertical);

		for (let child in mChildren)
		{
			if ((child.Visibility == .Gone) || (child.Layout.Position.Value != .Absolute))
				continue;

			let layout = child.Layout;
			let marginBox = child.MarginBoxSize;
			var x = layout.Left.Value;
			var y = layout.Top.Value;
			if (!layout.Left.IsDeclared && layout.Right.IsDeclared)
				x = contentWidth - layout.Right.Value - marginBox.X;
			if (!layout.Top.IsDeclared && layout.Bottom.IsDeclared)
				y = contentHeight - layout.Bottom.Value - marginBox.Y;

			child.Layout(chrome.Left + x, chrome.Top + y, marginBox.X, marginBox.Y);
		}
	}

	protected override Thickness OwnPaddingField() => Padding;
}
