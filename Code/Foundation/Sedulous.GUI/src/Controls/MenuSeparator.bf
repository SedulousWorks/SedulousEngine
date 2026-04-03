using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A horizontal separator line in a menu.
public class MenuSeparator : Control
{
	private float mHeight = 9;
	private float mLineThickness = 1;
	private Color mLineColor = Color(80, 80, 80, 255);
	private float mMarginLeft = 8;
	private float mMarginRight = 8;
	private ImageBrush? mDividerImage;

	/// Creates a new MenuSeparator.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;
		Background = Color.Transparent;
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies theme defaults for menu separator.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		let palette = theme?.Palette ?? Palette();
		mLineThickness = theme?.SeparatorThickness ?? 1;
		mLineColor = palette.Border.A > 0 ? palette.Border : Color(80, 80, 80, 255);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "MenuSeparator";

	/// The color of the separator line.
	public Color LineColor
	{
		get => mLineColor;
		set => mLineColor = value;
	}

	/// The thickness of the separator line.
	public float LineThickness
	{
		get => mLineThickness;
		set => mLineThickness = value;
	}

	/// Image for the divider (replaces drawn line).
	public ImageBrush? DividerImage
	{
		get => mDividerImage;
		set => mDividerImage = value;
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Return minimal width - separator will stretch to fill available space during arrange
		return .(0, mHeight);
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		if (mDividerImage.HasValue && mDividerImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mDividerImage.Value, bounds);
		}
		else
		{
			let centerY = bounds.Y + bounds.Height / 2;
			let startX = bounds.X + mMarginLeft;
			let endX = bounds.Right - mMarginRight;
			ctx.DrawLine(.(startX, centerY), .(endX, centerY), mLineColor, mLineThickness);
		}
	}
}
