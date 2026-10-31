using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// Two panes with a draggable divider between them.
///
/// The split is a RATIO rather than a pixel offset, so the panes keep their proportions when
/// the window resizes. Both panes are held to a minimum while dragging, unless the view is too
/// small to honour both, in which case the ratio is free and the minimums simply cannot apply.
class SplitView : ViewGroup
{
	/// QUALIFIED at every use: this field's name shadows the enum type inside the class.
	public Sedulous.UI.Orientation Orientation = .Horizontal;
	public float MinPaneSize = 50.0f;
	/// The thickness of the draggable strip, which is also its hit area.
	public float DividerSize = 6.0f;

	public Event<delegate void(SplitView, float)> OnSplitChanged ~ _.Dispose();

	/// BORROWED: the child list owns the panes.
	private View mFirst = null;
	private View mSecond = null;

	private float mSplitRatio = 0.5f;
	private bool mDragging = false;
	private bool mDividerHovered = false;
	private bool mFirstCollapsed = false;
	private bool mSecondCollapsed = false;

	public this() {}

	public this(Sedulous.UI.Orientation orientation)
	{
		Orientation = orientation;
	}

	/// Where the divider sits, 0 to 1. Nought collapses the first pane, one the second.
	public float SplitRatio
	{
		get => mSplitRatio;
		set
		{
			let clamped = Clamp(value, 0.0f, 1.0f);
			if (mSplitRatio == clamped)
				return;

			mSplitRatio = clamped;
			Invalidate();
			OnSplitChanged(this, clamped);
		}
	}

	/// Replaces both panes. CONSUMES the caller's references; the previous panes are released.
	public void SetPanes(View first, View second)
	{
		if (mFirst != null)
			RemoveView(mFirst);
		if (mSecond != null)
			RemoveView(mSecond);

		mFirst = first;
		mSecond = second;

		if (first != null)
			AddView(first);
		if (second != null)
			AddView(second);

		Invalidate();
	}

	public View FirstPane => mFirst;
	public View SecondPane => mSecond;

	/// Collapses a pane to its content's own minimum along the split axis: the other pane takes
	/// the rest, and the divider disappears because there is nothing left to drag.
	///
	/// LAYOUT ONLY. The pane is never reparented or destroyed, so a borrowed pointer to it
	/// stays good, and the stored ratio is untouched so expanding again restores the size the
	/// user chose rather than a default.
	public void SetPaneCollapsed(SplitPane pane, bool collapsed)
	{
		if (pane == .First)
		{
			if (mFirstCollapsed == collapsed)
				return;
			mFirstCollapsed = collapsed;
		}
		else
		{
			if (mSecondCollapsed == collapsed)
				return;
			mSecondCollapsed = collapsed;
		}

		Invalidate();
	}

	public bool IsPaneCollapsed(SplitPane pane) =>
		(pane == .First) ? mFirstCollapsed : mSecondCollapsed;

	public bool AnyPaneCollapsed => mFirstCollapsed || mSecondCollapsed;

	// ---- Drawing --------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);

		if (AnyPaneCollapsed)
			return; // nothing to drag, so nothing to draw

		let dividerRect = GetDividerRect();
		let dividerColor = (mDividerHovered || mDragging)
			? ResolveStyleColor(.AccentColor, Color.Rgb(80, 85, 105))
			: ResolveStyleColor(.BorderColor, Color.Rgb(55, 58, 70));
		ctx.VG.FillRect(dividerRect, dividerColor);

		// A row of dots across the middle, which is what marks the divider as draggable rather
		// than as a border.
		let gripColor = ResolveStyleColor(.TextDimColor, .(100 / 255.0f, 105 / 255.0f,
			120 / 255.0f, 180 / 255.0f));
		let center = dividerRect.Center();
		let dotRadius = 1.5f;

		for (int32 i = -2; i <= 2; i++)
		{
			if (Orientation == .Horizontal)
				ctx.VG.FillCircle(.(center.X, center.Y + (i * 5.0f)), dotRadius, gripColor);
			else
				ctx.VG.FillCircle(.(center.X + (i * 5.0f), center.Y), dotRadius, gripColor);
		}
	}

	// ---- Input ----------------------------------------------------------------------------------

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled() || (e.Button != .Left))
			return;

		if (!IsInDivider(e.X, e.Y))
			return;

		mDragging = true;
		// CAPTURED so the drag survives the pointer leaving the divider, which it does
		// immediately, since the divider moves to follow it.
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDragging)
		{
			DragTo(e);
			return;
		}

		let wasHovered = mDividerHovered;
		mDividerHovered = IsInDivider(e.X, e.Y);
		if (mDividerHovered == wasHovered)
			return;

		if (mDividerHovered)
			Cursor = (Orientation == .Horizontal) ? .SizeWE : .SizeNS;
		else
			Cursor = .Default;
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if ((e.Button != .Left) || !mDragging)
			return;

		mDragging = false;
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();
		e.Handled = true;
	}

	public override void OnMouseLeave()
	{
		mDividerHovered = false;
		if (!mDragging)
			Cursor = .Default;
	}

	private void DragTo(MouseEventArgs e)
	{
		let extent = (Orientation == .Horizontal) ? Width : Height;
		let position = (Orientation == .Horizontal) ? e.X : e.Y;
		let available = extent - DividerSize;
		if (available <= 0.0f)
			return;

		// The minimums only apply where BOTH can be honoured; below that the view is too small
		// for them to mean anything and clamping to them would pin the divider.
		let roomy = available > (MinPaneSize * 2.0f);
		let minRatio = roomy ? (MinPaneSize / available) : 0.0f;
		let maxRatio = roomy ? (1.0f - (MinPaneSize / available)) : 1.0f;

		SplitRatio = Clamp((position - (DividerSize * 0.5f)) / available, minRatio, maxRatio);
	}

	// ---- Layout ---------------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// A split view FILLS its parent: the panes divide what it is given, so asking for the
		// children's extent would make the ratio meaningless.
		MeasuredSize = .(constraints.MaxWidth, constraints.MaxHeight);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (AnyPaneCollapsed)
		{
			LayoutCollapsed(width, height);
			return;
		}

		let available = ((Orientation == .Horizontal) ? width : height) - DividerSize;
		var firstSize = available * mSplitRatio;
		var secondSize = available - firstSize;

		// The same "only where both fit" rule the drag uses.
		if (available > (MinPaneSize * 2.0f))
		{
			if (firstSize < MinPaneSize)
			{
				firstSize = MinPaneSize;
				secondSize = available - firstSize;
			}
			if (secondSize < MinPaneSize)
			{
				secondSize = MinPaneSize;
				firstSize = available - secondSize;
			}
		}

		if (Orientation == .Horizontal)
		{
			if (mFirst != null)
			{
				mFirst.Measure(BoxConstraints.Tight(firstSize, height));
				mFirst.Layout(0, 0, firstSize, height);
			}
			if (mSecond != null)
			{
				mSecond.Measure(BoxConstraints.Tight(secondSize, height));
				mSecond.Layout(firstSize + DividerSize, 0, secondSize, height);
			}
		}
		else
		{
			if (mFirst != null)
			{
				mFirst.Measure(BoxConstraints.Tight(width, firstSize));
				mFirst.Layout(0, 0, width, firstSize);
			}
			if (mSecond != null)
			{
				mSecond.Measure(BoxConstraints.Tight(width, secondSize));
				mSecond.Layout(0, firstSize + DividerSize, width, secondSize);
			}
		}
	}

	/// One pane at its content's minimum, the other taking everything else, and NO divider space
	/// reserved. The stored ratio is left alone, so un-collapsing restores it.
	private void LayoutCollapsed(float width, float height)
	{
		let horizontal = Orientation == .Horizontal;
		let extent = horizontal ? width : height;

		// The collapsed pane is measured LOOSE along the split axis and tight across it, which
		// is what asks it for its own minimum.
		let collapsed = mSecondCollapsed ? mSecond : mFirst;
		var collapsedSize = 0.0f;
		if (collapsed != null)
		{
			collapsed.Measure(horizontal ? BoxConstraints(0.0f, width, height, height)
				: BoxConstraints(width, width, 0.0f, height));
			collapsedSize = Clamp(horizontal ? collapsed.MeasuredSize.X : collapsed.MeasuredSize.Y,
				0.0f, extent);
		}

		let expanded = mSecondCollapsed ? mFirst : mSecond;
		let expandedSize = extent - collapsedSize;
		if (expanded != null)
		{
			expanded.Measure(horizontal ? BoxConstraints.Tight(expandedSize, height)
				: BoxConstraints.Tight(width, expandedSize));
		}

		let firstSize = mSecondCollapsed ? expandedSize : collapsedSize;
		let secondSize = mSecondCollapsed ? collapsedSize : expandedSize;

		if (horizontal)
		{
			if (mFirst != null)
				mFirst.Layout(0, 0, firstSize, height);
			if (mSecond != null)
				mSecond.Layout(firstSize, 0, secondSize, height);
		}
		else
		{
			if (mFirst != null)
				mFirst.Layout(0, 0, width, firstSize);
			if (mSecond != null)
				mSecond.Layout(0, firstSize, width, secondSize);
		}
	}

	// ---- Internals ------------------------------------------------------------------------------

	private Rectangle GetDividerRect()
	{
		if (Orientation == .Horizontal)
		{
			let available = Width - DividerSize;
			return .(available * mSplitRatio, 0, DividerSize, Height);
		}

		let available = Height - DividerSize;
		return .(0, available * mSplitRatio, Width, DividerSize);
	}

	private bool IsInDivider(float x, float y)
	{
		if (AnyPaneCollapsed)
			return false;

		let rect = GetDividerRect();
		return (x >= rect.X) && (x < rect.X + rect.Width) && (y >= rect.Y)
			&& (y < rect.Y + rect.Height);
	}
}
