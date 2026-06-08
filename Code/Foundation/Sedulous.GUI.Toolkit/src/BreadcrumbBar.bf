namespace Sedulous.GUI.Toolkit;

using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// Horizontal path display with clickable segments and separator arrows.
/// Used for file path navigation, hierarchy display, etc.
public class BreadcrumbBar : ViewGroup
{
	private List<String> mSegments = new .() ~ { for (let s in _) delete s; delete _; };
	private List<RectangleF> mSegmentRects = new .() ~ delete _;
	private int32 mHoveredIndex = -1;
	private float mFontSize = 13;
	private float mSegmentPadding = 8;
	private float mSeparatorWidth = 16;

	/// Fired when a segment is clicked. Parameter: segment index.
	public Event<delegate void(BreadcrumbBar, int32)> OnSegmentClicked ~ _.Dispose();

	public int32 SegmentCount => (int32)mSegments.Count;

	public this()
	{
		StyleId = new String("breadcrumbbar");
		Cursor = .Hand;
	}

	/// Set the path from a list of segments.
	public void SetSegments(Span<StringView> segments)
	{
		for (let s in mSegments) delete s;
		mSegments.Clear();
		for (let s in segments)
			mSegments.Add(new String(s));
		Invalidate();
	}

	/// Set the path from a separator-delimited string.
	public void SetPath(StringView path, char8 separator = '/')
	{
		for (let s in mSegments) delete s;
		mSegments.Clear();
		for (let part in path.Split(separator))
		{
			let trimmed = scope String(part);
			trimmed.Trim();
			if (!trimmed.IsEmpty)
				mSegments.Add(new String(trimmed));
		}
		Invalidate();
	}

	/// Get the segment text at an index.
	public StringView GetSegment(int32 index)
	{
		if (index < 0 || index >= mSegments.Count) return "";
		return mSegments[index];
	}

	/// Get the full path up to and including the given segment index.
	public void GetPathUpTo(int32 index, String output, char8 separator = '/')
	{
		for (int32 i = 0; i <= index && i < mSegments.Count; i++)
		{
			if (i > 0) output.Append(separator);
			output.Append(mSegments[i]);
		}
	}

	// === Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		float totalW = 0;
		float textH = mFontSize;

		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(mFontSize);
			if (font != null)
			{
				textH = font.Font.Metrics.LineHeight;
				for (int32 i = 0; i < mSegments.Count; i++)
				{
					totalW += font.Font.MeasureString(mSegments[i]) + mSegmentPadding * 2;
					if (i < mSegments.Count - 1)
						totalW += mSeparatorWidth;
				}
			}
		}

		MeasuredSize = .(constraints.ConstrainWidth(totalW),
			constraints.ConstrainHeight(textH + 8));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		RebuildSegmentRects();
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let h = Height;

		// Background.
		let bgDrawable = ResolveStyleDrawable(.Background);
		if (bgDrawable != null)
			bgDrawable.Draw(ctx, .(0, 0, Width, h));
		else
			ctx.VG.FillRect(.(0, 0, Width, h), .(40, 42, 52, 255));

		let font = ctx.FontService?.GetFont(mFontSize);
		if (font == null) return;

		let textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
		let hoverColor = ResolveStyleColor(.AccentColor, .(80, 150, 240, 255));
		let lastColor = ResolveStyleColor(.TextDimColor, .(180, 185, 200, 255));
		let sepColor = ResolveStyleColor(.BorderColor, .(100, 105, 120, 255));

		for (int32 i = 0; i < mSegments.Count; i++)
		{
			if (i >= mSegmentRects.Count) break;
			let rect = mSegmentRects[i];
			let isLast = i == mSegments.Count - 1;
			let isHovered = i == mHoveredIndex;

			// Hover highlight - derived from background.
			if (isHovered && !isLast)
			{
				var bgColor = Color(40, 42, 52, 255);
				if (let rrd = bgDrawable as RoundedRectDrawable)
					bgColor = rrd.FillColor;
				else if (let cd = bgDrawable as ColorDrawable)
					bgColor = cd.Color;
				ctx.VG.FillRect(rect, Palette.ComputeHover(bgColor));
			}

			// Segment text.
			let color = isHovered ? hoverColor : (isLast ? lastColor : textColor);
			ctx.VG.DrawText(mSegments[i], font, rect, .Center, .Middle, color);

			// Separator arrow after each segment except last.
			if (!isLast)
			{
				let sepX = rect.X + rect.Width + 2;
				let sepCY = h * 0.5f;
				let arrowSz = 4.0f;
				ctx.VG.BeginPath();
				ctx.VG.MoveTo(sepX, sepCY - arrowSz);
				ctx.VG.LineTo(sepX + arrowSz, sepCY);
				ctx.VG.LineTo(sepX, sepCY + arrowSz);
				ctx.VG.Stroke(sepColor, 1.5f);
			}
		}
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left) return;

		let screenX = Context?.InputManager?.MouseX ?? 0;
		let screenY = Context?.InputManager?.MouseY ?? 0;
		let local = ScreenToLocal(.(screenX, screenY));

		let idx = GetSegmentAt(local.X, local.Y);
		if (idx >= 0)
		{
			OnSegmentClicked(this, idx);
			e.Handled = true;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		let screenX = Context?.InputManager?.MouseX ?? 0;
		let screenY = Context?.InputManager?.MouseY ?? 0;
		let local = ScreenToLocal(.(screenX, screenY));

		let idx = GetSegmentAt(local.X, local.Y);
		if (idx != mHoveredIndex)
		{
			mHoveredIndex = idx;
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

	// === Internal ===

	private void RebuildSegmentRects()
	{
		mSegmentRects.Clear();
		let font = Context?.FontService?.GetFont(mFontSize);
		if (font == null) return;

		float x = 0;
		for (int32 i = 0; i < mSegments.Count; i++)
		{
			let textW = font.Font.MeasureString(mSegments[i]);
			let segW = textW + mSegmentPadding * 2;
			mSegmentRects.Add(.(x, 0, segW, Height));
			x += segW;
			if (i < mSegments.Count - 1)
				x += mSeparatorWidth;
		}
	}

	private int32 GetSegmentAt(float x, float y)
	{
		for (int32 i = 0; i < mSegmentRects.Count; i++)
		{
			let r = mSegmentRects[i];
			if (x >= r.X && x < r.X + r.Width && y >= r.Y && y < r.Y + r.Height)
				return i;
		}
		return -1;
	}
}
