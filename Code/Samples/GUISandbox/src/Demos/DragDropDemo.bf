namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.GUI;

/// Demo 15: Drag and Drop System
/// Shows draggable items, drop targets, and visual feedback during drag operations.
class DragDropDemo
{
	private StackPanel mRoot;
	private TextBlock mStatusLabel;
	private GUIContext mContext;

	public UIElement CreateDemo(GUIContext context)
	{
		mContext = context;

		mRoot = new StackPanel();
		mRoot.Orientation = .Vertical;
		mRoot.Spacing = 15;
		mRoot.Padding = .(20, 70, 20, 20);

		// Title
		let title = new TextBlock("Drag and Drop Demo");
		title.FontSize = 20;
		mRoot.AddChild(title);

		// Instructions
		let instructions = new TextBlock("Drag items from the left panel to the right panel or trash.");
		mRoot.AddChild(instructions);

		// Status label (create early so panels can reference it)
		mStatusLabel = new TextBlock("Drag an item to begin...");

		// Main content area with two panels
		let contentRow = new StackPanel();
		contentRow.Orientation = .Horizontal;
		contentRow.Spacing = 20;

		// Source panel (draggable items)
		CreateSourcePanel(contentRow);

		// Drop target panel
		CreateDropTargetPanel(contentRow);

		// Trash zone
		CreateTrashZone(contentRow);

		mRoot.AddChild(contentRow);

		// Add status label at the bottom
		mRoot.AddChild(mStatusLabel);

		return mRoot;
	}

	private void CreateSourcePanel(StackPanel parent)
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 8;
		section.Padding = .(15, 15, 15, 15);
		section.Width = .Fixed(200);

		let header = new TextBlock("Drag Source");
		header.FontSize = 14;
		section.AddChild(header);

		// Add draggable items
		for (int i = 1; i <= 5; i++)
		{
			let item = new DraggableItem(scope $"Item {i}");
			item.StatusLabel = mStatusLabel;
			section.AddChild(item);
		}

		parent.AddChild(section);
	}

	private void CreateDropTargetPanel(StackPanel parent)
	{
		let target = new DropTargetPanel();
		target.Width = .Fixed(250);
		target.Height = .Fixed(200);
		target.StatusLabel = mStatusLabel;
		parent.AddChild(target);
	}

	private void CreateTrashZone(StackPanel parent)
	{
		let trash = new TrashDropZone();
		trash.Width = .Fixed(100);
		trash.Height = .Fixed(200);
		trash.StatusLabel = mStatusLabel;
		parent.AddChild(trash);
	}
}

/// A draggable item that implements IDragSource.
class DraggableItem : Control, IDragSource
{
	private String mText ~ delete _;
	private TextBlock mTextBlock ~ delete _;
	private bool mIsDragging = false;

	public TextBlock StatusLabel;

	public this(StringView text)
	{
		mText = new String(text);
		mTextBlock = new TextBlock(text);

		Background = Color(60, 80, 100, 255);  // Keep distinct color for draggable items
		Padding = .(12, 8, 12, 8);
	}

	// IDragSource implementation

	public bool CanStartDrag()
	{
		return true;
	}

	public DragData CreateDragData()
	{
		let data = new ElementDragData(this);
		return data;
	}

	public DragDropEffects GetAllowedEffects()
	{
		return .Move | .Copy;
	}

	public void CreateDragVisual(DragAdorner adorner)
	{
		adorner.SetLabel(mText);
		adorner.Size = .(ArrangedBounds.Width, ArrangedBounds.Height);
	}

	public void OnDragStarted(DragEventArgs args)
	{
		mIsDragging = true;
		if (StatusLabel != null) StatusLabel.Text = scope $"Dragging: {mText}";
	}

	public void OnDragCompleted(DragEventArgs args)
	{
		mIsDragging = false;
		// Only report if drag was cancelled - drop targets handle their own feedback
		if (!args.Handled)
		{
			if (StatusLabel != null) StatusLabel.Text = scope $"Drag cancelled: {mText}";
		}
	}

	// Mouse handling

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && CanStartDrag())
		{
			let data = CreateDragData();
			Context?.DragDropManager?.BeginPotentialDrag(this, data, GetAllowedEffects(), e.ScreenPosition);
			e.Handled = true;
		}
	}

	// Layout and rendering

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		mTextBlock.Measure(constraints);
		let textSize = mTextBlock.DesiredSize;
		return .(textSize.Width + Padding.Left + Padding.Right,
				 textSize.Height + Padding.Top + Padding.Bottom);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		let textBounds = RectangleF(
			contentBounds.X + Padding.Left,
			contentBounds.Y + Padding.Top,
			contentBounds.Width - Padding.Left - Padding.Right,
			contentBounds.Height - Padding.Top - Padding.Bottom
		);
		mTextBlock.Arrange(textBounds);
	}

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;
		let bgColor = mIsDragging ? Color(80, 100, 120, 128) : Background;
		ctx.FillRoundedRect(bounds, 4, bgColor);
		mTextBlock.Render(ctx);
	}

	public override int VisualChildCount => 1;
	public override UIElement GetVisualChild(int index) => index == 0 ? mTextBlock : null;

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mTextBlock.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		mTextBlock.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}
}

/// A panel that accepts dropped items.
class DropTargetPanel : Panel, IDropTarget
{
	private bool mIsDropHighlighted = false;
	private DragDropEffects mCurrentEffect = .None;

	public TextBlock StatusLabel;

	public this()
	{
		Background = Color(40, 70, 40, 255);  // Keep distinct color for drop target
		Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Drop Here");
		header.FontSize = 14;
		AddChild(header);
	}

	// IDropTarget implementation

	public bool CanAcceptDrop(DragData data)
	{
		return data.HasFormat(DragDataFormats.UIElement);
	}

	public void OnDragEnter(DragEventArgs args)
	{
		mIsDropHighlighted = true;
		mCurrentEffect = args.IsEffectAllowed(.Move) ? .Move : .Copy;
		args.Effect = mCurrentEffect;
		if (StatusLabel != null) StatusLabel.Text = "Drop to add item here";
	}

	public void OnDragOver(DragEventArgs args)
	{
		args.Effect = mCurrentEffect;
	}

	public void OnDragLeave(DragEventArgs args)
	{
		mIsDropHighlighted = false;
		mCurrentEffect = .None;
	}

	public void OnDrop(DragEventArgs args)
	{
		mIsDropHighlighted = false;

		if (let elementData = args.Data as ElementDragData)
		{
			let element = elementData.GetElement();
			if (element != null)
			{
				// Clone the item instead of moving (for demo purposes)
				if (let draggable = element as DraggableItem)
				{
					let newItem = new TextBlock(scope $"Dropped: {draggable.[Friend]mText}");
					newItem.Padding = .(8, 4, 8, 4);
					AddChild(newItem);
				}
				args.Handled = true;
				if (StatusLabel != null) StatusLabel.Text = "Item dropped successfully!";
			}
		}
	}

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Background
		ctx.FillRoundedRect(bounds, 6, Background);

		// Drop highlight
		if (mIsDropHighlighted)
		{
			let highlightColor = mCurrentEffect == .Move ?
				Color(100, 200, 100, 100) : Color(100, 100, 200, 100);
			ctx.FillRoundedRect(bounds, 6, highlightColor);
			ctx.DrawRoundedRect(bounds, 6, Color(100, 200, 100, 255), 2);
		}
		else
		{
			ctx.DrawRoundedRect(bounds, 6, Color(60, 80, 60, 255), 1);
		}

		// Render children
		base.RenderOverride(ctx);
	}
}

/// A trash zone that deletes dropped items.
class TrashDropZone : Control, IDropTarget
{
	private bool mIsDropHighlighted = false;
	private TextBlock mLabel ~ delete _;

	public TextBlock StatusLabel;

	public this()
	{
		Background = Color(80, 40, 40, 255);  // Keep distinct color for trash zone
		Padding = .(15, 15, 15, 15);

		mLabel = new TextBlock("Trash");
		mLabel.FontSize = 14;
		mLabel.HorizontalAlignment = .Center;
		mLabel.VerticalAlignment = .Center;
	}

	// IDropTarget implementation

	public bool CanAcceptDrop(DragData data)
	{
		return data.HasFormat(DragDataFormats.UIElement);
	}

	public void OnDragEnter(DragEventArgs args)
	{
		mIsDropHighlighted = true;
		args.Effect = .Move;
		if (StatusLabel != null) StatusLabel.Text = "Drop to delete item";
	}

	public void OnDragOver(DragEventArgs args)
	{
		args.Effect = .Move;
	}

	public void OnDragLeave(DragEventArgs args)
	{
		mIsDropHighlighted = false;
	}

	public void OnDrop(DragEventArgs args)
	{
		mIsDropHighlighted = false;

		if (let elementData = args.Data as ElementDragData)
		{
			let element = elementData.GetElement();
			if (element != null)
			{
				// In a real app, you'd delete the source element
				// For demo, just acknowledge the drop
				args.Handled = true;
				if (StatusLabel != null) StatusLabel.Text = "Item deleted!";
			}
		}
	}

	// Layout and rendering

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		mLabel.Measure(constraints);
		return mLabel.DesiredSize;
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		mLabel.Arrange(contentBounds);
	}

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Background
		ctx.FillRoundedRect(bounds, 6, Background);

		// Drop highlight
		if (mIsDropHighlighted)
		{
			ctx.FillRoundedRect(bounds, 6, Color(200, 100, 100, 100));
			ctx.DrawRoundedRect(bounds, 6, Color(200, 100, 100, 255), 2);
		}
		else
		{
			ctx.DrawRoundedRect(bounds, 6, Color(80, 60, 60, 255), 1);
		}

		// Label
		mLabel.Render(ctx);
	}

	public override int VisualChildCount => 1;
	public override UIElement GetVisualChild(int index) => index == 0 ? mLabel : null;

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mLabel.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		mLabel.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}
}
