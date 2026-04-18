namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

using internal Sedulous.UI;

/// Scrollable container. Clips content to viewport and scrolls via
/// negative-offset layout (not render translate). Supports mouse wheel,
/// momentum scrolling, and optional scrollbars.
/// How scrollbars occupy space relative to content.
public enum ScrollBarMode
{
	/// Scrollbar draws on top of content (mobile/macOS style). Content uses full width.
	Overlay,
	/// Scrollbar reserves its own space. Content shrinks to make room. No overlap.
	Reserved
}

public class ScrollView : ViewGroup
{
	public ScrollBarPolicy HScrollPolicy = .Never;
	public ScrollBarPolicy VScrollPolicy = .Auto;
	public ScrollBarMode BarMode = .Overlay;

	private float mScrollX;
	private float mScrollY;
	private float mContentWidth;
	private float mContentHeight;
	private MomentumHelper mMomentum = .();

	// Scrollbars — managed separately, not in mChildren.
	private ScrollBar mVScrollBar ~ delete _;
	private ScrollBar mHScrollBar ~ delete _;
	private bool mVBarVisible;
	private bool mHBarVisible;

	public float ScrollX => mScrollX;
	public float ScrollY => mScrollY;
	public float ContentWidth => mContentWidth;
	public float ContentHeight => mContentHeight;
	public float MaxScrollX => Math.Max(0, mContentWidth - (Width - Padding.TotalHorizontal - (mVBarVisible ? ScrollBarThickness : 0)));
	public float MaxScrollY => Math.Max(0, mContentHeight - (Height - Padding.TotalVertical - (mHBarVisible ? ScrollBarThickness : 0)));

	public float ScrollBarThickness = 8;

	// Content drag state.
	private bool mDragging;
	private float mDragLastX;
	private float mDragLastY;

	public this()
	{
		ClipsContent = true;

		mVScrollBar = new ScrollBar();
		mVScrollBar.Orientation = .Vertical;
		mVScrollBar.Parent = this; // for coordinate conversion in InputManager.ToLocal
		mVScrollBar.OnValueChanged = new (val) => { mScrollY = val; InvalidateLayout(); };

		mHScrollBar = new ScrollBar();
		mHScrollBar.Orientation = .Horizontal;
		mHScrollBar.Parent = this;
		mHScrollBar.OnValueChanged = new (val) => { mScrollX = val; InvalidateLayout(); };
	}

	/// Scroll by a delta amount, clamping to valid range.
	public void ScrollBy(float dx, float dy)
	{
		mScrollX = Math.Clamp(mScrollX + dx, 0, MaxScrollX);
		mScrollY = Math.Clamp(mScrollY + dy, 0, MaxScrollY);
		InvalidateLayout();
	}

	/// Clear all children and add a single content view.
	public void SetContent(View content, LayoutParams lp = null)
	{
		while (ChildCount > 0)
			RemoveView(GetChildAt(0), true);
		if (content != null)
			AddView(content, lp);
	}

	/// Scroll to an absolute position, clamping to valid range.
	public void ScrollToTop() => ScrollTo(mScrollX, 0);
	public void ScrollToBottom() => ScrollTo(mScrollX, MaxScrollY);
	public void ScrollToLeft() => ScrollTo(0, mScrollY);
	public void ScrollToRight() => ScrollTo(MaxScrollX, mScrollY);

	/// Scroll to an absolute position, clamping to valid range.
	public void ScrollTo(float x, float y)
	{
		mScrollX = Math.Clamp(x, 0, MaxScrollX);
		mScrollY = Math.Clamp(y, 0, MaxScrollY);
		InvalidateLayout();
	}

	/// Scroll to make a child view visible within the viewport.
	/// The child must be a descendant of this ScrollView.
	public void ScrollToView(View child)
	{
		if (child == null) return;

		// Compute child's position relative to this ScrollView's content area.
		float relX = child.Bounds.X, relY = child.Bounds.Y;
		var p = child.Parent;
		while (p != null && p !== this)
		{
			relX += p.Bounds.X;
			relY += p.Bounds.Y;
			p = p.Parent;
		}
		if (p == null) return; // child is not a descendant

		let viewportW = Width - Padding.TotalHorizontal - (mVBarVisible ? ScrollBarThickness : 0);
		let viewportH = Height - Padding.TotalVertical - (mHBarVisible ? ScrollBarThickness : 0);

		// Vertical: ensure child is within [scrollY .. scrollY + viewportH].
		var newScrollY = mScrollY;
		if (relY < mScrollY)
			newScrollY = relY;
		else if (relY + child.Height > mScrollY + viewportH)
			newScrollY = relY + child.Height - viewportH;

		// Horizontal: ensure child is within [scrollX .. scrollX + viewportW].
		var newScrollX = mScrollX;
		if (relX < mScrollX)
			newScrollX = relX;
		else if (relX + child.Width > mScrollX + viewportW)
			newScrollX = relX + child.Width - viewportW;

		ScrollTo(newScrollX, newScrollY);
	}

	// === Mouse wheel ===

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (e.DeltaY != 0 && MaxScrollY > 0)
		{
			ScrollBy(0, -e.DeltaY * 40);
			mMomentum.VelocityY = -e.DeltaY * 200;
			e.Handled = true;
		}
		else if (e.DeltaX != 0 && MaxScrollX > 0)
		{
			ScrollBy(-e.DeltaX * 40, 0);
			mMomentum.VelocityX = -e.DeltaX * 200;
			e.Handled = true;
		}
	}

	// === Content drag-to-scroll ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Left && (MaxScrollY > 0 || MaxScrollX > 0))
		{
			mDragging = true;
			mDragLastX = e.X;
			mDragLastY = e.Y;

			// Capture the mouse so all subsequent move/up events come here
			// even if the cursor moves outside the ScrollView.
			Context?.FocusManager.SetCapture(this);
			e.Handled = true;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDragging)
		{
			let dx = mDragLastX - e.X;
			let dy = mDragLastY - e.Y;
			if (Math.Abs(dx) > 1 || Math.Abs(dy) > 1)
			{
				ScrollBy(dx, dy);
				mMomentum.VelocityX = dx * 60;
				mMomentum.VelocityY = dy * 60;
				mDragLastX = e.X;
				mDragLastY = e.Y;
			}
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDragging)
		{
			mDragging = false;
			Context?.FocusManager.ReleaseCapture();
			// Momentum continues from last drag velocity.
		}
	}

	// === Visual children: logical children + scrollbars ===
	// Scrollbars are ALWAYS in the visual child list so they're registered
	// with UIContext on attach (before layout determines visibility).
	// Their Visibility is set to Visible/Gone by UpdateScrollBarVisibility;
	// DrawChildren and HitTest already skip non-Visible children.

	public override int VisualChildCount => ChildCount + 2;

	public override View GetVisualChild(int index)
	{
		if (index < ChildCount)
			return GetChildAt(index);
		if (index == ChildCount)
			return mVScrollBar;
		if (index == ChildCount + 1)
			return mHScrollBar;
		return null;
	}

	// === Measure / Layout ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		// Measure children: unconstrained on scroll axis to get natural content size.
		float maxW = 0, maxH = 0;
		bool anyMatchParentW = false;

		// In Reserved mode, subtract scrollbar thickness from the width
		// available to children so they don't extend under the scrollbar.
		float reservedW = 0;
		float reservedH = 0;
		if (BarMode == .Reserved)
		{
			if (VScrollPolicy != .Never) reservedW = ScrollBarThickness;
			if (HScrollPolicy != .Never) reservedH = ScrollBarThickness;
		}

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let lp = child.LayoutParams;
			if (lp != null && lp.Width == Sedulous.UI.LayoutParams.MatchParent)
				anyMatchParentW = true;

			let childWSpec = MakeChildMeasureSpec(wSpec, Padding.TotalHorizontal + reservedW,
				lp?.Width ?? Sedulous.UI.LayoutParams.WrapContent);

			// Only use Unspecified on axes that actually scroll.
			// When scroll is disabled (.Never), pass through the parent's constraint
			// so MatchParent children get a real size.
			MeasureSpec childHSpec;
			if (VScrollPolicy == .Never)
				childHSpec = MakeChildMeasureSpec(hSpec, Padding.TotalVertical + reservedH,
					lp?.Height ?? Sedulous.UI.LayoutParams.WrapContent);
			else
				childHSpec = .Unspecified();

			child.Measure(childWSpec, childHSpec);

			maxW = Math.Max(maxW, child.MeasuredSize.X);
			maxH = Math.Max(maxH, child.MeasuredSize.Y);
		}

		// For MatchParent children, content width equals viewport — no horizontal overflow.
		if (anyMatchParentW)
			mContentWidth = 0; // will be ≤ viewport, so MaxScrollX = 0
		else
			mContentWidth = maxW;
		mContentHeight = maxH;

		MeasuredSize = .(wSpec.Resolve(maxW + Padding.TotalHorizontal),
						 hSpec.Resolve(maxH + Padding.TotalVertical));

		// Determine scrollbar visibility.
		UpdateScrollBarVisibility();
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let viewportW = (right - left) - Padding.TotalHorizontal - (mVBarVisible ? ScrollBarThickness : 0);
		let viewportH = (bottom - top) - Padding.TotalVertical - (mHBarVisible ? ScrollBarThickness : 0);

		// Clamp scroll to valid range.
		mScrollX = Math.Clamp(mScrollX, 0, MaxScrollX);
		mScrollY = Math.Clamp(mScrollY, 0, MaxScrollY);

		// Layout children at negative offset (the scroll trick).
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let margin = child.LayoutParams?.Margin ?? Thickness();
			let lp = child.LayoutParams;

			// MatchParent children fit the viewport (minus scrollbar) — don't overflow.
			// WrapContent children use their measured size (may be wider -> horizontal scroll).
			float childW;
			if (lp != null && lp.Width == Sedulous.UI.LayoutParams.MatchParent)
				childW = viewportW - margin.TotalHorizontal;
			else
				childW = child.MeasuredSize.X;

			let childH = child.MeasuredSize.Y;

			child.Layout(
				Padding.Left + margin.Left - mScrollX,
				Padding.Top + margin.Top - mScrollY,
				childW,
				childH);
		}

		// Layout scrollbars.
		if (mVBarVisible)
		{
			mVScrollBar.Value = mScrollY;
			mVScrollBar.MaxValue = MaxScrollY;
			mVScrollBar.ViewportSize = viewportH;
			mVScrollBar.BarThickness = ScrollBarThickness;
			mVScrollBar.Measure(.Exactly(ScrollBarThickness), .Exactly(viewportH));
			mVScrollBar.Layout(
				(right - left) - ScrollBarThickness,
				Padding.Top,
				ScrollBarThickness,
				viewportH);
		}

		if (mHBarVisible)
		{
			mHScrollBar.Value = mScrollX;
			mHScrollBar.MaxValue = MaxScrollX;
			mHScrollBar.ViewportSize = viewportW;
			mHScrollBar.BarThickness = ScrollBarThickness;
			mHScrollBar.Measure(.Exactly(viewportW), .Exactly(ScrollBarThickness));
			mHScrollBar.Layout(
				Padding.Left,
				(bottom - top) - ScrollBarThickness,
				viewportW,
				ScrollBarThickness);
		}
	}

	private void UpdateScrollBarVisibility()
	{
		let viewportW = Width - Padding.TotalHorizontal;
		let viewportH = Height - Padding.TotalVertical;

		mVBarVisible = ShouldShowBar(VScrollPolicy, mContentHeight, viewportH);
		mHBarVisible = ShouldShowBar(HScrollPolicy, mContentWidth, viewportW);

		// Cascading: if V bar visible, reduce viewport width, re-check H.
		if (mVBarVisible && !mHBarVisible && HScrollPolicy == .Auto)
			mHBarVisible = mContentWidth > (viewportW - ScrollBarThickness);

		// And vice versa.
		if (mHBarVisible && !mVBarVisible && VScrollPolicy == .Auto)
			mVBarVisible = mContentHeight > (viewportH - ScrollBarThickness);

		// Set Visibility so DrawChildren and HitTest skip hidden scrollbars.
		mVScrollBar.Visibility = mVBarVisible ? .Visible : .Gone;
		mHScrollBar.Visibility = mHBarVisible ? .Visible : .Gone;
	}

	private bool ShouldShowBar(ScrollBarPolicy policy, float contentSize, float viewportSize)
	{
		switch (policy)
		{
		case .Never:  return false;
		case .Always: return true;
		case .Auto:   return contentSize > viewportSize;
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		// Tick momentum.
		let (dx, dy) = mMomentum.Update(1.0f / 60.0f); // approximate dt
		if (dx != 0 || dy != 0)
			ScrollBy(dx, dy);

		// DrawChildren iterates VisualChildCount which includes scrollbars
		// appended after logical children — they draw on top automatically.
		DrawChildren(ctx);
	}
}
