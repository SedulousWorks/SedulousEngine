using System;
using System.Collections;

namespace Sedulous.UI.Toolkit;

/// Language name to lexer factory.
///
/// THE TOOLKIT SHIPS NO LANGUAGE TABLES. A module that owns a language registers it here beside
/// whatever else it contributes, the same layering the completion providers use. A page with
/// static knowledge of its one format builds its lexer directly instead and never comes here.
///
/// Names are compared WITHOUT case, because they arrive from file extensions and configuration
/// where the case is not anybody's decision.
static class CodeLexerRegistry
{
	private class Entry
	{
		public String Id = new .() ~ delete _;
		/// OWNED.
		public delegate ICodeLexer() Factory ~ delete _;
	}

	private static List<Entry> sEntries = new .() ~ DeleteContainerAndItems!(_);

	/// CONSUMES the factory. The LAST registration for a name wins, so a module may override
	/// one registered before it.
	public static void Register(StringView languageId, delegate ICodeLexer() factory)
	{
		for (let entry in sEntries)
		{
			if (!EqualsIgnoringAsciiCase(entry.Id, languageId))
				continue;

			delete entry.Factory;
			entry.Factory = factory;
			return;
		}

		let entry = new Entry();
		entry.Id.Set(languageId);
		entry.Factory = factory;
		sEntries.Add(entry);
	}

	/// OWNERSHIP transfers. Null for an unknown name, which leaves the text unstyled rather
	/// than failing: an editor should still open a file whose language nobody registered.
	public static ICodeLexer Create(StringView languageId)
	{
		for (let entry in sEntries)
		{
			if (EqualsIgnoringAsciiCase(entry.Id, languageId))
				return entry.Factory();
		}

		return null;
	}

	/// Forgets every registration. For tests, which must not leak one another's languages.
	public static void Clear() => ClearAndDeleteItems!(sEntries);

	private static bool EqualsIgnoringAsciiCase(StringView a, StringView b)
	{
		if (a.Length != b.Length)
			return false;

		for (int i = 0; i < a.Length; i++)
		{
			if (FoldAsciiCase(a[i]) != FoldAsciiCase(b[i]))
				return false;
		}

		return true;
	}

	private static char8 FoldAsciiCase(char8 c) => ((c >= 'A') && (c <= 'Z')) ? (char8)(c + 32) : c;
}
