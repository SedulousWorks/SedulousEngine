namespace Sedulous.GUI.Toolkit;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// Binary split node for the dock tree. Contains two children separated
/// by a draggable divider. Direct ViewGroup - no SplitView wrapper.
public class DockSplit : ViewGroup
{
	private Orientation mOrientation = .Horizontal;
	private float mSplitRatio = 0.5f;
	private float mDividerSize = 4;
	private float mMinPaneSize = 50;
	private bool mIsDragging;
	private bool mIsDividerHovered;

	public Orientation Orientation
	{
		get => mOrientation;
		set { mOrientation = value; Invalidate(); }
	}

	public float SplitRatio
	{
		get => mSplitRatio;
		set { mSplitRatio = Math.Clamp(value, 0.05f, 0.95f); Invalidate(); }
	}

	public float DividerSize
	{
		get => mDividerSize;
		set { mDividerSize = Math.Max(2, value); Invalidate(); }
	}

	public float MinPaneSize { get => mMinPaneSize; set => mMinPaneSize = Math.Max(10, value); }

	/// First child (left or top).
	public View First => (ChildCount > 0) ? GetChildAt(0) : null;

	/// Second child (right or bottom).
	public View Second => (ChildCount > 1) ? GetChildAt(1) : null;

	public this(Orientation orientation = .Horizontal)
	{
		mOrientation = orientation;
	}

	/// Set both children. Removes existing children first (deletes them).
	/// Use RemoveView before calling if you need to preserve existing children.
	public void SetChildren(View first, View second)
	{
		RemoveAllViews();
		if (first != null) AddView(first);
		if (second != null) AddView(second);
		Invalidate();
	}

	private RectangleF GetDividerRect()
	{
		if (mOrientation == .Horizontal)
		{
			let available = Width - mDividerSize;
			let firstW = available * mSplitRatio;
			return .(firstW, 0, mDividerSize, Height);
		}
		else
		{
			let available = Height - mDividerSize;
			let firstH = available * mSplitRatio;
			return .(0, firstH, Width, mDividerSize);
		}
	}

	// === Measure / Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let w = constraints.ConstrainWidth(200);
		let h = constraints.ConstrainHeight(200);

		if (mOrientation == .Horizontal)
		{
			let available = w - mDividerSize;
			let firstW = available * mSplitRatio;
			let secondW = available - firstW;
			if (First != null) First.Measure(BoxConstraints.Tight(firstW, h));
			if (Second != null) Second.Measure(BoxConstraints.Tight(secondW, h));
		}
		else
		{
			let available = h - mDividerSize;
			let firstH = available * mSplitRatio;
			let secondH = available - firstH;
			if (First != null) First.Measure(BoxConstraints.Tight(w, firstH));
			if (Second != null) Second.Measure(BoxConstraints.Tight(w, secondH));
		}

		MeasuredSize = .(w, h);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (mOrientation == .Horizontal)
		{
			let available = width - mDividerSize;
			let firstW = available * mSplitRatio;
			let secondW = available - firstW;
			if (First != null) First.Layout(0, 0, firstW, height);
			if (Second != null) Second.Layout(firstW + mDividerSize, 0, secondW, height);
		}
		else
		{
			let available = height - mDividerSize;
			let firstH = available * mSplitRatio;
			let secondH = available - firstH;
			if (First != null) First.Layout(0, 0, width, firstH);
			if (Second != null) Second.Layout(0, firstH + mDividerSize, width, secondH);
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		DrawChildren(ctx);

		// Draw divider.
		let dividerRect = GetDividerRect();
		let dividerColor = (mIsDragging || mIsDividerHovered)
			? ResolveStyleColor(.AccentColor, .(80, 150, 240, 255))
			: ResolveStyleColor(.BorderColor, .(65, 70, 85, 255));
		ctx.VG.FillRect(dividerRect, dividerColor);
	}

	// === Hit testing: intercept divider clicks ===

	public override View HitTest(Vector2 localPoint)
	{
		if (!IsInteractionEnabled || Visibility != .Visible) return null;
		if (localPoint.X < 0 || localPoint.Y < 0 || localPoint.X >= Width || localPoint.Y >= Height)
			return null;

		// Check divider first.
		let dividerRect = GetDividerRect();
		if (localPoint.X >= dividerRect.X && localPoint.X < dividerRect.X + dividerRect.Width &&
			localPoint.Y >= dividerRect.Y && localPoint.Y < dividerRect.Y + dividerRect.Height)
			return this;

		// Test children in reverse order.
		if (Second != null)
		{
			let childLocal = Vector2(localPoint.X - Second.Bounds.X, localPoint.Y - Second.Bounds.Y);
			let hit = Second.HitTest(childLocal);
			if (hit != null) return hit;
		}
		if (First != null)
		{
			let childLocal = Vector2(localPoint.X - First.Bounds.X, localPoint.Y - First.Bounds.Y);
			let hit = First.HitTest(childLocal);
			if (hit != null) return hit;
		}

		return this;
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		let dividerRect = GetDividerRect();
		if (e.X >= dividerRect.X && e.X < dividerRect.X + dividerRect.Width &&
			e.Y >= dividerRect.Y && e.Y < dividerRect.Y + dividerRect.Height)
		{
			mIsDragging = true;
			Context?.FocusManager.SetCapture(this);
			e.Handled = true;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mIsDragging)
		{
			UpdateSplitFromMouse(e.X, e.Y);
		}
		else
		{
			let dividerRect = GetDividerRect();
			let overDivider = e.X >= dividerRect.X && e.X < dividerRect.X + dividerRect.Width &&
				e.Y >= dividerRect.Y && e.Y < dividerRect.Y + dividerRect.Height;

			if (overDivider != mIsDividerHovered)
			{
				mIsDividerHovered = overDivider;
				if (overDivider)
					Cursor = (mOrientation == .Horizontal) ? .SizeWE : .SizeNS;
				else
					Cursor = .Default;
			}
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mIsDragging && e.Button == .Left)
		{
			mIsDragging = false;
			Context?.FocusManager.ReleaseCapture();
			e.Handled = true;
		}
	}

	public override void OnMouseLeave()
	{
		if (mIsDividerHovered)
		{
			mIsDividerHovered = false;
			Cursor = .Default;
		}
	}

	private void UpdateSplitFromMouse(float localX, float localY)
	{
		float ratio;
		if (mOrientation == .Horizontal)
		{
			let available = Width - mDividerSize;
			if (available <= 0) return;
			ratio = (localX - mDividerSize * 0.5f) / available;
		}
		else
		{
			let available = Height - mDividerSize;
			if (available <= 0) return;
			ratio = (localY - mDividerSize * 0.5f) / available;
		}
		SplitRatio = ratio;
	}
}
