using System;
using Sedulous.Script;

namespace Sedulous.Script.AngelScript;

/// The backend's registration: the language id a script asset names, to a runtime.
static class AngelScriptBackend
{
	public const String cLanguage = "angelscript";

	public static void Register()
	{
		ScriptBackends.Register(cLanguage, => Create);
	}

	private static ScriptRuntime Create() => new AngelScriptRuntime();
}
