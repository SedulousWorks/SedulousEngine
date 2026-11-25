using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Runtime;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Resource;
using Sedulous.Input;
using Sedulous.Engine.Run;
using Sedulous.Engine.Behavior;
using Dialogue;

namespace Sedulous.Integration.Plugins;

/// The dialogue plugin's assets cooked through the standalone MCP host's tools, as an agent or the
/// editor cooks them. A project enables the plugin; its dialogue files each name their cast and
/// dialogue assets. A file that names only what the project has cooks to its compiled
/// conversations, one with an error (a jump to a conversation the other file lacks among them)
/// fails the cook, and File > New's three creators make their assets, a new dialogue file taking
/// the settings' default cast and dialogue assets. Conversation ids are a file's own: two files may
/// share one, and a jump into another file names it by its dialogue asset.
static class DialogueCookTests
{
	/// A dialogue file in the project's sources and its asset, naming `cast` and `assets`; its guid.
	static Guid AddDialogueFile(EditorProject project, Group group, StringView name, StringView text, Guid cast, Guid assets)
	{
		let fileName = scope $"Dialogue/{name}.dialogue";
		let path = project.SourceFile(fileName, .. scope .());
		CreateDirectory(PathParent(path, .. scope .()));
		Test.Assert(WriteFile(path, Span<uint8>((uint8*)text.Ptr, text.Length)) case .Ok);
		let instance = group.CreateInstance(name, typeof(DialogueAsset).GetFullName(.. scope .()));
		Test.Assert(instance != null);
		let asset = scope DialogueAsset();
		asset.FileName.Set(fileName);
		asset.Cast = cast;
		asset.Assets = assets;
		Test.Assert(instance.WriteObject(asset) case .Ok);
		return instance.Id;
	}

	/// A scratch project enabling dialogue: its cast (a keeper and a visitor), its dialogue assets (the
	/// second file, as `lane`) and two clean dialogue files naming them, the first jumping into the
	/// second, both with a conversation `gate`, the second jumping within itself by its own name; the settings declare a command and a provided flag,
	/// and name the cast and the assets as a new file's defaults. The first file's guid.
	static Guid MakeProject(StringView dir, out Guid lane, out Guid castId, out Guid assetsId)
	{
		RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Dialogue Cook") case .Ok);
		let project = EditorProject.Open(dir);
		defer delete project;
		let root = project.SourceDb.RootGroup;

		let castInstance = root.CreateInstance("Cast", typeof(DialogueCastAsset).GetFullName(.. scope .()));
		let cast = scope DialogueCastAsset();
		let keeper = new DialogueSpeaker();
		keeper.Id.Set("keeper");
		keeper.ShownName.Set("The Keeper");
		keeper.Moods.Add(new .("neutral", .()));
		keeper.Moods.Add(new .("worried", .()));
		cast.Speakers.Add(keeper);
		let visitor = new DialogueSpeaker();
		visitor.Id.Set("visitor");
		cast.Speakers.Add(visitor);
		Test.Assert(castInstance.WriteObject(cast) case .Ok);

		let listInstance = root.CreateInstance("Dialogue Assets", typeof(DialogueAssetListAsset).GetFullName(.. scope .()));

		let gate = AddDialogueFile(project, root, "Gate",
			"conversation gate\n" +
			"@ keeper worried: Who goes there?\n" +
			"choice\n" +
			"> A friend.\n" +
			"  set friendly\n" +
			"> Nobody. #line:nobody\n" +
			"end\n" +
			"if seen_gate\n" +
			"  @ visitor: Again.\n" +
			"end\n" +
			"cue lights dim\n" +
			"jump lane in lane\n",
			castInstance.Id, listInstance.Id);
		lane = AddDialogueFile(project, root, "Lane",
			"conversation gate\n" +
			"@ visitor: The other gate.\n" +
			"jump lane in lane\n" +
			"conversation lane\n" +
			"@ visitor: Down the lane.\n",
			castInstance.Id, listInstance.Id);
		let list = scope DialogueAssetListAsset();
		list.Entries.Add(new .("lane", lane));
		list.Entries.Add(new .("gate", gate)); // the first file's own, which it does not refer to
		Test.Assert(listInstance.WriteObject(list) case .Ok);
		castId = castInstance.Id;
		assetsId = listInstance.Id;

		let settings = scope DialogueSettings();
		settings.Cast = castInstance.Id;
		settings.Assets = listInstance.Id;
		settings.Commands.Add(new .("cue <event:text>"));
		settings.ProvidedFlags.Add(new .("seen_*"));
		let entry = new EnabledPlugin();
		entry.Id.Set("dialogue");
		Test.Assert(EnabledPlugin.WriteSettings(settings, entry.Settings) case .Ok);
		project.Settings.Plugins.Add(entry);
		Test.Assert(project.SaveSettings() case .Ok);
		return gate;
	}

	[Test]
	public static void ADialogueFileCooksToItsConversationsOneWithAnErrorDoesNotAndFileNewMakesTheDialoguesAssets()
	{
		let cwd = Directory.GetCurrentDirectory(.. scope .());
		let dir = PathJoin(cwd, "scratch_plugins_dialogue_cook", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Guid lane, castId, assetsId;
		let gate = MakeProject(dir, out lane, out castId, out assetsId);

		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		let creators = scope AssetCreatorRegistry();
		let pluginTools = scope McpPluginServices();
		let server = scope McpServer();
		server.Paths.AddFolder(cwd);
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		owner.PluginRegistries = PipelineRegistries(builders, importers, creators);
		owner.PluginTools = pluginTools;
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetWriteTools.Register(server, session, importers, operations);
		AssetCreateTools.Register(server, session, creators, operations);
		ProjectOpenTools.Register(server, session, owner);
		pluginTools.AttachServer(server, session);

		let text = scope String();
		Test.Assert(Call(server, "project_open", Arguments("directory", dir), text), text);
		Test.Assert((session.Plugins != null) && session.Plugins.IsLoaded("dialogue"));
		Test.Assert(builders.Find(typeof(DialogueAsset)) != null);
		Test.Assert(builders.Find(typeof(DialogueCastAsset)) != null);

		// The clean file cooks: its conversation compiled, its texts by line id; the cast cooks too.
		Test.Assert(Call(server, "asset_cook", JsonValue.MakeObject(), text..Clear()), text);
		{
			let cooked = JsonValue.Parse(text);
			defer delete cooked;
			Test.Assert(cooked.Get("failed").AsInt() == 0, text);
		}
		{
			let read = session.Project.CookedDb.ReadObject(gate);
			defer delete read;
			let source = read as DialogueSource;
			Test.Assert((source != null) && (source.Conversations.Count == 1));
			Test.Assert(source.Cast == castId, "the runner loads it for the lines' speakers");
			let conversation = source.Conversations[0];
			Test.Assert(conversation.Id == "gate");
			Test.Assert(conversation.Steps[0].Kind == .Line);
			Test.Assert(conversation.Steps.Back.Kind == .End);
			let jump = conversation.Steps[conversation.Steps.Count - 2];
			Test.Assert(jump.Kind == .Jump);
			Test.Assert(jump.Name == "lane");
			Test.Assert(jump.Asset == lane);
			bool cue = false;
			for (let step in conversation.Steps)
				cue |= (step.Kind == .Command) && (step.Name == "cue");
			Test.Assert(cue);
			bool nobody = false;
			for (let line in source.Lines)
				nobody |= (line.Id == "nobody") && (line.Text == "Nobody.");
			Test.Assert(nobody);
		}
		{
			let read = session.Project.CookedDb.ReadObject(lane);
			defer delete read;
			let source = read as DialogueSource;
			Test.Assert((source != null) && (source.Conversations.Count == 2));
			let selfJump = source.Conversations[0].Steps[1];
			Test.Assert((selfJump.Kind == .Jump) && (selfJump.File == "lane"));
			Test.Assert(selfJump.Asset == Guid(), "a jump into its own file by its own name takes no asset");
		}
		{
			// Loaded, the resource names the cast; an export takes the cast and every dialogue asset
			// but the file itself.
			let loaded = scope DialogueFactory().Create(null, session.Project.CookedDb.GetInstance(gate));
			defer delete loaded;
			let resource = loaded as DialogueResource;
			Test.Assert((resource != null) && (resource.Cast == castId));
			let read = session.Project.SourceDb.ReadObject(gate);
			defer delete read;
			let context = scope AssetBuildContext();
			context.SourceDatabase = session.Project.SourceDb;
			context.Source = session.Project.SourceDb.GetInstance(gate);
			let deps = scope AssetDependencies();
			builders.Find(typeof(DialogueAsset)).ScanDependencies(read as DialogueAsset, context, deps);
			Test.Assert(deps.References.Contains(castId));
			Test.Assert(deps.References.Contains(lane));
			Test.Assert(!deps.References.Contains(gate), "not itself");
		}
		{
			// A run's runner plays the cooked file through the application's resources, its cast's
			// names on the line it publishes on the run's bus; its host labels an action with what
			// the player's map binds it to.
			let resources = scope ResourceManager(session.Project.CookedDb);
			let dialogues = scope DialogueFactory();
			let casts = scope DialogueCastFactory();
			resources.AddFactory(dialogues);
			resources.AddFactory(casts);
			let run = scope ApplicationRun();
			let source = scope ResourceSource(new () => resources);
			run.Get<BehaviorRunHost>().SetService(source);
			let runner = scope DialogueRunService(scope DialogueSettings(), run);
			int lines = 0;
			delegate void(Variant) listener = scope [&] (payload) =>
				{
					let notice = payload.Get<Object>() as DialogueLineNotice;
					Test.Assert(notice != null);
					Test.Assert((notice.ShownName == "The Keeper") && (notice.Mood == "worried"), "the cast's, through the run's resources");
					Test.Assert(notice.Text == "Who goes there?");
					lines++;
				};
			run.Events.Subscribe(StringHash(DialogueEvents.Line), listener);
			Test.Assert(runner.Play(gate, "gate"));
			Test.Assert(runner.Waiting == .Line);
			run.Events.Drain();
			Test.Assert(lines == 1, "the line went out on the run's bus");
			runner.Stop();
			run.Events.Drain();

			let map = scope InputMap();
			let set = new ActionSet();
			set.Name.Set("gameplay");
			map.Sets.Add(set);
			let action = new InputAction();
			action.Name.Set("Interact");
			var key = Binding();
			key.Source = .Key;
			key.Code = (uint32)Sedulous.Shell.KeyCode.E;
			action.Bindings.Add(key);
			set.Actions.Add(action);
			run.Get<ActionRuntime>().SetMap(map);
			let expected = BindingNames.DescribeBinding(key, .. scope .());
			Test.Assert(!expected.IsEmpty);
			let runHost = scope DialogueRunHost(scope DialogueSettings(), run);
			Test.Assert(runHost.ActionLabel("Interact", .. scope .()) == expected);
			Test.Assert(runHost.ActionLabel("Missing", .. scope .()).IsEmpty);
		}

		// A file naming a mood the keeper lacks does not cook, nor one jumping to a conversation the
		// other file lacks.
		AddDialogueFile(session.Project, session.Project.SourceDb.RootGroup, "Wrong",
			"conversation wrong\n" +
			"@ keeper angry: Out!\n", castId, assetsId);
		AddDialogueFile(session.Project, session.Project.SourceDb.RootGroup, "Astray",
			"conversation astray\n" +
			"@ visitor: This way.\n" +
			"jump nowhere in lane\n", castId, assetsId);
		Test.Assert(Call(server, "asset_cook", JsonValue.MakeObject(), text..Clear()), text);
		{
			let failing = JsonValue.Parse(text);
			defer delete failing;
			Test.Assert(failing.Get("failed").AsInt() == 2, text);
		}

		// File > New: the three creators make their types.
		Guid Create(StringView creator, StringView name, Type type)
		{
			let arguments = Arguments("creator", creator);
			arguments.Set("name", JsonValue.MakeString(name));
			let made = scope String();
			Test.Assert(Call(server, "asset_create", arguments, made), made);
			let result = JsonValue.Parse(made);
			defer delete result;
			Test.Assert(result.Get("type").AsString() == type.GetFullName(.. scope .()), made);
			return Guid.Parse(result.Get("guid").AsString()).GetValueOrDefault();
		}
		let village = Create(DialogueCreators.cDialogueCreator, "Village", typeof(DialogueAsset));
		{
			let read = session.Project.SourceDb.ReadObject(village);
			defer delete read;
			let asset = read as DialogueAsset;
			Test.Assert(asset != null);
			Test.Assert((asset.Cast == castId) && (asset.Assets == assetsId), "the settings' defaults");
		}
		Create(DialogueCreators.cDialogueCastCreator, "Second Cast", typeof(DialogueCastAsset));
		Create(DialogueCreators.cDialogueAssetsCreator, "More Assets", typeof(DialogueAssetListAsset));

		session.Plugins = null;
		DeleteAndNullify!(owner.Plugins);
		session.Project = null;
		DeleteAndNullify!(owner.Project);
		pluginTools.DetachServer(server);
	}

	/// The levels a conversation names load from the source database into a scratch scene: their
	/// entities' names, each level loaded once; a level that is not there gives none.
	[Test]
	public static void ALevelsEntitiesAreReadFromItsScene()
	{
		let cwd = Directory.GetCurrentDirectory(.. scope .());
		let dir = PathJoin(cwd, "scratch_plugins_dialogue_level", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Dialogue Level") case .Ok);
		let project = EditorProject.Open(dir);
		defer delete project;
		let instance = project.SourceDb.RootGroup.CreateInstance("Village", typeof(SceneDocument).GetFullName(.. scope .()));
		{
			let scene = scope Scene("Village");
			scene.CreateEntity("Keeper");
			scene.CreateEntity("Well");
			Test.Assert(SceneStorage.SaveScene(scene, instance) case .Ok);
		}
		let levels = scope LoadedLevels(project.SourceDb);
		let names = levels.EntityNames(instance.Id);
		Test.Assert((names != null) && (names.Count == 2));
		Test.Assert(names.Contains("Keeper") && names.Contains("Well"));
		Test.Assert(levels.EntityNames(instance.Id) === names, "loaded once");
		Test.Assert(levels.EntityNames(Guid(9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9)) == null);
	}

	static JsonValue Arguments(StringView key, StringView value)
	{
		let arguments = JsonValue.MakeObject();
		arguments.Set(key, JsonValue.MakeString(value));
		return arguments;
	}

	/// A tools/call through the real JSON-RPC path; the tool's text into `outText`, true when it
	/// succeeded. The arguments are consumed.
	static bool Call(McpServer server, StringView tool, JsonValue arguments, String outText)
	{
		let parameters = JsonValue.MakeObject();
		parameters.Set("name", JsonValue.MakeString(tool));
		parameters.Set("arguments", arguments);
		let request = JsonValue.MakeObject();
		defer delete request;
		request.Set("jsonrpc", JsonValue.MakeString("2.0"));
		request.Set("id", JsonValue.MakeNumber(1));
		request.Set("method", JsonValue.MakeString("tools/call"));
		request.Set("params", parameters);
		let line = scope String();
		Test.Assert(server.HandleLine(request.ToString(.. scope String()), line) == .Answered, "a call gets a reply");
		let response = JsonValue.Parse(line);
		defer delete response;
		Test.Assert(response.Get("error") == null, scope $"{tool}: a protocol error");
		let result = response.Get("result");
		outText.Set(result.Get("content").At(0).Get("text").AsString());
		return !result.Get("isError").AsBool();
	}
}
