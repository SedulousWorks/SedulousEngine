using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A container that provides scrolling for content larger than the viewport.
public class ScrollViewer : ContentControl
{
	// Scroll state
	private float mHorizontalOffset = 0;
	private float mVerticalOffset = 0;

	// Content extent (measured size of content)
	private float mExtentWidth = 0;
	private float mExtentHeight = 0;

	// Scrollbars
	private ScrollBar mHorizontalScrollBar = new .(.Horizontal) ~ delete _;
	private ScrollBar mVerticalScrollBar = new .(.Vertical) ~ delete _;

	// Visibility settings
	private ScrollBarVisibility mHorizontalScrollBarVisibility = .Auto;
	private ScrollBarVisibility mVerticalScrollBarVisibility = .Auto;

	// Computed visibility
	private bool mShowHorizontalScrollBar = false;
	private bool mShowVerticalScrollBar = false;

	// Scrollbar thickness
	private float mScrollBarThickness = 16;

	// Events
	private EventAccessor<delegate void(ScrollViewer)> mScrollChanged = new .() ~ delete _;

	/// Creates a new ScrollViewer.
	public this()
	{
		// ScrollViewer itself is not focusable, but content may be
		IsFocusable = false;
		IsTabStop = false;

		// Set up scrollbars
		mHorizontalScrollBar.SetParent(this);
		mVerticalScrollBar.SetParent(this);

		mHorizontalScrollBar.Scroll.Subscribe(new (sb, value) => {
			mHorizontalOffset = value;
			InvalidateLayout();
			mScrollChanged.[Friend]Invoke(this);
		});

		mVerticalScrollBar.Scroll.Subscribe(new (sb, value) => {
			mVerticalOffset = value;
			InvalidateLayout();
			mScrollChanged.[Friend]Invoke(this);
		});
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ScrollViewer";

	/// Horizontal scroll offset.
	public float HorizontalOffset
	{
		get => mHorizontalOffset;
		set
		{
			let clamped = Math.Clamp(value, 0, Math.Max(0, mExtentWidth - ViewportWidth));
			if (mHorizontalOffset != clamped)
			{
				mHorizontalOffset = clamped;
				mHorizontalScrollBar.Value = clamped;
				InvalidateLayout();
				mScrollChanged.[Friend]Invoke(this);
			}
		}
	}

	/// Vertical scroll offset.
	public float VerticalOffset
	{
		get => mVerticalOffset;
		set
		{
			let clamped = Math.Clamp(value, 0, Math.Max(0, mExtentHeight - ViewportHeight));
			if (mVerticalOffset != clamped)
			{
				mVerticalOffset = clamped;
				mVerticalScrollBar.Value = clamped;
				InvalidateLayout();
				mScrollChanged.[Friend]Invoke(this);
			}
		}
	}

	/// The total width of the content.
	public float ExtentWidth => mExtentWidth;

	/// The total height of the content.
	public float ExtentHeight => mExtentHeight;

	/// The visible width (viewport).
	public float ViewportWidth => ContentBounds.Width - (mShowVerticalScrollBar ? mScrollBarThickness : 0);

	/// The visible height (viewport).
	public float ViewportHeight => ContentBounds.Height - (mShowHorizontalScrollBar ? mScrollBarThickness : 0);

	/// Whether content can scroll horizontally.
	public bool CanScrollHorizontally => mExtentWidth > ViewportWidth;

	/// Whether content can scroll vertically.
	public bool CanScrollVertically => mExtentHeight > ViewportHeight;

	/// Horizontal scrollbar visibility mode.
	public ScrollBarVisibility HorizontalScrollBarVisibility
	{
		get => mHorizontalScrollBarVisibility;
		set
		{
			if (mHorizontalScrollBarVisibility != value)
			{
				mHorizontalScrollBarVisibility = value;
				InvalidateLayout();
			}
		}
	}

	/// Vertical scrollbar visibility mode.
	public ScrollBarVisibility VerticalScrollBarVisibility
	{
		get => mVerticalScrollBarVisibility;
		set
		{
			if (mVerticalScrollBarVisibility != value)
			{
				mVerticalScrollBarVisibility = value;
				InvalidateLayout();
			}
		}
	}

	/// Scrollbar thickness.
	public float ScrollBarThickness
	{
		get => mScrollBarThickness;
		set
		{
			if (mScrollBarThickness != value)
			{
				mScrollBarThickness = Math.Max(8, value);
				mHorizontalScrollBar.Thickness = mScrollBarThickness;
				mVerticalScrollBar.Thickness = mScrollBarThickness;
				InvalidateLayout();
			}
		}
	}

	/// Event fired when scroll position changes.
	public EventAccessor<delegate void(ScrollViewer)> ScrollChanged => mScrollChanged;

	// === Scrolling Methods ===

	/// Scrolls to make a point visible.
	public void ScrollToPoint(float x, float y)
	{
		// Adjust horizontal offset
		if (x < mHorizontalOffset)
			HorizontalOffset = x;
		else if (x > mHorizontalOffset + ViewportWidth)
			HorizontalOffset = x - ViewportWidth;

		// Adjust vertical offset
		if (y < mVerticalOffset)
			VerticalOffset = y;
		else if (y > mVerticalOffset + ViewportHeight)
			VerticalOffset = y - ViewportHeight;
	}

	/// Scrolls to make a rectangle visible.
	public void ScrollToRect(RectangleF rect)
	{
		// Horizontal
		if (rect.X < mHorizontalOffset)
			HorizontalOffset = rect.X;
		else if (rect.Right > mHorizontalOffset + ViewportWidth)
			HorizontalOffset = rect.Right - ViewportWidth;

		// Vertical
		if (rect.Y < mVerticalOffset)
			VerticalOffset = rect.Y;
		else if (rect.Bottom > mVerticalOffset + ViewportHeight)
			VerticalOffset = rect.Bottom - ViewportHeight;
	}

	/// Scrolls to the top.
	public void ScrollToTop() => VerticalOffset = 0;

	/// Scrolls to the bottom.
	public void ScrollToBottom() => VerticalOffset = mExtentHeight - ViewportHeight;

	/// Scrolls to the left edge.
	public void ScrollToLeft() => HorizontalOffset = 0;

	/// Scrolls to the right edge.
	public void ScrollToRight() => HorizontalOffset = mExtentWidth - ViewportWidth;

	/// Scrolls to home (top-left).
	public void ScrollToHome()
	{
		HorizontalOffset = 0;
		VerticalOffset = 0;
	}

	/// Scrolls to end (bottom-right).
	public void ScrollToEnd()
	{
		HorizontalOffset = mExtentWidth - ViewportWidth;
		VerticalOffset = mExtentHeight - ViewportHeight;
	}

	// === Context Propagation ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mHorizontalScrollBar.OnAttachedToContext(context);
		mVerticalScrollBar.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		mHorizontalScrollBar.OnDetachedFromContext();
		mVerticalScrollBar.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure content - use infinite constraints only in directions where scrolling is enabled
		if (Content != null && Content.Visibility != .Collapsed)
		{
			// When scrolling is disabled in a direction, constrain content to available space
			// This allows WrapPanel and similar controls to wrap properly
			float contentMaxWidth = SizeConstraints.Infinity;
			float contentMaxHeight = SizeConstraints.Infinity;

			if (mHorizontalScrollBarVisibility == .Disabled)
			{
				// No horizontal scrolling - constrain width (accounting for potential vertical scrollbar)
				contentMaxWidth = constraints.MaxWidth != SizeConstraints.Infinity
					? constraints.MaxWidth - (mVerticalScrollBarVisibility != .Disabled && mVerticalScrollBarVisibility != .Hidden ? mScrollBarThickness : 0)
					: SizeConstraints.Infinity;
			}

			if (mVerticalScrollBarVisibility == .Disabled)
			{
				// No vertical scrolling - constrain height (accounting for potential horizontal scrollbar)
				contentMaxHeight = constraints.MaxHeight != SizeConstraints.Infinity
					? constraints.MaxHeight - (mHorizontalScrollBarVisibility != .Disabled && mHorizontalScrollBarVisibility != .Hidden ? mScrollBarThickness : 0)
					: SizeConstraints.Infinity;
			}

			let contentConstraints = SizeConstraints(0, 0, contentMaxWidth, contentMaxHeight);
			let contentSize = Content.Measure(contentConstraints);
			mExtentWidth = contentSize.Width;
			mExtentHeight = contentSize.Height;
		}
		else
		{
			mExtentWidth = 0;
			mExtentHeight = 0;
		}

		// Determine scrollbar visibility
		UpdateScrollBarVisibility(constraints);

		// Return constrained size (ScrollViewer takes available space)
		float width = constraints.MaxWidth != SizeConstraints.Infinity ? constraints.MaxWidth : mExtentWidth;
		float height = constraints.MaxHeight != SizeConstraints.Infinity ? constraints.MaxHeight : mExtentHeight;

		return .(width, height);
	}

	private void UpdateScrollBarVisibility(SizeConstraints constraints)
	{
		let maxWidth = constraints.MaxWidth != SizeConstraints.Infinity ? constraints.MaxWidth : float.MaxValue;
		let maxHeight = constraints.MaxHeight != SizeConstraints.Infinity ? constraints.MaxHeight : float.MaxValue;

		// Determine if scrollbars are needed
		mShowHorizontalScrollBar = ShouldShowScrollBar(mHorizontalScrollBarVisibility, mExtentWidth > maxWidth);
		mShowVerticalScrollBar = ShouldShowScrollBar(mVerticalScrollBarVisibility, mExtentHeight > maxHeight);

		// If one scrollbar is shown, we may need the other due to reduced space
		if (mShowVerticalScrollBar && !mShowHorizontalScrollBar)
		{
			let adjustedWidth = maxWidth - mScrollBarThickness;
			mShowHorizontalScrollBar = ShouldShowScrollBar(mHorizontalScrollBarVisibility, mExtentWidth > adjustedWidth);
		}
		if (mShowHorizontalScrollBar && !mShowVerticalScrollBar)
		{
			let adjustedHeight = maxHeight - mScrollBarThickness;
			mShowVerticalScrollBar = ShouldShowScrollBar(mVerticalScrollBarVisibility, mExtentHeight > adjustedHeight);
		}
	}

	private bool ShouldShowScrollBar(ScrollBarVisibility visibility, bool isNeeded)
	{
		switch (visibility)
		{
		case .Disabled, .Hidden:
			return false;
		case .Visible:
			return true;
		case .Auto:
			return isNeeded;
		}
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		let bounds = contentBounds;

		// Calculate viewport (area for content, excluding scrollbars)
		let viewportWidth = bounds.Width - (mShowVerticalScrollBar ? mScrollBarThickness : 0);
		let viewportHeight = bounds.Height - (mShowHorizontalScrollBar ? mScrollBarThickness : 0);

		// Arrange content at its full extent size, offset by scroll position
		if (Content != null && Content.Visibility != .Collapsed)
		{
			let contentRect = RectangleF(
				bounds.X - mHorizontalOffset,
				bounds.Y - mVerticalOffset,
				Math.Max(viewportWidth, mExtentWidth),
				Math.Max(viewportHeight, mExtentHeight)
			);
			Content.Arrange(contentRect);
		}

		// Arrange scrollbars
		if (mShowHorizontalScrollBar)
		{
			mHorizontalScrollBar.Minimum = 0;
			mHorizontalScrollBar.Maximum = mExtentWidth;
			mHorizontalScrollBar.ViewportSize = viewportWidth;
			mHorizontalScrollBar.Value = mHorizontalOffset;
			mHorizontalScrollBar.LargeChange = viewportWidth * 0.9f;
			mHorizontalScrollBar.SmallChange = 20;

			let hScrollRect = RectangleF(
				bounds.X,
				bounds.Bottom - mScrollBarThickness,
				viewportWidth,
				mScrollBarThickness
			);
			mHorizontalScrollBar.Arrange(hScrollRect);
		}

		if (mShowVerticalScrollBar)
		{
			mVerticalScrollBar.Minimum = 0;
			mVerticalScrollBar.Maximum = mExtentHeight;
			mVerticalScrollBar.ViewportSize = viewportHeight;
			mVerticalScrollBar.Value = mVerticalOffset;
			mVerticalScrollBar.LargeChange = viewportHeight * 0.9f;
			mVerticalScrollBar.SmallChange = 20;

			let vScrollRect = RectangleF(
				bounds.Right - mScrollBarThickness,
				bounds.Y,
				mScrollBarThickness,
				viewportHeight
			);
			mVerticalScrollBar.Arrange(vScrollRect);
		}

		// Clamp scroll offsets
		mHorizontalOffset = Math.Clamp(mHorizontalOffset, 0, Math.Max(0, mExtentWidth - viewportWidth));
		mVerticalOffset = Math.Clamp(mVerticalOffset, 0, Math.Max(0, mExtentHeight - viewportHeight));
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw background
		RenderBackground(ctx);

		// Calculate viewport for clipping
		let viewportWidth = bounds.Width - (mShowVerticalScrollBar ? mScrollBarThickness : 0);
		let viewportHeight = bounds.Height - (mShowHorizontalScrollBar ? mScrollBarThickness : 0);
		let viewportRect = RectangleF(bounds.X, bounds.Y, viewportWidth, viewportHeight);

		// Clip content to viewport
		ctx.PushClipRect(viewportRect);

		// Render content
		Content?.Render(ctx);

		ctx.PopClip();

		// Render scrollbars
		if (mShowHorizontalScrollBar)
			mHorizontalScrollBar.Render(ctx);
		if (mShowVerticalScrollBar)
			mVerticalScrollBar.Render(ctx);

		// Draw corner if both scrollbars visible
		if (mShowHorizontalScrollBar && mShowVerticalScrollBar)
		{
			let cornerRect = RectangleF(
				bounds.Right - mScrollBarThickness,
				bounds.Bottom - mScrollBarThickness,
				mScrollBarThickness,
				mScrollBarThickness
			);
			ctx.FillRect(cornerRect, mHorizontalScrollBar.TrackColor);
		}
	}

	// === Input ===

	protected override void OnMouseWheel(MouseWheelEventArgs e)
	{
		base.OnMouseWheel(e);

		if (!e.Handled)
		{
			// Shift+wheel for horizontal scrolling
			if (e.HasModifier(.Shift) && CanScrollHorizontally)
			{
				HorizontalOffset -= e.DeltaY * mHorizontalScrollBar.SmallChange * 3;
				e.Handled = true;
			}
			else if (CanScrollVertically)
			{
				VerticalOffset -= e.DeltaY * mVerticalScrollBar.SmallChange * 3;
				e.Handled = true;
			}
			else if (CanScrollHorizontally)
			{
				HorizontalOffset -= e.DeltaY * mHorizontalScrollBar.SmallChange * 3;
				e.Handled = true;
			}
		}
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (!e.Handled)
		{
			switch (e.Key)
			{
			case .Home:
				if (e.HasModifier(.Ctrl))
					ScrollToHome();
				else
					ScrollToTop();
				e.Handled = true;
			case .End:
				if (e.HasModifier(.Ctrl))
					ScrollToEnd();
				else
					ScrollToBottom();
				e.Handled = true;
			case .PageUp:
				mVerticalScrollBar.PageUp();
				e.Handled = true;
			case .PageDown:
				mVerticalScrollBar.PageDown();
				e.Handled = true;
			default:
			}
		}
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Check scrollbars first
		if (mShowHorizontalScrollBar)
		{
			let hit = mHorizontalScrollBar.HitTest(point);
			if (hit != null)
				return hit;
		}
		if (mShowVerticalScrollBar)
		{
			let hit = mVerticalScrollBar.HitTest(point);
			if (hit != null)
				return hit;
		}

		// Check content within viewport
		let viewportWidth = ArrangedBounds.Width - (mShowVerticalScrollBar ? mScrollBarThickness : 0);
		let viewportHeight = ArrangedBounds.Height - (mShowHorizontalScrollBar ? mScrollBarThickness : 0);
		let viewportRect = RectangleF(ArrangedBounds.X, ArrangedBounds.Y, viewportWidth, viewportHeight);

		if (viewportRect.Contains(point.X, point.Y) && Content != null)
		{
			let hit = Content.HitTest(point);
			if (hit != null)
				return hit;
		}

		return this;
	}

	/// Hit tests only the scrollbars, not the content.
	/// Used by ItemsControl to allow scrollbar interaction while handling content input itself.
	public UIElement HitTestScrollBars(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Check scrollbars only
		if (mShowHorizontalScrollBar)
		{
			let hit = mHorizontalScrollBar.HitTest(point);
			if (hit != null)
				return hit;
		}
		if (mShowVerticalScrollBar)
		{
			let hit = mVerticalScrollBar.HitTest(point);
			if (hit != null)
				return hit;
		}

		return null;
	}

	// === Visual Children ===

	public override int VisualChildCount
	{
		get
		{
			int count = Content != null ? 1 : 0;
			if (mShowHorizontalScrollBar) count++;
			if (mShowVerticalScrollBar) count++;
			return count;
		}
	}

	public override UIElement GetVisualChild(int index)
	{
		int i = 0;
		if (Content != null)
		{
			if (index == i) return Content;
			i++;
		}
		if (mShowHorizontalScrollBar)
		{
			if (index == i) return mHorizontalScrollBar;
			i++;
		}
		if (mShowVerticalScrollBar)
		{
			if (index == i) return mVerticalScrollBar;
			i++;
		}
		return null;
	}
}

/// Controls when a scrollbar is visible.
public enum ScrollBarVisibility
{
	/// Scrollbar is never shown, scrolling is disabled.
	Disabled,
	/// Scrollbar is shown only when needed.
	Auto,
	/// Scrollbar is never shown, but scrolling is still possible.
	Hidden,
	/// Scrollbar is always shown.
	Visible
}
