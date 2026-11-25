using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.VFS;
using Sedulous.Input.Pipeline;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Composition;

namespace Dialogue;

/// A dialogue file: a `.dialogue` text in the project's sources, which the cook parses and checks.
[Category("Dialogue")]
[DisplayName("Dialogue")]
[Serializable]
class DialogueAsset : Asset
{
}

/// The project's cast, edited in the inspector: the speakers its conversations name.
[Category("Dialogue")]
[DisplayName("Dialogue Cast")]
[Serializable]
class DialogueCastAsset : Asset
{
	[DisplayName("Speakers")]
	public List<DialogueSpeaker> Speakers = new .() ~ DeleteContainerAndItems!(_);
}

/// The project's dialogue assets, edited in the inspector: the sounds, sequences and other assets
/// its conversations name, each by a name of its own, so a rename or a move breaks no conversation.
[Category("Dialogue")]
[DisplayName("Dialogue Assets")]
[Serializable]
class DialogueAssetListAsset : Asset
{
	[DisplayName("Assets")]
	public List<DialogueAssetEntry> Entries = new .() ~ DeleteContainerAndItems!(_);
}

/// The dialogue's asset types' registration, which the Pipeline part's load runs (recorded and
/// reversed).
[SerializableRegistry]
static class DialoguePipelineTypes
{
}

/// A dialogue file's project: what its checks read, gathered from a source database and the
/// sources it links. Cook and tools build it the same way.
class DialogueProject
{
	public List<DialogueCommandForm> Commands = new .() ~ DeleteContainerAndItems!(_);
	/// A command whose form is not one (line 0).
	public List<DialogueProblem> SettingsProblems = new .() ~ DeleteContainerAndItems!(_);
	public List<DialogueSpeaker> Cast = new .() ~ DeleteContainerAndItems!(_);
	public bool HasCast;
	public List<DialogueAssetEntry> DialogueAssets = new .() ~ DeleteContainerAndItems!(_);
	public bool HasDialogueAssets;
	/// Every other file's.
	public List<String> Conversations = new .() ~ DeleteContainerAndItems!(_);
	public List<String> LineIds = new .() ~ DeleteContainerAndItems!(_);
	public List<String> FlagsSet = new .() ~ DeleteContainerAndItems!(_);
	/// Every other dialogue file's asset.
	public List<Guid> Files = new .() ~ delete _;
	/// Every input map's actions.
	public List<String> Actions = new .() ~ DeleteContainerAndItems!(_);
	public bool HasInputMap;
	public List<Guid> InputMaps = new .() ~ delete _;

	/// Gathers it for the file `self` (nil for none) from `db`, reading the other files' sources
	/// through `reader`'s sources.
	public void Gather(DialogueSettings settings, IContentDatabase db, AssetBuildContext reader, Guid self)
	{
		let error = scope String();
		for (let text in settings.Commands)
		{
			let form = new DialogueCommandForm();
			error.Clear();
			if (!DialogueFormat.ParseCommandForm(text, form, error))
			{
				SettingsProblems.Add(new .(0, scope $"the dialogue settings' command `{text}`: {error}"));
				delete form;
				continue;
			}
			for (let other in Commands)
			{
				if (other.Name == form.Name)
					SettingsProblems.Add(new .(0, scope $"the dialogue settings declare two commands named `{form.Name}`"));
			}
			Commands.Add(form);
		}
		if (settings.Cast != .())
		{
			let read = db.ReadObject(settings.Cast);
			defer { delete read; }
			if (let castAsset = read as DialogueCastAsset)
			{
				Swap!(Cast, castAsset.Speakers);
				HasCast = true;
			}
		}
		if (settings.Assets != .())
		{
			let read = db.ReadObject(settings.Assets);
			defer { delete read; }
			if (let list = read as DialogueAssetListAsset)
			{
				Swap!(DialogueAssets, list.Entries);
				HasDialogueAssets = true;
			}
		}
		if (let root = db.RootGroup)
		{
			let maps = scope List<Instance>();
			InstancesOf(root, typeof(InputMapAsset), maps);
			for (let instance in maps)
			{
				let read = db.ReadObject(instance.Id);
				defer { delete read; }
				let map = read as InputMapAsset;
				if (map == null)
					continue;
				HasInputMap = true;
				InputMaps.Add(instance.Id);
				for (let set in map.Map.Sets)
				{
					for (let action in set.Actions)
						Actions.Add(new .(action.Name));
				}
			}
			let files = scope List<Instance>();
			DialogueAssetsOf(root, files);
			let text = scope String();
			for (let instance in files)
			{
				if (instance.Id == self)
					continue;
				Files.Add(instance.Id);
				let read = db.ReadObject(instance.Id);
				defer { delete read; }
				let other = read as DialogueAsset;
				text.Clear();
				if ((other == null) || (AssetSource.ReadText(reader, other.FileName.Value, text) case .Err))
					continue; // its own cook says so
				let parse = scope DialogueParse();
				DialogueFormat.ParseDialogue(text, Commands, parse);
				let flagsRead = scope List<String>(); // what a file reads is no other file's business
				defer { ClearAndDeleteItems!(flagsRead); }
				DialogueChecks.CollectDialogueFacts(parse, Conversations, LineIds, FlagsSet, flagsRead);
			}
		}
	}

	/// Every dialogue file's instance under `group`, its subgroups included.
	public static void DialogueAssetsOf(Group group, List<Instance> outInstances) => InstancesOf(group, typeof(DialogueAsset), outInstances);

	/// Every instance of the asset type `type` under `group`, its subgroups included.
	public static void InstancesOf(Group group, Type type, List<Instance> outInstances)
	{
		let typeName = type.GetFullName(.. scope .());
		InstancesNamed(group, typeName, outInstances);
	}

	static void InstancesNamed(Group group, StringView typeName, List<Instance> outInstances)
	{
		for (let instance in group.Instances)
		{
			if (instance.TypeName == typeName)
				outInstances.Add(instance);
		}
		for (let child in group.Groups)
			InstancesNamed(child, typeName, outInstances);
	}
}

/// The project's assets by guid, as the checks ask for them: an asset's name, and its type by its
/// short name ("AudioClipAsset"), as the checks and the forms' `asset(Type)` name types.
class DatabaseDialogueAssets : IDialogueAssets
{
	IContentDatabase mDb; // the caller's

	public this(IContentDatabase db)
	{
		mDb = db;
	}

	public void NameOf(Guid id, String outName)
	{
		if (let instance = mDb.GetInstance(id))
			outName.Append(instance.Name);
	}

	public void TypeOf(Guid id, String outType)
	{
		if (let instance = mDb.GetInstance(id))
		{
			StringView name = instance.TypeName;
			let dot = name.LastIndexOf('.');
			outType.Append((dot >= 0) ? name.Substring(dot + 1) : name);
		}
	}
}

/// The levels conversations name, each loaded once into a scratch scene (its prefabs placed, as a
/// load places them) for its entities' names.
class LoadedLevels : IDialogueLevels
{
	class Loaded
	{
		public Guid Level;
		public List<String> Names = new .() ~ DeleteContainerAndItems!(_);
		public bool Ok;
	}

	IContentDatabase mDb; // the caller's
	List<Loaded> mLoaded = new .() ~ DeleteContainerAndItems!(_);

	public this(IContentDatabase db)
	{
		mDb = db;
	}

	public List<String> EntityNames(Guid level)
	{
		for (let loaded in mLoaded)
		{
			if (loaded.Level == level)
				return loaded.Ok ? loaded.Names : null;
		}
		let loaded = new Loaded();
		loaded.Level = level;
		mLoaded.Add(loaded);
		let instance = mDb.GetInstance(level);
		if (instance == null)
			return null;
		let scratch = scope Scene("__dialogue_level");
		EngineSceneComposition.AddAllSceneManagers(scratch);
		if (SceneStorage.LoadScene(instance, scratch) case .Err)
			return null;
		if (scratch.PendingPrefabInstanceCount > 0)
		{
			// The spawn owns each stream it is handed; a nested prefab resolves through the same
			// reader, one level at a time.
			let db = mDb;
			ScenePrefabs.PayloadResolver resolver = scope (prefabId) =>
			{
				let prefab = db.GetInstance(prefabId);
				return (prefab != null) ? prefab.ReadData(SceneExportSupport.cSceneStream) : null;
			};
			ScenePrefabs.ResolveScenePrefabs(scratch, resolver);
		}
		scratch.ForEachEntity(scope [&](entity) => { loaded.Names.Add(new .(scratch.GetEntityName(entity))); });
		loaded.Ok = true;
		return loaded.Names;
	}
}

static class DialogueCook
{
	/// Parses `text` into `outParse` and checks it against `project`, its assets reached through
	/// `db` (null: their names and types are not checked) and the levels its conversations name
	/// loaded into scratch scenes from it.
	public static void CookDialogue(StringView text, DialogueSettings settings, DialogueProject project, IContentDatabase db,
		DialogueParse outParse)
	{
		DialogueFormat.ParseDialogue(text, project.Commands, outParse);
		for (let problem in project.SettingsProblems)
			outParse.Problems.Add(new .(problem.Line, problem.Message, problem.Warning));
		let assets = (db != null) ? scope:: DatabaseDialogueAssets(db) : null;
		let levels = (db != null) ? scope:: LoadedLevels(db) : null;
		let inputs = scope DialogueCheckInputs();
		inputs.Cast = project.HasCast ? project.Cast : null;
		inputs.DialogueAssets = project.HasDialogueAssets ? project.DialogueAssets : null;
		inputs.Commands = project.Commands;
		inputs.ProvidedFlags = settings.ProvidedFlags;
		inputs.OtherConversations = project.Conversations;
		inputs.OtherLineIds = project.LineIds;
		inputs.OtherFlagsSet = project.FlagsSet;
		inputs.Assets = assets;
		inputs.Actions = project.HasInputMap ? project.Actions : null;
		inputs.Levels = levels;
		DialogueChecks.CheckDialogue(outParse, inputs);
	}

	/// The source database the cook reads asset envelopes from: a scan's context carries it as
	/// Database, a build's as SourceDatabase.
	public static IContentDatabase SourceDatabase(AssetBuildContext context) =>
		(context.SourceDatabase != null) ? context.SourceDatabase : context.Database;
}

/// Cooks a dialogue file: gathers the project (the settings' commands, the cast, the dialogue
/// assets and what the other dialogue files hold), parses and checks the file, logs each problem
/// at its line, and writes the conversations, or fails on an error.
class DialogueBuilder : IAssetBuilder
{
	DialogueSettings mSettings; // the plugin's, held by the host while the plugin is loaded

	public this(DialogueSettings settings)
	{
		mSettings = settings;
	}

	public Type AssetType => typeof(DialogueAsset);
	public Type ProductType => typeof(DialogueSource);

	/// What the checks read from the settings: a change recooks every dialogue file.
	public uint64 EnvironmentHash
	{
		get
		{
			var cast = mSettings.Cast;
			var assets = mSettings.Assets;
			var hash = HashBytes(&cast, sizeof(Guid));
			hash = HashBytes(&assets, sizeof(Guid), hash);
			char8 separator = '\n';
			for (let form in mSettings.Commands)
			{
				hash = HashBytes(form.Ptr, form.Length, hash);
				hash = HashBytes(&separator, 1, hash);
			}
			for (let flag in mSettings.ProvidedFlags)
			{
				hash = HashBytes(flag.Ptr, flag.Length, hash);
				hash = HashBytes(&separator, 1, hash);
			}
			return hash;
		}
	}

	/// The cast, the dialogue assets, the input maps and every other dialogue file are read: a
	/// change to any of them can change what this file's checks find.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let db = DialogueCook.SourceDatabase(context);
		if (db == null)
			return;
		if (mSettings.Cast != .())
			outDeps.Reads.Add(mSettings.Cast);
		if (mSettings.Assets != .())
			outDeps.Reads.Add(mSettings.Assets);
		let self = (context.Source != null) ? context.Source.Id : Guid();
		if (let root = db.RootGroup)
		{
			let maps = scope List<Instance>();
			DialogueProject.InstancesOf(root, typeof(InputMapAsset), maps);
			for (let instance in maps)
				outDeps.Reads.Add(instance.Id);
			let files = scope List<Instance>();
			DialogueProject.DialogueAssetsOf(root, files);
			for (let instance in files)
			{
				if (instance.Id == self)
					continue;
				outDeps.Reads.Add(instance.Id);
				let read = db.ReadObject(instance.Id);
				defer { delete read; }
				if (let other = read as DialogueAsset)
					outDeps.AddFile(other.FileName.Value);
			}
		}
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		StringView file = asset.FileName.Value;
		let text = scope String();
		if (AssetSource.ReadText(context, file, text) case .Err(let readError))
		{
			GlobalLog(.Error, "Dialogue: '{}': the dialogue file is missing", file);
			return .Err(readError);
		}
		let db = DialogueCook.SourceDatabase(context);
		let project = scope DialogueProject();
		if (db != null)
			project.Gather(mSettings, db, context, (context.Source != null) ? context.Source.Id : Guid());
		let parse = scope DialogueParse();
		DialogueCook.CookDialogue(text, mSettings, project, db, parse);
		for (let problem in parse.Problems)
			GlobalLog(problem.Warning ? .Warning : .Error, "Dialogue: {}:{}: {}", file, problem.Line, problem.Message);
		if (!parse.Ok)
			return .Err(.InvalidArgument);
		let cooked = scope DialogueSource();
		Swap!(cooked.Conversations, parse.Conversations);
		Swap!(cooked.Lines, parse.Lines);
		return context.Output.WriteObject(cooked);
	}
}

/// Cooks the cast to its speakers.
class DialogueCastBuilder : IAssetBuilder
{
	public Type AssetType => typeof(DialogueCastAsset);
	public Type ProductType => typeof(DialogueCastSource);

	/// What the cast refers to at run time: its portraits, clips and sounds must exist.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let cast = (DialogueCastAsset)asset;
		void Refer(Guid id)
		{
			if (id != .())
				outDeps.References.Add(id);
		}
		for (let speaker in cast.Speakers)
		{
			Refer(speaker.Portrait);
			Refer(speaker.Talk);
			Refer(speaker.Voice);
			for (let mood in speaker.Moods)
				Refer(mood.Portrait);
			for (let clip in speaker.Clips)
				Refer(clip);
		}
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		// The cooked form borrows the asset's speakers for the write and gives them back.
		let cooked = scope DialogueCastSource();
		cooked.Speakers.AddRange(((DialogueCastAsset)asset).Speakers);
		defer cooked.Speakers.Clear();
		return context.Output.WriteObject(cooked);
	}
}

/// Imports a `.dialogue` file: copied into the sources, a DialogueAsset linking it.
class DialogueFileImporter : IFileImporter
{
	public StringView Label => "Dialogue";

	public bool Accepts(StringView @extension) => @extension == "dialogue";

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared, ImportPlan outPlan)
		=> ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath, DialogueCreators.TypeName, outPlan);

	public StringView AssetTypeName(StringView sourcePath) => DialogueCreators.TypeName;

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context, Group group, ImportOptions options,
		Object prepared, List<DeferredImportWrite> deferredWrites)
	{
		let fileName = scope String();
		let claimed = ImportPaths.ClaimSingleAsset(context, group, options, sourcePath, DialogueCreators.TypeName, fileName);
		if (claimed case .Err(let claimError))
			return .Err(claimError);
		let instance = claimed.Value;
		let asset = scope DialogueAsset();
		asset.FileName.Set(fileName);
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}

/// File > New's three creators, and the names the dialogue's asset types go by.
static class DialogueCreators
{
	/// The creators' labels, as File > New and asset_create name them.
	public const String cDialogueCreator = "Dialogue";
	public const String cDialogueCastCreator = "Dialogue Cast";
	public const String cDialogueAssetsCreator = "Dialogue Assets";

	/// A dialogue file's type name, as instances record it.
	public const String TypeName = "Dialogue.DialogueAsset";

	const String cStarter = "# One statement a line. A conversation starts with its id, then its lines:\n" +
		"#\n" +
		"# conversation greeting\n" +
		"# @ speaker mood: What the speaker says.\n";

	public static void AddCreators(PipelinePluginServices services)
	{
		services.AddCreator(new AssetCreator(cDialogueCreator, "Dialogue", typeof(DialogueAsset), new (context) => CreateDialogueFile(context)).Under("Dialogue"));
		services.AddCreator(new AssetCreator(cDialogueCastCreator, "Dialogue", typeof(DialogueCastAsset), new (context) =>
			{
				let target = context.Target;
				if (target == null)
					return null;
				let instance = target.CreateInstance(target.UniqueInstanceName(context.NameOr("Cast"), .. scope .()), typeof(DialogueCastAsset).GetFullName(.. scope .()));
				if ((instance == null) || (instance.WriteObject(scope DialogueCastAsset()) case .Err))
					return null;
				return instance;
			}).Under("Dialogue"));
		services.AddCreator(new AssetCreator(cDialogueAssetsCreator, "Dialogue", typeof(DialogueAssetListAsset), new (context) =>
			{
				let target = context.Target;
				if (target == null)
					return null;
				let instance = target.CreateInstance(target.UniqueInstanceName(context.NameOr("Dialogue Assets"), .. scope .()), typeof(DialogueAssetListAsset).GetFullName(.. scope .()));
				if ((instance == null) || (instance.WriteObject(scope DialogueAssetListAsset()) case .Err))
					return null;
				return instance;
			}).Under("Dialogue"));
	}

	/// A new dialogue file from the starter text in the target group's folder under the sources
	/// (the next free name when another file has that one), and the asset pointing at it. Refused
	/// without a sources folder or for a name that is not one file name.
	static Instance CreateDialogueFile(AssetCreationContext context)
	{
		let target = context.Target;
		if ((target == null) || context.SourcesRoot.IsEmpty)
			return null;
		let name = target.UniqueInstanceName(context.NameOr("Dialogue"), .. scope .());
		let fileName = scope String();
		if (!AssetCreator.FreeSourceFileName(context, target, name, ".dialogue", fileName))
			return null;
		let path = context.FileOf(fileName, .. scope .());
		CreateDirectory(PathParent(path, .. scope .()));
		if (WriteFile(path, Span<uint8>((uint8*)cStarter.Ptr, cStarter.Length)) case .Err)
			return null;
		let instance = target.CreateInstance(name, TypeName);
		if (instance == null)
			return null;
		let asset = scope DialogueAsset();
		asset.FileName.Set(fileName);
		if (instance.WriteObject(asset) case .Err)
			return null;
		return instance;
	}
}
