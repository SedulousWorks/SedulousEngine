using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A single tab within a TabControl.
/// Contains a Header (displayed in the tab strip) and Content (displayed when selected).
public class TabItem : ContentControl, ISelectable
{
	// Header displayed in tab strip
	private UIElement mHeader ~ delete _;
	private bool mIsSelected = false;
	private bool mIsCloseable = false;
	private int mIndex = -1;

	// Image support
	private ImageBrush? mActiveTabImage;
	private ImageBrush? mInactiveTabImage;

	// Events
	private EventAccessor<delegate void(TabItem)> mCloseRequested = new .() ~ delete _;

	// Internal: delegate for close button (owned by button's Click event)
	private delegate void(Button) mCloseButtonHandler;

	/// Creates a new empty TabItem.
	public this()
	{
		IsFocusable = false;  // Focus is managed by parent TabControl
		IsTabStop = false;
	}

	/// Creates a new TabItem with text header.
	public this(StringView headerText) : this()
	{
		Header = new TextBlock(headerText);
	}

	/// Creates a new TabItem with text header and content.
	public this(StringView headerText, UIElement content) : this()
	{
		Header = new TextBlock(headerText);
		Content = content;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "TabItem";

	/// The header content displayed in the tab strip.
	public UIElement Header
	{
		get => mHeader;
		set
		{
			if (mHeader == value)
				return;

			// Detach and delete old header
			if (mHeader != null)
			{
				let oldHeader = mHeader;
				mHeader = null;

				oldHeader.SetParent(null);
				if (Context != null)
				{
					oldHeader.OnDetachedFromContext();
					Context.MutationQueue.QueueDelete(oldHeader);
				}
				else
				{
					delete oldHeader;
				}
			}

			mHeader = value;

			// Attach new header
			if (mHeader != null)
			{
				mHeader.DetachFromParent();
				mHeader.SetParent(this);
				if (Context != null)
					mHeader.OnAttachedToContext(Context);
			}

			InvalidateLayout();
		}
	}

	/// Gets or sets whether this tab is selected.
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

	/// Whether this tab shows a close button.
	public bool IsCloseable
	{
		get => mIsCloseable;
		set => mIsCloseable = value;
	}

	/// The index of this tab within its parent TabControl.
	public int Index
	{
		get => mIndex;
		set => mIndex = value;
	}

	/// Event fired when the close button is clicked.
	public EventAccessor<delegate void(TabItem)> CloseRequested => mCloseRequested;

	/// Image for the active (selected) tab header background.
	public ImageBrush? ActiveTabImage
	{
		get => mActiveTabImage;
		set => mActiveTabImage = value;
	}

	/// Image for the inactive (unselected) tab header background.
	public ImageBrush? InactiveTabImage
	{
		get => mInactiveTabImage;
		set => mInactiveTabImage = value;
	}

	/// Gets the selection background color from theme.
	protected Color SelectionBackground
	{
		get
		{
			if (Context?.Theme != null)
				return Context.Theme.SelectionColor;
			return Color(51, 153, 255, 255);
		}
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		if (mHeader != null)
			mHeader.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		if (mHeader != null)
			mHeader.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Visual Children ===

	public override int VisualChildCount
	{
		get
		{
			int count = 0;
			if (mHeader != null) count++;
			if (Content != null) count++;
			return count;
		}
	}

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0 && mHeader != null)
			return mHeader;
		if (index == 1 && Content != null)
			return Content;
		if (index == 0 && mHeader == null && Content != null)
			return Content;
		return null;
	}

	// === Layout (for tab header rendering) ===

	/// Measure the header for tab strip display.
	public DesiredSize MeasureHeader(SizeConstraints constraints)
	{
		if (mHeader == null)
			return .(50, 24);  // Default tab size

		mHeader.Measure(constraints);
		let headerSize = mHeader.DesiredSize;

		// Add padding and space for close button
		float width = headerSize.Width + 16;  // 8px padding each side
		float height = headerSize.Height + 8;  // 4px padding each side

		if (mIsCloseable)
			width += 20;  // Space for close button

		return .(Math.Max(width, 50), Math.Max(height, 24));
	}

	/// Arrange the header within tab strip bounds.
	public void ArrangeHeader(RectangleF bounds)
	{
		if (mHeader == null)
			return;

		// Leave room for close button on right
		float contentWidth = bounds.Width - 16;  // Padding
		if (mIsCloseable)
			contentWidth -= 20;

		let headerBounds = RectangleF(
			bounds.X + 8,
			bounds.Y + 4,
			contentWidth,
			bounds.Height - 8
		);

		mHeader.Arrange(headerBounds);
	}

	/// Render the tab header (called by TabControl).
	public void RenderHeader(DrawContext ctx, RectangleF bounds, bool isHovered)
	{
		// Get theme colors for fallbacks
		let palette = Context?.Theme?.Palette ?? Palette();
		let surfaceColor = palette.Surface.A > 0 ? palette.Surface : Color(45, 45, 45, 255);
		let textColor = palette.Text.A > 0 ? palette.Text : Color(200, 200, 200, 255);

		// Try image-based tab header first
		ImageBrush? tabImage = mIsSelected ? mActiveTabImage : mInactiveTabImage;
		if (tabImage.HasValue && tabImage.Value.IsValid)
		{
			var img = tabImage.Value;
			if (isHovered && !mIsSelected)
				img.Tint = Palette.Lighten(img.Tint, 0.10f);
			ctx.DrawImageBrush(img, bounds);
		}
		else
		{
			// Draw background based on state
			Color bgColor;
			if (mIsSelected)
			{
				bgColor = SelectionBackground;
			}
			else if (isHovered)
			{
				bgColor = Palette.ComputeHover(Background.A > 0 ? Background : surfaceColor);
			}
			else
			{
				bgColor = Background.A > 0 ? Background : Palette.Lighten(surfaceColor, 0.1f);
			}

			ctx.FillRect(bounds, bgColor);
		}

		// Draw header content
		if (mHeader != null)
			mHeader.Render(ctx);

		// Draw close button if closeable
		if (mIsCloseable)
		{
			let closeSize = 16f;
			let closeX = bounds.Right - closeSize - 4;
			let closeY = bounds.Y + (bounds.Height - closeSize) / 2;
			let closeBounds = RectangleF(closeX, closeY, closeSize, closeSize);

			// Draw X
			let foreground = Foreground.A > 0 ? Foreground : textColor;
			let padding = 4f;
			ctx.DrawLine(
				.(closeBounds.X + padding, closeBounds.Y + padding),
				.(closeBounds.Right - padding, closeBounds.Bottom - padding),
				foreground, 1.5f);
			ctx.DrawLine(
				.(closeBounds.Right - padding, closeBounds.Y + padding),
				.(closeBounds.X + padding, closeBounds.Bottom - padding),
				foreground, 1.5f);
		}
	}

	/// Check if a point hits the close button.
	public bool HitTestCloseButton(Vector2 point, RectangleF headerBounds)
	{
		if (!mIsCloseable)
			return false;

		let closeSize = 16f;
		let closeX = headerBounds.Right - closeSize - 4;
		let closeY = headerBounds.Y + (headerBounds.Height - closeSize) / 2;
		let closeBounds = RectangleF(closeX, closeY, closeSize, closeSize);

		return closeBounds.Contains(point.X, point.Y);
	}

	/// Called when close button is clicked (by TabControl).
	public void OnCloseButtonClicked()
	{
		mCloseRequested.[Friend]Invoke(this);
	}
}
