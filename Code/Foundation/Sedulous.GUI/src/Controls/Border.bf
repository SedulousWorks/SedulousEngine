using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A decorator that draws a border and background around its child.
/// Border adds visual chrome (background, border lines, corner radius)
/// around its single child element.
public class Border : Decorator
{
	private Thickness mBorderThickness;
	private Color? mBorderBrush;

	/// Creates a new Border.
	public this()
	{
		// Borders are not focusable by default
		IsFocusable = false;
		IsTabStop = false;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Border";

	/// The thickness of the border on each side.
	public new Thickness BorderThickness
	{
		get => mBorderThickness;
		set
		{
			if (mBorderThickness != value)
			{
				mBorderThickness = value;
				InvalidateLayout();
			}
		}
	}

	/// The color of the border. If not set, uses theme border color.
	public Color BorderBrush
	{
		get => mBorderBrush ?? GetThemeStyle().BorderColor;
		set => mBorderBrush = value;
	}

	// Note: Background and CornerRadius are inherited from Control

	/// Sets uniform border thickness on all sides.
	public void SetBorderThickness(float uniform)
	{
		BorderThickness = .(uniform);
	}

	/// Sets horizontal and vertical border thickness.
	public void SetBorderThickness(float horizontal, float vertical)
	{
		BorderThickness = .(horizontal, vertical);
	}

	/// Measures the child plus border thickness.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Deflate constraints by border thickness for child measurement
		let childConstraints = SizeConstraints(
			Math.Max(0, constraints.MinWidth - mBorderThickness.TotalHorizontal),
			Math.Max(0, constraints.MinHeight - mBorderThickness.TotalVertical),
			constraints.MaxWidth != SizeConstraints.Infinity
				? Math.Max(0, constraints.MaxWidth - mBorderThickness.TotalHorizontal)
				: SizeConstraints.Infinity,
			constraints.MaxHeight != SizeConstraints.Infinity
				? Math.Max(0, constraints.MaxHeight - mBorderThickness.TotalVertical)
				: SizeConstraints.Infinity
		);

		DesiredSize childSize = .Zero;
		if (Child != null && Child.Visibility != .Collapsed)
		{
			childSize = Child.Measure(childConstraints);
		}

		// Add border thickness to child size
		return .(
			childSize.Width + mBorderThickness.TotalHorizontal,
			childSize.Height + mBorderThickness.TotalVertical
		);
	}

	/// Arranges the child within bounds deflated by border thickness.
	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		if (Child != null && Child.Visibility != .Collapsed)
		{
			// Deflate by border thickness
			let childBounds = RectangleF(
				contentBounds.X + mBorderThickness.Left,
				contentBounds.Y + mBorderThickness.Top,
				Math.Max(0, contentBounds.Width - mBorderThickness.TotalHorizontal),
				Math.Max(0, contentBounds.Height - mBorderThickness.TotalVertical)
			);
			Child.Arrange(childBounds);
		}
	}

	/// Renders background, child, then border.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;
		let bgColor = Background;
		let borderColor = BorderBrush;

		// Draw background
		if (bgColor.A > 0)
		{
			if (CornerRadius > 0)
				ctx.FillRoundedRect(bounds, CornerRadius, bgColor);
			else
				ctx.FillRect(bounds, bgColor);
		}

		// Draw child
		if (Child != null)
			Child.Render(ctx);

		// Draw border (after child so it appears on top)
		if (!mBorderThickness.IsZero && borderColor.A > 0)
		{
			if (mBorderThickness.IsUniform)
			{
				// Uniform border - use UI border methods (stroke inside bounds)
				if (CornerRadius > 0)
					ctx.DrawBorderRoundedRect(bounds, CornerRadius, borderColor, mBorderThickness.Left);
				else
					ctx.DrawBorderRect(bounds, borderColor, mBorderThickness.Left);
			}
			else
			{
				// Non-uniform border - draw each side separately (already fills inside bounds)
				DrawNonUniformBorder(ctx, bounds, borderColor);
			}
		}
	}

	/// Draws a border with different thicknesses on each side.
	private void DrawNonUniformBorder(DrawContext ctx, RectangleF bounds, Color color)
	{
		// Top border
		if (mBorderThickness.Top > 0)
		{
			ctx.FillRect(.(bounds.X, bounds.Y, bounds.Width, mBorderThickness.Top), color);
		}

		// Bottom border
		if (mBorderThickness.Bottom > 0)
		{
			ctx.FillRect(.(bounds.X, bounds.Bottom - mBorderThickness.Bottom, bounds.Width, mBorderThickness.Bottom), color);
		}

		// Left border (between top and bottom)
		if (mBorderThickness.Left > 0)
		{
			let top = bounds.Y + mBorderThickness.Top;
			let height = bounds.Height - mBorderThickness.Top - mBorderThickness.Bottom;
			if (height > 0)
				ctx.FillRect(.(bounds.X, top, mBorderThickness.Left, height), color);
		}

		// Right border (between top and bottom)
		if (mBorderThickness.Right > 0)
		{
			let top = bounds.Y + mBorderThickness.Top;
			let height = bounds.Height - mBorderThickness.Top - mBorderThickness.Bottom;
			if (height > 0)
				ctx.FillRect(.(bounds.Right - mBorderThickness.Right, top, mBorderThickness.Right, height), color);
		}
	}
}
