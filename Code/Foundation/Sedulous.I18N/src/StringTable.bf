using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.I18N;

/// A locale's direction as a table says it, or nothing said.
enum TextDirection : uint8
{
	case Unset;
	case LeftToRight;
	case RightToLeft;
}

/// The authored unit, one resource holding everything about its languages.
///
/// Locales, each with its plural rule and its direction (either may be unset, for a table that
/// only adds texts to a locale another table describes); keys, each plain or plural in all its
/// locales, a cell per locale missing, a text, or a plural entry (a text per category, `other`
/// among them). Mutable, so an editor's grid and an import change it in place; serializable as
/// a versioned payload, the same body an asset's source and its cooked product.
class StringTable : ISerializable
{
	public static readonly uint64 TypeId = TypeIdOf("Sedulous.I18N.StringTable");
	public const uint32 DataVersion = 1;

	private class LocaleInfo
	{
		public String Id = new .() ~ delete _;
		public PluralRule Rule = new .() ~ delete _;
		public bool HasRule;
		public TextDirection Direction = .Unset;
	}

	private class Cell
	{
		/// A plain text.
		public bool Present;
		public String Text = new .() ~ delete _;
		/// A plural entry's forms, one bit a category.
		public uint8 FormsPresent;
		public String[PluralCategory.Count] Forms = .(new .(), new .(), new .(), new .(), new .(), new .());

		public ~this()
		{
			for (let form in Forms)
				delete form;
		}

		public void Reset()
		{
			Present = false;
			Text.Clear();
			FormsPresent = 0;
			for (let form in Forms)
				form.Clear();
		}

		public String Form(PluralCategory category) =>
			((FormsPresent & (1 << (int)category)) != 0) ? Forms[(int)category] : null;
	}

	private class Entry
	{
		public String Key = new .() ~ delete _;
		public bool Plural;
		/// One a locale, in the locales' order.
		public List<Cell> Cells = new .() ~ DeleteContainerAndItems!(_);
	}

	/// Directions are written by name, so a table reads in a text editor.
	private static readonly String[3] sDirectionNames = .("", "ltr", "rtl");

	private List<LocaleInfo> mLocales = new .() ~ DeleteContainerAndItems!(_);
	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	/// A key's hash to its entry.
	private Dictionary<uint64, int> mIndex = new .() ~ delete _;

	/// Makes the table loadable by its type name. Safe to call again.
	public static void Register(SerializableRegistry registry = null)
	{
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		target.Register(TypeId, () => new StringTable());
	}

	// ---- Locales -------------------------------------------------------------------------------

	/// Adds a locale (its id as given; one with a locale's shape); false when it is not shaped as
	/// one or the table has it.
	public bool AddLocale(StringView locale)
	{
		if (!LocaleId.IsShaped(locale) || (FindLocale(locale) >= 0))
			return false;
		let info = new LocaleInfo();
		info.Id.Set(locale);
		mLocales.Add(info);
		for (let entry in mEntries)
			entry.Cells.Add(new Cell());
		return true;
	}

	/// Removes a locale and every text in it; false when the table has none such.
	public bool RemoveLocale(StringView locale)
	{
		let at = FindLocale(locale);
		if (at < 0)
			return false;
		delete mLocales[at];
		mLocales.RemoveAt(at);
		for (let entry in mEntries)
		{
			delete entry.Cells[at];
			entry.Cells.RemoveAt(at);
		}
		return true;
	}

	public int LocaleCount => mLocales.Count;
	public StringView LocaleAt(int index) => mLocales[index].Id;
	public bool HasLocale(StringView locale) => FindLocale(locale) >= 0;

	/// Sets the locale's plural rule ("one: n = 1; few: ..."); false, with `error`, when the
	/// locale is not the table's or the rule does not parse (the old rule then stays).
	public bool SetPluralRule(StringView locale, StringView rule, PluralRuleError error = null)
	{
		let at = FindLocale(locale);
		if (at < 0)
		{
			if (error != null)
			{
				error.Message.Set("no such locale in the table");
				error.Position = 0;
			}
			return false;
		}
		if (!mLocales[at].Rule.Parse(rule, error))
			return false;
		mLocales[at].HasRule = true;
		return true;
	}

	/// Leaves the locale's rule unset (another table may give it).
	public void ClearPluralRule(StringView locale)
	{
		let at = FindLocale(locale);
		if (at >= 0)
			mLocales[at].HasRule = false;
	}

	/// The locale's rule, or null when this table sets none.
	public PluralRule GetPluralRule(StringView locale)
	{
		let at = FindLocale(locale);
		return ((at >= 0) && mLocales[at].HasRule) ? mLocales[at].Rule : null;
	}

	/// Says which way the locale is written (Unset: this table does not say).
	public void SetDirection(StringView locale, TextDirection direction)
	{
		let at = FindLocale(locale);
		if (at >= 0)
			mLocales[at].Direction = direction;
	}

	public TextDirection GetDirection(StringView locale)
	{
		let at = FindLocale(locale);
		return (at >= 0) ? mLocales[at].Direction : .Unset;
	}

	// ---- Keys and their texts ------------------------------------------------------------------

	/// Sets a plain key's text in a locale (the locale added when the table lacks it); false when
	/// the key is plural, or the locale has no locale's shape.
	public bool Set(StringView key, StringView locale, StringView text)
	{
		let column = EnsureLocale(locale);
		if (column < 0)
			return false;
		let entry = EnsureEntry(key, false);
		if (entry.Plural)
			return false;
		let cell = entry.Cells[column];
		cell.Present = true;
		cell.Text.Set(text);
		return true;
	}

	/// Sets one form of a plural key in a locale; false when the key is plain, or the locale has
	/// no locale's shape.
	public bool SetPlural(StringView key, StringView locale, PluralCategory category, StringView text)
	{
		let column = EnsureLocale(locale);
		if (column < 0)
			return false;
		let entry = EnsureEntry(key, true);
		if (!entry.Plural)
			return false;
		let cell = entry.Cells[column];
		cell.Forms[(int)category].Set(text);
		cell.FormsPresent |= (uint8)(1 << (int)category);
		return true;
	}

	/// Removes a key (in every locale); false when the table has none such.
	public bool Remove(StringView key)
	{
		let at = FindEntry(key);
		if (at < 0)
			return false;
		delete mEntries[at];
		mEntries.RemoveAt(at);
		Reindex();
		return true;
	}

	/// Renames a key, its texts (every form) with it; false when `from` is none or `to` is taken.
	public bool RenameKey(StringView from, StringView to)
	{
		let at = FindEntry(from);
		if ((at < 0) || (FindEntry(to) >= 0))
			return false;
		mEntries[at].Key.Set(to);
		Reindex();
		return true;
	}

	/// Removes a key's text in one locale (the cell missing again).
	public void Clear(StringView key, StringView locale)
	{
		let at = FindEntry(key);
		let column = FindLocale(locale);
		if ((at >= 0) && (column >= 0))
			mEntries[at].Cells[column].Reset();
	}

	public int KeyCount => mEntries.Count;
	public StringView KeyAt(int index) => mEntries[index].Key;
	public bool HasKey(StringView key) => FindEntry(key) >= 0;

	public bool IsPlural(StringView key)
	{
		let at = FindEntry(key);
		return (at >= 0) && mEntries[at].Plural;
	}

	/// Whether the key has a text in the locale (a plain text, or any plural form).
	public bool HasText(StringView key, StringView locale)
	{
		let cell = FindCell(key, locale);
		return (cell != null) && (cell.Present || (cell.FormsPresent != 0));
	}

	/// The key's text in the locale: a plain key's, a plural key's `other` form; null when
	/// missing. BORROWED, valid until the table changes.
	public String Text(StringView key, StringView locale)
	{
		let cell = FindCell(key, locale);
		if (cell == null)
			return null;
		if (cell.Present)
			return cell.Text;
		return cell.Form(.Other);
	}

	/// One form of a plural key in the locale; null when missing (or the key is plain).
	public String PluralForm(StringView key, StringView locale, PluralCategory category)
	{
		let cell = FindCell(key, locale);
		return (cell != null) ? cell.Form(category) : null;
	}

	/// The categories a plural key's entry in the locale lacks that the rule uses (`other` always
	/// among those it needs); every used one when the entry is missing.
	public void MissingForms(StringView key, StringView locale, PluralRule rule, List<PluralCategory> outMissing)
	{
		let cell = FindCell(key, locale);
		for (int i < PluralCategory.Count)
		{
			let category = (PluralCategory)i;
			let used = (category == .Other) || ((rule != null) && rule.Uses(category));
			if (used && ((cell == null) || ((cell.FormsPresent & (1 << i)) == 0)))
				outMissing.Add(category);
		}
	}

	// ---- The payload ---------------------------------------------------------------------------

	/// The locales (each its id, its plural rule's text when it has one, its direction), then the
	/// keys (each plain or plural, a cell a locale: a text, or the plural forms by category
	/// name). A rule read back that does not parse fails the read.
	public void Serialize(ISerializer ar)
	{
		BeginVersionedPayload(ar, TypeId, DataVersion);
		let reading = ar.Mode == .Read;

		var localeCount = (uint32)mLocales.Count;
		ar.Key("locales");
		ar.BeginArray(ref localeCount);
		if (reading)
			ClearAndDeleteItems!(mLocales);
		for (uint32 i < localeCount)
		{
			let locale = reading ? new LocaleInfo() : mLocales[(int)i];
			let rule = scope String(locale.Rule.Source);
			let direction = scope String(sDirectionNames[(int)locale.Direction]);
			ar.BeginObject();
			Sedulous.Core.Serialization.Serialize(ar, "id", locale.Id);
			SerializeValue(ar, "hasRule", ref locale.HasRule);
			Sedulous.Core.Serialization.Serialize(ar, "rule", rule);
			Sedulous.Core.Serialization.Serialize(ar, "direction", direction);
			ar.EndObject();
			if (reading)
			{
				locale.Direction = DirectionNamed(direction);
				if (locale.HasRule && !locale.Rule.Parse(rule))
					ar.FailPayload(.InvalidArgument);
				mLocales.Add(locale);
			}
		}
		ar.EndArray();

		var entryCount = (uint32)mEntries.Count;
		ar.Key("entries");
		ar.BeginArray(ref entryCount);
		if (reading)
			ClearAndDeleteItems!(mEntries);
		for (uint32 i < entryCount)
		{
			let entry = reading ? new Entry() : mEntries[(int)i];
			ar.BeginObject();
			Sedulous.Core.Serialization.Serialize(ar, "key", entry.Key);
			SerializeValue(ar, "plural", ref entry.Plural);
			var cellCount = (uint32)entry.Cells.Count;
			ar.Key("cells");
			ar.BeginArray(ref cellCount);
			for (uint32 c < cellCount)
			{
				let cell = reading ? new Cell() : entry.Cells[(int)c];
				ar.BeginObject();
				SerializeValue(ar, "present", ref cell.Present);
				Sedulous.Core.Serialization.Serialize(ar, "text", cell.Text);
				SerializeValue(ar, "forms", ref cell.FormsPresent);
				// Each form under its category's name ("one", "other"), so a keyed table reads.
				for (int f < PluralCategory.Count)
				{
					ar.Key(((PluralCategory)f).Name);
					ar.Text(cell.Forms[f]);
				}
				ar.EndObject();
				if (reading)
					entry.Cells.Add(cell);
			}
			ar.EndArray();
			ar.EndObject();
			if (reading)
			{
				// A cell a locale, or the table is not one: the read fails, and the entry keeps a cell
				// for each locale so that a caller not checking the payload cannot index past them
				// (a fuzzer's find).
				if (entry.Cells.Count != mLocales.Count)
				{
					ar.FailPayload(.InvalidArgument);
					while (entry.Cells.Count > mLocales.Count)
					{
						delete entry.Cells.Back;
						entry.Cells.PopBack();
					}
					while (entry.Cells.Count < mLocales.Count)
						entry.Cells.Add(new Cell());
				}
				mEntries.Add(entry);
			}
		}
		ar.EndArray();
		if (reading)
			Reindex();
		EndVersionedPayload(ar);
	}

	private static TextDirection DirectionNamed(StringView name)
	{
		for (int i < sDirectionNames.Count)
		{
			if (sDirectionNames[i] == name)
				return (TextDirection)i;
		}
		return .Unset;
	}

	// ---- Lookup --------------------------------------------------------------------------------

	private int FindLocale(StringView locale)
	{
		for (int i < mLocales.Count)
		{
			if (LocaleId.Same(mLocales[i].Id, locale))
				return i;
		}
		return -1;
	}

	private int EnsureLocale(StringView locale)
	{
		var at = FindLocale(locale);
		if ((at < 0) && AddLocale(locale))
			at = mLocales.Count - 1;
		return at;
	}

	private int FindEntry(StringView key)
	{
		if (mIndex.TryGetValue(HashText(key), let at) && (mEntries[at].Key == key))
			return at;
		// A hash shared by two keys.
		for (int i < mEntries.Count)
		{
			if (mEntries[i].Key == key)
				return i;
		}
		return -1;
	}

	private Entry EnsureEntry(StringView key, bool plural)
	{
		let at = FindEntry(key);
		if (at >= 0)
			return mEntries[at];
		let entry = new Entry();
		entry.Key.Set(key);
		entry.Plural = plural;
		for (int i < mLocales.Count)
			entry.Cells.Add(new Cell());
		mEntries.Add(entry);
		mIndex[HashText(key)] = mEntries.Count - 1;
		return entry;
	}

	private Cell FindCell(StringView key, StringView locale)
	{
		let at = FindEntry(key);
		let column = FindLocale(locale);
		return ((at >= 0) && (column >= 0)) ? mEntries[at].Cells[column] : null;
	}

	private void Reindex()
	{
		mIndex.Clear();
		for (int i < mEntries.Count)
			mIndex[HashText(mEntries[i].Key)] = i;
	}
}
