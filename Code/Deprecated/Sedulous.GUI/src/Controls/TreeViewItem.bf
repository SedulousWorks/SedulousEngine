using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// An item in a TreeView that can contain child items.
public class TreeViewItem : Control, ISelectable
{
	// Text content
	private String mText ~ delete _;

	// Selection state
	private bool mIsSelected = false;

	// Expansion state
	private bool mIsExpanded = true;

	// User data
	private Object mTag;

	// Tree structure
	private TreeViewItem mParentItem;  // Reference only, not owned
	private List<TreeViewItem> mChildren = new .() ~ DeleteContainerAndItems!(_);
	private int mIndentLevel = 0;

	// Layout constants
	private const float cExpanderSize = 16;
	private const float cIndentWidth = 20;
	private const float cItemHeight = 24;

	// Hover state (set by parent TreeView)
	internal bool mIsHovered = false;

	// Image support
	private ImageBrush? mSelectionImage;
	private ImageBrush? mHoverImage;
	private ImageBrush? mExpandedArrowImage;
	private ImageBrush? mCollapsedArrowImage;

	/// Creates a new TreeViewItem.
	public this()
	{
	}

	/// Creates a new TreeViewItem with text.
	public this(StringView text) : this()
	{
		mText = new String(text);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "TreeViewItem";

	/// The text displayed for this item.
	public StringView Text
	{
		get => mText ?? "";
		set
		{
			if (mText == null)
				mText = new String(value);
			else
				mText.Set(value);
		}
	}

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

	/// Whether this item is expanded (showing children).
	public bool IsExpanded
	{
		get => mIsExpanded;
		set
		{
			if (mIsExpanded != value)
			{
				mIsExpanded = value;
				// Notify parent TreeView to rebuild visible items
				if (let tree = FindParentTree())
					tree.[Friend]OnItemExpandedChanged(this);
			}
		}
	}

	/// Whether this item has children.
	public bool HasChildren => mChildren.Count > 0;

	/// The number of direct children.
	public int ChildCount => mChildren.Count;

	/// The parent item (null for root items).
	public TreeViewItem ParentItem => mParentItem;

	/// The indent level (0 for root items).
	public int IndentLevel
	{
		get => mIndentLevel;
		internal set => mIndentLevel = value;
	}

	/// User-defined data associated with this item.
	public Object Tag
	{
		get => mTag;
		set => mTag = value;
	}

	/// Image for selected row background.
	public ImageBrush? SelectionImage
	{
		get => mSelectionImage;
		set => mSelectionImage = value;
	}

	/// Image for hovered row background.
	public ImageBrush? HoverImage
	{
		get => mHoverImage;
		set => mHoverImage = value;
	}

	/// Image for the expanded state arrow (replaces drawn triangle).
	public ImageBrush? ExpandedArrowImage
	{
		get => mExpandedArrowImage;
		set => mExpandedArrowImage = value;
	}

	/// Image for the collapsed state arrow (replaces drawn triangle).
	public ImageBrush? CollapsedArrowImage
	{
		get => mCollapsedArrowImage;
		set => mCollapsedArrowImage = value;
	}

	// === Child Management ===

	/// Adds a child item with the specified text.
	public TreeViewItem AddChild(StringView text)
	{
		let child = new TreeViewItem(text);
		AddChild(child);
		return child;
	}

	/// Adds an existing TreeViewItem as a child.
	public void AddChild(TreeViewItem item)
	{
		item.mParentItem = this;
		item.mIndentLevel = mIndentLevel + 1;
		item.UpdateChildIndentLevels();

		if (Context != null)
			item.OnAttachedToContext(Context);

		mChildren.Add(item);

		// Notify parent tree to rebuild
		if (let tree = FindParentTree())
			tree.[Friend]RebuildVisibleItems();
	}

	/// Removes a child item.
	public void RemoveChild(TreeViewItem item)
	{
		let index = mChildren.IndexOf(item);
		if (index < 0)
			return;

		mChildren.RemoveAt(index);
		item.mParentItem = null;

		if (Context != null)
		{
			item.OnDetachedFromContext();
			Context.MutationQueue.QueueDelete(item);
		}
		else
		{
			delete item;
		}

		// Notify parent tree to rebuild
		if (let tree = FindParentTree())
			tree.[Friend]RebuildVisibleItems();
	}

	/// Removes all children.
	public void ClearChildren()
	{
		for (let child in mChildren)
		{
			child.mParentItem = null;
			if (Context != null)
			{
				child.OnDetachedFromContext();
				Context.MutationQueue.QueueDelete(child);
			}
			else
			{
				delete child;
			}
		}
		mChildren.Clear();

		// Notify parent tree to rebuild
		if (let tree = FindParentTree())
			tree.[Friend]RebuildVisibleItems();
	}

	/// Gets the child at the specified index.
	public TreeViewItem GetChild(int index)
	{
		if (index < 0 || index >= mChildren.Count)
			return null;
		return mChildren[index];
	}

	// === Tree Traversal ===

	/// Enumerates all visible items (this item and expanded descendants).
	public void EnumerateVisible(List<TreeViewItem> outItems)
	{
		outItems.Add(this);

		if (mIsExpanded)
		{
			for (let child in mChildren)
				child.EnumerateVisible(outItems);
		}
	}

	/// Updates indent levels for all descendants.
	private void UpdateChildIndentLevels()
	{
		for (let child in mChildren)
		{
			child.mIndentLevel = mIndentLevel + 1;
			child.UpdateChildIndentLevels();
		}
	}

	/// Finds the parent TreeView.
	private TreeView FindParentTree()
	{
		// Walk up the parent chain to find the TreeView
		var current = Parent;
		while (current != null)
		{
			if (let tree = current as TreeView)
				return tree;
			current = current.Parent;
		}
		return null;
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		for (let child in mChildren)
			child.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		for (let child in mChildren)
			child.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// TreeViewItem has fixed height, width expands to container
		let indent = mIndentLevel * cIndentWidth;
		let textWidth = (mText?.Length ?? 0) * 8;  // Rough estimate
		let totalWidth = indent + cExpanderSize + 8 + textWidth;

		return .(totalWidth, cItemHeight);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		// Nothing to arrange - we render directly
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;
		let indent = mIndentLevel * cIndentWidth;

		// Get colors from theme
		let palette = Context?.Theme?.Palette ?? Palette();
		let foreground = Foreground.A > 0 ? Foreground : (palette.Text.A > 0 ? palette.Text : Color(200, 200, 200, 255));

		// Draw background (image or color)
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
			Color bgColor = Color.Transparent;
			if (mIsSelected)
			{
				let selectionColor = Context?.Theme?.SelectionColor ?? Color(100, 149, 237, 100);
				bgColor = selectionColor.A < 200 ? Color(selectionColor.R, selectionColor.G, selectionColor.B, 255) : selectionColor;
			}
			else if (mIsHovered)
				bgColor = Palette.ComputeHover(palette.Surface.A > 0 ? palette.Surface : Color(45, 45, 45, 255));

			if (bgColor.A > 0)
				ctx.FillRect(bounds, bgColor);
		}

		// Draw expander arrow (if has children)
		if (HasChildren)
		{
			let arrowSize = 10f;
			let arrowX = bounds.X + indent + 4;
			let arrowY = bounds.Y + (cItemHeight - arrowSize) / 2;
			let arrowRect = RectangleF(arrowX, arrowY, arrowSize, arrowSize);

			// Try image-based arrow first
			ImageBrush? arrowImage = mIsExpanded ? mExpandedArrowImage : mCollapsedArrowImage;
			if (arrowImage.HasValue && arrowImage.Value.IsValid)
			{
				ctx.DrawImageBrush(arrowImage.Value, arrowRect);
			}
			else if (mIsExpanded)
			{
				// Down arrow (expanded)
				Vector2[3] arrowPoints = .(
					.(arrowX, arrowY + 2),
					.(arrowX + arrowSize, arrowY + 2),
					.(arrowX + arrowSize / 2, arrowY + arrowSize - 2)
				);
				ctx.FillPolygon(arrowPoints, foreground);
			}
			else
			{
				// Right arrow (collapsed)
				Vector2[3] arrowPoints = .(
					.(arrowX + 2, arrowY),
					.(arrowX + arrowSize - 2, arrowY + arrowSize / 2),
					.(arrowX + 2, arrowY + arrowSize)
				);
				ctx.FillPolygon(arrowPoints, foreground);
			}
		}

		// Draw text
		if (mText != null && mText.Length > 0)
		{
			let textX = bounds.X + indent + cExpanderSize + 4;
			let textY = bounds.Y + (cItemHeight - 14) / 2;  // Center 14px text
			ctx.DrawText(mText, 14, .(textX, textY), foreground);
		}
	}

	// === Hit Testing ===

	/// Checks if the given local X coordinate is in the expander area.
	public bool IsInExpanderArea(float localX)
	{
		let indent = mIndentLevel * cIndentWidth;
		return localX >= indent && localX < indent + cExpanderSize + 4;
	}

	/// Gets the item height constant.
	public static float ItemHeight => cItemHeight;

	/// Gets the indent width constant.
	public static float IndentWidth => cIndentWidth;

	/// Gets the expander area width constant.
	public static float ExpanderSize => cExpanderSize;
}
