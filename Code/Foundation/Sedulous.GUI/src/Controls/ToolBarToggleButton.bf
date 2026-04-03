using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A toggle button for use in toolbars.
/// Shows checked state with background highlight.
public class ToolBarToggleButton : ToggleButton
{
	private ToolBarButtonDisplayMode mDisplayMode = .TextOnly;
	private ImageBrush? mButtonImage;

	/// Creates a new ToolBarToggleButton.
	public this() : base()
	{
	}

	/// Creates a new ToolBarToggleButton with text.
	public this(StringView text) : base(text)
	{
	}

	/// Gets the button text (from TextBlock content).
	public StringView Text
	{
		get
		{
			if (let textBlock = Content as TextBlock)
				return textBlock.Text;
			return "";
		}
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ToolBarToggleButton";

	/// The display mode for this button.
	public ToolBarButtonDisplayMode DisplayMode
	{
		get => mDisplayMode;
		set
		{
			if (mDisplayMode != value)
			{
				mDisplayMode = value;
				InvalidateLayout();
			}
		}
	}

	/// Image for the button background (per-state via auto-tint).
	public ImageBrush? ButtonImage
	{
		get => mButtonImage;
		set => mButtonImage = value;
	}

	/// Renders the toggle button with flat toolbar styling.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Try image-based background first
		if (mButtonImage.HasValue && mButtonImage.Value.IsValid)
		{
			if (IsChecked || IsHovered || IsPressed)
			{
				var img = mButtonImage.Value;
				img.Tint = ControlStyle.ModulateTint(img.Tint, CurrentState);
				if (IsChecked && !IsPressed)
					img.Tint = Palette.Darken(img.Tint, 0.1f);
				ctx.DrawImageBrush(img, bounds);
			}
		}
		else
		{
			// Get theme colors
			let palette = Context?.Theme?.Palette ?? Palette();
			let surfaceColor = palette.Surface.A > 0 ? palette.Surface : Color(45, 45, 45, 255);
			let accentColor = palette.Accent.A > 0 ? palette.Accent : Color(60, 120, 200, 255);
			let borderColor = palette.Border.A > 0 ? palette.Border : Color(100, 100, 100, 255);

			// Background when checked, hovered, or pressed
			if (IsChecked || IsHovered || IsPressed)
			{
				Color bgColor;
				if (IsPressed)
					bgColor = accentColor;
				else if (IsChecked)
					bgColor = Palette.Darken(accentColor, 0.15f);
				else
					bgColor = Palette.ComputeHover(surfaceColor);

				ctx.FillRect(bounds, bgColor);

				let checkedBorderColor = IsChecked ? Palette.Lighten(accentColor, 0.2f) : borderColor;
				ctx.DrawRect(bounds, checkedBorderColor, 1);
			}
		}

		// Render content (text)
		Content?.Render(ctx);
	}
}
