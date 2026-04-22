using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A single item in a Breadcrumb navigation trail.
public class BreadcrumbItem : ContentControl
{
	private Object mValue;  // Navigation value (not owned)
	private int mIndex = -1;
	private bool mIsLast = false;
	private bool mIsHovered = false;
	private ImageBrush? mSegmentImage;

	/// Creates a new BreadcrumbItem.
	public this()
	{
		IsFocusable = false;  // Focus is managed by parent Breadcrumb
	}

	/// Creates a new BreadcrumbItem with text content.
	public this(StringView text) : this()
	{
		Content = new TextBlock(text);
	}

	/// Creates a new BreadcrumbItem with text and associated value.
	public this(StringView text, Object value) : this(text)
	{
		mValue = value;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "BreadcrumbItem";

	/// An optional value associated with this item (for navigation).
	/// The BreadcrumbItem does NOT own this value.
	public Object Value
	{
		get => mValue;
		set => mValue = value;
	}

	/// The index of this item within its parent Breadcrumb.
	public int Index
	{
		get => mIndex;
		set => mIndex = value;
	}

	/// Whether this is the last (current) item in the breadcrumb.
	public bool IsLast
	{
		get => mIsLast;
		set => mIsLast = value;
	}

	/// Whether this item is currently hovered.
	public bool IsItemHovered
	{
		get => mIsHovered;
		set => mIsHovered = value;
	}

	/// Image for the breadcrumb segment background.
	public ImageBrush? SegmentImage
	{
		get => mSegmentImage;
		set => mSegmentImage = value;
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw hover background
		if (mIsHovered && !mIsLast)
		{
			if (mSegmentImage.HasValue && mSegmentImage.Value.IsValid)
			{
				var img = mSegmentImage.Value;
				img.Tint = Palette.Lighten(img.Tint, 0.10f);
				ctx.DrawImageBrush(img, bounds);
			}
			else
			{
				let hoverBg = Palette.ComputeHover(Background.A > 0 ? Background : Color(45, 45, 45, 255));
				ctx.FillRect(bounds, hoverBg);
			}
		}
		else if (mSegmentImage.HasValue && mSegmentImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mSegmentImage.Value, bounds);
		}

		// Render content
		Content?.Render(ctx);
	}
}
