using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;

namespace Sedulous.I18N;

/// A span pseudolocalization leaves as it is, by its opening and closing marks.
class UntouchedSpan
{
	public String Open = new .() ~ delete _;
	public String Close = new .() ~ delete _;

	public this(StringView open, StringView close)
	{
		Open.Set(open);
		Close.Set(close);
	}
}

/// What pseudolocalization does to each text.
class PseudoOptions
{
	public bool Enabled = false;
	/// Letters accented ("Settings" to "Šéţţîñĝš"), still readable.
	public bool Accents = true;
	/// Padded with `~` by this share of its length (nought: not at all).
	public float Lengthen = 0.3f;
	/// Each text between [ and ], so a cut off end shows.
	public bool Brackets = true;
	/// Wrapped in a right to left embedding, to try such a layout.
	public bool RightToLeft = false;
	/// Each key beside its text ("menu.play: Play").
	public bool ShowKeys = false;
	/// Spans a consumer's markup needs untouched, each by its opening and closing marks ("[" and
	/// "]" for rich text tags, "{{" and "}}" for bindings); `{0}` placeholders always are.
	public List<UntouchedSpan> Untouched = new .() ~ DeleteContainerAndItems!(_);

	public void CopyFrom(PseudoOptions other)
	{
		Enabled = other.Enabled;
		Accents = other.Accents;
		Lengthen = other.Lengthen;
		Brackets = other.Brackets;
		RightToLeft = other.RightToLeft;
		ShowKeys = other.ShowKeys;
		ClearAndDeleteItems!(Untouched);
		for (let span in other.Untouched)
			Untouched.Add(new .(span.Open, span.Close));
	}
}

/// A key asked for and found in no table, and the language it was asked in.
class MissingKey
{
	public String Key = new .() ~ delete _;
	public String Language = new .() ~ delete _;
}

/// The resolver its owner holds.
///
/// It borrows string tables (the last added wins for a key, and for a locale's rule or
/// direction), holds the language and a fallback, and answers: a key's text through the chain
/// (the language, its parents, the fallback, its parents), a plural key's form for a count by
/// the rule of the language the text came from, positional formatting, and which way the
/// language is written. A miss returns the key itself, logged once and kept for a tool to write
/// out. Pseudolocalization transforms whatever it resolves. Owners hear of changes through a
/// plain callback list: no bus, so this stays a leaf.
class Localization
{
	private struct Found
	{
		public String Text;
		public StringTable Table;
		public StringView Locale;
	}

	/// Right to left embedding and pop directional formatting, written as escapes: both are
	/// invisible in an editor.
	private const String cRightToLeftEmbedding = "\u{202B}";
	private const String cPopDirectionalFormatting = "\u{202C}";

	/// Each ASCII letter's accented look-alike, empty for a letter with none in Latin-1 or Latin
	/// Extended-A: a font baked for European languages draws them all, and the point is to see a
	/// layout with readable text, not holes.
	private static readonly String[26] sLowerAccents = .("á", "", "ç", "ð", "é", "", "ĝ", "ĥ", "î", "ĵ",
		"ķ", "ļ", "", "ñ", "ö", "þ", "", "ŕ", "š", "ţ", "û", "", "ŵ", "", "ý", "ž");
	private static readonly String[26] sUpperAccents = .("Å", "", "Ç", "Ð", "É", "", "Ĝ", "Ĥ", "Î", "Ĵ",
		"Ķ", "Ļ", "", "Ñ", "Ö", "Þ", "", "Ŕ", "Š", "Ţ", "Û", "", "Ŵ", "", "Ý", "Ž");

	/// BORROWED, the last winning.
	private List<StringTable> mTables = new .() ~ delete _;
	private String mLanguage = new .("en") ~ delete _;
	private String mFallback = new .("en") ~ delete _;
	private List<MissingKey> mMissing = new .() ~ DeleteContainerAndItems!(_);
	private HashSet<uint64> mMissedHashes = new .() ~ delete _;
	/// Locales already logged as having no rule.
	private HashSet<uint64> mRuleless = new .() ~ delete _;
	private PseudoOptions mPseudo = new .() ~ delete _;
	private String mBuffer = new .() ~ delete _;
	private List<(uint32 token, delegate void() call)> mCallbacks = new .() ~ { for (let callback in _) delete callback.call; delete _; };
	private uint32 mNextToken = 0;

	// ---- Tables (borrowed) ---------------------------------------------------------------------

	/// Adds a table, over those added before (it wins for its keys and locales).
	public void AddTable(StringTable table)
	{
		if (table == null)
			return;
		mTables.Add(table);
		Changed();
	}

	public void RemoveTable(StringTable table)
	{
		if (mTables.Remove(table))
			Changed();
	}

	// ---- The language --------------------------------------------------------------------------

	public StringView Language => mLanguage;

	public void SetLanguage(StringView locale)
	{
		mLanguage.Set(locale);
		Changed();
	}

	public StringView FallbackLanguage => mFallback;

	public void SetFallbackLanguage(StringView locale)
	{
		mFallback.Set(locale);
		Changed();
	}

	// ---- Texts ---------------------------------------------------------------------------------

	/// Whether some table has the key in the chain's languages.
	public bool Has(StringView key) => Find(key).Text != null;

	/// The key's text in the chain (a plural key's `other` form), else the key itself, logged
	/// once. A view into a table (valid until that table changes or goes), or into this
	/// resolver's buffer while pseudolocalizing (valid until the next call).
	public StringView Text(StringView key)
	{
		let found = Find(key);
		if (found.Text == null)
			return Missed(key);
		return Shown(key, found.Text);
	}

	/// The plural key's form for count `n` in the chain, by the plural rule of the language its
	/// text came from; its `other` form when that category is missing; the key when no table has
	/// it. A plain key gives its text.
	public StringView Plural(StringView key, int64 n)
	{
		let found = Find(key);
		if (found.Text == null)
			return Missed(key);
		if (found.Table.IsPlural(key))
		{
			let category = PluralCategoryOf(found.Locale, n);
			if (let form = found.Table.PluralForm(key, found.Locale, category))
				return Shown(key, form);
		}
		return Shown(key, found.Text);
	}

	/// The key's text with its placeholders `{0}`, `{1}` filled from the arguments, in any order
	/// the translation puts them; `{{` and `}}` are braces; a placeholder naming no argument
	/// prints as written.
	public void Format(StringView key, String outText, params Span<Object> args) =>
		Fill(Text(key), args, outText);

	/// Plural, then Format (`{0}` conventionally the count).
	public void FormatPlural(StringView key, int64 n, String outText, params Span<Object> args) =>
		Fill(Plural(key, n), args, outText);

	// ---- What the tables say about languages ---------------------------------------------------

	/// The plural category of `n` in the locale, by the last table's rule for it or its parents;
	/// Other for every count when no table gives one (logged once a locale).
	public PluralCategory PluralCategoryOf(StringView locale, int64 n)
	{
		for (var l = locale; !l.IsEmpty; l = LocaleId.Parent(l))
		{
			for (int t = mTables.Count - 1; t >= 0; t--)
			{
				if (let rule = mTables[t].GetPluralRule(l))
					return rule.CategoryOf(n);
			}
		}
		if (mRuleless.Add(HashText(locale)))
			GlobalLog(.Warning, "I18N: no plural rule for '{}': every count shows the other form", locale);
		return .Other;
	}

	/// Whether the current language is written right to left (by the tables, through its
	/// parents; left to right when none says).
	public bool IsRightToLeft() => IsRightToLeft(mLanguage);

	public bool IsRightToLeft(StringView locale)
	{
		for (var l = locale; !l.IsEmpty; l = LocaleId.Parent(l))
		{
			for (int t = mTables.Count - 1; t >= 0; t--)
			{
				let direction = mTables[t].GetDirection(l);
				if (direction != .Unset)
					return direction == .RightToLeft;
			}
		}
		return false;
	}

	// ---- Missing keys --------------------------------------------------------------------------

	public List<MissingKey> MissingKeys => mMissing;

	public void ClearMissingKeys()
	{
		ClearAndDeleteItems!(mMissing);
		mMissedHashes.Clear();
	}

	// ---- Pseudolocalization --------------------------------------------------------------------

	/// Copies the options in.
	public void SetPseudolocalization(PseudoOptions options)
	{
		mPseudo.CopyFrom(options);
		Changed();
	}

	public PseudoOptions Pseudolocalization => mPseudo;

	// ---- Changes -------------------------------------------------------------------------------

	/// Called when the language, the tables or pseudolocalization change. TAKES OWNERSHIP of the
	/// delegate; the token removes it.
	public uint32 OnChanged(delegate void() callback)
	{
		mCallbacks.Add((++mNextToken, callback));
		return mNextToken;
	}

	public void RemoveOnChanged(uint32 token)
	{
		for (int i < mCallbacks.Count)
		{
			if (mCallbacks[i].token == token)
			{
				delete mCallbacks[i].call;
				mCallbacks.RemoveAt(i);
				return;
			}
		}
	}

	// ---- The chain -----------------------------------------------------------------------------

	/// The first text along the chain: the language and its parents, then the fallback and its
	/// parents; at each, the last table first.
	private Found Find(StringView key)
	{
		StringView[2] starts = .(mLanguage, mFallback);
		for (let start in starts)
		{
			for (var l = start; !l.IsEmpty; l = LocaleId.Parent(l))
			{
				for (int t = mTables.Count - 1; t >= 0; t--)
				{
					if (let text = mTables[t].Text(key, l))
						return .() { Text = text, Table = mTables[t], Locale = l };
				}
			}
		}
		return .();
	}

	private StringView Missed(StringView key)
	{
		if (mMissedHashes.Add(HashText(key)))
		{
			let missing = new MissingKey();
			missing.Key.Set(key);
			missing.Language.Set(mLanguage);
			mMissing.Add(missing);
			GlobalLog(.Warning, "I18N: no text for '{}' in '{}'", key, mLanguage);
		}
		return Shown(key, key);
	}

	/// The text as shown: itself, or pseudolocalized into the buffer.
	private StringView Shown(StringView key, StringView text)
	{
		if (!mPseudo.Enabled)
			return text;
		// The text may be a view of the buffer itself (a miss shown twice), so it is built aside.
		let shown = scope String();
		Pseudolocalize(key, text, shown);
		mBuffer.Set(shown);
		return mBuffer;
	}

	private void Pseudolocalize(StringView key, StringView text, String outText)
	{
		if (mPseudo.RightToLeft)
			outText.Append(cRightToLeftEmbedding);
		if (mPseudo.Brackets)
			outText.Append('[');
		if (mPseudo.ShowKeys)
		{
			outText.Append(key);
			outText.Append(": ");
		}

		int letters = 0;
		int i = 0;
		while (i < text.Length)
		{
			// A span to leave as it is: a placeholder, or one the consumer named.
			let kept = UntouchedAt(text, i);
			if (kept != 0)
			{
				outText.Append(text.Substring(i, kept));
				i += kept;
				continue;
			}
			let c = text[i];
			let accented = mPseudo.Accents ? Accented(c) : StringView();
			if (!accented.IsEmpty)
				outText.Append(accented);
			else
				outText.Append(c);
			// A code point's first byte: one letter.
			if (((uint8)c & 0xC0) != 0x80)
				letters++;
			i++;
		}

		let pad = (int)((float)letters * Math.Max(0.0f, mPseudo.Lengthen) + 0.5f);
		outText.Append('~', pad);
		if (mPseudo.Brackets)
			outText.Append(']');
		if (mPseudo.RightToLeft)
			outText.Append(cPopDirectionalFormatting);
	}

	/// The length of the untouched span starting at `at`, or nought.
	private int UntouchedAt(StringView text, int at)
	{
		if (text[at] == '{')
		{
			var end = at + 1;
			while ((end < text.Length) && (text[end] >= '0') && (text[end] <= '9'))
				end++;
			if ((end > at + 1) && (end < text.Length) && (text[end] == '}'))
				return end + 1 - at;
		}
		for (let marks in mPseudo.Untouched)
		{
			StringView open = marks.Open;
			StringView close = marks.Close;
			if (open.IsEmpty || (at + open.Length > text.Length) || (text.Substring(at, open.Length) != open))
				continue;
			for (int end = at + open.Length; end + close.Length <= text.Length; end++)
			{
				if (text.Substring(end, close.Length) == close)
					return end + close.Length - at;
			}
		}
		return 0;
	}

	private static StringView Accented(char8 c)
	{
		if ((c >= 'a') && (c <= 'z'))
			return sLowerAccents[(int)c - (int)'a'];
		if ((c >= 'A') && (c <= 'Z'))
			return sUpperAccents[(int)c - (int)'A'];
		return .();
	}

	// ---- Formatting ----------------------------------------------------------------------------

	/// Positional placeholders filled.
	private static void Fill(StringView text, Span<Object> args, String outText)
	{
		int i = 0;
		while (i < text.Length)
		{
			let c = text[i];
			if (((c == '{') || (c == '}')) && (i + 1 < text.Length) && (text[i + 1] == c))
			{
				// An escaped brace.
				outText.Append(c);
				i += 2;
				continue;
			}
			if (c == '{')
			{
				var end = i + 1;
				int index = 0;
				while ((end < text.Length) && (text[end] >= '0') && (text[end] <= '9'))
					index = index * 10 + ((int)text[end++] - (int)'0');
				if ((end > i + 1) && (end < text.Length) && (text[end] == '}') && (index < args.Length))
				{
					AppendArgument(args[index], outText);
					i = end + 1;
					continue;
				}
			}
			// A placeholder naming no argument stays as written.
			outText.Append(c);
			i++;
		}
	}

	/// An argument as text: a bool as "true" or "false" (Beef's own spelling is capitalised),
	/// anything else as it prints.
	private static void AppendArgument(Object value, String outText)
	{
		if (value == null)
			return;
		if (value is bool)
		{
			outText.Append((bool)value ? "true" : "false");
			return;
		}
		value.ToString(outText);
	}

	private void Changed()
	{
		for (int i < mCallbacks.Count)
			mCallbacks[i].call();
	}
}
