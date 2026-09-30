using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.Script;
using Sedulous.Script.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Script;

/// The script editor's composition: the asset serializables, the page against the host's
/// script surface, and a Behavior, Level and Game creator per backend that has a cook.
static class ScriptEditor
{
	public static void Register(EditorContext context, ScriptSurface surface)
	{
		ScriptPipeline.RegisterAll();
		context.Pages.Register(new ScriptClassPageFactory(surface));

		let languages = scope List<String>();
		defer { ClearAndDeleteItems!(languages); }
		ScriptBackends.CollectLanguages(languages);
		GlobalLog(.Information, "Editor: RegisterScriptEditor: {} script backend(s) in the registry", languages.Count);
		for (let language in languages)
		{
			// The creators are the pipeline's (ScriptCreators), one set per language with a cook.
			if (ScriptLanguageCooks.Find(language) == null)
				GlobalLog(.Warning, "Editor: script backend '{}' has NO registered cook, no New-Asset creator", language);
		}
	}
}
