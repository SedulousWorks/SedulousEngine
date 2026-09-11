using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[CodeEditView]]'s painting.
///
/// Only the visible line range is drawn, and every horizontal position is column times advance
/// rather than a measured string, which is what a monospace editor buys: scrolling a large file
/// costs the same as scrolling a small one.
extension CodeEditView
{
	public override void OnDraw(UIDrawContext ctx)
	{
		RefreshMetrics(ctx.FontService);
		let font = (ctx.FontService != null) ? ctx.FontService.GetFont(FontFamily, FontSize) : null;

		let width = Width;
		let height = Height;
		let lineH = LineHeight;
		let advance = ColumnAdvance;
		let gutterW = GutterWidth;
		let textLeft = gutterW + PadLeft - mScrollX;
		let ascent = (font != null) ? font.Font.Metrics.Ascent : (lineH * 0.8f);

		let background = ResolveStyleColor(.Background, Color.Rgb(26, 28, 34));
		let textColor = ResolveStyleColor(.TextColor, Color.Rgb(220, 225, 235));
		let dimColor = ResolveStyleColor(.TextDimColor, Color.Rgb(120, 128, 144));
		let selectionColor = ResolveStyleColor(.SelectionColor, Color.Rgb(60, 120, 200, 80));
		let cursorColor = ResolveStyleColor(.CursorColor, Color.Rgb(220, 225, 235));
		let accent = ResolveStyleColor(.AccentColor, Color.Rgb(230, 140, 60));
		// Severity is SEMANTIC, so it comes from the theme rather than from the token palette.
		let errorColor = ResolveStyleColor(.ErrorColor, Color.Rgb(214, 80, 80));
		let warningColor = ResolveStyleColor(.WarningColor, Color.Rgb(240, 200, 90));

		ctx.VG.FillRect(.(0, 0, width, height), background);

		let firstLine = Math.Max(0, (int32)((mScrollY - PadTop) / lineH));
		let lastLine = Math.Min(mDoc.LineCount - 1,
			(int32)((mScrollY + mViewportH) / lineH) + 1);
		let selection = Selection;

		if (mHighlighter.HasLexer)
			mHighlighter.EnsureLexed(mDoc, lastLine);

		// The text region is CLIPPED to the right of the gutter: horizontally scrolled text
		// must never bleed under the line numbers. The gutter is painted afterwards, on top.
		ctx.PushClip(.(gutterW, 0, width - gutterW, height));

		for (var line = firstLine; line <= lastLine; line++)
		{
			let lineTop = PadTop + ((float)line * lineH) - mScrollY;
			let markers = mDoc.MarkersOn(line);

			// Row highlights: the execution line wins over the quiet current line tint.
			if (markers.HasFlag(.ExecutionLine))
			{
				ctx.VG.FillRect(.(gutterW, lineTop, width - gutterW, lineH),
					WithAlpha(accent, 0.18f));
			}
			else if ((line == mCursor.Line) && !HasSelection && IsFocused())
			{
				ctx.VG.FillRect(.(gutterW, lineTop, width - gutterW, lineH),
					WithAlpha(textColor, 0.05f));
			}

			if (markers.HasFlag(.Error))
			{
				ctx.VG.FillRect(.(gutterW, lineTop, width - gutterW, lineH),
					WithAlpha(errorColor, 26.0f / 255.0f));
			}

			// Search matches sit UNDER the selection band, with the current one brighter.
			for (int m < mMatches.Count)
			{
				let match = mMatches[m];
				if (match.Begin.Line != line)
					continue;

				let current = (m == mCurrentMatch);
				ctx.VG.FillRect(
					.(textLeft + ((float)match.Begin.Column * advance), lineTop,
						(float)(match.End.Column - match.Begin.Column) * advance, lineH),
					WithAlpha(accent, current ? 0.45f : 0.18f));
			}

			// Selection band.
			if (HasSelection && (line >= selection.Begin.Line) && (line <= selection.End.Line))
			{
				let fromCol = (line == selection.Begin.Line) ? selection.Begin.Column : 0;
				// A line fully inside the selection shows a sliver past its end, which is the
				// newline being selected.
				let toCol = (line == selection.End.Line)
					? (float)selection.End.Column
					: ((float)mDoc.LineLength(line) + 0.4f);
				ctx.VG.FillRect(
					.(textLeft + ((float)fromCol * advance), lineTop,
						(toCol - (float)fromCol) * advance, lineH),
					selectionColor);
			}

			// The text: styled token runs when a lexer is set, one draw call otherwise.
			if ((font != null) && !mDoc.Line(line).IsEmpty)
			{
				let tokens = mHighlighter.TokensFor(line);
				if (mHighlighter.HasLexer && (tokens.Length > 0))
				{
					let text = mDoc.Line(line);
					for (let token in tokens)
					{
						ctx.VG.DrawText(text.Substring(token.ByteBegin,
							token.ByteEnd - token.ByteBegin), font,
							Float2(textLeft + ((float)token.Column * advance), lineTop + ascent),
							TokenColors.For(token.Kind, textColor));
					}
				}
				else if (!mHighlighter.HasLexer)
				{
					ctx.VG.DrawText(mDoc.Line(line), font, Float2(textLeft, lineTop + ascent),
						textColor);
				}
			}
		}

		DrawCaret(ctx, textLeft, lineH, advance, cursorColor);
		DrawBracketMatch(ctx, firstLine, lastLine, textLeft, lineH, advance, accent);

		ctx.PopClip();

		if (ShowGutter)
			DrawGutter(ctx, font, firstLine, lastLine, gutterW, height, lineH, advance, ascent,
				background, textColor, dimColor, errorColor, warningColor);

		// The backdrop behind the floating find bar. Its controls are drawn by DrawChildren.
		if ((mFindBarMode != .Closed) && (mFindBar != null))
		{
			ctx.VG.FillRect(mFindBarFrame, Palette.Lighten(background, 0.06f));
			ctx.VG.StrokeRect(mFindBarFrame, WithAlpha(textColor, 0.25f), 1.0f);
		}

		DrawChildren(ctx); // scrollbars and find bar

		if (mCompletion.IsOpen)
			DrawCompletionPopup(ctx, font, textLeft, lineH, advance, ascent, background,
				textColor, accent);
	}

	private static Color WithAlpha(Color color, float alpha) =>
		.(color.R, color.G, color.B, alpha);

	private void DrawCaret(UIDrawContext ctx, float textLeft, float lineH, float advance,
		Color cursorColor)
	{
		if (!IsFocused() || ReadOnly)
			return;

		let elapsed = ((Context != null) ? Context.TotalTime : 0.0f) - mBlinkReset;
		if (((int32)(elapsed / 0.5f) % 2) != 0)
			return;

		let caretX = textLeft + ((float)mCursor.Column * advance);
		let caretY = PadTop + ((float)mCursor.Line * lineH) - mScrollY;
		ctx.VG.FillRect(.(caretX - 1.0f, caretY, 2.0f, lineH), cursorColor);
	}

	private void DrawBracketMatch(UIDrawContext ctx, int32 firstLine, int32 lastLine,
		float textLeft, float lineH, float advance, Color accent)
	{
		RefreshBracketMatch();
		if (!mBracketValid)
			return;

		CodePosition[2] brackets = .(mBracketA, mBracketB);
		for (let bracket in brackets)
		{
			if ((bracket.Line < firstLine) || (bracket.Line > lastLine))
				continue;

			let x = textLeft + ((float)bracket.Column * advance);
			let y = PadTop + ((float)bracket.Line * lineH) - mScrollY;
			ctx.VG.StrokeRect(.(x - 1.0f, y, advance + 2.0f, lineH),
				WithAlpha(accent, 0.7f), 1.0f);
		}
	}

	private void DrawGutter(UIDrawContext ctx, CachedFont font, int32 firstLine, int32 lastLine,
		float gutterW, float height, float lineH, float advance, float ascent, Color background,
		Color textColor, Color dimColor, Color errorColor, Color warningColor)
	{
		ctx.VG.FillRect(.(0, 0, gutterW, height), Palette.Darken(background, 0.25f));

		let number = scope String();
		for (var line = firstLine; line <= lastLine; line++)
		{
			let lineTop = PadTop + ((float)line * lineH) - mScrollY;
			let markers = mDoc.MarkersOn(line);
			let centerY = lineTop + (lineH * 0.5f);

			if (markers.HasFlag(.Breakpoint))
				ctx.VG.FillCircle(.(MarkerMargin * 0.5f, centerY), 4.5f, errorColor);

			if (markers.HasFlag(.ExecutionLine))
			{
				// A right pointing arrow in the margin.
				ctx.VG.BeginPath();
				ctx.VG.MoveTo((MarkerMargin * 0.5f) - 4.0f, centerY - 4.5f);
				ctx.VG.LineTo((MarkerMargin * 0.5f) + 4.0f, centerY);
				ctx.VG.LineTo((MarkerMargin * 0.5f) - 4.0f, centerY + 4.5f);
				ctx.VG.Stroke(warningColor, 2.0f);
			}
			else if (markers.HasFlag(.Error) || markers.HasFlag(.Warning))
			{
				let color = markers.HasFlag(.Error) ? errorColor : warningColor;
				ctx.VG.FillRect(.(MarkerMargin - 5.0f, centerY - 3.5f, 7.0f, 7.0f), color);
			}

			if (ShowLineNumbers && (font != null))
			{
				number.Clear();
				(line + 1).ToString(number);

				let numberRight = gutterW - GutterGap;
				let numberX = numberRight - ((float)number.Length * advance);
				let numberColor = (line == mCursor.Line) ? textColor : dimColor;
				ctx.VG.DrawText(number, font, Float2(numberX, lineTop + ascent), numberColor);
			}
		}
	}

	private void DrawCompletionPopup(UIDrawContext ctx, CachedFont font, float textLeft,
		float lineH, float advance, float ascent, Color background, Color textColor, Color accent)
	{
		let count = Math.Min(mCompletion.ItemCount, PopupMaxVisible);
		if (count <= 0)
			return;

		int maxLabel = 8;
		for (int32 i < mCompletion.ItemCount)
			maxLabel = Math.Max(maxLabel, Utf8Text.CharCount(mCompletion.Item(i).Label));

		let popupW = Math.Clamp(((float)maxLabel * advance) + 16.0f, 140.0f, 380.0f);
		let popupH = ((float)count * lineH) + 6.0f;

		let anchor = mCompletion.Anchor;
		var x = textLeft + ((float)anchor.Column * advance) - 4.0f;
		var y = PadTop + ((float)(anchor.Line + 1) * lineH) - mScrollY + 2.0f;
		if ((y + popupH) > Height)
			y = PadTop + ((float)anchor.Line * lineH) - mScrollY - popupH - 2.0f;

		x = Math.Clamp(x, 0.0f, Math.Max(0.0f, Width - popupW));

		ctx.VG.FillRect(.(x, y, popupW, popupH), Palette.Lighten(background, 0.08f));
		ctx.VG.StrokeRect(.(x, y, popupW, popupH), WithAlpha(textColor, 0.25f), 1.0f);

		// Keep the selected row inside the visible window.
		int32 firstItem = 0;
		if (mCompletion.SelectedIndex >= count)
			firstItem = mCompletion.SelectedIndex - count + 1;

		for (int32 i < count)
		{
			let index = firstItem + i;
			let item = mCompletion.Item(index);
			if (item == null)
				break;

			let rowY = y + 3.0f + ((float)i * lineH);
			if (index == mCompletion.SelectedIndex)
				ctx.VG.FillRect(.(x + 1.0f, rowY, popupW - 2.0f, lineH), WithAlpha(accent, 0.3f));

			if (font != null)
				ctx.VG.DrawText(item.Label, font, Float2(x + 8.0f, rowY + ascent), textColor);
		}

		// A slim proportional thumb on the right edge, so a list longer than the window is
		// evident. The popup is keyboard driven, so the strip is informational only, tracking
		// the selection window as the arrows move it.
		let total = mCompletion.ItemCount;
		if (total <= count)
			return;

		let trackX = x + popupW - 4.0f;
		let trackTop = y + 2.0f;
		let trackHeight = popupH - 4.0f;
		ctx.VG.FillRect(.(trackX, trackTop, 3.0f, trackHeight), WithAlpha(textColor, 0.08f));

		let thumbHeight = Math.Max(8.0f, trackHeight * (float)count / (float)total);
		let thumbTravel = trackHeight - thumbHeight;
		let thumbY = trackTop + (thumbTravel * (float)firstItem / (float)Math.Max(1, total - count));
		ctx.VG.FillRect(.(trackX, thumbY, 3.0f, thumbHeight), WithAlpha(textColor, 0.35f));
	}
}
