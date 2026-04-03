using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A horizontal status bar typically displayed at the bottom of an application.
/// Contains StatusBarItem segments with optional separators.
public class StatusBar : Control
{
	private List<StatusBarItem> mItems = new .() ~ DeleteContainerAndItems!(_);
	private bool mShowSeparators = true;
	private Color mSeparatorColor;
	private float mSeparatorWidth = 1;

	/// Creates a new StatusBar.
	public this()
	{
		IsFocusable = false;
		IsTabStop = false;
		mSeparatorColor = Color(80, 80, 80, 255);  // Default, will be updated by theme
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
		for (let item in mItems)
			item.OnAttachedToContext(context);
	}

	/// Applies theme defaults for status bar styling.
	private void ApplyThemeDefaults()
	{
		let palette = Context?.Theme?.Palette ?? Palette();
		mSeparatorColor = palette.Border.A > 0 ? palette.Border : Color(80, 80, 80, 255);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "StatusBar";

	/// Whether to show separator lines between items.
	public bool ShowSeparators
	{
		get => mShowSeparators;
		set => mShowSeparators = value;
	}

	/// The color of separator lines.
	public Color SeparatorColor
	{
		get => mSeparatorColor;
		set => mSeparatorColor = value;
	}

	/// Number of items in the status bar.
	public int ItemCount => mItems.Count;

	/// Adds a text item to the status bar.
	public StatusBarItem AddItem(StringView text)
	{
		let item = new StatusBarItem(text);
		AddItem(item);
		return item;
	}

	/// Adds an existing StatusBarItem.
	public void AddItem(StatusBarItem item)
	{
		mItems.Add(item);
		InvalidateLayout();
	}

	/// Adds a flexible item that stretches to fill available space.
	public StatusBarItem AddFlexibleItem(StringView text)
	{
		let item = new StatusBarItem(text);
		item.IsFlexible = true;
		AddItem(item);
		return item;
	}

	/// Adds a fixed-width item.
	public StatusBarItem AddFixedItem(StringView text, float width)
	{
		let item = new StatusBarItem(text);
		item.MinWidth = width;
		item.MaxWidth = width;
		AddItem(item);
		return item;
	}

	/// Removes an item from the status bar.
	public void RemoveItem(StatusBarItem item)
	{
		mItems.Remove(item);
		InvalidateLayout();
	}

	/// Gets the item at the specified index.
	public StatusBarItem GetItem(int index)
	{
		if (index >= 0 && index < mItems.Count)
			return mItems[index];
		return null;
	}

	/// Clears all items from the status bar.
	public void ClearItems()
	{
		DeleteContainerAndItems!(mItems);
		mItems = new .();
		InvalidateLayout();
	}

	// Layout

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float totalWidth = Padding.Left + Padding.Right;
		float maxHeight = 0;

		for (int i = 0; i < mItems.Count; i++)
		{
			let item = mItems[i];
			item.Measure(constraints);
			totalWidth += item.DesiredSize.Width;
			maxHeight = Math.Max(maxHeight, item.DesiredSize.Height);

			// Separator space
			if (mShowSeparators && i < mItems.Count - 1)
				totalWidth += mSeparatorWidth + 8;  // separator + padding
		}

		return .(totalWidth, maxHeight + Padding.Top + Padding.Bottom);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		let availableWidth = contentBounds.Width - Padding.Left - Padding.Right;
		let itemHeight = contentBounds.Height - Padding.Top - Padding.Bottom;

		// Calculate total fixed width and count flexible items
		float fixedWidth = 0;
		int flexibleCount = 0;
		float separatorSpace = 0;

		for (int i = 0; i < mItems.Count; i++)
		{
			let item = mItems[i];
			if (item.IsFlexible)
				flexibleCount++;
			else
				fixedWidth += item.DesiredSize.Width;

			if (mShowSeparators && i < mItems.Count - 1)
				separatorSpace += mSeparatorWidth + 8;
		}

		// Calculate flexible item width
		float remainingWidth = availableWidth - fixedWidth - separatorSpace;
		float flexibleWidth = flexibleCount > 0 ? Math.Max(0, remainingWidth / flexibleCount) : 0;

		// Arrange items
		float x = contentBounds.X + Padding.Left;
		let y = contentBounds.Y + Padding.Top;

		for (int i = 0; i < mItems.Count; i++)
		{
			let item = mItems[i];
			float itemWidth = item.IsFlexible ? flexibleWidth : item.DesiredSize.Width;

			item.Arrange(.(x, y, itemWidth, itemHeight));
			x += itemWidth;

			// Separator space
			if (mShowSeparators && i < mItems.Count - 1)
				x += mSeparatorWidth + 8;
		}
	}

	// Rendering

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Background
		RenderBackground(ctx);

		// Top border
		ctx.DrawLine(.(bounds.X, bounds.Y), .(bounds.Right, bounds.Y), BorderColor, 1);

		// Render items
		for (let item in mItems)
		{
			item.Render(ctx);
		}

		// Render separators
		if (mShowSeparators)
		{
			for (int i = 0; i < mItems.Count - 1; i++)
			{
				let item = mItems[i];
				let itemBounds = item.ArrangedBounds;
				let sepX = itemBounds.Right + 4;
				ctx.DrawLine(.(sepX, bounds.Y + 4), .(sepX, bounds.Bottom - 4), mSeparatorColor, mSeparatorWidth);
			}
		}
	}

	// Hit testing - test StatusBarItem children

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Test items in reverse order (topmost first)
		for (int i = mItems.Count - 1; i >= 0; i--)
		{
			let hit = mItems[i].HitTest(point);
			if (hit != null)
				return hit;
		}

		return this;
	}

	// Visual children

	public override int VisualChildCount => mItems.Count;

	public override UIElement GetVisualChild(int index)
	{
		if (index >= 0 && index < mItems.Count)
			return mItems[index];
		return null;
	}


	public override void OnDetachedFromContext()
	{
		for (let item in mItems)
			item.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}
}
