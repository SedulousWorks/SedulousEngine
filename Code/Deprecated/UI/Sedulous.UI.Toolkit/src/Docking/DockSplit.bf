using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A binary split in the dock tree: two children with a draggable divider between them.
///
/// Distinct from [[SplitView]] because a dock split is a TREE NODE. It is created and destroyed
/// by the manager as panels come and go, it has no collapse, and its divider drag is the only
/// interaction it offers.
///
/// The ratio is clamped away from both ends, so a divider dragged to the edge still leaves a
/// sliver of the other pane to drag back by. A pane at exactly nought would be unrecoverable.
class DockSplit : ViewGroup
{
	/// QUALIFIED at every use: this field's name shadows the enum type inside the class.
	private Sedulous.UI.Orientation mOrientation = .Horizontal;
	private float mSplitRatio = 0.5f;
	private float mDividerSize = 4.0f;
	private float mMinPaneSize = 50.0f;
	private bool mIsDragging = false;
	private bool mIsDividerHovered = false;

	public this() {}

	public this(Sedulous.UI.Orientation orientation)
	{
		mOrientation = orientation;
	}

	public Sedulous.UI.Orientation Orientation
	{
		get => mOrientation;
		set
		{
			mOrientation = value;
			Invalidate();
		}
	}

	public float SplitRatio
	{
		get => mSplitRatio;
		set
		{
			mSplitRatio = Clamp(value, 0.05f, 0.95f);
			Invalidate();
		}
	}

	public float DividerSize
	{
		get => mDividerSize;
		set
		{
			mDividerSize = Max(2.0f, value);
			Invalidate();
		}
	}

	public float MinPaneSize
	{
		get => mMinPaneSize;
		set => mMinPaneSize = Max(10.0f, value);
	}

	/// BORROWED. Left or top.
	public View First => (ChildCount > 0) ? GetChildAt(0) : null;

	/// BORROWED. Right or bottom.
	public View Second => (ChildCount > 1) ? GetChildAt(1) : null;

	/// Replaces both children. CONSUMES the caller's references.
	public void SetChildren(View first, View second)
	{
		RemoveAllViews();

		if (first != null)
			AddView(first);
		if (second != null)
			AddView(second);

		Invalidate();
	}

	// ---- Drawing --------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);

		// The divider takes the ACCENT while it is being used, so a drag is visible even when
		// the panes either side are empty.
		ctx.VG.FillRect(DividerRect, (mIsDragging || mIsDividerHovered)
			? ResolveStyleColor(.AccentColor, Color.Rgb(80, 150, 240))
			: ResolveStyleColor(.BorderColor, Color.Rgb(65, 70, 85)));
	}

	// ---- Input ----------------------------------------------------------------------------------

	/// The divider is tested BEFORE the children, because it sits between them and a child's own
	/// bounds may reach under it.
	public override View HitTest(Float2 localPoint)
	{
		if (!IsInteractionEnabled || (Visibility != .Visible))
			return null;

		if ((localPoint.X < 0) || (localPoint.Y < 0) || (localPoint.X >= Width)
			|| (localPoint.Y >= Height))
			return null;

		if (DividerRect.Contains(localPoint))
			return this;

		// Reverse order, so the later child wins where they overlap.
		if (let second = Second)
		{
			if (let hit = second.HitTest(.(localPoint.X - second.Bounds.X,
				localPoint.Y - second.Bounds.Y)))
				return hit;
		}

		if (let first = First)
		{
			if (let hit = first.HitTest(.(localPoint.X - first.Bounds.X,
				localPoint.Y - first.Bounds.Y)))
				return hit;
		}

		return this;
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled() || (e.Button != .Left))
			return;

		if (!DividerRect.Contains(.(e.X, e.Y)))
			return;

		mIsDragging = true;
		// CAPTURED, because the divider moves to follow the pointer and would otherwise slide
		// out from under it on the first frame.
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);

		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mIsDragging)
		{
			UpdateSplitFromMouse(e.X, e.Y);
			return;
		}

		let overDivider = DividerRect.Contains(.(e.X, e.Y));
		if (overDivider == mIsDividerHovered)
			return;

		mIsDividerHovered = overDivider;
		Cursor = overDivider ? ((mOrientation == .Horizontal) ? .SizeWE : .SizeNS) : .Default;
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (!mIsDragging || (e.Button != .Left))
			return;

		mIsDragging = false;
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();

		e.Handled = true;
	}

	public override void OnMouseLeave()
	{
		if (!mIsDividerHovered)
			return;

		mIsDividerHovered = false;
		Cursor = .Default;
	}

	// ---- Layout ---------------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let width = constraints.ConstrainWidth(200);
		let height = constraints.ConstrainHeight(200);
		MeasureChildren(width, height);
		MeasuredSize = .(width, height);
	}

	private void MeasureChildren(float width, float height)
	{
		let horizontal = mOrientation == .Horizontal;
		let available = (horizontal ? width : height) - mDividerSize;
		let firstSize = available * mSplitRatio;
		let secondSize = available - firstSize;

		if (let first = First)
			first.Measure(horizontal ? BoxConstraints.Tight(firstSize, height)
				: BoxConstraints.Tight(width, firstSize));

		if (let second = Second)
			second.Measure(horizontal ? BoxConstraints.Tight(secondSize, height)
				: BoxConstraints.Tight(width, secondSize));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let horizontal = mOrientation == .Horizontal;
		let available = (horizontal ? width : height) - mDividerSize;
		let firstSize = available * mSplitRatio;
		let secondSize = available - firstSize;

		if (let first = First)
			first.Layout(0, 0, horizontal ? firstSize : width, horizontal ? height : firstSize);

		if (let second = Second)
		{
			let offset = firstSize + mDividerSize;
			second.Layout(horizontal ? offset : 0, horizontal ? 0 : offset,
				horizontal ? secondSize : width, horizontal ? height : secondSize);
		}
	}

	// ---- Internals ------------------------------------------------------------------------------

	private Rectangle DividerRect
	{
		get
		{
			if (mOrientation == .Horizontal)
			{
				let available = Width - mDividerSize;
				return .(available * mSplitRatio, 0, mDividerSize, Height);
			}

			let available = Height - mDividerSize;
			return .(0, available * mSplitRatio, Width, mDividerSize);
		}
	}

	private void UpdateSplitFromMouse(float localX, float localY)
	{
		let horizontal = mOrientation == .Horizontal;
		let available = (horizontal ? Width : Height) - mDividerSize;
		if (available <= 0.0f)
			return;

		// Measured to the divider's MIDDLE, so the divider stays centred under the pointer
		// rather than jumping half its width on grab.
		SplitRatio = ((horizontal ? localX : localY) - (mDividerSize * 0.5f)) / available;
	}
}
