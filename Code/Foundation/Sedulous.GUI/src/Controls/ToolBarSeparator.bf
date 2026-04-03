using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A separator line for use in toolbars.
/// Renders as a vertical line in horizontal toolbars, horizontal line in vertical toolbars.
public class ToolBarSeparator : Control
{
	private Orientation mOrientation = .Vertical;
	private float mThickness = 1;
	private float mMargin = 4;
	private Color mLineColor = Color(80, 80, 80, 255);
	private ImageBrush? mDividerImage;

	/// Creates a new ToolBarSeparator.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies theme defaults for toolbar separator.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		let palette = theme?.Palette ?? Palette();
		mThickness = theme?.SeparatorThickness ?? 1;
		mLineColor = palette.Border.A > 0 ? palette.Border : Color(80, 80, 80, 255);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ToolBarSeparator";

	/// The orientation of the separator line.
	/// Set automatically by the parent ToolBar.
	public Orientation Orientation
	{
		get => mOrientation;
		set
		{
			if (mOrientation != value)
			{
				mOrientation = value;
				InvalidateLayout();
			}
		}
	}

	/// The thickness of the separator line.
	public float Thickness
	{
		get => mThickness;
		set
		{
			if (mThickness != value)
			{
				mThickness = value;
				InvalidateLayout();
			}
		}
	}

	/// The margin around the line.
	public float LineMargin
	{
		get => mMargin;
		set
		{
			if (mMargin != value)
			{
				mMargin = value;
				InvalidateLayout();
			}
		}
	}

	/// The color of the separator line.
	public Color LineColor
	{
		get => mLineColor;
		set => mLineColor = value;
	}

	/// Image for the divider (replaces drawn line).
	public ImageBrush? DividerImage
	{
		get => mDividerImage;
		set => mDividerImage = value;
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		if (mOrientation == .Vertical)
		{
			// Vertical line - takes minimal horizontal space
			return .(mThickness + mMargin * 2, 0);
		}
		else
		{
			// Horizontal line - takes minimal vertical space
			return .(0, mThickness + mMargin * 2);
		}
	}

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		if (mDividerImage.HasValue && mDividerImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mDividerImage.Value, bounds);
		}
		else if (mOrientation == .Vertical)
		{
			let x = bounds.X + bounds.Width / 2;
			ctx.DrawLine(.(x, bounds.Y + mMargin), .(x, bounds.Bottom - mMargin), mLineColor, mThickness);
		}
		else
		{
			let y = bounds.Y + bounds.Height / 2;
			ctx.DrawLine(.(bounds.X + mMargin, y), .(bounds.Right - mMargin, y), mLineColor, mThickness);
		}
	}
}
