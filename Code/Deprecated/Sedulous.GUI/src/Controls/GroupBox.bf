using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A container with a titled border that groups related controls.
public class GroupBox : ContentControl
{
	// Header/title (displayed in top border)
	private UIElement mHeader ~ delete _;
	private float mHeaderPadding = 8;  // Horizontal padding around header in border
	private ImageBrush? mFrameImage;

	/// Creates a new GroupBox.
	public this()
	{
	}

	/// Creates a new GroupBox with text header.
	public this(StringView headerText) : this()
	{
		Header = new TextBlock(headerText);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "GroupBox";

	/// Image for the group box frame (replaces border drawing).
	public ImageBrush? FrameImage
	{
		get => mFrameImage;
		set => mFrameImage = value;
	}

	/// The header/title content displayed in the top border.
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

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float headerHeight = 0;
		float headerWidth = 0;

		// Measure header
		if (mHeader != null)
		{
			mHeader.Measure(constraints);
			let headerSize = mHeader.DesiredSize;
			headerHeight = headerSize.Height;
			headerWidth = headerSize.Width + mHeaderPadding + 8;  // Left margin + small right padding for gap
		}

		// Measure content
		float contentWidth = 0;
		float contentHeight = 0;
		if (Content != null)
		{
			// Content is inside the border, so subtract padding
			let contentConstraints = SizeConstraints.FromMaximum(
				Math.Max(0, constraints.MaxWidth - 16),  // 8px padding on each side
				Math.Max(0, constraints.MaxHeight - headerHeight / 2 - 16)
			);
			Content.Measure(contentConstraints);
			let contentSize = Content.DesiredSize;
			contentWidth = contentSize.Width + 16;
			contentHeight = contentSize.Height + 16;
		}

		// Total size: header contributes half height (centered on border), plus full content
		let totalWidth = Math.Max(headerWidth, contentWidth);
		let totalHeight = headerHeight / 2 + contentHeight + 8;

		return .(totalWidth, totalHeight);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		float headerHeight = 0;

		// Arrange header
		if (mHeader != null)
		{
			headerHeight = mHeader.DesiredSize.Height;
			let headerBounds = RectangleF(
				contentBounds.X + mHeaderPadding,  // Offset from left border
				contentBounds.Y,
				mHeader.DesiredSize.Width,
				headerHeight
			);
			mHeader.Arrange(headerBounds);
		}

		// Arrange content (inside border)
		if (Content != null)
		{
			let contentTop = contentBounds.Y + headerHeight / 2 + 8;  // Below border line
			let contentRect = RectangleF(
				contentBounds.X + 8,
				contentTop,
				contentBounds.Width - 16,
				contentBounds.Height - (contentTop - contentBounds.Y) - 8
			);
			Content.Arrange(contentRect);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;

		// Try image-based frame first
		if (mFrameImage.HasValue && mFrameImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mFrameImage.Value, bounds);
		}
		else
		{
			// Calculate header dimensions and position based on where header was actually arranged
			float headerWidth = 0;
			float headerHeight = 0;
			float headerLeft = 0;
			float headerCenterY = 0;
			if (mHeader != null)
			{
				headerWidth = mHeader.DesiredSize.Width;
				headerHeight = mHeader.DesiredSize.Height;
				headerLeft = mHeader.ArrangedBounds.X;
				headerCenterY = mHeader.ArrangedBounds.Y + headerHeight / 2;
			}

			// Border line is at the vertical center of the header
			let borderTop = mHeader != null ? headerCenterY : bounds.Y;
			let borderBounds = RectangleF(bounds.X, borderTop, bounds.Width, bounds.Bottom - borderTop);

			// Draw background (inside border)
			if (Background.A > 0)
				ctx.FillRect(borderBounds, Background);

			// Draw border with gap for header
			let borderColor = BorderColor.A > 0 ? BorderColor : Color(80, 80, 80, 255);
			let thickness = BorderThickness > 0 ? BorderThickness : 1;

			let gapPadding = 4.0f;
			let headerGapStart = headerLeft - gapPadding;
			let headerGapEnd = headerLeft + headerWidth + gapPadding;

			// Top border (with gap)
			if (headerWidth > 0)
			{
				ctx.DrawLine(.(bounds.X, borderTop), .(headerGapStart, borderTop), borderColor, thickness);
				ctx.DrawLine(.(headerGapEnd, borderTop), .(bounds.Right, borderTop), borderColor, thickness);
			}
			else
			{
				ctx.DrawLine(.(bounds.X, borderTop), .(bounds.Right, borderTop), borderColor, thickness);
			}

			// Right, bottom, left borders
			ctx.DrawLine(.(bounds.Right - thickness / 2, borderTop), .(bounds.Right - thickness / 2, bounds.Bottom), borderColor, thickness);
			ctx.DrawLine(.(bounds.Right, bounds.Bottom - thickness / 2), .(bounds.X, bounds.Bottom - thickness / 2), borderColor, thickness);
			ctx.DrawLine(.(bounds.X + thickness / 2, bounds.Bottom), .(bounds.X + thickness / 2, borderTop), borderColor, thickness);
		}

		// Draw header
		if (mHeader != null)
			mHeader.Render(ctx);

		// Draw content
		if (Content != null)
			Content.Render(ctx);
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Check content
		if (Content != null)
		{
			let hit = Content.HitTest(point);
			if (hit != null)
				return hit;
		}

		return this;
	}
}
