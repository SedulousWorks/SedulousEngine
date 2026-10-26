using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Label: a UIWidget that displays text. It composes the Text primitive (drawn in the
// padding-inset content bounds) onto the widget base; modeled on eepp's UITextView (role, not a
// line-for-line port). Its text is shaped and laid out by TextLayout: it wraps as its white-space
// says, takes line-height and letter-spacing, ends an overflowing line as its text-overflow says
// and clamps its lines; a rich label's text is markup, its links events.

static
{
	/// CSS's text-overflow keyword for `overflow` ("clip", "ellipsis", "ellipsis-start", "ellipsis-middle").
	public static StringView TextOverflowName(TextOverflow overflow)
	{
		switch (overflow)
		{
		case .Ellipsis: return "ellipsis";
		case .EllipsisStart: return "ellipsis-start";
		case .EllipsisMiddle: return "ellipsis-middle";
		default: return "clip";
		}
	}

	/// The overflow a keyword names (clip for one it does not know).
	public static TextOverflow TextOverflowNamed(StringView name)
	{
		if (name == "ellipsis")
			return .Ellipsis;
		if (name == "ellipsis-start")
			return .EllipsisStart;
		if (name == "ellipsis-middle")
			return .EllipsisMiddle;
		return .Clip;
	}
}

[GuiReflect(true), Scriptable]
class Label : UIWidget
{
	protected Sedulous.GUI.Text mText = new .() ~ delete _;
	protected bool mRich = false;
	// The pointer is over one of its links.
	protected bool mOverLink = false;
	// The access key's bytes, underlined while access keys show.
	protected int mMnemonicStart = 0;
	protected int mMnemonicEnd = 0;
	// What bindings reading the text follow.
	protected Observable mTextChanged = new .() ~ delete _;
	// Its text as written (a field's label shows it without its `&`).
	private String mWritten = new .() ~ delete _;
	// The field it labels, by id.
	private String mFor = new .() ~ delete _;
	private char32 mMnemonic = '\0';

	public this()
	{
		Tag = "label";
		AccessRoleName = "label"; // what a screen reader takes it for
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			SetTextAlignment(.Start, .Middle);
		}
	}

	/// The bytes of its text an access key is: underlined while access keys show; start == end for
	/// none. Its button sets it, having taken the `&` out.
	public void SetMnemonicRange(int start, int end)
	{
		mMnemonicStart = start;
		mMnemonicEnd = end;
		if (end <= start)
			mText.SetUnderline(0, 0);
		Invalidate();
	}

	/// Its text: plain, or a rich text's markup when it is rich (Rich). Read, it is a read a
	/// binding records.
	[GuiProperty("", .Translatable, "name"), Scriptable]
	public StringView Text
	{
		get
		{
			mTextChanged.Track();
			return mText.GetString();
		}
		set
		{
			if (!mFor.IsEmpty && !mRich)
			{
				// A field's label (`for`): its `&` marks its access key, taken out of what shows.
				mWritten.Set(value);
				let mnemonic = scope Sedulous.GUI.Mnemonic();
				ParseMnemonic(value, mnemonic);
				mMnemonic = mnemonic.Key;
				SetMnemonicRange(mnemonic.Start, mnemonic.End);
				if (mnemonic.Shown == mText.GetString())
					return;
				mText.SetString(mnemonic.Shown);
				RequestLayout();
				Invalidate();
				mTextChanged.Notify();
				return;
			}
			mWritten.Set(value);
			if (value == mText.GetString())
				return;
			if (mRich)
				mText.SetMarkup(value);
			else
				mText.SetString(value);
			RequestLayout(); // its size follows its text
			Invalidate();
			mTextChanged.Notify();
		}
	}

	/// Its text's colour, as markup, bindings and tweens name it.
	[GuiProperty, Scriptable]
	public new Color TextColor
	{
		get => base.TextColor;
		set => base.TextColor = value;
	}

	/// A rich label's text is markup: runs in their own colours, sizes, faces and effects,
	/// underlines, inline icons and links (TextRuns), a click on a link reported as a `link` event
	/// with its id. Markup's `rich="true"`, or the RichText element.
	[GuiProperty, Scriptable]
	public bool Rich
	{
		get => mRich;
		set
		{
			if (value == mRich)
				return;
			mRich = value;
			let text = scope String(mText.GetString());
			if (value)
				mText.SetMarkup(text);
			else
				mText.SetString(text);
			RequestLayout();
			Invalidate();
		}
	}

	/// The field it labels, by id (HTML's `for`): its text's `&` marks an access key, and Alt with
	/// it (or the key alone in an open menu's scope) focuses that field. Empty: none, its text
	/// shown as written.
	public StringView For
	{
		get => mFor;
		set
		{
			if (value == mFor)
				return;
			mFor.Set(value);
			mMnemonic = '\0';
			SetMnemonicRange(0, 0);
			let written = scope String(mWritten);
			mText.SetString(""); // shown again from what was written
			Text = written;
		}
	}

	public override char32 Mnemonic => !mFor.IsEmpty ? mMnemonic : '\0';

	// Markup: <Label text="Hello" rich="true" for="name">.
	public override bool SetMarkupAttribute(StringView name, StringView value)
	{
		if (name == "text")
		{
			Text = value;
			return true;
		}
		if (name == "rich")
		{
			Rich = value == "true";
			return true;
		}
		if (name == "for")
		{
			For = value;
			return true;
		}
		return base.SetMarkupAttribute(name, value);
	}

	/// CSS's text-overflow: what shows where a line passes the label's width (clip, or an ellipsis
	/// at its end, start or middle). Not inherited.
	public Sedulous.GUI.TextOverflow TextOverflow
	{
		get => mText.Overflow;
		set
		{
			mText.Overflow = value;
			Invalidate();
		}
	}

	/// TextOverflow by its keyword (a sheet's `text-overflow`).
	[GuiProperty("text-overflow"), Scriptable]
	public StringView TextOverflowName
	{
		get => LabelDetail.OverflowName(TextOverflow);
		set => TextOverflow = TextOverflowNamed(ParseUtil.Trim(value));
	}

	/// CSS's line-clamp: the most lines it shows, the last ending in an ellipsis when its
	/// text-overflow has one (0: all). Not inherited.
	[GuiProperty("line-clamp"), Scriptable]
	public int32 LineClamp
	{
		get => (int32)mText.MaxLines;
		set
		{
			mText.MaxLines = (uint32)Math.Max(0, value);
			RequestLayout();
			Invalidate();
		}
	}

	/// The natural size of the text (for layout).
	public Float2 MeasureText() => mText.Measure();

	/// Its text's size: shaped, on one line, or wrapped to the width available where its
	/// white-space wraps (its longest word when no width is given), clamped to its lines.
	public override Float2 MeasureContent(Float2 available)
	{
		SyncServices();
		if ((mText.Font == null) || mText.IsEmpty)
			return .(0.0f, (mText.Font != null) ? mText.LineHeight : 0.0f);
		return mText.MeasureWrapped(available.X);
	}

	/// Its text's first baseline, where it draws it in the content box.
	public override float BaselineAt(Float2 size)
	{
		let c = Chrome;
		return mText.FirstBaseline(.(c.Left, c.Top, Math.Max(0.0f, size.X - c.TotalHorizontal), Math.Max(0.0f, size.Y - c.TotalVertical)));
	}

	/// The size wrapped text occupies at `maxWidth` (widest line x total height).
	public Float2 MeasureWrapped(float maxWidth) => mText.MeasureWrapped(maxWidth);

	/// What it lays out and draws (a method: the type is named Text).
	public Sedulous.GUI.Text GetTextLayout() => mText;

	// Its text draws in its text style (its own, a sheet's, or what it inherits).
	protected override void OnTextStyleChange()
	{
		let style = GetTextStyle();
		mText.Font = Font;
		mText.SetFontSelection(FontService, style.FontFamily, style.Selection);
		mText.Color = base.TextColor;
		mText.SetAlignment(TextAlignH, TextAlignV);
		mText.Direction = TextDirectionFor();
		mText.WhiteSpace = style.WhiteSpace;
		mText.SetLineHeight(style.LineHeightPixels);
		mText.LetterSpacing = style.LetterSpacing;
		mText.BreakWords = style.BreakWords;
	}

	/// Its box and, unless it clips it, its text where it is laid out (a line past the box).
	public override Rect InkBounds
	{
		get
		{
			let ink = base.InkBounds;
			if (ClipsChildren || !mText.HasFont || mText.IsEmpty)
				return ink;
			let bounds = ContentBounds;
			let layout = mText.LayoutFor(bounds);
			let origin = mText.Origin(bounds);
			return Rect.Union(ink, .(origin.X, origin.Y, Math.Max(layout.Width, bounds.Width), layout.Height));
		}
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		SyncServices();
		// An access key underlined while access keys show.
		if (mMnemonicEnd > mMnemonicStart)
		{
			let shown = AreMnemonicsShown;
			mText.SetUnderline(shown ? mMnemonicStart : 0, shown ? mMnemonicEnd : 0);
		}
		// Overflow other than visible clips its own text too, as CSS's does an element's content.
		let clip = ClipsChildren;
		if (clip)
			ctx.PushClip(LocalBounds);
		mText.Draw(ctx, ContentBounds); // aligned within the padding-inset bounds
		if (clip)
			ctx.PopClip();
	}

	// Over a rich text's link the pointer shows the hand, as a browser's does.
	public override Sedulous.GUI.Cursor CursorNow => mOverLink ? .Pointer : base.CursorNow;

	protected override void OnMouseMove(MouseEvent e)
	{
		mOverLink = mRich && (mText.LinkAt(ContentBounds, ConvertToNodeSpace(e.Position)).Length != 0);
	}

	protected override void OnMouseLeave(MouseEvent e)
	{
		mOverLink = false;
	}

	// A click on a rich text's link reports it.
	protected override void OnMouseClick(MouseEvent e)
	{
		if (!mRich)
			return;
		let link = mText.LinkAt(ContentBounds, ConvertToNodeSpace(e.Position));
		if (link.Length == 0)
			return;
		e.Handled = true;
		let id = scope String(link); // the event outlives no relayout
		SendEvent(scope LinkEvent(this, id));
	}

	// Its access key focuses the field it labels (a label is not a stop of its own).
	protected override bool OnActivate()
	{
		if (mFor.IsEmpty)
			return false;
		Node top = this;
		while (top.Parent != null)
			top = top.Parent;
		let field = FindLabelled(top);
		if ((field == null) || !field.IsTreeEnabled || !field.TabFocusable)
			return false;
		field.RequestFocus();
		return true;
	}

	// The widget under `node` whose id is the one it labels (not itself).
	private Node FindLabelled(Node node)
	{
		let w = node as UIWidget;
		if ((w != null) && (w != this) && (w.Id == mFor))
			return node;
		for (int i = 0; i < node.ChildCount; i++)
		{
			let found = FindLabelled(node.GetChildAt(i));
			if (found != null)
				return found;
		}
		return null;
	}

	// The GUI's fonts and resources, which a rich text's own faces and icons need.
	protected void SyncServices()
	{
		if (!mRich)
			return;
		mText.FontService = FontService;
		mText.SetResourceProvider(ResourceProvider);
	}
}

/// A label whose text is markup (Label with rich on), for markup's <RichText text="...">.
[GuiReflect(true), Scriptable]
class RichText : Label
{
	public this()
	{
		Tag = "richtext";
		Rich = true;
	}
}

/// What Label.bf keeps out of the public surface.
internal static class LabelDetail
{
	/// TextOverflowName, where a label's property of that name hides it.
	public static StringView OverflowName(TextOverflow overflow) => TextOverflowName(overflow);
}
