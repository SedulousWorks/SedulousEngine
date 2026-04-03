using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Visual container for items in a ListBox.
/// Displays content with selection highlighting when selected.
public class ListBoxItem : ContentControl, ISelectable
{
	private bool mIsSelected = false;
	private int mIndex = -1;
	private ImageBrush? mSelectionImage;
	private ImageBrush? mHoverImage;

	/// Creates a new ListBoxItem.
	public this()
	{
		// ListBoxItems are focusable for keyboard navigation within the list
		IsFocusable = false;  // Focus is managed by parent ListBox
		IsTabStop = false;
	}

	/// Creates a new ListBoxItem with text content.
	public this(StringView text) : this()
	{
		Content = new TextBlock(text);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ListBoxItem";

	/// Gets or sets whether this item is selected.
	public bool IsSelected
	{
		get => mIsSelected;
		set
		{
			if (mIsSelected != value)
			{
				mIsSelected = value;
				// Visual update will happen on next render
			}
		}
	}

	/// The index of this item within its parent ItemsControl.
	public int Index
	{
		get => mIndex;
		set => mIndex = value;
	}

	/// Gets the selection background color from theme.
	protected Color SelectionBackground
	{
		get
		{
			if (Context?.Theme != null)
				return Context.Theme.SelectionColor;
			return Color(51, 153, 255, 255);  // Default selection blue
		}
	}

	/// Image for the selected row background.
	public ImageBrush? SelectionImage
	{
		get => mSelectionImage;
		set => mSelectionImage = value;
	}

	/// Image for the hovered row background.
	public ImageBrush? HoverImage
	{
		get => mHoverImage;
		set => mHoverImage = value;
	}

	/// Renders the item with selection highlight if selected.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Try image-based backgrounds first
		if (mIsSelected && mSelectionImage.HasValue && mSelectionImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mSelectionImage.Value, bounds);
		}
		else if (!mIsSelected && IsHoveredByParent && mHoverImage.HasValue && mHoverImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mHoverImage.Value, bounds);
		}
		else
		{
			// Draw background with state (selected or hover)
			let bgColor = GetStateBackground();
			ctx.FillRect(bounds, bgColor);
		}

		// Draw content
		Content?.Render(ctx);
	}

	/// Gets the background color based on selection and hover state.
	protected override Color GetStateBackground()
	{
		if (mIsSelected)
			return SelectionBackground;

		// Check if parent ListBox has this item hovered
		let isHovered = IsHoveredByParent;

		// Use item's background, or parent ListBox's background if transparent
		var baseColor = Background;
		if (baseColor.A == 0)
		{
			// Get ListBox's background for hover calculation
			if (let listBox = Parent?.Parent?.Parent as ListBox)
				baseColor = listBox.Background;
		}

		if (isHovered)
			return Palette.ComputeHover(baseColor);

		return Background;  // Return original (possibly transparent) for non-hover
	}

	/// Checks if the parent ListBox has this item as hovered.
	private bool IsHoveredByParent
	{
		get
		{
			// Parent chain: ListBoxItem → StackPanel → ScrollViewer → ListBox
			if (let listBox = Parent?.Parent?.Parent as ListBox)
				return listBox.IsItemHovered(mIndex);
			return false;
		}
	}

	/// Hit test returns this item (not the content).
	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		return this;
	}
}
