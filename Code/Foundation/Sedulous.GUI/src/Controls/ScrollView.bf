namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Scroll bar visibility policy.
public enum ScrollBarPolicy { Never, Always, Auto }

/// Scroll bar rendering mode.
public enum ScrollBarMode
{
	/// Scrollbar overlays content (content uses full width/height).
	Overlay,
	/// Space is reserved for the scrollbar (content shrinks to make room).
	Reserved
}

/// Scrollable container. Content can be larger than the viewport.
/// Supports vertical and horizontal scrolling with optional scroll bars
/// and momentum-based kinetic scrolling.
public class ScrollView : ViewGroup
{
	private float mScrollX;
	private float mScrollY;
	private float mContentWidth;
	private float mContentHeight;
	private MomentumHelper mMomentum = .();

	// Drag-to-scroll state.
	private bool mDragging;
	private float mDragLastX;
	private float mDragLastY;

	// Scrollbars (owned as visual elements, not in mChildren)
	private ScrollBar mVBar;
	private ScrollBar mHBar;

	/// Vertical scroll bar policy.
	public Property<ScrollBarPolicy> VScrollBarPolicy = new .(.Auto) ~ delete _;

	/// Horizontal scroll bar policy.
	public Property<ScrollBarPolicy> HScrollBarPolicy = new .(.Auto) ~ delete _;

	/// How scrollbars affect content layout.
	public Property<ScrollBarMode> ScrollBarMode = new .(.Overlay) ~ delete _;

	/// Whether momentum scrolling is enabled.
	public Property<bool> MomentumEnabled = new .(true) ~ delete _;

	/// Scroll bar thickness.
	public Property<float> ScrollBarThickness = new .(10) ~ delete _;

	/// Current horizontal scroll offset.
	public float ScrollX
	{
		get => mScrollX;
		set
		{
			let clamped = Math.Clamp(value, 0, MaxScrollX);
			if (mScrollX == clamped) return;
			mScrollX = clamped;
			Invalidate();
		}
	}

	/// Current vertical scroll offset.
	public float ScrollY
	{
		get => mScrollY;
		set
		{
			let clamped = Math.Clamp(value, 0, MaxScrollY);
			if (mScrollY == clamped) return;
			mScrollY = clamped;
			Invalidate();
		}
	}

	/// Maximum horizontal scroll.
	public float MaxScrollX => Math.Max(0, mContentWidth - ViewportWidth);

	/// Maximum vertical scroll.
	public float MaxScrollY => Math.Max(0, mContentHeight - ViewportHeight);

	/// Total content width (as measured during layout).
	public float ContentWidth => mContentWidth;

	/// Total content height (as measured during layout).
	public float ContentHeight => mContentHeight;

	/// Visible viewport width (minus scrollbar if visible in Reserved mode).
	public float ViewportWidth
	{
		get
		{
			float barSpace = (ScrollBarMode.Value == .Reserved && NeedsVBar) ? ScrollBarThickness.Value : 0;
			return Math.Max(0, Width - Padding.TotalHorizontal - barSpace);
		}
	}

	/// Visible viewport height (minus scrollbar if visible in Reserved mode).
	public float ViewportHeight
	{
		get
		{
			float barSpace = (ScrollBarMode.Value == .Reserved && NeedsHBar) ? ScrollBarThickness.Value : 0;
			return Math.Max(0, Height - Padding.TotalVertical - barSpace);
		}
	}

	private bool NeedsVBar
	{
		get
		{
			if (VScrollBarPolicy.Value == .Never) return false;
			if (VScrollBarPolicy.Value == .Always) return true;
			return mContentHeight > Height - Padding.TotalVertical;
		}
	}

	private bool NeedsHBar
	{
		get
		{
			if (HScrollBarPolicy.Value == .Never) return false;
			if (HScrollBarPolicy.Value == .Always) return true;
			return mContentWidth > Width - Padding.TotalHorizontal;
		}
	}

	public this()
	{
		ClipsContent = true;
		VScrollBarPolicy.SetOwner(this);
		HScrollBarPolicy.SetOwner(this);
		ScrollBarMode.SetOwner(this);
		MomentumEnabled.SetOwner(this);
		ScrollBarThickness.SetOwner(this);

		// Scrollbars are visual children (not logical) - they participate in
		// draw and hit-test via VisualChildCount/GetVisualChild but don't
		// affect content measurement or layout.
		mVBar = new ScrollBar(false) { Visibility = .Gone };
		mVBar.BarThickness = ScrollBarThickness.Value;
		mVBar.OnValueChanged.Add(new (bar, val) => { ScrollY = val; });

		mHBar = new ScrollBar(true) { Visibility = .Gone };
		mHBar.BarThickness = ScrollBarThickness.Value;
		mHBar.OnValueChanged.Add(new (bar, val) => { ScrollX = val; });
	}

	public ~this()
	{
		if (mVBar.Context != null)
			mVBar.Context.DetachView(mVBar);
		if (mHBar.Context != null)
			mHBar.Context.DetachView(mHBar);
		mVBar.Parent = null;
		mHBar.Parent = null;
		delete mVBar;
		delete mHBar;
	}

	// Scrollbars appended as visual children after logical children.
	public override int VisualChildCount => ChildCount + 2;

	public override View GetVisualChild(int index)
	{
		if (index < ChildCount) return GetChildAt(index);
		if (index == ChildCount) return mVBar;
		if (index == ChildCount + 1) return mHBar;
		return null;
	}

	/// Scroll to a specific position.
	public void ScrollTo(float x, float y)
	{
		ScrollX = x;
		ScrollY = y;
		mMomentum.Stop();
	}

	/// Scroll to top.
	public void ScrollToTop() { ScrollY = 0; mMomentum.Stop(); }

	/// Scroll to bottom.
	public void ScrollToBottom() { ScrollY = MaxScrollY; mMomentum.Stop(); }

	/// Scroll to the left edge.
	public void ScrollToLeft() { ScrollX = 0; mMomentum.Stop(); }

	/// Scroll to the right edge.
	public void ScrollToRight() { ScrollX = MaxScrollX; mMomentum.Stop(); }

	/// Scroll by a delta amount, clamping to valid range.
	public void ScrollBy(float dx, float dy)
	{
		ScrollX = mScrollX + dx;
		ScrollY = mScrollY + dy;
	}

	/// Scroll to make the given child view visible within the viewport.
	/// Walks the parent chain from child up to this ScrollView's content to compute offset.
	public void ScrollToView(View child)
	{
		if (child == null) return;

		// Compute the child's position relative to this ScrollView's content area.
		float offsetX = 0;
		float offsetY = 0;
		var current = child;
		while (current != null && current !== this)
		{
			offsetX += current.Bounds.X;
			offsetY += current.Bounds.Y;
			current = current.Parent;
		}

		if (current == null) return; // child is not a descendant

		// Add back the current scroll offset since child bounds are laid out
		// at scroll-adjusted positions.
		offsetX += mScrollX;
		offsetY += mScrollY;

		// Adjust horizontal scroll to make child visible.
		let childRight = offsetX + child.Width;
		if (offsetX < mScrollX)
			ScrollX = offsetX;
		else if (childRight > mScrollX + ViewportWidth)
			ScrollX = childRight - ViewportWidth;

		// Adjust vertical scroll to make child visible.
		let childBottom = offsetY + child.Height;
		if (offsetY < mScrollY)
			ScrollY = offsetY;
		else if (childBottom > mScrollY + ViewportHeight)
			ScrollY = childBottom - ViewportHeight;

		mMomentum.Stop();
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// First pass: measure content WITHOUT reserving scrollbar space.
		// This determines if scrolling is actually needed.
		let fullW = Math.Max(0, constraints.MaxWidth - Padding.TotalHorizontal);
		let fullH = Math.Max(0, constraints.MaxHeight - Padding.TotalVertical);

		let childMaxW = (HScrollBarPolicy.Value == .Always) ? float.MaxValue : fullW;
		let childMaxH = (VScrollBarPolicy.Value == .Never) ? fullH : float.MaxValue;
		let childConstraints = BoxConstraints(0, childMaxW, 0, childMaxH);

		float maxW = 0, maxH = 0;
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let margin = child.LayoutParams?.Margin ?? Thickness();
			child.Measure(childConstraints.Deflate(margin));
			maxW = Math.Max(maxW, child.MeasuredSize.X + margin.TotalHorizontal);
			maxH = Math.Max(maxH, child.MeasuredSize.Y + margin.TotalVertical);
		}

		mContentWidth = maxW;
		mContentHeight = maxH;

		// Second pass: if Reserved mode and content overflows, re-measure with
		// scrollbar space subtracted so children account for the narrower viewport.
		if (ScrollBarMode.Value == .Reserved)
		{
			bool needsVBar = (VScrollBarPolicy.Value == .Always) || (VScrollBarPolicy.Value == .Auto && maxH > fullH);
			bool needsHBar = (HScrollBarPolicy.Value == .Always) || (HScrollBarPolicy.Value == .Auto && maxW > fullW);

			if (needsVBar || needsHBar)
			{
				let barW = needsVBar ? ScrollBarThickness.Value : 0;
				let barH = needsHBar ? ScrollBarThickness.Value : 0;
				let adjustedW = Math.Max(0, fullW - barW);
				let adjustedH = Math.Max(0, fullH - barH);

				let adjChildMaxW = (HScrollBarPolicy.Value == .Always) ? float.MaxValue : adjustedW;
				let adjChildMaxH = (VScrollBarPolicy.Value == .Never) ? adjustedH : float.MaxValue;
				let adjConstraints = BoxConstraints(0, adjChildMaxW, 0, adjChildMaxH);

				maxW = 0; maxH = 0;
				for (int i = 0; i < ChildCount; i++)
				{
					let child = GetChildAt(i);
					if (child.Visibility == .Gone) continue;

					let margin = child.LayoutParams?.Margin ?? Thickness();
					child.Measure(adjConstraints.Deflate(margin));
					maxW = Math.Max(maxW, child.MeasuredSize.X + margin.TotalHorizontal);
					maxH = Math.Max(maxH, child.MeasuredSize.Y + margin.TotalVertical);
				}

				mContentWidth = maxW;
				mContentHeight = maxH;
			}
		}

		// Width: fill available if horizontal scrolling, else wrap to content
		let measuredW = (HScrollBarPolicy.Value == .Never)
			? maxW + Padding.TotalHorizontal
			: constraints.MaxWidth;

		// Height: fill available if vertical scrolling, else wrap to content + scrollbar
		float measuredH;
		if (VScrollBarPolicy.Value == .Never)
		{
			let hBarH = (HScrollBarPolicy.Value != .Never && ScrollBarMode.Value == .Reserved) ? ScrollBarThickness.Value : 0;
			measuredH = maxH + Padding.TotalVertical + hBarH;
		}
		else
			measuredH = constraints.MaxHeight;

		MeasuredSize = .(constraints.ConstrainWidth(measuredW),
			constraints.ConstrainHeight(measuredH));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		// Update scrollbar visibility
		mVBar.Visibility = NeedsVBar ? .Visible : .Gone;
		mHBar.Visibility = NeedsHBar ? .Visible : .Gone;

		// Clamp scroll
		mScrollX = Math.Clamp(mScrollX, 0, MaxScrollX);
		mScrollY = Math.Clamp(mScrollY, 0, MaxScrollY);

		// Ensure scrollbars have parent set and are attached to context.
		// Parent must be set even if already attached (AttachView via
		// VisualChild recursion may set Context before OnLayout runs).
		mVBar.Parent = this;
		mHBar.Parent = this;
		if (Context != null && mVBar.Context == null)
			Context.AttachView(mVBar);
		if (Context != null && mHBar.Context == null)
			Context.AttachView(mHBar);

		// Layout content children at scrolled offset
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let margin = child.LayoutParams?.Margin ?? Thickness();
			let childW = Math.Max(child.MeasuredSize.X, ViewportWidth - margin.TotalHorizontal);
			let childH = child.MeasuredSize.Y;

			child.Layout(
				Padding.Left + margin.Left - mScrollX,
				Padding.Top + margin.Top - mScrollY,
				childW, childH);
		}

		// Layout scrollbars at fixed positions (not scrolled)
		if (NeedsVBar)
		{
			mVBar.MaxValue = MaxScrollY;
			mVBar.ViewportSize = ViewportHeight;
			mVBar.Value = mScrollY;
			mVBar.Measure(BoxConstraints.Tight(ScrollBarThickness.Value, ViewportHeight));
			mVBar.Layout(width - ScrollBarThickness.Value, Padding.Top, ScrollBarThickness.Value, ViewportHeight);
		}

		if (NeedsHBar)
		{
			mHBar.MaxValue = MaxScrollX;
			mHBar.ViewportSize = ViewportWidth;
			mHBar.Value = mScrollX;
			mHBar.Measure(BoxConstraints.Tight(ViewportWidth, ScrollBarThickness.Value));
			mHBar.Layout(Padding.Left, height - ScrollBarThickness.Value, ViewportWidth, ScrollBarThickness.Value);
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		// Tick momentum
		if (MomentumEnabled.Value && mMomentum.IsActive)
		{
			let (dx, dy) = mMomentum.Update(Context?.DeltaTime ?? 0.016f);
			ScrollX = mScrollX + dx;
			ScrollY = mScrollY + dy;
		}

		// DrawChildren iterates VisualChildCount which includes scrollbars
		// appended after logical children - they draw on top automatically.
		DrawChildren(ctx);
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		let scrollAmount = 40.0f;

		// Horizontal scroll: explicit DeltaX, Shift+DeltaY, or DeltaY when only H bar needed.
		float hDelta = 0;
		if (e.DeltaX != 0)
			hDelta = e.DeltaX;
		else if (NeedsHBar && e.DeltaY != 0 && e.Modifiers.HasFlag(.Shift))
			hDelta = e.DeltaY;
		else if (NeedsHBar && !NeedsVBar && e.DeltaY != 0)
			hDelta = e.DeltaY;

		if (NeedsHBar && hDelta != 0)
		{
			ScrollX = mScrollX - hDelta * scrollAmount;
			if (MomentumEnabled.Value)
				mMomentum.VelocityX = -hDelta * scrollAmount * 3;
			e.Handled = true;
		}
		else if (NeedsVBar && e.DeltaY != 0)
		{
			ScrollY = mScrollY - e.DeltaY * scrollAmount;
			if (MomentumEnabled.Value)
				mMomentum.VelocityY = -e.DeltaY * scrollAmount * 3;
			e.Handled = true;
		}
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Left && (MaxScrollX > 0 || MaxScrollY > 0))
		{
			let screenX = Context?.InputManager?.MouseX ?? 0;
			let screenY = Context?.InputManager?.MouseY ?? 0;
			let local = ScreenToLocal(.(screenX, screenY));

			mDragging = true;
			mDragLastX = local.X;
			mDragLastY = local.Y;
			mMomentum.Stop();
			Context?.FocusManager.SetCapture(this);
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDragging)
		{
			let screenX = Context?.InputManager?.MouseX ?? 0;
			let screenY = Context?.InputManager?.MouseY ?? 0;
			let local = ScreenToLocal(.(screenX, screenY));

			let dx = mDragLastX - local.X;
			let dy = mDragLastY - local.Y;

			if (Math.Abs(dx) > 1 || Math.Abs(dy) > 1)
			{
				ScrollBy(dx, dy);
				mMomentum.VelocityX = dx * 60;
				mMomentum.VelocityY = dy * 60;
				mDragLastX = local.X;
				mDragLastY = local.Y;
			}
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDragging)
		{
			mDragging = false;
			Context?.FocusManager.ReleaseCapture();
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		let pageSize = ViewportHeight * 0.9f;
		switch (e.Key)
		{
		case .Up:       ScrollY = mScrollY - 40; e.Handled = true;
		case .Down:     ScrollY = mScrollY + 40; e.Handled = true;
		case .PageUp:   ScrollY = mScrollY - pageSize; e.Handled = true;
		case .PageDown: ScrollY = mScrollY + pageSize; e.Handled = true;
		case .Home:     ScrollToTop(); e.Handled = true;
		case .End:      ScrollToBottom(); e.Handled = true;
		default:
		}
	}
}
