using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A popup that displays helpful information when hovering over a control.
public class Tooltip : ContentControl
{
	// Text content (alternative to setting Content directly)
	private String mText ~ delete _;

	/// Creates a new Tooltip.
	public this()
	{
		// Don't stretch to fill container - size to content
		HorizontalAlignment = .Left;
		VerticalAlignment = .Top;
	}

	/// Applies theme-based styling on attach.
	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies default tooltip styling from theme.
	private void ApplyThemeDefaults()
	{
		let style = GetThemeStyle();
		let theme = Context?.Theme;
		let palette = theme?.Palette ?? Palette();

		// Apply style properties, with sensible fallbacks for tooltip appearance
		Background = style.Background.A > 0 ? style.Background : Color(palette.Surface.R, palette.Surface.G, palette.Surface.B, 240);
		Foreground = style.Foreground.A > 0 ? style.Foreground : palette.Text;
		Padding = style.Padding.Left > 0 || style.Padding.Top > 0 ? style.Padding : .(8, 4, 8, 4);
		CornerRadius = style.CornerRadius > 0 ? style.CornerRadius : (theme?.DefaultCornerRadius ?? 4);
		base.BorderColor = style.BorderColor.A > 0 ? style.BorderColor : palette.Border;
		base.BorderThickness = style.BorderThickness > 0 ? style.BorderThickness : 1;
	}

	/// Creates a new Tooltip with text.
	public this(StringView text) : this()
	{
		Text = text;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Tooltip";

	/// The text displayed in the tooltip.
	/// Setting this creates a TextBlock as content.
	public StringView Text
	{
		get => mText ?? "";
		set
		{
			if (mText == null)
				mText = new String(value);
			else
				mText.Set(value);

			// Create or update TextBlock content
			if (Content == null || !(Content is TextBlock))
			{
				Content = new TextBlock(value);
			}
			else if (let textBlock = Content as TextBlock)
			{
				textBlock.Text = value;
			}
		}
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure content
		var size = base.MeasureOverride(constraints);

		// Add padding
		size.Width += Padding.Left + Padding.Right;
		size.Height += Padding.Top + Padding.Bottom;

		return size;
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		// Arrange content with padding
		let innerBounds = RectangleF(
			contentBounds.X + Padding.Left,
			contentBounds.Y + Padding.Top,
			contentBounds.Width - Padding.Left - Padding.Right,
			contentBounds.Height - Padding.Top - Padding.Bottom
		);

		if (Content != null && Content.Visibility != .Collapsed)
			Content.Arrange(innerBounds);
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Try image-based background first (replaces background + border)
		let bgImage = GetStateBackgroundImage();
		if (bgImage.HasValue && bgImage.Value.IsValid)
		{
			ctx.DrawImageBrush(bgImage.Value, bounds);
		}
		else
		{
			let cornerRadius = CornerRadius;
			let borderColor = BorderColor;
			let borderThickness = BorderThickness;

			// Draw background with rounded corners
			if (Background.A > 0)
			{
				if (cornerRadius > 0)
					ctx.FillRoundedRect(bounds, cornerRadius, Background);
				else
					ctx.FillRect(bounds, Background);
			}

			// Draw border
			if (borderColor.A > 0 && borderThickness > 0)
			{
				if (cornerRadius > 0)
					ctx.DrawRoundedRect(bounds, cornerRadius, borderColor, borderThickness);
				else
					ctx.DrawRect(bounds, borderColor, borderThickness);
			}
		}

		// Render content
		Content?.Render(ctx);
	}
}
