using System;
using System.Collections;

namespace Sedulous.Script;

/// The backends a host may create a runtime from, by language id. A backend registers
/// itself once at startup; a run resolves the language a script asset names.
static class ScriptBackends
{
	public typealias Factory = function ScriptRuntime();

	private static Dictionary<String, Factory> sFactories = new .() ~ DeleteDictionaryAndKeys!(_);
	private static Dictionary<String, ScriptEditorTooling> sTooling = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

	/// `tooling`, what an outside editor needs for the language (null: nothing); OWNERSHIP of it
	/// transfers.
	public static void Register(StringView language, Factory factory, ScriptEditorTooling tooling = null)
	{
		if (sFactories.ContainsKey(scope String(language)))
		{
			delete tooling;
			return;
		}
		sFactories[new String(language)] = factory;
		if (tooling != null)
			sTooling[new String(language)] = tooling;
	}

	/// What an outside editor needs for the language; null when its backend named nothing. The
	/// registry's.
	public static ScriptEditorTooling EditorTooling(StringView language)
	{
		if (sTooling.TryGetValue(scope String(language), let tooling))
			return tooling;
		return null;
	}

	/// A new runtime for the language, or null when no backend registered it.
	public static ScriptRuntime Create(StringView language)
	{
		if (sFactories.TryGetValue(scope String(language), let factory))
			return factory();
		return null;
	}

	public static bool Has(StringView language) => sFactories.ContainsKey(scope String(language));

	/// Every registered language id, in registration order. A host describing its backends,
	/// the MCP script_api say, reads the set live rather than naming languages.
	public static void CollectLanguages(List<String> outLanguages)
	{
		for (let entry in sFactories)
			outLanguages.Add(new String(entry.key));
	}
}

/// What VS Code needs for a language: the extension that reads its declarations
/// (ScriptRuntime.Declarations), as publisher.name, and the workspace settings that point it at
/// them, each a key and its value as JSON text. Empty: none.
class ScriptEditorTooling
{
	public String VscodeExtension = new .() ~ delete _;
	public List<(String Key, String Json)> VscodeSettings = new .() ~ { for (let setting in _) { delete setting.Key; delete setting.Json; } delete _; };

	public this(StringView vscodeExtension)
	{
		VscodeExtension.Set(vscodeExtension);
	}

	/// Adds a setting, its value JSON text as written into settings.json.
	public Self AddVscodeSetting(StringView key, StringView json)
	{
		VscodeSettings.Add((new String(key), new String(json)));
		return this;
	}
}
