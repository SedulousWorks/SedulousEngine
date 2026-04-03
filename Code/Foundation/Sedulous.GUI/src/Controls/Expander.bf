using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A collapsible section control with a header and expandable content.
public class Expander : ContentControl
{
	// Header (always visible)
	private UIElement mHeader ~ delete _;

	// Expand state
	private bool mIsExpanded = true;
	private float mHeaderHeight = 28;

	// Events
	private EventAccessor<delegate void(Expander, bool)> mExpandedChanged = new .() ~ delete _;

	/// Creates a new Expander.
	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
	}

	/// Creates a new Expander with text header.
	public this(StringView headerText) : this()
	{
		Header = new TextBlock(headerText);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Expander";

	/// The header content (always visible).
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

	/// Whether the content is expanded (visible).
	public bool IsExpanded
	{
		get => mIsExpanded;
		set
		{
			if (mIsExpanded != value)
			{
				mIsExpanded = value;
				InvalidateLayout();
				mExpandedChanged.[Friend]Invoke(this, value);
			}
		}
	}

	/// Event fired when expanded state changes.
	public EventAccessor<delegate void(Expander, bool)> ExpandedChanged => mExpandedChanged;

	/// Expands the content.
	public void Expand() => IsExpanded = true;

	/// Collapses the content.
	public void Collapse() => IsExpanded = false;

	/// Toggles the expanded state.
	public void Toggle() => IsExpanded = !mIsExpanded;

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
			if (Content != null && mIsExpanded) count++;
			return count;
		}
	}

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0 && mHeader != null)
			return mHeader;
		if (index == 1 && Content != null && mIsExpanded)
			return Content;
		if (index == 0 && mHeader == null && Content != null && mIsExpanded)
			return Content;
		return null;
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float width = 0;
		float height = 0;

		// Always measure header
		if (mHeader != null)
		{
			let headerConstraints = SizeConstraints.FromMaximum(
				constraints.MaxWidth - 24,  // Leave room for toggle button
				constraints.MaxHeight
			);
			mHeader.Measure(headerConstraints);
			let headerSize = mHeader.DesiredSize;
			width = headerSize.Width + 24;
			height = Math.Max(headerSize.Height + 8, mHeaderHeight);
		}
		else
		{
			height = mHeaderHeight;
		}

		// Measure content only if expanded
		if (mIsExpanded && Content != null)
		{
			let contentConstraints = SizeConstraints.FromMaximum(
				constraints.MaxWidth,
				constraints.MaxHeight - height
			);
			Content.Measure(contentConstraints);
			let contentSize = Content.DesiredSize;
			width = Math.Max(width, contentSize.Width);
			height += contentSize.Height;
		}

		return .(width, height);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		// Header bounds (with toggle button space on left)
		let headerBounds = RectangleF(
			contentBounds.X + 24,  // Space for toggle
			contentBounds.Y,
			contentBounds.Width - 24,
			mHeaderHeight
		);

		if (mHeader != null)
			mHeader.Arrange(headerBounds);

		// Content bounds (below header)
		if (mIsExpanded && Content != null)
		{
			let contentBoundsRect = RectangleF(
				contentBounds.X,
				contentBounds.Y + mHeaderHeight,
				contentBounds.Width,
				contentBounds.Height - mHeaderHeight
			);
			Content.Arrange(contentBoundsRect);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Draw background
		RenderBackground(ctx);

		// Draw header background
		let headerBounds = RectangleF(bounds.X, bounds.Y, bounds.Width, mHeaderHeight);
		let headerBg = IsHovered ? Palette.ComputeHover(Background) : Background;
		if (headerBg.A > 0)
			ctx.FillRect(headerBounds, headerBg);

		// Draw toggle arrow
		let arrowSize = 10f;
		let arrowX = bounds.X + 8;
		let arrowY = bounds.Y + (mHeaderHeight - arrowSize) / 2;

		let palette = Context?.Theme?.Palette ?? Palette();
		let foreground = Foreground.A > 0 ? Foreground : (palette.Text.A > 0 ? palette.Text : Color(200, 200, 200, 255));

		if (mIsExpanded)
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

		// Draw header content
		if (mHeader != null)
			mHeader.Render(ctx);

		// Draw border around entire control
		let borderColor = palette.Border.A > 0 ? palette.Border : Color(80, 80, 80, 255);

		// Top border
		ctx.DrawLine(.(bounds.X, bounds.Y), .(bounds.Right, bounds.Y), borderColor, 1);

		// Bottom border (at header bottom if collapsed, at content bottom if expanded)
		let bottomY = mIsExpanded ? bounds.Bottom : bounds.Y + mHeaderHeight;
		ctx.DrawLine(.(bounds.X, bottomY), .(bounds.Right, bottomY), borderColor, 1);

		// Left border
		ctx.DrawLine(.(bounds.X, bounds.Y), .(bounds.X, bottomY), borderColor, 1);

		// Right border
		ctx.DrawLine(.(bounds.Right, bounds.Y), .(bounds.Right, bottomY), borderColor, 1);

		// Separator line under header (only when expanded)
		if (mIsExpanded)
		{
			ctx.DrawLine(
				.(bounds.X, bounds.Y + mHeaderHeight),
				.(bounds.Right, bounds.Y + mHeaderHeight),
				borderColor, 1
			);
		}

		// Draw content if expanded
		if (mIsExpanded && Content != null)
			Content.Render(ctx);
	}

	// === Input ===

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && !e.Handled)
		{
			// Check if click is in header area
			let bounds = ArrangedBounds;
			let headerBounds = RectangleF(bounds.X, bounds.Y, bounds.Width, mHeaderHeight);

			if (headerBounds.Contains(e.ScreenX, e.ScreenY))
			{
				Toggle();
				e.Handled = true;
			}
		}
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		if (e.Handled)
			return;

		switch (e.Key)
		{
		case .Space, .Return:
			Toggle();
			e.Handled = true;
		case .Left:
			if (mIsExpanded)
			{
				Collapse();
				e.Handled = true;
			}
		case .Right:
			if (!mIsExpanded)
			{
				Expand();
				e.Handled = true;
			}
		default:
		}
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Check if in content area and content is interactive
		if (mIsExpanded && Content != null)
		{
			let contentTop = ArrangedBounds.Y + mHeaderHeight;
			if (point.Y >= contentTop)
			{
				let hit = Content.HitTest(point);
				if (hit != null)
					return hit;
			}
		}

		return this;
	}
}
