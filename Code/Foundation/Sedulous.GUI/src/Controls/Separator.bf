using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A visual divider line used to separate sections of UI.
/// Can be oriented horizontally or vertically.
public class Separator : Control
{
	private Orientation mOrientation = .Horizontal;
	private float mThickness = 1;
	private Color? mLineColor;
	private ImageBrush? mLineImage;

	/// Creates a new Separator.
	public this()
	{
		// Separators are not focusable
		IsFocusable = false;
		IsTabStop = false;
	}

	/// Creates a new Separator with the specified orientation.
	public this(Orientation orientation) : this()
	{
		mOrientation = orientation;
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies theme defaults for separator thickness.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		mThickness = theme?.SeparatorThickness ?? 1;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Separator";

	/// The orientation of the separator line.
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

	/// The thickness of the separator line in pixels.
	public float Thickness
	{
		get => mThickness;
		set
		{
			if (mThickness != value)
			{
				mThickness = Math.Max(1, value);
				InvalidateLayout();
			}
		}
	}

	/// The color of the separator line. If not set, uses theme border color.
	public Color LineColor
	{
		get => mLineColor ?? GetThemeStyle().BorderColor;
		set => mLineColor = value;
	}

	/// Image for the separator line (replaces color-based line).
	public ImageBrush? LineImage
	{
		get => mLineImage;
		set => mLineImage = value;
	}

	/// Measures the separator.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		switch (mOrientation)
		{
		case .Horizontal:
			// Horizontal separator: thin height, stretch width
			let width = constraints.MaxWidth != SizeConstraints.Infinity
				? constraints.MaxWidth
				: 100; // Default width if unconstrained
			return .(width, mThickness);

		case .Vertical:
			// Vertical separator: thin width, stretch height
			let height = constraints.MaxHeight != SizeConstraints.Infinity
				? constraints.MaxHeight
				: 100; // Default height if unconstrained
			return .(mThickness, height);
		}
	}

	/// Renders the separator line.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		if (mLineImage.HasValue && mLineImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mLineImage.Value, bounds);
			return;
		}

		let color = LineColor;
		if (color.A == 0)
			return;

		switch (mOrientation)
		{
		case .Horizontal:
			let y = bounds.Y + (bounds.Height - mThickness) / 2;
			ctx.FillRect(.(bounds.X, y, bounds.Width, mThickness), color);

		case .Vertical:
			let x = bounds.X + (bounds.Width - mThickness) / 2;
			ctx.FillRect(.(x, bounds.Y, mThickness, bounds.Height), color);
		}
	}
}
