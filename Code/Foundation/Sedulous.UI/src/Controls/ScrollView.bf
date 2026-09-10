using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A container whose content may be larger than the space it is given.
///
/// The two scroll bars are VISUAL children, not logical ones: they are appended after the real
/// children so they draw and hit test on top, while contributing nothing to the content's
/// measure or layout. A bar that was a logical child would scroll along with what it scrolls.
///
/// The `ScrollBarMode` property shadows the enum type inside this class, so the declaration
/// spells the type out and the values are reached through inference.
class ScrollView : ViewGroup
{
	private const float WheelStep = 40.0f;
	/// A wheel notch also seeds momentum, at this multiple of the step it just scrolled.
	private const float WheelMomentum = 3.0f;
	/// A drag seeds momentum from its per-frame delta scaled to a per-second velocity.
	private const float DragMomentum = 60.0f;
	/// A page is most of a viewport, not all of it: the overlap is what keeps the reader's
	/// place across a page down.
	private const float PageFraction = 0.9f;

	public Property<ScrollBarPolicy> VScrollBarPolicy = new .(.Auto) ~ delete _;
	public Property<ScrollBarPolicy> HScrollBarPolicy = new .(.Auto) ~ delete _;
	public Property<Sedulous.UI.ScrollBarMode> ScrollBarMode = new .(.Overlay) ~ delete _;
	public Property<bool> MomentumEnabled = new .(true) ~ delete _;
	public Property<float> ScrollBarThickness = new .(10.0f) ~ delete _;

	private float mScrollX = 0.0f;
	private float mScrollY = 0.0f;
	private float mContentWidth = 0.0f;
	private float mContentHeight = 0.0f;
	private MomentumHelper mMomentum = .();

	private bool mDragging = false;
	private float mDragLastX = 0.0f;
	private float mDragLastY = 0.0f;

	/// OWNED, and not logical children: released here, and detached by hand because a view
	/// released while still registered leaves the context holding a dangling pointer.
	private ScrollBar mVBar;
	private ScrollBar mHBar;

	public this()
	{
		ClipsContent = true;
		VScrollBarPolicy.SetOwner(this);
		HScrollBarPolicy.SetOwner(this);
		ScrollBarMode.SetOwner(this);
		MomentumEnabled.SetOwner(this);
		ScrollBarThickness.SetOwner(this);

		mVBar = new ScrollBar(false);
		mVBar.Visibility = .Gone;
		mVBar.BarThickness = ScrollBarThickness.Value;
		mVBar.OnValueChanged.Add(new (bar, val) => { SetScrollY(val); });

		mHBar = new ScrollBar(true);
		mHBar.Visibility = .Gone;
		mHBar.BarThickness = ScrollBarThickness.Value;
		mHBar.OnValueChanged.Add(new (bar, val) => { SetScrollX(val); });
	}

	public ~this()
	{
		ReleaseBar(ref mVBar);
		ReleaseBar(ref mHBar);
	}

	private void ReleaseBar(ref ScrollBar bar)
	{
		if (bar == null)
			return;

		if (bar.Context != null)
			bar.Context.DetachView(bar);
		bar.Parent = null;
		bar.ReleaseRef();
		bar = null;
	}

	// ---- Offsets ----------------------------------------------------------------------------

	public float ScrollX => mScrollX;
	public float ScrollY => mScrollY;

	public void SetScrollX(float value)
	{
		let clamped = Clamp(value, 0.0f, MaxScrollX);
		if (mScrollX == clamped)
			return;

		mScrollX = clamped;
		Invalidate();
	}

	public void SetScrollY(float value)
	{
		let clamped = Clamp(value, 0.0f, MaxScrollY);
		if (mScrollY == clamped)
			return;

		mScrollY = clamped;
		Invalidate();
	}

	public float MaxScrollX => Max(0.0f, mContentWidth - ViewportWidth);
	public float MaxScrollY => Max(0.0f, mContentHeight - ViewportHeight);
	public float ContentWidth => mContentWidth;
	public float ContentHeight => mContentHeight;

	/// The visible width. In Reserved mode a vertical bar takes its thickness out of it; in
	/// Overlay mode the bar floats and the viewport keeps the lot.
	public float ViewportWidth
	{
		get
		{
			let barSpace = ((ScrollBarMode.Value == .Reserved) && NeedsVBar) ? ScrollBarThickness.Value : 0.0f;
			return Max(0.0f, Width - Padding.TotalHorizontal - barSpace);
		}
	}

	public float ViewportHeight
	{
		get
		{
			let barSpace = ((ScrollBarMode.Value == .Reserved) && NeedsHBar) ? ScrollBarThickness.Value : 0.0f;
			return Max(0.0f, Height - Padding.TotalVertical - barSpace);
		}
	}

	// ---- Commands ---------------------------------------------------------------------------

	/// Every command STOPS the momentum: a caller asking to be somewhere means there, not
	/// there and then drifting on.
	public void ScrollTo(float x, float y)
	{
		SetScrollX(x);
		SetScrollY(y);
		mMomentum.Stop();
	}

	public void ScrollToTop()
	{
		SetScrollY(0);
		mMomentum.Stop();
	}

	public void ScrollToBottom()
	{
		SetScrollY(MaxScrollY);
		mMomentum.Stop();
	}

	public void ScrollToLeft()
	{
		SetScrollX(0);
		mMomentum.Stop();
	}

	public void ScrollToRight()
	{
		SetScrollX(MaxScrollX);
		mMomentum.Stop();
	}

	/// Relative, and does NOT stop the momentum: this is what a drag and a wheel notch use.
	public void ScrollBy(float dx, float dy)
	{
		SetScrollX(mScrollX + dx);
		SetScrollY(mScrollY + dy);
	}

	/// Brings a descendant into view, scrolling the least that will do it.
	public void ScrollToView(View child)
	{
		if (child == null)
			return;

		var offsetX = 0.0f;
		var offsetY = 0.0f;
		var current = child;
		while ((current != null) && (current != this))
		{
			offsetX += current.Bounds.X;
			offsetY += current.Bounds.Y;
			current = current.Parent;
		}

		// Walked off the top without finding us: not a descendant.
		if (current == null)
			return;

		// The bounds were laid out already scrolled, so the current offset goes back in to
		// recover the position within the content.
		offsetX += mScrollX;
		offsetY += mScrollY;

		let childRight = offsetX + child.Width;
		if (offsetX < mScrollX)
			SetScrollX(offsetX);
		else if (childRight > mScrollX + ViewportWidth)
			SetScrollX(childRight - ViewportWidth);

		let childBottom = offsetY + child.Height;
		if (offsetY < mScrollY)
			SetScrollY(offsetY);
		else if (childBottom > mScrollY + ViewportHeight)
			SetScrollY(childBottom - ViewportHeight);

		mMomentum.Stop();
	}

	// ---- Visual children --------------------------------------------------------------------

	public override int VisualChildCount => ChildCount + 2;

	public override View GetVisualChild(int index)
	{
		if (index < ChildCount)
			return GetChildAt(index);
		if (index == ChildCount)
			return mVBar;
		if (index == ChildCount + 1)
			return mHBar;

		return null;
	}

	// ---- Input ------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		if (MomentumEnabled.Value && mMomentum.IsActive)
		{
			let delta = mMomentum.Update((Context != null) ? Context.DeltaTime : 0.016f);
			SetScrollX(mScrollX + delta.X);
			SetScrollY(mScrollY + delta.Y);
		}

		// Includes the bars, which are visual children and so draw last, on top.
		DrawChildren(ctx);
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		var horizontalDelta = 0.0f;

		if (e.DeltaX != 0)
			horizontalDelta = e.DeltaX;
		else if (NeedsHBar && (e.DeltaY != 0) && e.Modifiers.HasFlag(.Shift))
			horizontalDelta = e.DeltaY;
		// A vertical wheel on a view that only scrolls sideways drives it sideways, which is
		// what a wheel over a horizontal strip is expected to do.
		else if (NeedsHBar && !NeedsVBar && (e.DeltaY != 0))
			horizontalDelta = e.DeltaY;

		if (NeedsHBar && (horizontalDelta != 0))
		{
			SetScrollX(mScrollX - horizontalDelta * WheelStep);
			if (MomentumEnabled.Value)
				mMomentum.VelocityX = -horizontalDelta * WheelStep * WheelMomentum;

			e.Handled = true;
		}
		else if (NeedsVBar && (e.DeltaY != 0))
		{
			SetScrollY(mScrollY - e.DeltaY * WheelStep);
			if (MomentumEnabled.Value)
				mMomentum.VelocityY = -e.DeltaY * WheelStep * WheelMomentum;

			e.Handled = true;
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		// Only worth grabbing when there is somewhere to go.
		if ((e.Button == .Left) && ((MaxScrollX > 0) || (MaxScrollY > 0)))
		{
			let local = ScreenToLocal(MouseScreenPos());
			mDragging = true;
			mDragLastX = local.X;
			mDragLastY = local.Y;
			mMomentum.Stop();

			if (Context != null)
				Context.GetFocusManager().SetCapture(this);
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (!mDragging)
			return;

		let local = ScreenToLocal(MouseScreenPos());
		let dx = mDragLastX - local.X;
		let dy = mDragLastY - local.Y;

		// A dead zone of a pixel, so a click that trembles does not scroll.
		if ((Abs(dx) > 1) || (Abs(dy) > 1))
		{
			ScrollBy(dx, dy);
			mMomentum.VelocityX = dx * DragMomentum;
			mMomentum.VelocityY = dy * DragMomentum;
			mDragLastX = local.X;
			mDragLastY = local.Y;
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDragging)
		{
			mDragging = false;
			if (Context != null)
				Context.GetFocusManager().ReleaseCapture();
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		let pageSize = ViewportHeight * PageFraction;

		switch (e.Key)
		{
		case .Up:
			SetScrollY(mScrollY - WheelStep);
			e.Handled = true;
		case .Down:
			SetScrollY(mScrollY + WheelStep);
			e.Handled = true;
		case .PageUp:
			SetScrollY(mScrollY - pageSize);
			e.Handled = true;
		case .PageDown:
			SetScrollY(mScrollY + pageSize);
			e.Handled = true;
		case .Home:
			ScrollToTop();
			e.Handled = true;
		case .End:
			ScrollToBottom();
			e.Handled = true;
		default:
		}
	}

	// ---- Layout -----------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fullWidth = Max(0.0f, constraints.MaxWidth - Padding.TotalHorizontal);
		let fullHeight = Max(0.0f, constraints.MaxHeight - Padding.TotalVertical);

		// A child is given UNBOUNDED room on any axis that can scroll, so it reports the size
		// it actually wants rather than the size it was squeezed into.
		let childMaxWidth = (HScrollBarPolicy.Value == .Always) ? FloatMax : fullWidth;
		let childMaxHeight = (VScrollBarPolicy.Value == .Never) ? fullHeight : FloatMax;

		var maxWidth = 0.0f;
		var maxHeight = 0.0f;
		MeasureContent(.(0, childMaxWidth, 0, childMaxHeight), ref maxWidth, ref maxHeight);
		mContentWidth = maxWidth;
		mContentHeight = maxHeight;

		// Reserved mode needs a SECOND pass: the first tells us whether a bar is needed, and a
		// bar changes the room the content had. Wrapping content measured against the wider
		// box would come out the wrong height.
		if (ScrollBarMode.Value == .Reserved)
			RemeasureForReservedBars(fullWidth, fullHeight, ref maxWidth, ref maxHeight);

		// An axis that cannot scroll WRAPS to its content; one that can fills what it was
		// given, since that is the window being scrolled through.
		let measuredWidth = (HScrollBarPolicy.Value == .Never)
			? maxWidth + Padding.TotalHorizontal
			: constraints.MaxWidth;

		var measuredHeight = constraints.MaxHeight;
		if (VScrollBarPolicy.Value == .Never)
		{
			let hBarHeight = ((HScrollBarPolicy.Value != .Never) && (ScrollBarMode.Value == .Reserved))
				? ScrollBarThickness.Value
				: 0.0f;
			measuredHeight = maxHeight + Padding.TotalVertical + hBarHeight;
		}

		MeasuredSize = .(constraints.ConstrainWidth(measuredWidth),
			constraints.ConstrainHeight(measuredHeight));
	}

	private void RemeasureForReservedBars(float fullWidth, float fullHeight, ref float maxWidth,
		ref float maxHeight)
	{
		let needsVBar = (VScrollBarPolicy.Value == .Always) ||
			((VScrollBarPolicy.Value == .Auto) && (maxHeight > fullHeight));
		let needsHBar = (HScrollBarPolicy.Value == .Always) ||
			((HScrollBarPolicy.Value == .Auto) && (maxWidth > fullWidth));

		if (!needsVBar && !needsHBar)
			return;

		let adjustedWidth = Max(0.0f, fullWidth - (needsVBar ? ScrollBarThickness.Value : 0.0f));
		let adjustedHeight = Max(0.0f, fullHeight - (needsHBar ? ScrollBarThickness.Value : 0.0f));
		let childMaxWidth = (HScrollBarPolicy.Value == .Always) ? FloatMax : adjustedWidth;
		let childMaxHeight = (VScrollBarPolicy.Value == .Never) ? adjustedHeight : FloatMax;

		maxWidth = 0;
		maxHeight = 0;
		MeasureContent(.(0, childMaxWidth, 0, childMaxHeight), ref maxWidth, ref maxHeight);
		mContentWidth = maxWidth;
		mContentHeight = maxHeight;
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		mVBar.Visibility = NeedsVBar ? .Visible : .Gone;
		mHBar.Visibility = NeedsHBar ? .Visible : .Gone;

		// Re-clamped here, because the content may have changed size since the offsets were
		// last written and a stale offset would scroll past the end.
		mScrollX = Clamp(mScrollX, 0.0f, MaxScrollX);
		mScrollY = Clamp(mScrollY, 0.0f, MaxScrollY);

		AttachBar(mVBar);
		AttachBar(mHBar);

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone)
				continue;

			// The MARGIN box, offset by the scroll: at least a viewport wide, so content
			// narrower than the view still fills it, and as tall as it measured.
			let marginBox = child.MarginBoxSize;
			child.Layout(Padding.Left - mScrollX, Padding.Top - mScrollY,
				Max(marginBox.X, ViewportWidth), marginBox.Y);
		}

		if (NeedsVBar)
		{
			mVBar.MaxValue = MaxScrollY;
			mVBar.ViewportSize = ViewportHeight;
			mVBar.Value = mScrollY;
			mVBar.Measure(BoxConstraints.Tight(ScrollBarThickness.Value, ViewportHeight));
			mVBar.Layout(width - ScrollBarThickness.Value, Padding.Top, ScrollBarThickness.Value,
				ViewportHeight);
		}

		if (NeedsHBar)
		{
			mHBar.MaxValue = MaxScrollX;
			mHBar.ViewportSize = ViewportWidth;
			mHBar.Value = mScrollX;
			mHBar.Measure(BoxConstraints.Tight(ViewportWidth, ScrollBarThickness.Value));
			mHBar.Layout(Padding.Left, height - ScrollBarThickness.Value, ViewportWidth,
				ScrollBarThickness.Value);
		}
	}

	private void AttachBar(ScrollBar bar)
	{
		bar.Parent = this;
		if ((Context != null) && (bar.Context == null))
			Context.AttachView(bar);
	}

	private bool NeedsVBar
	{
		get
		{
			if (VScrollBarPolicy.Value == .Never)
				return false;
			if (VScrollBarPolicy.Value == .Always)
				return true;

			return mContentHeight > Height - Padding.TotalVertical;
		}
	}

	private bool NeedsHBar
	{
		get
		{
			if (HScrollBarPolicy.Value == .Never)
				return false;
			if (HScrollBarPolicy.Value == .Always)
				return true;

			return mContentWidth > Width - Padding.TotalHorizontal;
		}
	}

	private void MeasureContent(BoxConstraints childConstraints, ref float maxWidth,
		ref float maxHeight)
	{
		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone)
				continue;

			// The margin is handled by the base Measure; the aggregate is by margin box.
			child.Measure(childConstraints);
			let marginBox = child.MarginBoxSize;
			maxWidth = Max(maxWidth, marginBox.X);
			maxHeight = Max(maxHeight, marginBox.Y);
		}
	}

	private Float2 MouseScreenPos()
	{
		if ((Context == null) || (Context.GetInputManager() == null))
			return .Zero;

		let input = Context.GetInputManager();
		return .(input.MouseX, input.MouseY);
	}
}
