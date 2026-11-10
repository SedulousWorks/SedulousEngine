using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// ResolvedStyle + StyleSheet: the cascade. Ported from eepp's css/StyleSheet(::getElement
// Styles). A StyleSheet is an ordered list of StyleRules; Resolve(element) gathers the rules that
// match, orders them by (specificity, source order), and applies their declarations so higher-
// specificity and later-source rules win, producing a flat name/value ResolvedStyle.
//
// What C++ keeps by value here owns text or lists, so each is a class, with a deep Set; what
// is resolved is written into a style the caller owns.

/// One property of a resolved style: its text (var() substituted) and its typed value.
class ResolvedProperty
{
	public String Name = new .() ~ delete _;
	public String Value = new .() ~ delete _;
	/// Kind None: not a property the table parses, or its text did not parse.
	public StyleValue Typed = new .() ~ delete _;
	public bool Important = false;

	public void Set(ResolvedProperty other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		Value.Set(other.Value);
		Typed.Set(other.Typed);
		Important = other.Important;
	}
}

/// The custom properties an element sees (they inherit). One set is shared, unchanged, by an
/// element and every element below it that sets none of its own, so a sheet's hundreds of tokens
/// on :root are not copied into every element; an element that sets some gets a set of its own
/// (its parent's with its own over them). Kept by name hash, so a var() finds its property
/// without walking the list. A style holds a reference (ReleaseRef, never delete).
class CustomProperties : RefCounted
{
	private struct Entry
	{
		public uint64 Hash;
		public ResolvedProperty Property;

		public this(uint64 hash, ResolvedProperty property)
		{
			Hash = hash;
			Property = property;
		}
	}

	private List<Entry> mEntries = new .() ~ DeleteEntries(_); // by hash

	public this()
	{
	}

	/// A copy of `from`, its own properties (what a write to a shared set starts from).
	public this(CustomProperties from)
	{
		mEntries.Reserve(from.mEntries.Count);
		for (let e in from.mEntries)
		{
			let copy = new ResolvedProperty();
			copy.Set(e.Property);
			mEntries.Add(.(e.Hash, copy));
		}
	}

	/// `name`'s property, or null. Borrowed.
	public ResolvedProperty Find(StringView name)
	{
		let hash = HashText(name);
		for (int i = LowerBound(hash); (i < mEntries.Count) && (mEntries[i].Hash == hash); i++)
		{
			if (mEntries[i].Property.Name == name)
				return mEntries[i].Property;
		}
		return null;
	}

	/// Sets `name` (an !important value resists a later normal one). Internal: a set handed out
	/// may be shared, so only its style writes it, copying first.
	internal void Put(StringView name, StringView value, bool important)
	{
		let hash = HashText(name);
		let at = LowerBound(hash);
		for (int k = at; (k < mEntries.Count) && (mEntries[k].Hash == hash); k++)
		{
			let p = mEntries[k].Property;
			if (p.Name != name)
				continue;
			if (p.Important && !important)
				return;
			p.Value.Set(value);
			p.Important = important;
			return;
		}
		let added = new ResolvedProperty();
		added.Name.Set(name);
		added.Value.Set(value);
		added.Important = important;
		mEntries.Insert(at, Entry(hash, added));
	}

	/// Removes `name`. Internal, as Put is.
	internal void Remove(StringView name)
	{
		let hash = HashText(name);
		for (int i = LowerBound(hash); (i < mEntries.Count) && (mEntries[i].Hash == hash); i++)
		{
			if (mEntries[i].Property.Name == name)
			{
				delete mEntries[i].Property;
				mEntries.RemoveAt(i);
				return;
			}
		}
	}

	public int Count => mEntries.Count;

	/// The property at `index` (in hash order). Borrowed.
	public ResolvedProperty this[int index] => mEntries[index].Property;

	/// The same names with the same values.
	public bool SameAs(CustomProperties other)
	{
		if (mEntries.Count != other.mEntries.Count)
			return false;
		for (int i = 0; i < mEntries.Count; i++)
		{
			let a = mEntries[i];
			let b = other.mEntries[i];
			if ((a.Hash != b.Hash) || (a.Property.Name != b.Property.Name) || (a.Property.Value != b.Property.Value))
				return false;
		}
		return true;
	}

	private int LowerBound(uint64 hash)
	{
		int lo = 0;
		int hi = mEntries.Count;
		while (lo < hi)
		{
			let mid = lo + (hi - lo) / 2;
			if (mEntries[mid].Hash < hash)
				lo = mid + 1;
			else
				hi = mid;
		}
		return lo;
	}

	private static void DeleteEntries(List<Entry> entries)
	{
		for (let e in entries)
			delete e.Property;
		delete entries;
	}
}

/// The cascaded properties of one element: longhands, var() substituted and parsed.
class ResolvedStyle
{
	/// Where currentColor reads the nearest declared `color` (a custom property: it inherits).
	public const String cCurrentColorProperty = "--gui-current-color";

	// What a value that did not parse (or was not parsed) is set from.
	private static StyleValue sNoValue = new .() ~ delete _;

	private List<ResolvedProperty> mProps = new .() ~ DeleteContainerAndItems!(_); // but the custom ones
	private CustomProperties mCustoms = null ~ _?.ReleaseRef(); // shared down the tree (copy on write)
	private ResolvedProperty mCurrentColor = new .() ~ delete _; // currentColor's colour, which inherits
	private bool mHasCurrentColor = false;
	private bool mFinalized = true; // an empty style is settled

	public void Set(ResolvedStyle other)
	{
		if (other === this)
			return;
		ClearAndDeleteItems!(mProps);
		for (let p in other.mProps)
		{
			let copy = new ResolvedProperty();
			copy.Set(p);
			mProps.Add(copy);
		}
		ShareCustoms(other.mCustoms); // shared, as the C++ copy shares its pointer
		mCurrentColor.Set(other.mCurrentColor);
		mHasCurrentColor = other.mHasCurrentColor;
		mFinalized = other.mFinalized;
	}

	/// Empties it: no properties, and settled.
	public void Clear()
	{
		ClearAndDeleteItems!(mProps);
		ShareCustoms(null);
		mHasCurrentColor = false;
		mFinalized = true;
	}

	/// Sets (or overrides) `name` as written; a shorthand or a var() is settled by Finalize. An
	/// !important value resists later normal ones.
	public void Set(StringView name, StringView value, bool important = false)
	{
		Put(name, value, null, important);
		mFinalized = false;
	}

	/// Sets a longhand already settled (its text substituted and its value parsed; null: none).
	public void SetParsed(StringView name, StringView value, StyleValue typed, bool important)
	{
		Put(name, value, typed, important);
	}

	/// Puts `typed` in place of `name`'s value, whatever its importance: a transition's or an
	/// animation's value over the cascade's.
	public void Override(StringView name, StyleValue typed)
	{
		for (let p in mProps)
		{
			if (p.Name == name)
			{
				p.Typed.Set(typed);
				return;
			}
		}
		let added = new ResolvedProperty();
		added.Name.Set(name);
		added.Typed.Set(typed);
		mProps.Add(added);
	}

	public bool Has(StringView name) => Find(name) != null;

	public void Remove(StringView name)
	{
		if (IsCustomProperty(name))
		{
			if (name == cCurrentColorProperty)
				mHasCurrentColor = false;
			else if ((mCustoms != null) && (mCustoms.Find(name) != null))
				OwnCustoms().Remove(name);
			return;
		}
		for (int i = 0; i < mProps.Count; i++)
		{
			if (mProps[i].Name == name)
			{
				delete mProps[i];
				mProps.RemoveAt(i);
				return;
			}
		}
	}

	/// Settles the CSS-wide keywords. `inherit` takes `parent`'s value (an inherited property:
	/// what it inherits anyway); `initial` the table's initial value, or the node's own when the
	/// table gives none (kept as `initial` for an inherited property, which then stops
	/// inheriting); `unset` is `inherit` for an inherited property, `initial` otherwise.
	public void SettleKeywords(ResolvedStyle parent)
	{
		for (int i = 0; i < mProps.Count;)
		{
			let p = mProps[i];
			let v = ParseUtil.Trim(p.Value);
			let inherit = v == "inherit";
			let initial = v == "initial";
			let unset = v == "unset";
			if (!inherit && !initial && !unset)
			{
				i++;
				continue;
			}
			let spec = FindStyleProperty(p.Name);
			let inherited = (spec != null) && spec.Inherited;
			if ((inherit || unset) && inherited)
			{
				RemoveAt(i); // as if unset: it inherits
				continue;
			}
			if (inherit)
			{
				let from = (parent != null) ? parent.Find(p.Name) : null;
				if (from == null)
				{
					RemoveAt(i);
					continue;
				}
				p.Value.Set(from.Value);
				p.Typed.Set(from.Typed);
				i++;
				continue;
			}
			// initial, or unset on a property that does not inherit.
			if ((spec != null) && (spec.Initial != null))
			{
				p.Value.Set(spec.Initial);
				ParseLonghand(p.Name, p.Value, p.Typed);
				i++;
			}
			else if (inherited)
			{
				p.Value.Set("initial");
				p.Typed.Set(sNoValue);
				i++;
			}
			else
				RemoveAt(i); // the node's own
		}
	}

	/// The text of `name`, or empty.
	public StringView Get(StringView name) => Get(name, default(StringView));

	/// The text of `name`, or `fallback`.
	public StringView Get(StringView name, StringView fallback)
	{
		let p = Find(name);
		return (p != null) ? (StringView)p.Value : fallback;
	}

	/// The typed value of `name`, or null when it is unset or did not parse. Borrowed.
	public StyleValue Value(StringView name)
	{
		let p = Find(name);
		return ((p != null) && (p.Typed.Kind != .None)) ? p.Typed : null;
	}

	/// Every property it holds, its custom properties counted.
	public int Count => mProps.Count + ((mCustoms != null) ? mCustoms.Count : 0) + (mHasCurrentColor ? 1 : 0);
	/// Its properties but the custom ones (Customs has those).
	public Span<ResolvedProperty> Properties => mProps;
	/// Its custom properties (shared with the elements that set none of their own), or null.
	/// Borrowed, and read only: a write goes through the style, which copies a shared set first.
	public CustomProperties Customs => mCustoms;

	/// The same custom properties as `other` (the same set shared: at once), and the same colour
	/// for currentColor: what an element's children inherit from it.
	public static bool SameCustomProperties(ResolvedStyle a, ResolvedStyle b)
	{
		if ((a.mHasCurrentColor != b.mHasCurrentColor) || (a.mHasCurrentColor && (a.mCurrentColor.Value != b.mCurrentColor.Value)))
			return false;
		if (a.mCustoms === b.mCustoms)
			return true;
		let sa = (a.mCustoms != null) ? a.mCustoms.Count : 0;
		let sb = (b.mCustoms != null) ? b.mCustoms.Count : 0;
		if (sa != sb)
			return false;
		return (sa == 0) || a.mCustoms.SameAs(b.mCustoms);
	}

	public bool IsFinalized => mFinalized;

	/// Settles what Set left as written: substitutes var() anywhere in a value (its own custom
	/// properties first, then `inherited`'s), expands shorthands into longhands in order, and
	/// parses each longhand's value. Declarations whose var() cannot resolve are dropped.
	public void Finalize(ResolvedStyle inherited = null)
	{
		let written = mProps;
		mProps = new .();
		defer { DeleteContainerAndItems!(written); }
		for (let p in written)
		{
			if (IsCustomProperty(p.Name))
				Put(p.Name, p.Value, null, p.Important);
		}
		// currentColor: the nearest `color` declared here or above, kept as a custom property
		// (which inherits) so every element finds it.
		for (let p in written)
		{
			if (p.Name == "color")
				SetCurrentColor(p.Value, inherited);
		}
		let text = scope String();
		for (let p in written)
		{
			if (IsCustomProperty(p.Name))
				continue;
			if (ResolveText(p.Name, p.Value, inherited, text))
				SetDeclaration(p.Name, text, p.Important);
		}
		mFinalized = true;
	}

	/// Expands `name: text` (var() already substituted) into its longhands, parsed, and sets them.
	public void SetDeclaration(StringView name, StringView text, bool important)
	{
		let longhands = scope List<StyleLonghand>();
		defer { ClearAndDeleteItems!(longhands); }
		if (!ExpandStyleShorthand(name, text, longhands))
			return;
		let value = scope StyleValue();
		for (let longhand in longhands)
		{
			ParseLonghand(longhand.Name, longhand.Text, value);
			SetParsed(longhand.Name, longhand.Text, value, important);
		}
	}

	/// A longhand's text parsed by the table's grammar for it, into `outValue` (Kind None when
	/// the table does not name it, or it does not parse).
	public static void ParseLonghand(StringView name, StringView text, StyleValue outValue)
	{
		outValue.Set(sNoValue);
		let spec = FindStyleProperty(name);
		if ((spec != null) && !ParseStyleValue(spec.Grammar, text, outValue))
			outValue.Set(sNoValue);
	}

	/// var() in `value` substituted from this style's custom properties, then `inherited`'s, into
	/// `outText` (cleared first).
	public bool Substitute(StringView value, ResolvedStyle inherited, String outText)
	{
		bool hasVar = false;
		for (int i = 0; (i + 3 < value.Length) && !hasVar; i++)
			hasVar = value.Substring(i, 4) == "var(";
		if (!hasVar)
		{
			outText.Set(value);
			return true;
		}
		return SubstituteVariables(value, scope [&] (name, outValue) =>
			{
				if (let own = Find(name))
				{
					outValue.Append(own.Value);
					return true;
				}
				if (inherited != null)
				{
					if (let parent = inherited.Find(name))
					{
						outValue.Append(parent.Value);
						return true;
					}
				}
				return false;
			}, outText);
	}

	/// A declaration's text as it applies here, into `outText` (cleared first): var()
	/// substituted, then currentColor (the nearest declared colour; for `color` itself, the
	/// parent's). False when either cannot.
	public bool ResolveText(StringView name, StringView value, ResolvedStyle inherited, String outText)
	{
		let text = scope String();
		if (!Substitute(value, inherited, text))
			return false;
		if (!HasCurrentColor(text))
		{
			outText.Set(text);
			return true;
		}
		return ReplaceCurrentColor(text, (name == "color") ? inherited : this, outText);
	}

	/// Records the colour currentColor reads here: `colorText` (the winning `color`), resolved;
	/// none declared: the parent's stays.
	public void SetCurrentColor(StringView colorText, ResolvedStyle inherited)
	{
		let resolved = scope String();
		if (ResolveText("color", colorText, inherited, resolved))
			PutCurrentColor(resolved, null, false);
	}

	public static bool HasCurrentColor(StringView value)
	{
		let ignored = scope String();
		return !ReplaceCurrentColor(value, null, ignored);
	}

	/// `value` with each currentColor (in any case) replaced by `from`'s nearest declared colour,
	/// into `outText` (cleared first); false when it has one and no colour was declared.
	public static bool ReplaceCurrentColor(StringView value, ResolvedStyle from, String outText)
	{
		StringView word = "currentcolor";
		bool At(int i)
		{
			if (i + word.Length > value.Length)
				return false;
			for (int k = 0; k < word.Length; k++)
			{
				var c = value[i + k];
				if ((c >= 'A') && (c <= 'Z'))
					c = (char8)((int32)c - (int32)'A' + (int32)'a');
				if (c != word[k])
					return false;
			}
			return true;
		}
		outText.Clear();
		for (int i = 0; i < value.Length;)
		{
			if (At(i))
			{
				let color = (from != null) ? from.Find(cCurrentColorProperty) : null;
				if (color == null)
					return false;
				outText.Append(color.Value);
				i += word.Length;
				continue;
			}
			outText.Append(value[i++]);
		}
		return true;
	}

	/// This style's custom properties and `parent`'s it does not set (custom properties inherit):
	/// sharing its set when it sets none of its own; else adding the parent's it does not set.
	public void InheritCustomProperties(ResolvedStyle parent)
	{
		if (!mHasCurrentColor && parent.mHasCurrentColor)
		{
			mCurrentColor.Set(parent.mCurrentColor);
			mHasCurrentColor = true;
		}
		if ((parent.mCustoms == null) || (parent.mCustoms.Count == 0))
			return;
		if ((mCustoms == null) || (mCustoms.Count == 0))
		{
			ShareCustoms(parent.mCustoms); // shared: nothing of its own
			return;
		}
		let own = OwnCustoms();
		let from = parent.mCustoms;
		for (int i = 0; i < from.Count; i++)
		{
			let p = from[i];
			if (own.Find(p.Name) == null)
				own.Put(p.Name, p.Value, p.Important);
		}
	}

	public static bool IsCustomProperty(StringView name) => (name.Length >= 2) && (name[0] == '-') && (name[1] == '-');

	private ResolvedProperty Find(StringView name)
	{
		if (IsCustomProperty(name))
		{
			if (name == cCurrentColorProperty)
				return mHasCurrentColor ? mCurrentColor : null;
			return (mCustoms != null) ? mCustoms.Find(name) : null;
		}
		for (let p in mProps)
		{
			if (p.Name == name)
				return p;
		}
		return null;
	}

	private void RemoveAt(int i)
	{
		delete mProps[i];
		mProps.RemoveAt(i);
	}

	// Its own set to change: made, or copied when shared (copy on write).
	private CustomProperties OwnCustoms()
	{
		if (mCustoms == null)
			mCustoms = new .();
		else if (mCustoms.RefCount > 1)
		{
			let copy = new CustomProperties(mCustoms);
			mCustoms.ReleaseRef(); // still held by whoever shares it
			mCustoms = copy;
		}
		return mCustoms;
	}

	// Holds `customs` (null: none) in place of its own set, the reference counted.
	private void ShareCustoms(CustomProperties customs)
	{
		if (customs === mCustoms)
			return;
		customs?.AddRef();
		mCustoms?.ReleaseRef();
		mCustoms = customs;
	}

	// currentColor's colour, copied into the property Find hands out (a borrowed one stays alive).
	private void PutCurrentColor(StringView value, StyleValue typed, bool important)
	{
		mCurrentColor.Name.Set(cCurrentColorProperty);
		mCurrentColor.Value.Set(value);
		mCurrentColor.Typed.Set(typed ?? sNoValue);
		mCurrentColor.Important = important;
		mHasCurrentColor = true;
	}

	private void Put(StringView name, StringView value, StyleValue typed, bool important)
	{
		if (IsCustomProperty(name))
		{
			if (name == cCurrentColorProperty)
				PutCurrentColor(value, typed, important);
			else
				OwnCustoms().Put(name, value, important);
			return;
		}
		for (let p in mProps)
		{
			if (p.Name != name)
				continue;
			if (p.Important && !important)
				return; // important wins over normal
			p.Value.Set(value);
			p.Typed.Set(typed ?? sNoValue);
			p.Important = important;
			return;
		}
		let added = new ResolvedProperty();
		added.Name.Set(name);
		added.Value.Set(value);
		added.Typed.Set(typed ?? sNoValue);
		added.Important = important;
		mProps.Add(added);
	}
}

// One @keyframes stop: an offset in [0,1] (0% .. 100%, from/to) + its declarations.
class KeyframeStop
{
	public float Offset = 0.0f;
	public List<StyleProperty> Properties = new .() ~ DeleteContainerAndItems!(_);

	public void Set(KeyframeStop other)
	{
		if (other === this)
			return;
		Offset = other.Offset;
		ClearAndDeleteItems!(Properties);
		for (let p in other.Properties)
		{
			let copy = new StyleProperty();
			copy.Set(p);
			Properties.Add(copy);
		}
	}
}

// An @font-face rule: a face of a family, and the file it is in, which the host loads
// (StyleManager.SetFontFaceLoader).
class FontFaceRule
{
	public String Family = new .() ~ delete _;
	/// Its src, url() and quotes taken off.
	public String Source = new .() ~ delete _;
	public uint16 Weight = 400;
	public bool Italic = false;

	public void Set(FontFaceRule other)
	{
		if (other === this)
			return;
		Family.Set(other.Family);
		Source.Set(other.Source);
		Weight = other.Weight;
		Italic = other.Italic;
	}
}

// An @spritesheet (RmlUi's): one image's named regions, which a sheet names as images
// (`url(button-normal)`); the style manager writes each such url as the image and its region
// (`url(atlas.png#xywh=0,0,64,32)`).
class Sprite
{
	public String Name = new .() ~ delete _;
	public float X = 0.0f;
	public float Y = 0.0f;
	public float Width = 0.0f;
	public float Height = 0.0f;

	public this()
	{
	}

	public this(StringView name, float x, float y, float width, float height)
	{
		Name.Set(name);
		X = x;
		Y = y;
		Width = width;
		Height = height;
	}

	public void Set(Sprite other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		X = other.X;
		Y = other.Y;
		Width = other.Width;
		Height = other.Height;
	}
}

class Spritesheet
{
	public String Name = new .() ~ delete _;
	/// Its image's path.
	public String Source = new .() ~ delete _;
	public List<Sprite> Sprites = new .() ~ DeleteContainerAndItems!(_);

	public void Set(Spritesheet other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		Source.Set(other.Source);
		ClearAndDeleteItems!(Sprites);
		for (let s in other.Sprites)
		{
			let copy = new Sprite();
			copy.Set(s);
			Sprites.Add(copy);
		}
	}
}

// A named @keyframes animation: an ordered list of stops.
class Keyframes
{
	public String Name = new .() ~ delete _;
	public List<KeyframeStop> Stops = new .() ~ DeleteContainerAndItems!(_);

	public void Set(Keyframes other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		ClearAndDeleteItems!(Stops);
		for (let s in other.Stops)
		{
			let copy = new KeyframeStop();
			copy.Set(s);
			Stops.Add(copy);
		}
	}
}

/// A rule that matched an element, with what orders it in the cascade. The rule is borrowed
/// from its sheet.
struct StyleRuleMatch
{
	public StyleRule Rule = null;
	/// The sheet's place among the origins (user agent, the GUI's, a subtree's).
	public uint32 Origin = 0;
	public int64 Specificity = 0;
	/// Its place in its sheet.
	public uint32 Order = 0;

	public this()
	{
	}

	public this(StyleRule rule, uint32 origin, int64 specificity, uint32 order)
	{
		Rule = rule;
		Origin = origin;
		Specificity = specificity;
		Order = order;
	}
}

/// One declaration that set a longhand: from a rule (with its origin; borrowed), or the inline
/// style (Rule null).
class DeclarationTrace
{
	public StyleRule Rule = null;
	public uint32 Origin = 0;
	/// As written (a var() not substituted).
	public String Value = new .() ~ delete _;
	public bool Important = false;

	public this()
	{
	}

	public this(StyleRule rule, uint32 origin, StringView value, bool important)
	{
		Rule = rule;
		Origin = origin;
		Value.Set(value);
		Important = important;
	}

	public void Set(DeclarationTrace other)
	{
		if (other === this)
			return;
		Rule = other.Rule;
		Origin = other.Origin;
		Value.Set(other.Value);
		Important = other.Important;
	}
}

/// A longhand an element's cascade set, with every declaration that set it, the winner first.
class LonghandTrace
{
	public String Name = new .() ~ delete _;
	public List<DeclarationTrace> Declarations = new .() ~ DeleteContainerAndItems!(_);

	public void Set(LonghandTrace other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		ClearAndDeleteItems!(Declarations);
		for (let d in other.Declarations)
		{
			let copy = new DeclarationTrace();
			copy.Set(d);
			Declarations.Add(copy);
		}
	}
}

class StyleSheet
{
	// The rules by their subject compound's key, as browsers and RmlUi keep them: its id, else
	// its first class, else its tag; a subject with none is tried on every element. An element
	// tries only the lists its id, classes and tag name, so a sheet of many rules costs what
	// could match. Keys are hashes of the names: a collision only adds candidates, which the full
	// match then turns away.
	private class RuleIndex
	{
		public Dictionary<uint64, List<uint32>> ById = new .() ~ DeleteDictionaryAndValues!(_);
		public Dictionary<uint64, List<uint32>> ByClass = new .() ~ DeleteDictionaryAndValues!(_);
		public Dictionary<uint64, List<uint32>> ByTag = new .() ~ DeleteDictionaryAndValues!(_);
		public List<uint32> Universal = new .() ~ delete _;
		public bool Built = false;

		public void Clear()
		{
			Empty(ById);
			Empty(ByClass);
			Empty(ByTag);
			Universal.Clear();
			Built = false;
		}

		private static void Empty(Dictionary<uint64, List<uint32>> map)
		{
			for (let list in map.Values)
				delete list;
			map.Clear();
		}
	}

	private List<StyleRule> mRules = new .() ~ DeleteContainerAndItems!(_);
	private List<Keyframes> mKeyframes = new .() ~ DeleteContainerAndItems!(_);
	private List<FontFaceRule> mFontFaces = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mImports = new .() ~ DeleteContainerAndItems!(_);
	private List<Spritesheet> mSpritesheets = new .() ~ DeleteContainerAndItems!(_);
	private RuleIndex mIndex = new .() ~ delete _;
	private String mName = new .() ~ delete _;

	/// Makes this a copy of `other`: its rules, keyframes, font faces, imports and spritesheets.
	public void Set(StyleSheet other)
	{
		if (other === this)
			return;
		ClearAndDeleteItems!(mRules);
		for (let r in other.mRules)
		{
			let copy = new StyleRule();
			copy.Set(r);
			mRules.Add(copy);
		}
		ClearAndDeleteItems!(mKeyframes);
		for (let k in other.mKeyframes)
		{
			let copy = new Keyframes();
			copy.Set(k);
			mKeyframes.Add(copy);
		}
		ClearAndDeleteItems!(mFontFaces);
		for (let f in other.mFontFaces)
		{
			let copy = new FontFaceRule();
			copy.Set(f);
			mFontFaces.Add(copy);
		}
		ClearAndDeleteItems!(mImports);
		for (let i in other.mImports)
			mImports.Add(new String(i));
		ClearAndDeleteItems!(mSpritesheets);
		for (let s in other.mSpritesheets)
		{
			let copy = new Spritesheet();
			copy.Set(s);
			mSpritesheets.Add(copy);
		}
		mName.Set(other.mName);
		mIndex.Clear();
	}

	/// What it is called where it came from (a path, "theme"); empty when it was not named.
	public StringView Name
	{
		get => mName;
		set => mName.Set(value);
	}

	/// OWNERSHIP of `rule` transfers.
	public void AddRule(StyleRule rule)
	{
		mRules.Add(rule);
		mIndex.Built = false;
	}

	public int RuleCount => mRules.Count;
	public Span<StyleRule> Rules => mRules;

	/// `rule` as one to change, when it is this sheet's (null when it is not).
	public StyleRule MutableRule(StyleRule rule)
	{
		for (let r in mRules)
		{
			if (r === rule)
				return r;
		}
		return null;
	}

	/// OWNERSHIP of `keyframes` transfers.
	public void AddKeyframes(Keyframes keyframes) => mKeyframes.Add(keyframes);
	/// OWNERSHIP of `face` transfers.
	public void AddFontFace(FontFaceRule face) => mFontFaces.Add(face);
	/// The paths it @imports, in order: the style manager loads and expands them.
	public void AddImport(StringView path) => mImports.Add(new String(path));
	/// OWNERSHIP of `sheet` transfers.
	public void AddSpritesheet(Spritesheet sheet) => mSpritesheets.Add(sheet);
	public Span<Spritesheet> Spritesheets => mSpritesheets;

	/// Every rule's value naming one of `sheets`' sprites as an image (url(name)) written as its
	/// spritesheet's image and region instead.
	public void ResolveSprites(Span<Spritesheet> sheets)
	{
		let output = scope String();
		for (let rule in mRules)
		{
			for (let p in rule.Properties)
			{
				StringView value = p.Value;
				bool hasUrl = false;
				for (int i = 0; (i + 4 <= value.Length) && !hasUrl; i++)
					hasUrl = value.Substring(i, 4) == "url(";
				if (!hasUrl)
					continue;
				output.Clear();
				bool changed = false;
				for (int i = 0; i < value.Length;)
				{
					if ((i + 4 > value.Length) || (value.Substring(i, 4) != "url("))
					{
						output.Append(value[i++]);
						continue;
					}
					int close = i + 4;
					while ((close < value.Length) && (value[close] != ')'))
						close++;
					var name = ParseUtil.Trim(value.Substring(i + 4, close - i - 4));
					if ((name.Length >= 2) && ((name[0] == '"') || (name[0] == '\'')) && (name[name.Length - 1] == name[0]))
						name = name.Substring(1, name.Length - 2);
					Sprite found = null;
					Spritesheet inSheet = null;
					for (let sheet in sheets)
					{
						for (let sprite in sheet.Sprites)
						{
							if ((found == null) && (sprite.Name == name))
							{
								found = sprite;
								inSheet = sheet;
							}
						}
					}
					if (found == null)
					{
						output.Append(value.Substring(i, close - i));
						i = close;
						continue;
					}
					output.Append("url(");
					output.Append(inSheet.Source);
					output.AppendF("#xywh={},{},{},{}", found.X, found.Y, found.Width, found.Height);
					i = close;
					changed = true;
				}
				if (changed)
					rule.SetProperty(p.Name, output, p.Important);
			}
		}
		mIndex.Built = false;
	}

	public Span<String> Imports => mImports;

	/// Puts `imported`'s rules before its own (an import comes first in source order, so this
	/// sheet's own win a tie), and takes its keyframes, font faces and spritesheets after its
	/// own. `imported` is left empty of them; the caller still owns it.
	public void PrependImported(StyleSheet imported)
	{
		let own = scope List<StyleRule>();
		own.AddRange(mRules);
		mRules.Clear();
		mRules.AddRange(imported.mRules);
		mRules.AddRange(own);
		imported.mRules.Clear();
		imported.mIndex.Built = false;
		mKeyframes.AddRange(imported.mKeyframes);
		imported.mKeyframes.Clear();
		mFontFaces.AddRange(imported.mFontFaces);
		imported.mFontFaces.Clear();
		mSpritesheets.AddRange(imported.mSpritesheets);
		imported.mSpritesheets.Clear();
		mIndex.Built = false;
	}

	public Span<FontFaceRule> FontFaces => mFontFaces;
	public int KeyframesCount => mKeyframes.Count;
	public Span<Keyframes> AllKeyframes => mKeyframes;

	/// The keyframes named `name`, or null. Borrowed.
	public Keyframes FindKeyframes(StringView name)
	{
		for (let k in mKeyframes)
		{
			if (k.Name == name)
				return k;
		}
		return null;
	}

	/// The rules of this sheet that match `element` (its own style with `pseudoElement` empty,
	/// else that part's, from rules written `tag::part`) under `context`, added to `outMatches`
	/// at `origin` (a later origin wins over an earlier one at any specificity). A part's rules
	/// that ask for its states (`::thumb:hover`) match when `partStates` has them. `ancestors`,
	/// when given, holds the names of every widget above `element`.
	public void CollectMatches(UIWidget element, MediaContext context, bool applyPseudo, StringView pseudoElement, uint32 origin,
		List<StyleRuleMatch> outMatches, uint32 partStates = 0, AncestorFilter ancestors = null)
	{
		// Only the rules whose subject could match: those keyed by the element's id, one of its
		// classes or its tag, and those with no key (the order is the cascade's to set).
		let index = Index();
		void TryRules(List<uint32> candidates)
		{
			for (let i in candidates)
			{
				let rule = mRules[(int)i];
				if (rule.Selector.PseudoElement != pseudoElement)
					continue;
				if (applyPseudo && ((rule.Selector.PartPseudoClasses & ~partStates) != 0))
					continue;
				if ((ancestors != null) && !ancestors.MayMatch(rule.Selector))
					continue;
				let mediaActive = rule.Media.IsEmpty || rule.Media.Evaluate(context);
				if (mediaActive && rule.Selector.Select(element, applyPseudo))
					outMatches.Add(.(rule, origin, rule.Specificity, i));
			}
		}
		void TryKey(Dictionary<uint64, List<uint32>> map, StringView key)
		{
			if ((key.Length != 0) && map.TryGetValue(HashText(key), let candidates))
				TryRules(candidates);
		}
		TryKey(index.ById, element.Id);
		for (let cls in element.Classes)
			TryKey(index.ByClass, cls);
		TryKey(index.ByTag, element.Tag);
		TryRules(index.Universal);
	}

	// Resolve the cascade for `element` against this sheet alone, into `outStyle`: the element's
	// own style (rules with no ::part), under the default media context.
	public void Resolve(UIWidget element, ResolvedStyle outStyle)
	{
		Resolve(element, MediaContext(), true, default, null, outStyle);
	}

	public void Resolve(UIWidget element, MediaContext context, ResolvedStyle outStyle)
	{
		Resolve(element, context, true, default, null, outStyle);
	}

	/// With `pseudoElement` empty this is the element's own style (rules with no ::part); pass a
	/// part name (e.g. "thumb") to resolve the cascade for that widget part (rules written as
	/// `tag::part { ... }`). `inherited` (the parent's resolved style) gives the custom
	/// properties this element does not set.
	public void Resolve(UIWidget element, MediaContext context, bool applyPseudo, StringView pseudoElement, ResolvedStyle inherited,
		ResolvedStyle outStyle)
	{
		let matches = scope List<StyleRuleMatch>();
		CollectMatches(element, context, applyPseudo, pseudoElement, 0, matches);
		Cascade(matches, inherited, default, outStyle);
	}

	/// The cascade of `matches` (from any sheets), into `outStyle` (emptied first): ordered by
	/// origin, then specificity, then source order, applied low to high so the later wins
	/// (!important resists a later normal value); then `inlineStyle` (markup's attributes,
	/// SetInlineStyle's), the highest origin. Custom properties first (this element's, then those
	/// it inherits from `inherited`), so a var() anywhere resolves against the whole cascade; then
	/// each declaration as its longhands, parsed: once per declaration when it has no var() (its
	/// value cannot change), else each time.
	public static void Cascade(List<StyleRuleMatch> matches, ResolvedStyle inherited, Span<InlineStyleDeclaration> inlineStyle,
		ResolvedStyle outStyle)
	{
		SortMatches(matches);
		outStyle.Clear();
		for (let m in matches)
		{
			for (let p in m.Rule.Properties)
			{
				if (ResolvedStyle.IsCustomProperty(p.Name))
					outStyle.SetParsed(p.Name, p.Value, null, p.Important);
			}
		}
		for (let d in inlineStyle)
		{
			if (ResolvedStyle.IsCustomProperty(d.Name))
				outStyle.SetParsed(d.Name, d.Value, null, false);
		}
		if (inherited != null)
			outStyle.InheritCustomProperties(inherited);
		// currentColor's colour: the winning `color` here, before anything reads it.
		{
			StyleProperty winner = null;
			StringView inlineColor = default;
			for (let m in matches)
			{
				for (let p in m.Rule.Properties)
				{
					if ((p.Name == "color") && ((winner == null) || p.Important || !winner.Important))
						winner = p;
				}
			}
			for (let d in inlineStyle)
			{
				if ((d.Name == "color") && ((winner == null) || !winner.Important))
					inlineColor = d.Value;
			}
			if (inlineColor.Length != 0)
				outStyle.SetCurrentColor(inlineColor, inherited);
			else if (winner != null)
				outStyle.SetCurrentColor(winner.Value, inherited);
		}
		let text = scope String();
		for (let m in matches)
		{
			for (let p in m.Rule.Properties)
			{
				if (ResolvedStyle.IsCustomProperty(p.Name))
					continue;
				if (!p.Cached)
					Cache(p);
				if (p.CacheValid)
				{
					for (let longhand in p.Longhands)
						outStyle.SetParsed(longhand.Name, longhand.Text, longhand.Value, p.Important);
					continue;
				}
				if (outStyle.ResolveText(p.Name, p.Value, inherited, text))
					outStyle.SetDeclaration(p.Name, text, p.Important);
			}
		}
		for (let d in inlineStyle)
		{
			if (ResolvedStyle.IsCustomProperty(d.Name))
				continue;
			if (outStyle.ResolveText(d.Name, d.Value, inherited, text))
				outStyle.SetDeclaration(d.Name, text, false);
		}
	}

	/// Where each longhand of `matches` and `inlineStyle` came from, as Cascade applies them,
	/// added to `outTraces` (empty): ordered by origin, specificity and source, then the inline
	/// style; for each longhand every declaration that set it, the winner first (the last
	/// !important one, else the last), the rest by precedence. For the inspector, not the frame.
	public static void Trace(List<StyleRuleMatch> matches, Span<InlineStyleDeclaration> inlineStyle, List<LonghandTrace> outTraces)
	{
		SortMatches(matches);
		// In the order the cascade applies them: the longhand's place in `outTraces`, and the
		// declaration, which goes to that longhand's list.
		let applied = scope List<(int longhand, DeclarationTrace declaration)>();
		void Add(StringView name, DeclarationTrace d)
		{
			int at = outTraces.Count;
			for (int i = 0; i < outTraces.Count; i++)
			{
				if (outTraces[i].Name == name)
					at = i;
			}
			if (at == outTraces.Count)
			{
				let trace = new LonghandTrace();
				trace.Name.Set(name);
				outTraces.Add(trace);
			}
			applied.Add((at, d));
		}
		void Declare(StringView name, StringView value, StyleRule rule, uint32 origin, bool important)
		{
			if (ResolvedStyle.IsCustomProperty(name))
			{
				Add(name, new DeclarationTrace(rule, origin, value, important));
				return;
			}
			let longhands = scope List<StyleLonghand>();
			defer { ClearAndDeleteItems!(longhands); }
			if (ExpandStyleShorthand(name, value, longhands))
			{
				for (let l in longhands)
					Add(l.Name, new DeclarationTrace(rule, origin, l.Text, important));
			}
		}
		for (let m in matches)
		{
			for (let p in m.Rule.Properties)
				Declare(p.Name, p.Value, m.Rule, m.Origin, p.Important);
		}
		for (let d in inlineStyle)
			Declare(d.Name, d.Value, null, 0, false);
		// Precedence: an important one over every normal one, then the later over the earlier.
		for (int i = applied.Count - 1; i >= 0; i--)
		{
			if (applied[i].declaration.Important)
				outTraces[applied[i].longhand].Declarations.Add(applied[i].declaration);
		}
		for (int i = applied.Count - 1; i >= 0; i--)
		{
			if (!applied[i].declaration.Important)
				outTraces[applied[i].longhand].Declarations.Add(applied[i].declaration);
		}
	}

	// Stable insertion sort (ties keep their order: sheet, then source).
	private static void SortMatches(List<StyleRuleMatch> matches)
	{
		for (int a = 1; a < matches.Count; a++)
		{
			let key = matches[a];
			int b = a;
			while ((b > 0) && Before(key, matches[b - 1]))
			{
				matches[b] = matches[b - 1];
				b--;
			}
			matches[b] = key;
		}
	}

	private static bool Before(StyleRuleMatch a, StyleRuleMatch b)
	{
		if (a.Origin != b.Origin)
			return a.Origin < b.Origin;
		if (a.Specificity != b.Specificity)
			return a.Specificity < b.Specificity;
		return a.Order < b.Order;
	}

	// A declaration without var() expands and parses once: its longhands cached on it.
	private static void Cache(StyleProperty p)
	{
		p.Cached = true;
		for (int i = 0; i + 3 < p.Value.Length; i++)
		{
			if (p.Value.Substring(i, 4) == "var(")
				return; // re-substituted each cascade
		}
		if (ResolvedStyle.HasCurrentColor(p.Value))
			return; // its colour is each element's
		let longhands = scope List<StyleLonghand>();
		defer { ClearAndDeleteItems!(longhands); }
		if (!ExpandStyleShorthand(p.Name, p.Value, longhands))
		{
			p.CacheValid = true; // a shorthand that does not parse sets nothing, every time
			return;
		}
		for (let longhand in longhands)
		{
			let value = new StyleLonghandValue();
			value.Name.Set(longhand.Name);
			value.Text.Set(longhand.Text);
			ResolvedStyle.ParseLonghand(longhand.Name, longhand.Text, value.Value);
			p.Longhands.Add(value);
		}
		p.CacheValid = true;
	}

	private static void AddToIndex(Dictionary<uint64, List<uint32>> map, StringView key, uint32 at)
	{
		let hash = HashText(key);
		if (map.TryGetValue(hash, let list))
			list.Add(at);
		else
		{
			let list1 = new List<uint32>();
			list1.Add(at);
			map[hash] = list1;
		}
	}

	private RuleIndex Index()
	{
		if (mIndex.Built)
			return mIndex;
		mIndex.Clear();
		for (int i = 0; i < mRules.Count; i++)
		{
			let selector = mRules[i].Selector;
			if (selector.IsEmpty)
				continue;
			let subject = selector.RuleAt(selector.RuleCount - 1);
			if (subject.IsNever)
				continue; // matches nothing
			let at = (uint32)i;
			if (subject.Id.Length != 0)
				AddToIndex(mIndex.ById, subject.Id, at);
			else if (!subject.Classes.IsEmpty)
				AddToIndex(mIndex.ByClass, subject.Classes[0], at);
			else if (subject.Tag.Length != 0)
				AddToIndex(mIndex.ByTag, subject.Tag, at);
			else
				mIndex.Universal.Add(at);
		}
		mIndex.Built = true;
		return mIndex;
	}
}
