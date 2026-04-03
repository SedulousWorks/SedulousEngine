using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A checkbox control with a check indicator and optional label text.
public class CheckBox : ToggleButton
{
	private float mBoxSize = 18;
	private float mBoxSpacing = 8;
	private ImageBrush? mUncheckedImage;
	private ImageBrush? mCheckedImage;
	private ImageBrush? mIndeterminateImage;

	/// Creates a new CheckBox.
	public this() : base()
	{
	}

	/// Creates a new CheckBox with text content.
	public this(StringView text) : base()
	{
		// Create TextBlock with left alignment (not center like Button)
		let textBlock = new TextBlock(text);
		textBlock.TextAlignment = .Left;
		textBlock.VerticalAlignment = .Center;
		Content = textBlock;
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies theme defaults for checkbox dimensions.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		mBoxSize = theme?.CheckBoxSize ?? 18;
		mBoxSpacing = theme?.CheckBoxSpacing ?? 8;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "CheckBox";

	/// The size of the checkbox indicator (default 18).
	public float BoxSize
	{
		get => mBoxSize;
		set => mBoxSize = Math.Max(12, value);
	}

	/// The spacing between the checkbox and content (default 8).
	public float BoxSpacing
	{
		get => mBoxSpacing;
		set => mBoxSpacing = Math.Max(0, value);
	}

	/// Image for the unchecked indicator box.
	public ImageBrush? UncheckedImage
	{
		get => mUncheckedImage;
		set => mUncheckedImage = value;
	}

	/// Image for the checked indicator box (includes checkmark in the texture).
	public ImageBrush? CheckedImage
	{
		get => mCheckedImage;
		set => mCheckedImage = value;
	}

	/// Image for the indeterminate indicator box.
	public ImageBrush? IndeterminateImage
	{
		get => mIndeterminateImage;
		set => mIndeterminateImage = value;
	}

	/// Measures the checkbox with its indicator and content.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure content
		DesiredSize contentSize = .Zero;
		if (Content != null)
		{
			let contentConstraints = constraints.Deflate(Thickness(mBoxSize + mBoxSpacing, 0));
			contentSize = Content.Measure(contentConstraints);
		}

		// Total size: box + spacing + content
		return DesiredSize(
			mBoxSize + mBoxSpacing + contentSize.Width,
			Math.Max(mBoxSize, contentSize.Height)
		);
	}

	/// Arranges the checkbox content.
	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		if (Content != null)
		{
			// Content goes to the right of the checkbox
			let contentX = contentBounds.X + mBoxSize + mBoxSpacing;
			let contentWidth = contentBounds.Width - mBoxSize - mBoxSpacing;
			let contentBoundsAdjusted = RectangleF(
				contentX,
				contentBounds.Y,
				contentWidth,
				contentBounds.Height
			);
			Content.Arrange(contentBoundsAdjusted);
		}
	}

	/// Renders the checkbox with its indicator and content.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;
		let style = GetThemeStyle();

		// Calculate checkbox box position (vertically centered)
		let boxY = bounds.Y + (bounds.Height - mBoxSize) / 2;
		let boxRect = RectangleF(bounds.X, boxY, mBoxSize, mBoxSize);

		// Try image-based indicator first
		ImageBrush? indicatorImage = IsChecked ? mCheckedImage : mUncheckedImage;
		if (indicatorImage.HasValue && indicatorImage.Value.IsValid)
		{
			var img = indicatorImage.Value;
			img.Tint = ControlStyle.ModulateTint(img.Tint, CurrentState);
			ctx.DrawImageBrush(img, boxRect);
		}
		else
		{
			// Get colors based on state
			let bgColor = IsChecked ? GetCheckedBackground() : GetStateBackground();
			let borderColor = GetStateBorderColor();

			// Draw checkbox background
			let cornerRadius = style.CornerRadius > 0 ? style.CornerRadius : (Context?.Theme?.DefaultCornerRadius ?? 3f);
			if (bgColor.A > 0)
			{
				ctx.FillRoundedRect(boxRect, cornerRadius, bgColor);
			}

			// Draw checkbox border
			if (style.BorderThickness > 0 && borderColor.A > 0)
			{
				ctx.DrawBorderRoundedRect(boxRect, cornerRadius, borderColor, style.BorderThickness);
			}

			// Draw checkmark if checked
			if (IsChecked)
			{
				let checkColor = GetStateForeground();
				DrawCheckmark(ctx, boxRect, checkColor);
			}
		}

		// Draw content (label text)
		Content?.Render(ctx);

		// Draw focus indicator around checkbox
		if (IsFocused)
		{
			let cornerRadius = style.CornerRadius > 0 ? style.CornerRadius : (Context?.Theme?.DefaultCornerRadius ?? 3f);
			let focusColor = FocusBorderColor;
			let focusThickness = FocusBorderThickness;
			let focusBounds = RectangleF(
				boxRect.X - focusThickness,
				boxRect.Y - focusThickness,
				boxRect.Width + focusThickness * 2,
				boxRect.Height + focusThickness * 2
			);
			ctx.DrawRoundedRect(focusBounds, cornerRadius + focusThickness, focusColor, focusThickness);
		}
	}

	/// Draws a checkmark inside the given rectangle.
	private void DrawCheckmark(DrawContext ctx, RectangleF boxRect, Color color)
	{
		// Checkmark as three lines forming a check
		let padding = mBoxSize * 0.2f;
		let x = boxRect.X + padding;
		let y = boxRect.Y + padding;
		let w = boxRect.Width - padding * 2;
		let h = boxRect.Height - padding * 2;

		// Checkmark path: start at left middle, go down to bottom, then up to right top
		let thickness = 2f;
		let p1 = Vector2(x, y + h * 0.5f);              // Left middle
		let p2 = Vector2(x + w * 0.35f, y + h * 0.85f); // Bottom
		let p3 = Vector2(x + w, y + h * 0.15f);         // Right top

		ctx.DrawLine(p1, p2, color, thickness);
		ctx.DrawLine(p2, p3, color, thickness);
	}

	/// Gets the background color for the checkbox box.
	protected override Color GetStateBackground()
	{
		// Use surface color for unchecked background
		if (!IsChecked)
		{
			if (let theme = Context?.Theme)
				return theme.Palette.Surface;
			return Color(255, 255, 255, 255); // Fallback white
		}
		return base.GetStateBackground();
	}
}
