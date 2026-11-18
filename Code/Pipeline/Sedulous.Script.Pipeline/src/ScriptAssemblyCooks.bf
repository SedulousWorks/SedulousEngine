using System;
using System.Collections;

namespace Sedulous.Script.Pipeline;

/// The project builds registered, by language id, for the languages whose classes build
/// together; each claims its project file's extension.
static class ScriptAssemblyCooks
{
	private class Entry
	{
		public String Language = new .() ~ delete _;
		public IScriptAssemblyCook Cook ~ delete _;
	}

	private static List<Entry> sEntries = new .() ~ DeleteContainerAndItems!(_);

	/// TAKES OWNERSHIP of the cook. A language registered already keeps its first.
	public static void Register(StringView language, IScriptAssemblyCook cook)
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
		entry.Cook = cook;
		sEntries.Add(entry);
	}

	public static IScriptAssemblyCook Find(StringView language)
	{
		for (let entry in sEntries)
		{
			if (entry.Language == language)
				return entry.Cook;
		}
		return null;
	}

	/// The language whose project files have `suffix` (lowercase, no dot); empty for none.
	public static void LanguageOfProject(StringView suffix, String outLanguage)
	{
		outLanguage.Clear();
		for (let entry in sEntries)
		{
			if (entry.Cook.ProjectExtension == suffix)
			{
				outLanguage.Set(entry.Language);
				return;
			}
		}
	}

	/// Every project build's version summed, for the project builder's own.
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

	/// Drops every registration: a host's teardown, and tests.
	public static void Clear() => ClearAndDeleteItems!(sEntries);
}
