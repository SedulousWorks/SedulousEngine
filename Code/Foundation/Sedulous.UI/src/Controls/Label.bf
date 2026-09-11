using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// Text: one line, several lines, wrapped, or ellipsised.
///
/// Measure runs EVERY frame, since there are no layout dirty flags yet, and shaping a
/// paragraph per pass was the single biggest steady state text cost in the UI. Both the
/// measure and the draw therefore cache their results, keyed on the VALUES that produced them.
class Label : View
{
	public Property<String> Text = new .(new String()) ~ delete _;
	public Property<TextAlignment> HAlign = new .(.Left) ~ delete _;
	public Property<VerticalAlignment> VAlign = new .(.Middle) ~ delete _;
	public Property<bool> WordWrap = new .(false) ~ delete _;
	public Property<bool> Ellipsis = new .(false) ~ delete _;
	/// Null defers to the cascade.
	public Property<float?> FontSize = new .() ~ delete _;
	public Property<String> FontFamily = new .(new String()) ~ delete _;
	public Property<Color?> TextColor = new .() ~ delete _;

	/// Keyed on VALUES, never on a font pointer: a freed font's address can come back as a
	/// different font, and a pointer key would then match the wrong thing.
	///
	/// Holds its OWN copy of the text so the line slices stay valid until it is rekeyed.
	private class ShapedCache
	{
		public String Text = new .() ~ delete _;
		public String Family = new .() ~ delete _;
		public float FontSize = -1.0f;
		/// The wrap or ellipsis width; -1 when the result does not depend on one.
		public float Width = -1.0f;
		public bool Wrap = false;
		public float TextWidth = 0.0f;
		public float TextHeight = 0.0f;
		/// BORROW this cache's own Text.
		public List<StringView> Lines = new .() ~ delete _;
		public String Ellipsized = new .() ~ delete _;

		public bool Matches(StringView text, StringView family, float fontSize, float width,
			bool wrap) =>
			(Wrap == wrap) && (FontSize == fontSize) && (Width == width) && (Family == family)
			&& (Text == text);

		public void Rekey(StringView text, StringView family, float fontSize, float width,
			bool wrap)
		{
			Text.Set(text);
			Family.Set(family);
			FontSize = fontSize;
			Width = width;
			Wrap = wrap;
			TextWidth = 0.0f;
			TextHeight = 0.0f;
			Lines.Clear();
			Ellipsized.Clear();
		}
	}

	/// Two caches, not one: the measure constraint and the ARRANGED width differ, and a single
	/// slot would ping pong between them every frame.
	private ShapedCache mMeasureCache = new .() ~ delete _;
	private ShapedCache mDrawCache = new .() ~ delete _;

	public this()
	{
		Text.SetOwner(this);
		HAlign.SetOwner(this, .Visual);
		VAlign.SetOwner(this, .Visual);
		WordWrap.SetOwner(this);
		Ellipsis.SetOwner(this, .Visual);
		FontSize.SetOwner(this);
		FontFamily.SetOwner(this, .Visual);
		TextColor.SetOwner(this, .Visual);
	}

	public this(StringView text) : this()
	{
		Text.Value.Set(text); // reuses the empty String the property was built with
	}

	public ~this()
	{
		delete Text.Value;
		delete FontFamily.Value;
	}

	/// Sets the text and answers this, so a label can be built in one expression.
	public Label SetText(StringView text)
	{
		if (Text.Value == null)
			Text.Value = new String(text);
		else
			Text.Value.Set(text);
		Invalidate();
		return this;
	}

	/// The first line's baseline, so a row of labels and controls can align on their text
	/// rather than on their boxes.
	public override float GetBaseline()
	{
		if ((Context != null) && (Context.FontService != null))
		{
			if (let font = ResolveFont(Context.FontService))
				return font.Font.Metrics.Ascent;
		}
		return -1.0f;
	}

	/// Whether single line truncation is on: the property, or `text-overflow: ellipsis` from
	/// the cascade. The property WINS when set.
	public bool EffectiveEllipsis()
	{
		if (Ellipsis.Value)
			return true;

		let overflow = scope String();
		ResolveStyleString(.TextOverflow, overflow);
		return overflow == "ellipsis";
	}

	// ---- Measure -------------------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = ResolveFontSize();
		var textWidth = 0.0f;
		var textHeight = fontSize; // the best estimate with no font to ask

		let text = Text.Value;
		if (!text.IsEmpty && (Context != null) && (Context.FontService != null))
		{
			if (let font = ResolveFont(Context.FontService))
			{
				let family = scope String();
				ResolveStyleFontFamily(family, FontFamily.Value);

				if (WordWrap.Value && (font.Shaper != null))
					MeasureWrapped(font, text, family, fontSize, constraints, out textWidth,
						out textHeight);
				else if (HasNewlines(text))
					MeasureLines(font, text, family, fontSize, out textWidth, out textHeight);
				else
					MeasureSingleLine(font, text, family, fontSize, out textWidth,
						out textHeight);
			}
		}

		MeasuredSize = .(constraints.ConstrainWidth(textWidth),
			constraints.ConstrainHeight(textHeight));
	}

	private void MeasureWrapped(CachedFont font, StringView text, StringView family,
		float fontSize, BoxConstraints constraints, out float textWidth, out float textHeight)
	{
		// Unbounded, a wrapped label has no width to wrap against, so a large finite number
		// stands in rather than letting the shaper run to the float ceiling.
		let maxWidth = (constraints.MaxWidth < FloatMax) ? constraints.MaxWidth : 10000.0f;
		textWidth = maxWidth;

		if (!mMeasureCache.Matches(text, family, fontSize, maxWidth, true))
		{
			mMeasureCache.Rekey(text, family, fontSize, maxWidth, true);
			let positions = scope List<GlyphPosition>();
			if (font.Shaper.ShapeTextWrapped(font.Font, text, maxWidth, positions,
				var totalHeight) case .Ok)
				mMeasureCache.TextHeight = totalHeight;
			else
				mMeasureCache.TextHeight = fontSize;
		}

		textHeight = mMeasureCache.TextHeight;
	}

	private void MeasureLines(CachedFont font, StringView text, StringView family, float fontSize,
		out float textWidth, out float textHeight)
	{
		if (!mMeasureCache.Matches(text, family, fontSize, -1.0f, false))
		{
			mMeasureCache.Rekey(text, family, fontSize, -1.0f, false);
			// The slices borrow the CACHE's copy, which is stable until the next rekey.
			SplitLines(mMeasureCache.Text, mMeasureCache.Lines);

			var widest = 0.0f;
			for (let line in mMeasureCache.Lines)
				widest = Max(widest, font.Font.MeasureString(line));

			mMeasureCache.TextWidth = widest;
			mMeasureCache.TextHeight = font.Font.Metrics.LineHeight
				* (float)mMeasureCache.Lines.Count;
		}

		textWidth = mMeasureCache.TextWidth;
		textHeight = mMeasureCache.TextHeight;
	}

	private void MeasureSingleLine(CachedFont font, StringView text, StringView family,
		float fontSize, out float textWidth, out float textHeight)
	{
		if (!mMeasureCache.Matches(text, family, fontSize, -1.0f, false))
		{
			mMeasureCache.Rekey(text, family, fontSize, -1.0f, false);
			mMeasureCache.TextWidth = font.Font.MeasureString(text);
			mMeasureCache.TextHeight = font.Font.Metrics.LineHeight;
		}

		textWidth = mMeasureCache.TextWidth;
		textHeight = mMeasureCache.TextHeight;
	}

	// ---- Draw ----------------------------------------------------------------------------------

	public override void OnDraw(UIDrawContext ctx)
	{
		let text = Text.Value;
		if (text.IsEmpty || (ctx.FontService == null))
			return;

		let font = ResolveFont(ctx.FontService);
		if (font == null)
			return;

		var textColor = (TextColor.Value != null) ? TextColor.Value.Value
			: ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		if (!IsEffectivelyEnabled())
			textColor = Palette.ComputeDisabled(textColor);

		let family = scope String();
		ResolveStyleFontFamily(family, FontFamily.Value);
		let fontSize = ResolveFontSize();

		if (WordWrap.Value)
			DrawWrapped(ctx, font, text, family, fontSize, textColor);
		else if (HasNewlines(text))
			DrawLines(ctx, font, text, family, fontSize, textColor);
		else if (EffectiveEllipsis())
			DrawEllipsized(ctx, font, text, family, fontSize, textColor);
		else
			ctx.VG.DrawText(text, font, .(0, 0, Width, Height), HAlign.Value, VAlign.Value,
				textColor);
	}

	private void DrawWrapped(UIDrawContext ctx, CachedFont font, StringView text,
		StringView family, float fontSize, Color textColor)
	{
		var y = 0.0f;

		// Only a non top alignment needs the total height, so the measurement is skipped
		// entirely for the common case.
		if ((VAlign.Value != .Top) && (font.Shaper != null))
		{
			if (!mDrawCache.Matches(text, family, fontSize, Width, true))
			{
				mDrawCache.Rekey(text, family, fontSize, Width, true);
				mDrawCache.TextHeight = ctx.VG.MeasureTextWrapped(text, font, Width);
			}

			let totalHeight = mDrawCache.TextHeight;
			if (VAlign.Value == .Middle)
				y = (Height - totalHeight) * 0.5f;
			else if (VAlign.Value == .Bottom)
				y = Height - totalHeight;
		}

		ctx.VG.DrawTextWrapped(text, font, Float2(0, y), Width, textColor, HAlign.Value);
	}

	private void DrawLines(UIDrawContext ctx, CachedFont font, StringView text, StringView family,
		float fontSize, Color textColor)
	{
		let lineHeight = font.Font.Metrics.LineHeight;
		if (!mDrawCache.Matches(text, family, fontSize, -1.0f, false))
		{
			mDrawCache.Rekey(text, family, fontSize, -1.0f, false);
			SplitLines(mDrawCache.Text, mDrawCache.Lines);
		}

		let totalHeight = lineHeight * (float)mDrawCache.Lines.Count;
		var y = 0.0f;
		if (VAlign.Value == .Middle)
			y = (Height - totalHeight) * 0.5f;
		else if (VAlign.Value == .Bottom)
			y = Height - totalHeight;

		// Each line is drawn TOP aligned in its own band: the vertical alignment was already
		// spent positioning the block.
		for (let line in mDrawCache.Lines)
		{
			ctx.VG.DrawText(line, font, .(0, y, Width, lineHeight), HAlign.Value, .Top, textColor);
			y += lineHeight;
		}
	}

	private void DrawEllipsized(UIDrawContext ctx, CachedFont font, StringView text,
		StringView family, float fontSize, Color textColor)
	{
		if (!mDrawCache.Matches(text, family, fontSize, Width, false))
		{
			mDrawCache.Rekey(text, family, fontSize, Width, false);
			TruncateToWidth(font.Font, text, Width, mDrawCache.Ellipsized);
		}

		ctx.VG.DrawText(mDrawCache.Ellipsized, font, .(0, 0, Width, Height), HAlign.Value,
			VAlign.Value, textColor);
	}

	// ---- Helpers -------------------------------------------------------------------------------

	private float ResolveFontSize() =>
		(FontSize.Value != null) ? FontSize.Value.Value : ResolveStyleFloat(.FontSize, 16.0f);

	private CachedFont ResolveFont(IFontService service)
	{
		if (service == null)
			return null;

		let family = scope String();
		ResolveStyleFontFamily(family, FontFamily.Value);
		return service.GetFont(family, ResolveFontSize());
	}

	private static bool HasNewlines(StringView text)
	{
		for (let c in text.RawChars)
		{
			if (c == '\n')
				return true;
		}
		return false;
	}

	/// Splits on newlines into BORROWED slices, valid while the string behind them lives.
	private static void SplitLines(StringView text, List<StringView> outLines)
	{
		var start = 0;
		for (int i < text.Length)
		{
			if (text[i] != '\n')
				continue;

			outLines.Add(.(text.Ptr + start, i - start));
			start = i + 1;
		}
		outLines.Add(.(text.Ptr + start, text.Length - start));
	}
}
