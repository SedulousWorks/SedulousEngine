using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Script;
using Sedulous.Pipeline.Core;
using Sedulous.VFS;

namespace Sedulous.Script.Pipeline;

/// The script domain's New Asset creators: for every language with a registered cook, a
/// Behavior, a Level and a Game class from the cook's starter for that tier, and for one whose
/// classes build together its project file too. The source file lands in the sources folder and
/// the asset points at it. Registered AFTER the cooks are.
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
			// A language whose classes build together needs its project file: one creator for it,
			// seeded from the project build's template.
			let project = ScriptAssemblyCooks.Find(language);
			if (project != null)
				AddProject(registry, language, project.ProjectExtension);
		}
	}

	/// How many creators Register makes: three per language with a cook, and one more for each of
	/// those whose classes build in a project.
	public static int CountFor(int languages, int projectLanguages) => languages * 3 + projectLanguages;

	private static void AddProject(AssetCreatorRegistry registry, StringView language, StringView projectSuffix)
	{
		let languageId = new String(language);
		let suffixCopy = new String(projectSuffix);
		registry.Register(new AssetCreator(scope $"{language} Project", "Scripts", typeof(ScriptAssemblyAsset), new [=languageId, =suffixCopy](context) =>
			{
				return CreateProject(context, languageId, suffixCopy);
			} ~ { delete languageId; delete suffixCopy; }));
	}

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

	/// A behaviour's class name from its asset's name: the letters, digits and underscores, a
	/// leading digit prefixed with an underscore; `fallback` when nothing is left. So a script
	/// asset and the class it holds share a name ("Player Controller" holds PlayerController).
	public static void ClassNameFor(StringView assetName, StringView fallback, String outClass)
	{
		for (let c in assetName)
		{
			if (c.IsLetterOrDigit || (c == '_'))
				outClass.Append(c);
		}
		if (outClass.IsEmpty)
			outClass.Set(fallback);
		else if (outClass[0].IsDigit)
			outClass.Insert(0, '_');
	}

	/// A new class from the language cook's starter for `tier`: the source file in the project's
	/// Code/ folder, in its group's folder there (the next free name when another file has that
	/// one), and the asset pointing at it. Refused without a sources folder or for a name that is
	/// not one file name.
	public static Instance CreateScript(AssetCreationContext context, StringView languageId, StringView fileSuffix, ScriptTier tier, StringView baseName)
	{
		let target = context.Target;
		if ((target == null) || context.SourcesRoot.IsEmpty)
			return null;
		let cook = ScriptLanguageCooks.Find(languageId);
		if (cook == null)
			return null;
		let name = target.UniqueInstanceName(context.NameOr(baseName), .. scope .());
		let fileName = scope String();
		if (!AssetCreator.FreeSourceFileName(context, target, name, scope $".{fileSuffix}", fileName, SourcePath.CodeFolder))
			return null;
		let starter = scope String();
		let className = ClassNameFor(name, baseName, .. scope .());
		cook.NewAssetTemplate(tier, className, starter);
		let path = context.FileOf(fileName, .. scope .());
		CreateDirectory(PathParent(path, .. scope .()));
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

	/// A new project file for a language whose classes build together: the project build's
	/// template in the project's Code/ folder, in its group's folder there (the next free name
	/// when another file has that one), its ScriptAssemblyAsset, and the build's local files
	/// beside it, so the project opens
	/// in an IDE at once rather than after its first cook. Null when the language has no project
	/// build, without a sources folder, or when a write is refused.
	public static Instance CreateProject(AssetCreationContext context, StringView languageId, StringView projectSuffix)
	{
		let target = context.Target;
		if ((target == null) || context.SourcesRoot.IsEmpty)
			return null;
		let cook = ScriptAssemblyCooks.Find(languageId);
		if (cook == null)
			return null;
		let name = target.UniqueInstanceName(context.NameOr("Game"), .. scope .());
		let fileName = scope String();
		if (!AssetCreator.FreeSourceFileName(context, target, name, scope $".{projectSuffix}", fileName, SourcePath.CodeFolder))
			return null;
		let text = scope String();
		cook.NewProjectTemplate(ClassNameFor(name, "Game", .. scope .()), text);
		let path = context.FileOf(fileName, .. scope .());
		CreateDirectory(PathParent(path, .. scope .()));
		if (!(WriteFile(path, .((uint8*)text.Ptr, text.Length)) case .Ok))
			return null;
		let instance = target.CreateInstance(name, typeof(ScriptAssemblyAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let asset = scope ScriptAssemblyAsset();
		asset.FileName.Set(fileName);
		asset.Language.Set(languageId);
		if (!(instance.WriteObject(asset) case .Ok))
			return null;

		// Beside the project file, in its folder.
		let folder = PathParent(fileName, .. scope .());
		let local = scope List<ScriptAssemblyFile>();
		defer { ClearAndDeleteItems!(local); }
		cook.LocalFiles(local);
		for (let file in local)
		{
			let localPath = context.FileOf(PathJoin(folder, file.Path, .. scope .()), .. scope .());
			CreateDirectory(PathParent(localPath, .. scope .()));
			WriteFile(localPath, .((uint8*)file.Text.Ptr, file.Text.Length)).IgnoreError();
		}
		return instance;
	}
}
