using System;
using System.Collections;

namespace Sedulous.GUI;

// StyleProperty + StyleRule: a CSS declaration block. Ported from eepp's
// css/StyleSheetProperty + StyleSheetStyle. A StyleRule pairs one StyleSelector with a list of
// name/value declarations: the value as written, and its longhands parsed into typed values
// once, by the first cascade that reaches it (a value with var() is parsed at each).
//
// Each owns text and lists, so each is a class, with a deep Set.

/// One longhand a declaration sets, with its value parsed (Kind None when it does not parse).
class StyleLonghandValue
{
	public String Name = new .() ~ delete _;
	public String Text = new .() ~ delete _;
	public StyleValue Value = new .() ~ delete _;

	public void Set(StyleLonghandValue other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		Text.Set(other.Text);
		Value.Set(other.Value);
	}
}

class StyleProperty
{
	public String Name = new .() ~ delete _;
	public String Value = new .() ~ delete _;
	public bool Important = false;
	// The longhands this declaration sets, parsed once (a declaration without var(): its value
	// cannot change); filled by the first cascade that reaches it (StyleSheet).
	public bool Cached = false;
	public bool CacheValid = false;
	public List<StyleLonghandValue> Longhands = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
	}

	public this(StringView name, StringView value, bool important = false)
	{
		Name.Set(name);
		Value.Set(value);
		Important = important;
	}

	public void Set(StyleProperty other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		Value.Set(other.Value);
		Important = other.Important;
		Cached = other.Cached;
		CacheValid = other.CacheValid;
		ClearAndDeleteItems!(Longhands);
		for (let l in other.Longhands)
		{
			let copy = new StyleLonghandValue();
			copy.Set(l);
			Longhands.Add(copy);
		}
	}
}

class StyleRule
{
	private StyleSelector mSelector ~ delete _;
	private List<StyleProperty> mProperties = new .() ~ DeleteContainerAndItems!(_);
	private MediaQuery mMedia = new .() ~ delete _;
	private String mSelectorText = new .() ~ delete _;
	private uint32 mLine = 0;

	public this()
	{
		mSelector = new .();
	}

	/// OWNERSHIP of `selector` transfers.
	public this(StyleSelector selector)
	{
		mSelector = selector;
	}

	public this(StringView selector)
	{
		mSelector = new .(selector);
	}

	public void Set(StyleRule other)
	{
		if (other === this)
			return;
		mSelector.Set(other.mSelector);
		ClearAndDeleteItems!(mProperties);
		for (let p in other.mProperties)
		{
			let copy = new StyleProperty();
			copy.Set(p);
			mProperties.Add(copy);
		}
		mMedia.Set(other.mMedia);
		mSelectorText.Set(other.mSelectorText);
		mLine = other.mLine;
	}

	public StyleSelector Selector => mSelector;
	public int64 Specificity => mSelector.Specificity;

	// Set (or override) a declaration.
	public void SetProperty(StringView name, StringView value, bool important = false)
	{
		for (let p in mProperties)
		{
			if (p.Name == name)
			{
				p.Value.Set(value);
				p.Important = important;
				p.Cached = false; // re-expanded and re-parsed on the next cascade
				p.CacheValid = false;
				ClearAndDeleteItems!(p.Longhands);
				return;
			}
		}
		mProperties.Add(new StyleProperty(name, value, important));
	}

	public Span<StyleProperty> Properties => mProperties;
	public int PropertyCount => mProperties.Count;

	/// Where it was written: its selector as written and its line in its sheet (0: not from a sheet).
	public void SetSource(StringView selectorText, uint32 line)
	{
		mSelectorText.Set(selectorText);
		mLine = line;
	}

	public StringView SelectorText => mSelectorText;
	public uint32 Line => mLine;

	// The @media condition this rule is nested in (empty = always active).
	public MediaQuery Media
	{
		get => mMedia;
		set => mMedia.Set(value);
	}
}
