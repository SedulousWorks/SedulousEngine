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
			if (ScriptLanguageCooks.Find(language) == null)
			{
				GlobalLog(.Warning, "Editor: script backend '{}' has NO registered cook, no New-Asset creator", language);
				continue;
			}
			let suffix = scope String();
			ScriptLanguageCooks.ExtensionOf(language, suffix);
			if (suffix.IsEmpty)
				suffix.Set(language);
			AddCreator(context, language, suffix, .Behavior, "Behavior", "NewBehavior");
			AddCreator(context, language, suffix, .Level, "Level", "NewLevel");
			AddCreator(context, language, suffix, .Game, "Game", "NewGame");
		}
	}

	private static void AddCreator(EditorContext context, StringView language, StringView fileSuffix, ScriptTier tier, StringView suffix, StringView baseName)
	{
		let languageId = new String(language);
		let extensionCopy = new String(fileSuffix);
		let stem = new String(baseName);
		context.RegisterCreator(new AssetCreator(scope $"{language} {suffix}", "Scripts", new [=languageId, =extensionCopy, =tier, =stem](ctx, group) =>
			{
				return ScriptAssetCreators.CreateScriptInstance(ctx, group, languageId, extensionCopy, tier, stem);
			} ~ { delete languageId; delete extensionCopy; delete stem; }));
	}
}
