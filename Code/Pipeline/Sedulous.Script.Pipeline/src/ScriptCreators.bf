using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Script;
using Sedulous.Pipeline.Core;

namespace Sedulous.Script.Pipeline;

/// The script domain's New Asset creators: for every language with a registered cook, a
/// Behavior, a Level and a Game class from the cook's starter for that tier. The source file
/// lands in the sources folder and the asset points at it. Registered AFTER the cooks are.
static class ScriptCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		let languages = scope List<String>();
		defer { ClearAndDeleteItems!(languages); }
		ScriptLanguageCooks.CollectLanguages(languages);
		for (let language in languages)
		{
			let suffix = scope String();
			ScriptLanguageCooks.ExtensionOf(language, suffix);
			if (suffix.IsEmpty)
				suffix.Set(language);
			Add(registry, language, suffix, .Behavior, "Behavior", "NewBehavior");
			Add(registry, language, suffix, .Level, "Level", "NewLevel");
			Add(registry, language, suffix, .Game, "Game", "NewGame");
		}
	}

	/// How many creators Register makes: three per language with a cook.
	public static int CountFor(int languages) => languages * 3;

	private static void Add(AssetCreatorRegistry registry, StringView language, StringView fileSuffix, ScriptTier tier, StringView tierLabel, StringView baseName)
	{
		let languageId = new String(language);
		let suffixCopy = new String(fileSuffix);
		let stem = new String(baseName);
		registry.Register(new AssetCreator(scope $"{language} {tierLabel}", "Scripts", typeof(ScriptClassAsset), new [=languageId, =suffixCopy, =tier, =stem](context) =>
			{
				return CreateScript(context, languageId, suffixCopy, tier, stem);
			} ~ { delete languageId; delete suffixCopy; delete stem; }));
	}

	/// A new class from the language cook's starter for `tier`: the source file under the
	/// sources folder, and the asset pointing at it. Refused without a sources folder.
	public static Instance CreateScript(AssetCreationContext context, StringView languageId, StringView fileSuffix, ScriptTier tier, StringView baseName)
	{
		let target = context.Target;
		if ((target == null) || context.SourcesRoot.IsEmpty)
			return null;
		let cook = ScriptLanguageCooks.Find(languageId);
		if (cook == null)
			return null;
		let name = target.UniqueInstanceName(context.NameOr(baseName), .. scope .());
		let fileName = scope String(name);
		fileName.Append('.');
		fileName.Append(fileSuffix);
		let starter = scope String();
		cook.NewAssetTemplate(tier, starter);
		let path = PathJoin(context.SourcesRoot, fileName, .. scope .());
		if (!(WriteFile(path, .((uint8*)starter.Ptr, starter.Length)) case .Ok))
			return null;
		let instance = target.CreateInstance(name, typeof(ScriptClassAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let asset = scope ScriptClassAsset();
		asset.FileName.Set(fileName);
		asset.Language.Set(languageId);
		if (!(instance.WriteObject(asset) case .Ok))
			return null;
		return instance;
	}
}
