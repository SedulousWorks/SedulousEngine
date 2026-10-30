using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.Script;
using Sedulous.Script.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Script;

/// The script editor's composition: the asset serializables and the page against the host's script
/// surface. The New Asset creators (one per tier per backend with a cook) are the script pipeline's
/// (ScriptCreators).
static class ScriptEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made; `surface` (borrowed, may be null) is what its API is described
	/// against.
	public static void Register(EditorContext context, AssetPageServicesSource services, ScriptSurface surface)
	{
		ScriptPipeline.RegisterAll();
		context.Pages.Register(new ScriptClassPageFactory(services, surface));

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
