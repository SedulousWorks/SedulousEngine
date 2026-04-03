using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// An item displayed in a TileView as a tile with custom content.
/// Extends ContentControl to allow any UIElement as tile content.
public class TileViewItem : ContentControl, ISelectable
{
	// Selection state
	private bool mIsSelected = false;

	// User data
	private Object mTag;

	// Index in parent TileView
	private int mIndex = -1;

	// Hover state (set by parent TileView)
	internal bool mIsHovered = false;

	// Image support
	private ImageBrush? mSelectionImage;
	private ImageBrush? mHoverImage;

	/// Creates a new TileViewItem.
	public this()
	{
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "TileViewItem";

	/// Whether this item is selected (ISelectable).
	public bool IsSelected
	{
		get => mIsSelected;
		set
		{
			if (mIsSelected != value)
			{
				mIsSelected = value;
			}
		}
	}

	/// The index of this item in the parent TileView.
	public int Index
	{
		get => mIndex;
		set => mIndex = value;
	}

	/// User-defined data associated with this item.
	public Object Tag
	{
		get => mTag;
		set => mTag = value;
	}

	/// Image for the selected tile background.
	public ImageBrush? SelectionImage
	{
		get => mSelectionImage;
		set => mSelectionImage = value;
	}

	/// Image for the hovered tile background.
	public ImageBrush? HoverImage
	{
		get => mHoverImage;
		set => mHoverImage = value;
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure content within the tile bounds
		if (Content != null && Content.Visibility != .Collapsed)
			Content.Measure(constraints);

		// TileViewItem uses the size set by parent TileView
		return .(constraints.MaxWidth, constraints.MaxHeight);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		// Arrange content within the tile bounds (with padding for selection border)
		if (Content != null && Content.Visibility != .Collapsed)
		{
			let padding = 4f;
			let innerBounds = RectangleF(
				contentBounds.X + padding,
				contentBounds.Y + padding,
				contentBounds.Width - padding * 2,
				contentBounds.Height - padding * 2
			);
			Content.Arrange(innerBounds);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Try image-based backgrounds first
		if (mIsSelected && mSelectionImage.HasValue && mSelectionImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mSelectionImage.Value, bounds);
		}
		else if (mIsHovered && !mIsSelected && mHoverImage.HasValue && mHoverImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mHoverImage.Value, bounds);
		}
		else
		{
			// Get theme colors
			let theme = Context?.Theme;
			let palette = theme?.Palette ?? Palette();
			let selectionColor = theme?.SelectionColor ?? palette.Accent;

			// Get colors for selection/hover state
			Color bgColor = Color.Transparent;
			Color borderColor = Color.Transparent;

			if (mIsSelected)
			{
				bgColor = selectionColor.A > 0 ? selectionColor : Color(0, 120, 215, 255);
				borderColor = bgColor;
			}
			else if (mIsHovered)
			{
				let baseColor = palette.Surface.A > 0 ? palette.Surface : Color(45, 45, 45, 255);
				bgColor = Palette.ComputeHover(baseColor);
				borderColor = palette.Border.A > 0 ? palette.Border : Color(80, 80, 80, 255);
			}

			// Draw background
			if (bgColor.A > 0)
				ctx.FillRect(bounds, bgColor);

			// Draw border
			if (borderColor.A > 0)
				ctx.DrawRect(bounds, borderColor, 1);
		}

		// Render content
		Content?.Render(ctx);
	}
}
