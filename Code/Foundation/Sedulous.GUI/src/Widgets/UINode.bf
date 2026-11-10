using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.GUI;

// UINode: a Node with UI chrome. Ported from eepp's UI::UINode - adds padding (a content inset)
// and the text style; its look is its box, which sheets set, its states the selectors'.
//
// What it keeps that C++ keeps by value (a text style, an inline declaration, a motion value, a
// styled property) owns text or lists, so each is a class with a deep Set.

/// One declaration of a node's inline style: markup's attributes the node does not claim, a
/// script's style. The cascade's highest origin.
class InlineStyleDeclaration
{
	public String Name = new .() ~ delete _;
	public String Value = new .() ~ delete _;

	public void Set(InlineStyleDeclaration other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		Value.Set(other.Value);
	}
}

/// One property a tween moves: the style pass composes it over the cascade, as CSS's animation
/// origin, from `From` (or the value underneath when it has none) toward `To`.
class MotionValue
{
	public String Property = new .() ~ delete _;
	public StyleValue From = new .() ~ delete _;
	public bool HasFrom = false;
	public StyleValue To = new .() ~ delete _;
	/// Eased: a curve that overshoots leaves [0, 1].
	public float Progress = 0.0f;
	/// What the last style pass showed.
	public StyleValue Shown = new .() ~ delete _;
	public bool HasShown = false;
	/// What it moved from there (From, or the value underneath).
	public StyleValue Under = new .() ~ delete _;
	public bool HasUnder = false;
	/// The tween writing it.
	public uint64 Owner = 0;

	/// Makes this a copy of `other`, its values included.
	public void Set(MotionValue other)
	{
		if (other === this)
			return;
		Property.Set(other.Property);
		From.Set(other.From);
		HasFrom = other.HasFrom;
		To.Set(other.To);
		Progress = other.Progress;
		Shown.Set(other.Shown);
		HasShown = other.HasShown;
		Under.Set(other.Under);
		HasUnder = other.HasUnder;
		Owner = other.Owner;
	}
}

[GuiReflect]
class UINode : Node
{
	// === Text style ===
	// Every node carries the text properties, so they inherit down the tree through nodes that
	// draw no text (a panel's colour reaches the labels in it): the colour, the font (family and
	// size, resolved to one cached font), and the alignment. A widget showing text reads them, told
	// by OnTextStyleChange; from code they are the code's (pinned), and the subtree restyles, as
	// what it inherits changed.

	/// The text properties a node carries. A class: it owns its family's name and its selection.
	public class TextStyle
	{
		public Color TextColor = .White;
		/// Borrowed.
		public CachedFont Font = null;
		/// The font's family as CSS names it (empty: unknown).
		public String FontFamily = new .() ~ delete _;
		/// Its font-family list's rest, its font-weight and its font-style.
		public FontSelection Selection = new .() ~ delete _;
		/// In pixels (0: unknown).
		public float FontSize = 0.0f;
		public TextHAlign HAlign = .Start;
		public TextVAlign VAlign = .Top;
		/// A node's own: one line (CSS's initial is normal).
		public TextWhiteSpace WhiteSpace = .NoWrap;
		/// Pixels, or a multiple of the font size when LineHeightFactor; 0: normal.
		public float LineHeight = 0.0f;
		/// A unitless line-height, which each node applies to its own font size.
		public bool LineHeightFactor = false;
		/// Pixels.
		public float LetterSpacing = 0.0f;
		/// overflow-wrap: break-word or anywhere.
		public bool BreakWords = false;

		/// Makes this a copy of `other`.
		public void Set(TextStyle other)
		{
			if (other === this)
				return;
			TextColor = other.TextColor;
			Font = other.Font;
			FontFamily.Set(other.FontFamily);
			Selection.Set(other.Selection);
			FontSize = other.FontSize;
			HAlign = other.HAlign;
			VAlign = other.VAlign;
			WhiteSpace = other.WhiteSpace;
			LineHeight = other.LineHeight;
			LineHeightFactor = other.LineHeightFactor;
			LetterSpacing = other.LetterSpacing;
			BreakWords = other.BreakWords;
		}

		public bool Equals(TextStyle o) =>
			(TextColor == o.TextColor) && (Font == o.Font) && (FontFamily == o.FontFamily) &&
			Selection.Equals(o.Selection) && (FontSize == o.FontSize) &&
			(HAlign == o.HAlign) && (VAlign == o.VAlign) && (WhiteSpace == o.WhiteSpace) && (LineHeight == o.LineHeight) &&
			(LineHeightFactor == o.LineHeightFactor) && (LetterSpacing == o.LetterSpacing) &&
			(BreakWords == o.BreakWords);

		/// The line height in pixels (0: the font's own).
		public float LineHeightPixels => LineHeightFactor ? LineHeight * FontSize : LineHeight;
	}

	/// A reflected property a sheet set by its CSS name: the node's own value from before, the
	/// value the sheet last wrote (as text; empty when it writes none now), and whether code has
	/// since taken it.
	public class StyledProperty
	{
		public String Name = new .() ~ delete _;
		public System.Variant Own ~ _.Dispose();
		public String Written = new .() ~ delete _;
		public bool Code = false;
	}

	private class NamedPartStyle
	{
		public String Name = new .() ~ delete _;
		public PartStyle Style = new .() ~ delete _;
	}

	private TextStyle mTextStyle = new .() ~ delete _;
	// The direction its text was last told.
	private ParagraphDirection mTextDirection = .();
	private TextStyle mUnstyledText = new .() ~ delete _;
	private bool mUnstyledTextCaptured = false;
	private List<InlineStyleDeclaration> mInlineStyle = new .() ~ DeleteContainerAndItems!(_);
	// What tweens move, over the cascade.
	private List<MotionValue> mMotion = new .() ~ DeleteContainerAndItems!(_);
	private List<StyledProperty> mStyledProperties = new .() ~ DeleteContainerAndItems!(_);
	private List<NamedPartStyle> mPartStyles = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
	}

	public Color TextColor
	{
		get => mTextStyle.TextColor;
		set
		{
			PinStyle(SlotBit(.SlotColor));
			let style = scope TextStyle();
			style.Set(mTextStyle);
			style.TextColor = value;
			ChangeTextStyle(style);
		}
	}

	/// The cached font its text draws in (borrowed); setting it takes the font's family and size.
	public CachedFont Font
	{
		get => mTextStyle.Font;
		set
		{
			PinStyle(SlotBit(.SlotFontFamily) | SlotBit(.SlotFontSize));
			let style = scope TextStyle();
			style.Set(mTextStyle);
			style.Font = value;
			style.FontFamily.Clear();
			if ((value != null) && (value.Font != null))
				value.Font.GetFamilyName(style.FontFamily);
			style.Selection.FallbackFamilies.Clear();
			style.FontSize = ((value != null) && (value.Font != null)) ? value.Font.PixelHeight : 0.0f;
			ChangeTextStyle(style);
		}
	}

	public void SetTextAlignment(TextHAlign horizontal, TextVAlign vertical)
	{
		PinStyle(SlotBit(.SlotTextAlign) | SlotBit(.SlotVerticalAlign));
		let style = scope TextStyle();
		style.Set(mTextStyle);
		style.HAlign = horizontal;
		style.VAlign = vertical;
		ChangeTextStyle(style);
	}

	/// CSS's white-space (inherited): whether spaces collapse and lines wrap.
	public TextWhiteSpace WhiteSpace
	{
		get => mTextStyle.WhiteSpace;
		set
		{
			PinStyle(SlotBit(.SlotWhiteSpace));
			let style = scope TextStyle();
			style.Set(mTextStyle);
			style.WhiteSpace = value;
			ChangeTextStyle(style);
		}
	}

	/// CSS's line-height (inherited): pixels, or with `factor` a multiple of the font size; 0: normal.
	public void SetLineHeight(float value, bool factor = false)
	{
		PinStyle(SlotBit(.SlotLineHeight));
		let style = scope TextStyle();
		style.Set(mTextStyle);
		style.LineHeight = Math.Max(0.0f, value);
		style.LineHeightFactor = factor;
		ChangeTextStyle(style);
	}

	/// CSS's letter-spacing (inherited), in pixels.
	public void SetLetterSpacing(float pixels)
	{
		PinStyle(SlotBit(.SlotLetterSpacing));
		let style = scope TextStyle();
		style.Set(mTextStyle);
		style.LetterSpacing = pixels;
		ChangeTextStyle(style);
	}

	/// CSS's overflow-wrap (inherited): a word wider than its line breaks inside it.
	public void SetBreakWords(bool breakWords)
	{
		PinStyle(SlotBit(.SlotOverflowWrap));
		let style = scope TextStyle();
		style.Set(mTextStyle);
		style.BreakWords = breakWords;
		ChangeTextStyle(style);
	}

	/// CSS's font-weight (inherited), 100 to 900: the face of the nearest weight the family has.
	public void SetFontWeight(uint16 weight)
	{
		PinStyle(SlotBit(.SlotFontWeight));
		let style = scope TextStyle();
		style.Set(mTextStyle);
		style.Selection.Weight = Math.Clamp(weight, (uint16)1, (uint16)1000);
		ChangeTextStyle(style);
	}

	/// CSS's font-style (inherited): italic takes the family's italic face, or slants.
	public void SetFontItalic(bool italic)
	{
		PinStyle(SlotBit(.SlotFontStyle));
		let style = scope TextStyle();
		style.Set(mTextStyle);
		style.Selection.Italic = italic;
		ChangeTextStyle(style);
	}

	/// The whole text style (a method: the type is named TextStyle).
	public TextStyle GetTextStyle() => mTextStyle;
	public TextHAlign TextAlignH => mTextStyle.HAlign;
	public TextVAlign TextAlignV => mTextStyle.VAlign;

	/// Which way its text's paragraphs run: as it does, or each as it reads (auto).
	public ParagraphDirection TextDirectionFor()
	{
		let rightToLeft = IsRightToLeft;
		if (IsDirectionAuto)
			return .(.Auto, rightToLeft);
		return .(rightToLeft ? .RightToLeft : .LeftToRight, false);
	}

	/// The whole text style as a sheet computed it (no pins; inside a StyleWriteScope).
	public void ApplyTextStyle(TextStyle style)
	{
		ChangeTextStyle(style);
	}

	/// Its own text style, captured when a sheet first styles it (what no rule and no parent gives).
	public TextStyle CaptureUnstyledText()
	{
		if (!mUnstyledTextCaptured)
		{
			mUnstyledTextCaptured = true;
			mUnstyledText.Set(mTextStyle);
		}
		return mUnstyledText;
	}

	/// Gives `child` this node's font and colour as its own (no pin): a composite widget's parts,
	/// kept in step where no sheet runs; a sheet's inheritance gives them the same.
	public void ShareTextStyle(UINode child, bool color = true)
	{
		using (StyleWriteScope(child))
		{
			let style = scope TextStyle();
			style.Set(child.mTextStyle);
			style.Font = mTextStyle.Font;
			style.FontFamily.Set(mTextStyle.FontFamily);
			style.Selection.Set(mTextStyle.Selection);
			style.FontSize = mTextStyle.FontSize;
			if (color)
				style.TextColor = mTextStyle.TextColor;
			child.ChangeTextStyle(style);
		}
	}

	// === Inline style ===

	/// Sets `name: value` in this node's inline style (replacing one of that name): it wins over
	/// every sheet's normal declarations, at the next restyle.
	public void SetInlineStyle(StringView name, StringView value)
	{
		for (let d in mInlineStyle)
		{
			if (d.Name == name)
			{
				if (d.Value == value)
					return;
				d.Value.Set(value);
				MarkStyleDirty(false);
				return;
			}
		}
		let declaration = new InlineStyleDeclaration();
		declaration.Name.Set(name);
		declaration.Value.Set(value);
		mInlineStyle.Add(declaration);
		MarkStyleDirty(false);
	}

	public void RemoveInlineStyle(StringView name)
	{
		for (int i = 0; i < mInlineStyle.Count; i++)
		{
			if (mInlineStyle[i].Name == name)
			{
				delete mInlineStyle[i];
				mInlineStyle.RemoveAt(i);
				MarkStyleDirty(false);
				return;
			}
		}
	}

	public Span<InlineStyleDeclaration> InlineStyle => mInlineStyle;

	// === The animated layer ===

	/// What tweens move on it, over its cascade. A change marks it for the style pass to apply
	/// again (MarkStyleMotionDirty), not to resolve anew.
	public Span<MotionValue> MotionValues => mMotion;
	public bool HasMotion => !mMotion.IsEmpty;

	public MotionValue FindMotion(StringView property)
	{
		for (let m in mMotion)
		{
			if (m.Property == property)
				return m;
		}
		return null;
	}

	/// Sets the layer's value for its property (replacing the one there): a copy of `value`, which
	/// the caller keeps; the one stored comes back.
	public MotionValue SetMotion(MotionValue value)
	{
		MarkStyleMotionDirty();
		let m = FindMotion(value.Property);
		if (m != null)
		{
			m.Set(value);
			return m;
		}
		let stored = new MotionValue();
		stored.Set(value);
		mMotion.Add(stored);
		return stored;
	}

	/// Gives `property` back to the cascade; false when nothing moved it.
	public bool RemoveMotion(StringView property)
	{
		for (int i = 0; i < mMotion.Count; i++)
		{
			if (mMotion[i].Property == property)
			{
				delete mMotion[i];
				mMotion.RemoveAt(i);
				MarkStyleMotionDirty();
				return true;
			}
		}
		return false;
	}

	/// The reflected properties a sheet set (the list is the node's; its entries too).
	public List<StyledProperty> StyledProperties => mStyledProperties;

	// Markup hook: a widget consumes its own structural XML attributes (e.g. a number field's
	// "prefix" and "suffix", a table item's "cells"), returning true if it handled `name`.
	// Attributes it doesn't claim are applied as CSS properties by the markup loader. Default: none.
	public virtual bool SetMarkupAttribute(StringView name, StringView value)
	{
		return false;
	}

	/// Markup hook: a `<template type="...">` child's markup (its first element, as text), which a
	/// widget that makes nodes from it (an item view's rows) keeps; false when it takes none, and
	/// the loader drops it.
	public virtual bool SetMarkupTemplate(StringView type, StringView markup) => false;

	// Pseudo-element parts: a widget names the parts it paints (slider "track"/"fill"/"thumb",
	// checkbox "box"/"mark", window "title"/"grip", ...) so CSS `tag::part` can style them with the
	// box properties and opacity. CollectStyleParts lists them; the sheet sets each one's
	// PartStyle; the widget draws a part through GetPartStyle(part).
	public virtual void CollectStyleParts(List<StringView> outParts)
	{
	}

	/// Sets `part`'s style to a copy of `style` (the caller keeps it).
	public void SetPartStyle(StringView part, PartStyle style)
	{
		for (let p in mPartStyles)
		{
			if (p.Name == part)
			{
				p.Style.Set(style);
				OnPartStyleChange(part);
				Invalidate();
				return;
			}
		}
		let named = new NamedPartStyle();
		named.Name.Set(part);
		named.Style.Set(style);
		mPartStyles.Add(named);
		OnPartStyleChange(part);
		Invalidate();
	}

	/// A part's style as the sheet set it: its GetPartStyle (an empty one when the sheet styles it
	/// not).
	public override PartStyle FindPartStyle(StringView part) => GetPartStyle(part);

	/// A modal popup's dim: its `::backdrop` part over the default one.
	public override void DrawBackdrop(DrawContext ctx, Rect bounds)
	{
		GetPartStyle("backdrop").Draw(ctx, bounds, FilledBox(.(0.0f, 0.0f, 0.0f, 0.45f), scope NodeBox()));
	}

	/// The way it runs may have changed: what shows text takes it in OnTextStyleChange.
	public override void OnDirectionChange()
	{
		let direction = TextDirectionFor();
		if (direction == mTextDirection)
			return; // it runs as it did: joining a tree that runs the same way costs nothing
		mTextDirection = direction;
		OnTextStyleChange();
		RequestLayout();
		Invalidate();
	}

	/// The text style changed: a widget showing text refreshes what it draws with.
	protected virtual void OnTextStyleChange()
	{
	}

	/// A part's style changed: a widget whose part is a node of its own passes it on.
	protected virtual void OnPartStyleChange(StringView part)
	{
	}

	private void ChangeTextStyle(TextStyle style)
	{
		if (style.Equals(mTextStyle))
			return;
		mTextStyle.Set(style);
		if (!IsStyleWriting)
			MarkStyleDirty(true); // what the subtree inherits changed
		OnTextStyleChange();
		RequestLayout();
		Invalidate();
	}
}
