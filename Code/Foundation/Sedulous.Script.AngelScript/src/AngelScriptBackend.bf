using System;
using Sedulous.Script;

namespace Sedulous.Script.AngelScript;

/// The backend's registration: the language id a script asset names, to a runtime.
static class AngelScriptBackend
{
	public const String cLanguage = "angelscript";

	public static void Register()
	{
		// angel-lsp reads as.predefined beside the scripts, so it needs no settings.
		ScriptBackends.Register(cLanguage, => Create, new ScriptEditorTooling("sashi0034.angel-lsp"));
	}

	private static ScriptRuntime Create() => new AngelScriptRuntime();
}
