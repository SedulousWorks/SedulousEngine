using System;
using System.Collections;

namespace Sedulous.Script.Pipeline;

/// The cooks registered, by language id, and the file extensions they claim.
static class ScriptLanguageCooks
{
	private class Entry
	{
		public String Language = new .() ~ delete _;
		public String Extension = new .() ~ delete _;
		public IScriptLanguageCook Cook ~ delete _;
	}

	private static List<Entry> sEntries = new .() ~ DeleteContainerAndItems!(_);

	/// TAKES OWNERSHIP of the cook. `suffix` is the file extension, lowercase, without the dot.
	public static void Register(StringView language, StringView suffix, IScriptLanguageCook cook)
	{
		for (let entry in sEntries)
		{
			if (entry.Language == language)
			{
				delete cook;
				return;
			}
		}
		let entry = new Entry();
		entry.Language.Set(language);
		entry.Extension.Set(suffix);
		entry.Cook = cook;
		sEntries.Add(entry);
	}

	public static IScriptLanguageCook Find(StringView language)
	{
		for (let entry in sEntries)
		{
			if (entry.Language == language)
				return entry.Cook;
		}
		return null;
	}

	/// The language a file extension belongs to, empty when none claims it.
	public static void LanguageOf(StringView suffix, String outLanguage)
	{
		outLanguage.Clear();
		for (let entry in sEntries)
		{
			if (entry.Extension == suffix)
			{
				outLanguage.Set(entry.Language);
				return;
			}
		}
	}

	/// Every cook's version summed, for the builder's own.
	public static int32 VersionSum
	{
		get
		{
			int32 sum = 0;
			for (let entry in sEntries)
				sum += entry.Cook.CookVersion;
			return sum;
		}
	}

	/// Tests only: drops every registration.
	public static void Clear() => ClearAndDeleteItems!(sEntries);
}
