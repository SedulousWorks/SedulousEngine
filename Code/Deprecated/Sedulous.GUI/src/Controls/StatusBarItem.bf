using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A segment in a status bar.
/// Can display text and optionally be clickable.
public class StatusBarItem : Control
{
	private String mText ~ delete _;
	private TextBlock mTextBlock ~ delete _;
	private bool mIsClickable = false;
	private bool mIsFlexible = false;  // Whether this item stretches to fill available space
	private ImageBrush? mBackgroundImage;

	// Click event
	private EventAccessor<delegate void(StatusBarItem)> mClick = new .() ~ delete _;

	/// Creates a new StatusBarItem.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;

		mTextBlock = new TextBlock();
	}

	/// Creates a new StatusBarItem with text.
	public this(StringView text) : this()
	{
		Text = text;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "StatusBarItem";

	/// The text to display.
	public StringView Text
	{
		get => mText ?? "";
		set
		{
			if (mText == null)
				mText = new String();
			mText.Set(value);
			mTextBlock.Text = value;
			InvalidateLayout();
		}
	}

	/// Whether this item is clickable.
	public bool IsClickable
	{
		get => mIsClickable;
		set => mIsClickable = value;
	}

	/// Whether this item stretches to fill available space.
	public bool IsFlexible
	{
		get => mIsFlexible;
		set
		{
			if (mIsFlexible != value)
			{
				mIsFlexible = value;
				InvalidateLayout();
			}
		}
	}

	/// Event fired when the item is clicked (if IsClickable is true).
	public EventAccessor<delegate void(StatusBarItem)> Click => mClick;

	/// Image for the item background.
	public ImageBrush? ItemBackgroundImage
	{
		get => mBackgroundImage;
		set => mBackgroundImage = value;
	}

	// Input handling

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (mIsClickable && e.Button == .Left)
		{
			mClick.[Friend]Invoke(this);
			e.Handled = true;
		}
	}

	// Layout

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		mTextBlock.Measure(constraints);
		let textSize = mTextBlock.DesiredSize;

		float width = textSize.Width + Padding.Left + Padding.Right;
		width = Math.Max(width, MinWidth);
		width = Math.Min(width, MaxWidth);

		// Flexible items report 0 width and will be expanded during arrange
		if (mIsFlexible)
			width = Math.Max(MinWidth, Padding.Left + Padding.Right);

		return .(width, textSize.Height + Padding.Top + Padding.Bottom);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		let textBounds = RectangleF(
			contentBounds.X + Padding.Left,
			contentBounds.Y + Padding.Top,
			contentBounds.Width - Padding.Left - Padding.Right,
			contentBounds.Height - Padding.Top - Padding.Bottom
		);
		mTextBlock.Arrange(textBounds);
	}

	// Rendering

	protected override void RenderOverride(DrawContext ctx)
	{
		// Try image-based background first
		if (mBackgroundImage.HasValue && mBackgroundImage.Value.IsValid)
		{
			var img = mBackgroundImage.Value;
			if (mIsClickable && IsHovered)
				img.Tint = Palette.Lighten(img.Tint, 0.10f);
			ctx.DrawImageBrush(img, ArrangedBounds);
		}
		else if (mIsClickable && IsHovered)
		{
			// Hover highlight for clickable items
			let palette = Context?.Theme?.Palette ?? Palette();
			let surfaceColor = palette.Surface.A > 0 ? palette.Surface : Color(45, 45, 45, 255);
			let hoverColor = Palette.ComputeHover(surfaceColor);
			ctx.FillRect(ArrangedBounds, Color(hoverColor.R, hoverColor.G, hoverColor.B, 128));
		}

		// Text
		mTextBlock.Foreground = Foreground;
		mTextBlock.Render(ctx);
	}

	// Hit testing - return self, not child TextBlock

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Return self to receive mouse events
		return this;
	}

	// Visual children

	public override int VisualChildCount => 1;
	public override UIElement GetVisualChild(int index) => index == 0 ? mTextBlock : null;

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mTextBlock.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		mTextBlock.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}
}
