using System;
using System.Collections;

namespace Sedulous.Script;

/// The backends a host may create a runtime from, by language id. A backend registers
/// itself once at startup; a run resolves the language a script asset names.
static class ScriptBackends
{
	public typealias Factory = function ScriptRuntime();

	private static Dictionary<String, Factory> sFactories = new .() ~ DeleteDictionaryAndKeys!(_);

	public static void Register(StringView language, Factory factory)
	{
		if (sFactories.ContainsKey(scope String(language)))
			return;
		sFactories[new String(language)] = factory;
	}

	/// A new runtime for the language, or null when no backend registered it.
	public static ScriptRuntime Create(StringView language)
	{
		if (sFactories.TryGetValue(scope String(language), let factory))
			return factory();
		return null;
	}

	public static bool Has(StringView language) => sFactories.ContainsKey(scope String(language));
}
