using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// A paragraph of styled runs, the sibling of Label, which keeps its single run contract and
/// measure cache.
///
/// Its text is markup (see TextMarkup) or runs set directly; runs take the control's font family,
/// size and text colour where they leave them unset; it wraps at its width unless told not to; a
/// click on a link raises OnLink with the link's id. Markup problems are logged once per text and
/// the offending text drawn as written.
class RichText : View
{
	/// The text, as markup ([b], [color=], [link=], ...). Setting it replaces runs set directly.
	public Property<String> Markup = new .(new String()) ~ delete _;
	public Property<TextAlignment> HAlign = new .(.Left) ~ delete _;
	public Property<VerticalAlignment> VAlign = new .(.Top) ~ delete _;
	/// Null: the style's word-wrap when set, else wrapped.
	public Property<bool?> WordWrap = new .() ~ delete _;
	/// Null defers to the cascade.
	public Property<float?> FontSize = new .() ~ delete _;
	public Property<String> FontFamily = new .(new String()) ~ delete _;
	/// Null defers to the style's text-color.
	public Property<Color?> TextColor = new .() ~ delete _;

	/// A link was clicked: the control and the link's id.
	public Event<delegate void(RichText, StringView)> OnLink ~ _.Dispose();

	private TextDocument mDocument = new .() ~ delete _;
	private String mParsedMarkup = new .() ~ delete _;
	private bool mParsed;
	private bool mRunsSet;
	private uint64 mDocumentVersion = 1;

	private TextLayout mLayout = new .() ~ delete _;
	private uint64 mLayoutVersion;
	private String mLayoutFamily = new .() ~ delete _;
	private float mLayoutSize = -1.0f;
	private Color mLayoutColor;
	private TextAlignment mLayoutAlign = .Left;
	private bool mLayoutWrap;
	private float mLayoutWidth = -1.0f;
	/// Identity only, never dereferenced.
	private IFontService mLayoutService;
	private Float2 mDrawOffset;

	public this()
	{
		Markup.SetOwner(this);
		HAlign.SetOwner(this, .Visual);
		VAlign.SetOwner(this, .Visual);
		WordWrap.SetOwner(this);
		FontSize.SetOwner(this);
		FontFamily.SetOwner(this);
		TextColor.SetOwner(this, .Visual);
	}

	public this(StringView markup) : this()
	{
		Markup.Value.Set(markup);
	}

	public ~this()
	{
		delete Markup.Value;
		delete FontFamily.Value;
	}

	/// Sets the markup and answers this, for chaining.
	public RichText SetMarkup(StringView markup)
	{
		Markup.Value.Set(markup);
		mParsed = false;
		Invalidate();
		return this;
	}

	/// Sets the runs directly, for a script building a paragraph without markup; the control
	/// takes them. Markup set later replaces them.
	public void SetRuns(List<TextRun> runs)
	{
		delete mDocument;
		mDocument = new .();
		mDocument.Runs.AddRange(runs);
		runs.Clear();
		mRunsSet = true;
		// Markup set after replaces them, whatever it was before.
		Markup.Value.Clear();
		mParsedMarkup.Clear();
		mDocumentVersion++;
		Invalidate();
	}

	/// The runs the control draws: its markup's, or those set directly.
	public TextDocument Document
	{
		get
		{
			SyncDocument();
			return mDocument;
		}
	}

	/// The last layout, in the control's own coordinates, for tests and tools.
	public TextLayout Layout => mLayout;

	/// The link id under a point in the control's coordinates, or empty.
	public StringView LinkAt(Float2 local)
	{
		let run = mLayout.LinkAt(.(local.X - mDrawOffset.X, local.Y - mDrawOffset.Y));
		if ((run < 0) || (run >= mDocument.Runs.Count))
			return default;
		return mDocument.Runs[run].Link;
	}

	public override CursorType CursorAt(Float2 localPoint) => LinkAt(localPoint).IsEmpty ? Cursor : .Hand;

	/// The colour the text draws with: the control's own, else the style's text-color.
	public Color ResolvedTextColor => (TextColor.Value != null) ? TextColor.Value.Value
		: ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));

	/// Its own WordWrap when set, else the `word-wrap` style, else wrapped.
	public bool IsWordWrapped
	{
		get
		{
			if (WordWrap.Value.HasValue)
				return WordWrap.Value.Value;
			let styled = ResolveStyle(.WordWrap).AsBool;
			return !styled.HasValue || styled.Value;
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		var width = 0.0f;
		var height = 0.0f;
		if ((Context != null) && (Context.FontService != null))
		{
			let maxWidth = (constraints.MaxWidth < FloatMax) ? constraints.MaxWidth : 0.0f;
			let layout = LayOut(Context.FontService, IsWordWrapped ? maxWidth : 0.0f);
			// As wide as its widest line, within maxWidth when wrapped.
			width = layout.Width;
			height = layout.Height;
		}
		MeasuredSize = .(constraints.ConstrainWidth(width), constraints.ConstrainHeight(height));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (ctx.FontService == null)
			return;
		let layout = LayOut(ctx.FontService, IsWordWrapped ? Width : 0.0f, Width);
		let v = VAlign.Value;
		mDrawOffset = .(0.0f, (v == .Middle) ? (Height - layout.Height) * 0.5f : ((v == .Bottom) ? Height - layout.Height : 0.0f));
		let dim = !IsEffectivelyEnabled();
		Color Tone(Color c) => dim ? Palette.ComputeDisabled(c) : c;
		for (let run in layout.GlyphRuns)
		{
			let slanted = run.SyntheticItalic;
			if (slanted)
			{
				// Lean the glyphs about their baseline: x moves right by a fifth of the height
				// above it.
				ctx.VG.PushState();
				var lean = Float4x4.Identity();
				let baseline = mDrawOffset.Y + run.Baseline;
				lean[1, 0] = -0.2f;
				lean[3, 0] = 0.2f * baseline;
				ctx.VG.SetTransform(lean * ctx.VG.GetTransform());
			}
			ctx.VG.DrawPositionedGlyphs(run.Glyphs, run.Font, mDrawOffset.X, mDrawOffset.Y, Tone(run.Color));
			if (run.SyntheticBold)
				ctx.VG.DrawPositionedGlyphs(run.Glyphs, run.Font, mDrawOffset.X + Max(0.5f, run.Size / 24.0f), mDrawOffset.Y,
					Tone(run.Color));
			if (slanted)
				ctx.VG.PopState();
		}
		for (let underline in layout.Underlines)
		{
			let r = underline.Rect;
			ctx.VG.FillRect(.(r.X + mDrawOffset.X, r.Y + mDrawOffset.Y, r.Width, r.Height), Tone(underline.Color));
		}
		let provider = (Context != null) ? Context.ResourceProvider : null;
		for (let icon in layout.Icons)
		{
			let run = mDocument.Runs[icon.Run];
			let image = (provider != null) ? provider.LoadImage(run.Icon) : null;
			if (image == null)
			{
				// Not loaded yet: ask again next frame.
				InvalidateVisual();
				continue;
			}
			let r = icon.Rect;
			ctx.VG.DrawImage(image, .(r.X + mDrawOffset.X, r.Y + mDrawOffset.Y, r.Width, r.Height));
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;
		let link = LinkAt(e.Position);
		if (link.IsEmpty)
			return;
		// A copy: the handler may change the text.
		let id = scope String(link);
		OnLink(this, id);
		e.Handled = true;
	}

	/// The document from the markup, parsed again only when it changed; problems logged once.
	private void SyncDocument()
	{
		let markup = StringView(Markup.Value);
		if (mRunsSet && (mParsedMarkup == markup))
			return;
		if (!mRunsSet && mParsed && (mParsedMarkup == markup))
			return;
		delete mDocument;
		mDocument = TextMarkup.Parse(markup);
		for (let diagnostic in mDocument.Diagnostics)
			GlobalLog(.Warning, "RichText markup at byte {}: {} (in \"{}\")", diagnostic.Offset, diagnostic.Message, markup);
		mParsedMarkup.Set(markup);
		mParsed = true;
		mRunsSet = false;
		mDocumentVersion++;
	}

	/// Lays out against the style and width, again only when either or the document changed.
	private TextLayout LayOut(IFontService service, float maxWidth, float alignWidth = -1.0f)
	{
		SyncDocument();
		let family = scope String();
		ResolveStyleFontFamily(family, FontFamily.Value);
		var style = TextLayoutStyle();
		style.Family = family;
		style.Size = FontSize.Value.HasValue ? FontSize.Value.Value : ResolveStyleFloat(.FontSize, 16.0f);
		style.Color = ResolvedTextColor;
		style.Align = HAlign.Value;
		style.Wrap = maxWidth > 0.0f;
		style.MaxWidth = (maxWidth > 0.0f) ? maxWidth : Max(0.0f, alignWidth);
		let color = style.Color;
		if ((mLayoutVersion == mDocumentVersion) && (mLayoutFamily == family) && (mLayoutSize == style.Size)
			&& (mLayoutColor.R == color.R) && (mLayoutColor.G == color.G) && (mLayoutColor.B == color.B)
			&& (mLayoutColor.A == color.A) && (mLayoutAlign == style.Align) && (mLayoutWrap == style.Wrap)
			&& (mLayoutWidth == style.MaxWidth) && (mLayoutService === service))
			return mLayout;
		delete mLayout;
		mLayout = TextLayouter.LayOut(mDocument, style, service);
		mLayoutVersion = mDocumentVersion;
		mLayoutFamily.Set(family);
		mLayoutSize = style.Size;
		mLayoutColor = color;
		mLayoutAlign = style.Align;
		mLayoutWrap = style.Wrap;
		mLayoutWidth = style.MaxWidth;
		mLayoutService = service;
		return mLayout;
	}
}
