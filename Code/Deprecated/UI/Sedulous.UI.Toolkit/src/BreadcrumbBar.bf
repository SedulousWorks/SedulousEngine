using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A path shown as clickable segments with arrows between them: a file path, a scene hierarchy,
/// a navigation trail.
///
/// The LAST segment is where you already are, so it is drawn dimmed and takes no hover fill;
/// only the ones you can go back to look clickable.
class BreadcrumbBar : ViewGroup
{
	/// Fired with the index of the segment clicked.
	public Event<delegate void(BreadcrumbBar, int32)> OnSegmentClicked ~ _.Dispose();

	private List<String> mSegments = new .() ~ DeleteContainerAndItems!(_);
	/// Rebuilt on layout, because the widths depend on the font the sheet resolves.
	private List<Rectangle> mSegmentRects = new .() ~ delete _;

	private int32 mHoveredIndex = -1;
	private float mFontSize = 13.0f;
	private float mSegmentPadding = 8.0f;
	private float mSeparatorWidth = 16.0f;

	public this()
	{
		Cursor = .Hand;
	}

	public int32 SegmentCount => (int32)mSegments.Count;

	/// Replaces the path with a ready made list of segments.
	public void SetSegments(Span<StringView> segments)
	{
		ClearAndDeleteItems!(mSegments);
		for (let segment in segments)
			mSegments.Add(new String(segment));
		Invalidate();
	}

	/// Replaces the path by splitting a delimited string.
	///
	/// Empty pieces are DROPPED, so a leading, trailing or doubled separator does not become a
	/// zero width segment that can still be clicked.
	public void SetPath(StringView path, char8 separator = '/')
	{
		ClearAndDeleteItems!(mSegments);

		var start = 0;
		for (int i = 0; i <= path.Length; i++)
		{
			if ((i != path.Length) && (path[i] != separator))
				continue;

			var piece = path.Substring(start, i - start);
			piece.Trim();
			if (!piece.IsEmpty)
				mSegments.Add(new String(piece));

			start = i + 1;
		}

		Invalidate();
	}

	public StringView GetSegment(int32 index) =>
		((index >= 0) && (index < mSegments.Count)) ? StringView(mSegments[index]) : default;

	/// Appends the path down to and including one segment, which is what a click handler needs
	/// in order to navigate to what was clicked.
	public void GetPathUpTo(int32 index, String output, char8 separator = '/')
	{
		let last = Math.Min((int)index, mSegments.Count - 1);
		for (int i = 0; i <= last; i++)
		{
			if (i > 0)
				output.Append(separator);
			output.Append(mSegments[i]);
		}
	}

	// ---- Drawing --------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		let background = ResolveStyleDrawable(.Background);

		// A rounded background is drawn with the THEME's radius rather than its own, then put
		// back, so one shared drawable can serve a flat theme and a rounded one.
		if (let rounded = background as RoundedRectDrawable)
		{
			let cornerRadius = ResolveStyleFloat(.CornerRadius, 0.0f);
			let saved = rounded.Radii;
			rounded.Radii = .(cornerRadius);
			rounded.Draw(ctx, bounds);
			rounded.Radii = saved;
		}
		else if (background != null)
		{
			background.Draw(ctx, bounds);
		}
		else
		{
			ctx.VG.FillRect(bounds, Color.Rgb(40, 42, 52));
		}

		if (ctx.FontService == null)
			return;

		let font = ctx.FontService.GetFont(ResolveStyleFloat(.FontSize, mFontSize));
		if (font == null)
			return;

		let textColor = ResolveStyleColor(.TextColor, Color.Rgb(220, 225, 235));
		let hoverColor = ResolveStyleColor(.AccentColor, Color.Rgb(80, 150, 240));
		let lastColor = ResolveStyleColor(.TextDimColor, Color.Rgb(180, 185, 200));
		let separatorColor = ResolveStyleColor(.BorderColor, Color.Rgb(100, 105, 120));

		let count = Math.Min(mSegments.Count, mSegmentRects.Count);
		for (int i < count)
		{
			let rect = mSegmentRects[i];
			let isLast = i == mSegments.Count - 1;
			let isHovered = i == mHoveredIndex;

			if (isHovered && !isLast)
			{
				var backgroundColor = Color.Rgb(40, 42, 52);
				if (let rounded = background as RoundedRectDrawable)
					backgroundColor = rounded.FillColor;
				else if (let solid = background as ColorDrawable)
					backgroundColor = solid.Color;

				let hover = Palette.ComputeHover(backgroundColor);
				let cornerRadius = ResolveStyleFloat(.CornerRadius, 0.0f);
				if (cornerRadius > 0.0f)
					ctx.VG.FillRoundedRect(rect, cornerRadius, hover);
				else
					ctx.VG.FillRect(rect, hover);
			}

			let color = isHovered ? hoverColor : (isLast ? lastColor : textColor);
			ctx.VG.DrawText(mSegments[i], font, rect, .Center, .Middle, color);

			if (isLast)
				continue;

			let arrowX = rect.X + rect.Width + 2.0f;
			let arrowCenterY = Height * 0.5f;
			let arrowSize = 4.0f;
			ctx.VG.BeginPath();
			ctx.VG.MoveTo(arrowX, arrowCenterY - arrowSize);
			ctx.VG.LineTo(arrowX + arrowSize, arrowCenterY);
			ctx.VG.LineTo(arrowX, arrowCenterY + arrowSize);
			ctx.VG.Stroke(separatorColor, 1.5f);
		}
	}

	// ---- Input ----------------------------------------------------------------------------------

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;

		let local = MouseLocal();
		let index = GetSegmentAt(local.X, local.Y);
		if (index >= 0)
		{
			OnSegmentClicked(this, index);
			e.Handled = true;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		let local = MouseLocal();
		let index = GetSegmentAt(local.X, local.Y);
		if (index != mHoveredIndex)
		{
			mHoveredIndex = index;
			Invalidate();
		}
	}

	public override void OnMouseLeave()
	{
		if (mHoveredIndex >= 0)
		{
			mHoveredIndex = -1;
			Invalidate();
		}
	}

	// ---- Layout ---------------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		var totalWidth = 0.0f;
		var textHeight = ResolveStyleFloat(.FontSize, mFontSize);

		if ((Context != null) && (Context.FontService != null))
		{
			if (let font = Context.FontService.GetFont(ResolveStyleFloat(.FontSize, mFontSize)))
			{
				textHeight = font.Font.Metrics.LineHeight;
				for (int i < mSegments.Count)
				{
					totalWidth += font.Font.MeasureString(mSegments[i]) + (mSegmentPadding * 2.0f);
					if (i < mSegments.Count - 1)
						totalWidth += mSeparatorWidth;
				}
			}
		}

		MeasuredSize = .(constraints.ConstrainWidth(totalWidth),
			constraints.ConstrainHeight(textHeight + 8.0f));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		RebuildSegmentRects();
	}

	// ---- Internals ------------------------------------------------------------------------------

	/// The pointer in this view's own space.
	///
	/// Read from the input manager rather than the event, because the hover test also runs from
	/// a move event whose coordinates a parent may already have transformed.
	private Float2 MouseLocal()
	{
		if (Context == null)
			return .Zero;

		let input = Context.GetInputManager();
		return ScreenToLocal(.(input.MouseX, input.MouseY));
	}

	private void RebuildSegmentRects()
	{
		mSegmentRects.Clear();

		if ((Context == null) || (Context.FontService == null))
			return;

		let font = Context.FontService.GetFont(ResolveStyleFloat(.FontSize, mFontSize));
		if (font == null)
			return;

		var x = 0.0f;
		for (int i < mSegments.Count)
		{
			let segmentWidth = font.Font.MeasureString(mSegments[i]) + (mSegmentPadding * 2.0f);
			mSegmentRects.Add(.(x, 0, segmentWidth, Height));
			x += segmentWidth;
			if (i < mSegments.Count - 1)
				x += mSeparatorWidth;
		}
	}

	/// HALF OPEN on the right and bottom edges: segments sit next to their separator gap, and
	/// the first match wins.
	private int32 GetSegmentAt(float x, float y)
	{
		for (int i < mSegmentRects.Count)
		{
			let rect = mSegmentRects[i];
			if ((x >= rect.X) && (x < rect.X + rect.Width) && (y >= rect.Y)
				&& (y < rect.Y + rect.Height))
				return (int32)i;
		}
		return -1;
	}
}
