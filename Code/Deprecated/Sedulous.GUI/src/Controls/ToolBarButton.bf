using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Display modes for toolbar buttons.
public enum ToolBarButtonDisplayMode
{
	/// Show only the icon.
	IconOnly,
	/// Show only the text.
	TextOnly,
	/// Show icon and text side by side.
	IconAndText
}

/// A flat-styled button for use in toolbars.
/// Has transparent background by default, shows border only on hover.
///
/// ## Icon Support (Future Enhancement)
///
/// Currently supports text-only buttons. For icon support, consider these approaches:
///
/// **Approach 1: Use ContentControl directly (works today)**
/// Since ToolBarButton extends Button (a ContentControl), set any content:
/// ```
/// let btn = new ToolBarButton();
/// btn.Content = new Image(iconTexture);  // Icon only
/// // Or combine icon + text with a StackPanel
/// ```
///
/// **Approach 2: Add Icon property + DisplayMode (recommended for future)**
/// Add an Icon property that accepts a texture/image source. The button would
/// internally create the appropriate content layout based on DisplayMode:
/// - IconOnly: Just the icon
/// - TextOnly: Just text (current behavior)
/// - IconAndText: Horizontal StackPanel with icon and text
///
/// **Approach 3: Factory methods on ToolBar**
/// Add convenience methods like AddIconButton(), AddTextButton(), AddIconTextButton()
/// to the ToolBar container class.
///
public class ToolBarButton : Button
{
	private ToolBarButtonDisplayMode mDisplayMode = .TextOnly;
	private ImageBrush? mButtonImage;

	/// Creates a new ToolBarButton.
	public this() : base()
	{
	}

	/// Creates a new ToolBarButton with text.
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
	protected override StringView ControlTypeName => "ToolBarButton";

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

	/// Renders the button with flat toolbar styling.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Try image-based background first
		if (mButtonImage.HasValue && mButtonImage.Value.IsValid)
		{
			if (IsHovered || IsPressed)
			{
				var img = mButtonImage.Value;
				img.Tint = ControlStyle.ModulateTint(img.Tint, CurrentState);
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

			// Only show background on hover/pressed
			if (IsHovered || IsPressed)
			{
				let bgColor = IsPressed ? accentColor : Palette.ComputeHover(surfaceColor);
				ctx.FillRect(bounds, bgColor);
				ctx.DrawRect(bounds, borderColor, 1);
			}
		}

		// Render content (text)
		Content?.Render(ctx);
	}
}
