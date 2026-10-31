using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[CodeEditView]]'s metrics, scrolling and layout.
extension CodeEditView
{
	protected void RefreshMetrics() =>
		RefreshMetrics((Context != null) ? Context.FontService : null);

	/// Takes the real monospace advance from the font when there is one. The fallbacks in
	/// LineHeight and ColumnAdvance carry the headless case, so nothing here has to guard the
	/// absence of a font service beyond returning.
	protected void RefreshMetrics(IFontService service)
	{
		if (service == null)
			return;

		let font = service.GetFont(FontFamily, FontSize);
		if ((font == null) || (font.Font == null))
			return;

		mLineHeight = font.Font.Metrics.LineHeight;
		let info = font.Font.GetGlyphInfo((int32)'M');
		mAdvance = (info.AdvanceWidth > 0.0f) ? info.AdvanceWidth : font.Font.MeasureString("M");
	}

	/// The widest line, which is the horizontal scroll extent. Recomputed only when the line
	/// set changed, because it is a full pass over the buffer.
	protected void RefreshMaxLine()
	{
		if (!mMaxLineDirty)
			return;

		mMaxLineLength = 0;
		for (int32 line < mDoc.LineCount)
			mMaxLineLength = Math.Max(mMaxLineLength, mDoc.LineLength(line));

		mMaxLineDirty = false;
	}

	protected float ContentHeight => (PadTop * 2.0f) + ((float)mDoc.LineCount * LineHeight);

	protected float ContentWidth => (PadLeft * 2.0f) + ((float)(mMaxLineLength + 1) * ColumnAdvance);

	protected float MaxScrollY => Math.Max(0.0f, ContentHeight - mViewportH);

	protected float MaxScrollX => Math.Max(0.0f, ContentWidth - (mViewportW - GutterWidth));

	protected void ClampScroll()
	{
		mScrollY = Math.Clamp(mScrollY, 0.0f, MaxScrollY);
		mScrollX = Math.Clamp(mScrollX, 0.0f, MaxScrollX);
	}

	protected void EnsureCursorVisible()
	{
		let lineH = LineHeight;
		let caretTop = PadTop + ((float)mCursor.Line * lineH);
		if ((caretTop - PadTop) < mScrollY)
			mScrollY = caretTop - PadTop;
		else if ((caretTop + lineH) > (mScrollY + mViewportH))
			mScrollY = caretTop + lineH - mViewportH;

		let caretX = (float)mCursor.Column * ColumnAdvance;
		let textViewportW = mViewportW - GutterWidth - (PadLeft * 2.0f);
		if (caretX < mScrollX)
			mScrollX = Math.Max(0.0f, caretX - (ColumnAdvance * 4.0f));
		else if (caretX > (mScrollX + textViewportW))
			mScrollX = caretX - textViewportW + (ColumnAdvance * 4.0f);
	}

	protected override void OnMeasure(BoxConstraints constraints) =>
		MeasuredSize = .(constraints.ConstrainWidth(480.0f), constraints.ConstrainHeight(320.0f));

	protected override void OnLayout(float left, float top, float width, float height)
	{
		RefreshMetrics();
		RefreshMaxLine();

		let barSize = mVBar.BarThickness;
		let needV = ContentHeight > height;
		let needH = ContentWidth > (width - (needV ? barSize : 0.0f) - GutterWidth);
		mViewportH = height - (needH ? barSize : 0.0f);
		mViewportW = width - (needV ? barSize : 0.0f);

		if (mPendingCursorScroll)
		{
			EnsureCursorVisible();
			mPendingCursorScroll = false;
		}

		ClampScroll();

		if ((Context != null) && (mVBar.Context == null))
			Context.AttachView(mVBar);

		if ((Context != null) && (mHBar.Context == null))
			Context.AttachView(mHBar);

		mVBar.Visibility = needV ? .Visible : .Gone;
		mHBar.Visibility = needH ? .Visible : .Gone;

		// The MAX goes in before the value. SetValue clamps against the bar's current maximum
		// and fires OnValueChanged on a clamp, so with a stale, smaller maximum it would snap
		// the scroll back a line right after EnsureCursorVisible advanced it, which is the
		// half hidden caret line.
		if (needV)
		{
			mVBar.MaxValue = MaxScrollY;
			mVBar.ViewportSize = mViewportH;
			mVBar.Value = mScrollY;
			mVBar.Measure(BoxConstraints.Tight(barSize, mViewportH));
			mVBar.Layout(width - barSize, 0, barSize, mViewportH);
		}

		if (needH)
		{
			mHBar.MaxValue = MaxScrollX;
			mHBar.ViewportSize = mViewportW - GutterWidth;
			mHBar.Value = mScrollX;
			mHBar.Measure(BoxConstraints.Tight(mViewportW, barSize));
			mHBar.Layout(0, height - barSize, mViewportW, barSize);
		}

		// The find bar FLOATS top right over the text. It is a logical child, so DrawChildren
		// paints it above the content and hit testing finds it.
		if ((mFindBar != null) && (mFindBarMode != .Closed))
		{
			mFindBar.Measure(BoxConstraints.Loose(width - GutterWidth - 16.0f, height));
			let barWidth = mFindBar.MeasuredSize.X;
			let barHeight = mFindBar.MeasuredSize.Y;
			let barX = Math.Max(GutterWidth,
				width - barWidth - (needV ? barSize : 0.0f) - 6.0f);
			mFindBar.Layout(barX, 2.0f, barWidth, barHeight);
			mFindBarFrame = .(barX, 2.0f, barWidth, barHeight);
		}
	}

	/// The scrollbars are visual children WITHOUT being logical ones, so they draw and hit test
	/// without appearing in the child list the find bar lives in.
	public override int VisualChildCount => ChildCount + 2;

	public override View GetVisualChild(int index)
	{
		if (index < ChildCount)
			return base.GetVisualChild(index);

		if (index == ChildCount)
			return mVBar;

		if (index == (ChildCount + 1))
			return mHBar;

		return null;
	}
}
