using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Visual indicator showing where a panel will dock during drag operations.
/// Displays semi-transparent highlight over the target drop zone.
public class DockTarget : Control
{
	private DockPosition mPosition = .Center;
	private RectangleF mTargetBounds;
	private bool mIsVisible = false;
	private Color mHighlightColor = Color(60, 120, 200, 100);
	private Color mBorderColor = Color(60, 120, 200, 200);
	private ImageBrush? mOverlayImage;

	/// Creates a new DockTarget.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;
	}

	/// The dock position this target represents.
	public DockPosition Position
	{
		get => mPosition;
		set => mPosition = value;
	}

	/// The bounds where the panel will be placed.
	public RectangleF TargetBounds
	{
		get => mTargetBounds;
		set
		{
			mTargetBounds = value;
			InvalidateLayout();
		}
	}

	/// Whether the target indicator is visible.
	public bool IsTargetVisible
	{
		get => mIsVisible;
		set => mIsVisible = value;
	}

	/// The highlight fill color.
	public Color HighlightColor
	{
		get => mHighlightColor;
		set => mHighlightColor = value;
	}

	/// The border color for the dock target indicator.
	public new Color BorderColor
	{
		get => mBorderColor;
		set => mBorderColor = value;
	}

	/// Image for the overlay (replaces highlight fill + border).
	public ImageBrush? OverlayImage
	{
		get => mOverlayImage;
		set => mOverlayImage = value;
	}

	/// Shows the target at the specified bounds.
	public void Show(RectangleF bounds, DockPosition position)
	{
		mTargetBounds = bounds;
		mPosition = position;
		mIsVisible = true;
	}

	/// Hides the target indicator.
	public void Hide()
	{
		mIsVisible = false;
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		return .(0, 0);  // Takes no space in layout
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		// DockTarget positions itself based on TargetBounds, not parent arrangement
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		if (!mIsVisible || mTargetBounds.Width <= 0 || mTargetBounds.Height <= 0)
			return;

		if (mOverlayImage.HasValue && mOverlayImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mOverlayImage.Value, mTargetBounds);
		}
		else
		{
			// Fill with semi-transparent highlight
			ctx.FillRect(mTargetBounds, mHighlightColor);

			// Draw border
			ctx.DrawRect(mTargetBounds, mBorderColor, 2);
		}
	}

	// === Hit Testing ===

	/// DockTarget is purely visual and should not intercept mouse events.
	public override UIElement HitTest(Vector2 point)
	{
		return null;
	}
}

/// Dock zone indicator buttons shown when dragging over a dock area.
/// Displays the compass-style dock buttons (left/right/top/bottom/center).
public class DockZoneIndicator : Control
{
	private const float ButtonSize = 32;
	private const float ButtonSpacing = 4;
	private const float CenterOffset = 44;  // Distance from center to edge buttons

	private RectangleF mLeftButton;
	private RectangleF mRightButton;
	private RectangleF mTopButton;
	private RectangleF mBottomButton;
	private RectangleF mCenterButton;

	private DockPosition? mHoveredZone = null;
	private bool mIsVisible = false;
	private Vector2 mCenter;

	private Color mButtonColor = Color(60, 60, 60, 220);
	private Color mButtonHoverColor = Color(60, 120, 200, 220);
	private Color mButtonBorderColor = Color(100, 100, 100, 255);
	private Color mArrowColor = Color(200, 200, 200, 255);
	private ImageBrush? mButtonImage;
	private ImageBrush? mButtonHoverImage;

	/// Creates a new DockZoneIndicator.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;
	}

	/// Whether the indicator is visible.
	public bool IsIndicatorVisible
	{
		get => mIsVisible;
		set => mIsVisible = value;
	}

	/// The currently hovered zone, or null.
	public DockPosition? HoveredZone => mHoveredZone;

	/// Image for zone buttons (normal state).
	public ImageBrush? ButtonImage
	{
		get => mButtonImage;
		set => mButtonImage = value;
	}

	/// Image for zone buttons (hovered state).
	public ImageBrush? ButtonHoverImage
	{
		get => mButtonHoverImage;
		set => mButtonHoverImage = value;
	}

	/// Shows the indicator centered at the specified position.
	public void Show(Vector2 center)
	{
		mCenter = center;
		mIsVisible = true;
		UpdateButtonBounds();
	}

	/// Hides the indicator.
	public void Hide()
	{
		mIsVisible = false;
		mHoveredZone = null;
	}

	/// Updates hover state based on mouse position.
	/// Returns the hovered zone, or null if none.
	public DockPosition? UpdateHover(Vector2 point)
	{
		if (!mIsVisible)
		{
			mHoveredZone = null;
			return null;
		}

		if (mCenterButton.Contains(point.X, point.Y))
			mHoveredZone = .Center;
		else if (mLeftButton.Contains(point.X, point.Y))
			mHoveredZone = .Left;
		else if (mRightButton.Contains(point.X, point.Y))
			mHoveredZone = .Right;
		else if (mTopButton.Contains(point.X, point.Y))
			mHoveredZone = .Top;
		else if (mBottomButton.Contains(point.X, point.Y))
			mHoveredZone = .Bottom;
		else
			mHoveredZone = null;

		return mHoveredZone;
	}

	private void UpdateButtonBounds()
	{
		let halfSize = ButtonSize / 2;

		mCenterButton = .(mCenter.X - halfSize, mCenter.Y - halfSize, ButtonSize, ButtonSize);
		mLeftButton = .(mCenter.X - CenterOffset - halfSize, mCenter.Y - halfSize, ButtonSize, ButtonSize);
		mRightButton = .(mCenter.X + CenterOffset - halfSize, mCenter.Y - halfSize, ButtonSize, ButtonSize);
		mTopButton = .(mCenter.X - halfSize, mCenter.Y - CenterOffset - halfSize, ButtonSize, ButtonSize);
		mBottomButton = .(mCenter.X - halfSize, mCenter.Y + CenterOffset - halfSize, ButtonSize, ButtonSize);
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		return .(0, 0);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		if (!mIsVisible)
			return;

		RenderButton(ctx, mCenterButton, .Center);
		RenderButton(ctx, mLeftButton, .Left);
		RenderButton(ctx, mRightButton, .Right);
		RenderButton(ctx, mTopButton, .Top);
		RenderButton(ctx, mBottomButton, .Bottom);
	}

	private void RenderButton(DrawContext ctx, RectangleF bounds, DockPosition position)
	{
		let isHovered = mHoveredZone == position;

		// Button background
		let hoverImg = isHovered ? mButtonHoverImage : (ImageBrush?)null;
		let normalImg = mButtonImage;
		let btnImage = hoverImg.HasValue && hoverImg.Value.IsValid ? hoverImg : normalImg;
		if (btnImage.HasValue && btnImage.Value.IsValid)
		{
			ctx.DrawImageBrush(btnImage.Value, bounds);
		}
		else
		{
			let bgColor = isHovered ? mButtonHoverColor : mButtonColor;
			ctx.FillRect(bounds, bgColor);
			ctx.DrawRect(bounds, mButtonBorderColor, 1);
		}

		// Arrow/icon
		let cx = bounds.X + bounds.Width / 2;
		let cy = bounds.Y + bounds.Height / 2;
		let arrowSize = 8.0f;

		switch (position)
		{
		case .Center:
			// Draw a square
			ctx.FillRect(.(cx - arrowSize/2, cy - arrowSize/2, arrowSize, arrowSize), mArrowColor);

		case .Left:
			// Left arrow
			ctx.DrawLine(.(cx + arrowSize/2, cy - arrowSize/2), .(cx - arrowSize/2, cy), mArrowColor, 2);
			ctx.DrawLine(.(cx - arrowSize/2, cy), .(cx + arrowSize/2, cy + arrowSize/2), mArrowColor, 2);

		case .Right:
			// Right arrow
			ctx.DrawLine(.(cx - arrowSize/2, cy - arrowSize/2), .(cx + arrowSize/2, cy), mArrowColor, 2);
			ctx.DrawLine(.(cx + arrowSize/2, cy), .(cx - arrowSize/2, cy + arrowSize/2), mArrowColor, 2);

		case .Top:
			// Up arrow
			ctx.DrawLine(.(cx - arrowSize/2, cy + arrowSize/2), .(cx, cy - arrowSize/2), mArrowColor, 2);
			ctx.DrawLine(.(cx, cy - arrowSize/2), .(cx + arrowSize/2, cy + arrowSize/2), mArrowColor, 2);

		case .Bottom:
			// Down arrow
			ctx.DrawLine(.(cx - arrowSize/2, cy - arrowSize/2), .(cx, cy + arrowSize/2), mArrowColor, 2);
			ctx.DrawLine(.(cx, cy + arrowSize/2), .(cx + arrowSize/2, cy - arrowSize/2), mArrowColor, 2);

		case .Float:
			// Float icon (small window)
			ctx.DrawRect(.(cx - arrowSize/2, cy - arrowSize/2, arrowSize, arrowSize), mArrowColor, 1);
		}
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (!mIsVisible)
			return null;

		// Check if point is in any button
		if (mCenterButton.Contains(point.X, point.Y) ||
			mLeftButton.Contains(point.X, point.Y) ||
			mRightButton.Contains(point.X, point.Y) ||
			mTopButton.Contains(point.X, point.Y) ||
			mBottomButton.Contains(point.X, point.Y))
		{
			return this;
		}

		return null;
	}
}
