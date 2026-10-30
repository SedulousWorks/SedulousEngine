using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Profiler.GUI;

/// What every profiler view shares: the focus it reads (joined while set), its colours from the
/// sheet's parts (each view's tag, Profiler.GUI's sheet giving them through the theme's tokens), a
/// name's colour (one of eight hues picked by the name, so a scope keeps its colour across frames and
/// lanes) and one text drawn in turn for its labels.
[GuiReflect]
abstract class ProfilerWidget : UIWidget, IProfileFocusClient
{
	/// A name's colours: this many hues, the sheet's `hue-0` to `hue-7` parts.
	public const uint32 cHueCount = 8;
	private static readonly String[cHueCount] cHueParts = .("hue-0", "hue-1", "hue-2", "hue-3", "hue-4", "hue-5", "hue-6", "hue-7");

	protected ProfileFocus mFocus = null;
	/// Each label in turn.
	protected Sedulous.GUI.Text mText = new .() ~ delete _;

	public ~this()
	{
		if (mFocus != null)
		{
			mFocus.Leave(this);
			mFocus.ReleaseRef();
		}
	}

	/// What it shows (shared: every view on one page holds the same focus). It takes a reference of
	/// its own: the caller keeps its.
	public ProfileFocus Focus
	{
		get => mFocus;
		set
		{
			if (value != null)
				value.AddRef();
			if (mFocus != null)
			{
				mFocus.Leave(this);
				mFocus.ReleaseRef();
			}
			mFocus = value;
			if (mFocus != null)
				mFocus.Join(this);
			OnProfileSourceChanged();
			Invalidate();
		}
	}

	public IProfileSource Source => (mFocus != null) ? mFocus.Source : null;

	/// The hue a name is drawn in (0 to cHueCount - 1): the same for its every scope.
	public static uint32 HueOf(StringView name)
	{
		uint32 hash = 0;
		for (let c in name.RawChars)
			hash = hash * 31 + (uint32)(uint8)c;
		return hash % cHueCount;
	}

	/// The parts every view draws: a name's hues. Each view adds its own; a part the sheet is to style
	/// must be named here, or the sheet never reaches it.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		for (let hue in cHueParts)
			outParts.Add(hue);
	}

	public virtual void OnProfileSourceChanged() { Invalidate(); }
	public virtual void OnProfileFramesChanged() { Invalidate(); }
	public virtual void OnProfileChoiceChanged() { Invalidate(); }

	/// A part's background colour (times its opacity), or `fallback` where the sheet gives none.
	protected Color PartColor(StringView part, Color fallback)
	{
		let style = GetPartStyle(part);
		var color = style.HasBackground ? style.Box.BackgroundColor : fallback;
		color.A *= style.Opacity;
		return color;
	}

	/// A part's text colour, or the view's own.
	protected Color PartTextColor(StringView part)
	{
		let style = GetPartStyle(part);
		return style.HasColor ? style.TextColor : TextColor;
	}

	/// A name's colour: its hue's part.
	protected Color NameColor(StringView name) => PartColor(cHueParts[HueOf(name)], .(0.55f, 0.65f, 0.80f, 1.0f));

	protected override void OnTextStyleChange()
	{
		mText.Font = Font;
		mText.SetFontSelection(FontService, GetTextStyle().FontFamily, GetTextStyle().Selection);
		mText.WhiteSpace = .NoWrap;
		mText.Overflow = .Ellipsis;
	}

	/// `text` in `bounds` (one line, cut with an ellipsis), placed by `align`, in `color`.
	protected void DrawLabel(DrawContext ctx, StringView text, Rect bounds, Color color, TextHAlign align = .Start)
	{
		if (!mText.HasFont || (bounds.Width < 4.0f) || text.IsEmpty)
			return;
		mText.SetString(text);
		mText.Color = color;
		mText.SetAlignment(align, .Middle);
		mText.Draw(ctx, bounds);
	}

	/// How wide `text` is, in the view's font.
	protected float LabelWidth(StringView text)
	{
		if (!mText.HasFont)
			return 0.0f;
		mText.SetString(text);
		return mText.Width;
	}

	/// A point of an event (screen space) in its own space.
	protected Float2 Local(Float2 screen) => ConvertToNodeSpace(screen);
}
