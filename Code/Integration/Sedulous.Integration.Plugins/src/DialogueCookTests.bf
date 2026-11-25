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
using Dialogue;

namespace Sedulous.Integration.Plugins;

/// The dialogue plugin's assets cooked through the standalone MCP host's tools, as an agent or the
/// editor cooks them. A project enables the plugin with its cast and its dialogue assets named in
/// the settings; a dialogue file that names only what the project has cooks to its compiled
/// conversations, one with an error fails the cook, and File > New's three creators make their
/// assets.
static class DialogueCookTests
{
	/// A dialogue file in the project's sources and its asset; its guid.
	static Guid AddDialogueFile(EditorProject project, Group group, StringView name, StringView text)
	{
		let fileName = scope $"Dialogue/{name}.dialogue";
		let path = project.SourceFile(fileName, .. scope .());
		CreateDirectory(PathParent(path, .. scope .()));
		Test.Assert(WriteFile(path, Span<uint8>((uint8*)text.Ptr, text.Length)) case .Ok);
		let instance = group.CreateInstance(name, typeof(DialogueAsset).GetFullName(.. scope .()));
		Test.Assert(instance != null);
		let asset = scope DialogueAsset();
		asset.FileName.Set(fileName);
		Test.Assert(instance.WriteObject(asset) case .Ok);
		return instance.Id;
	}

	/// A scratch project enabling dialogue: its cast (a keeper and a visitor), its dialogue assets
	/// (empty) and one clean dialogue file, the settings naming the cast, the assets, a command and
	/// a provided flag. The file's guid.
	static Guid MakeProject(StringView dir)
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
		Test.Assert(listInstance.WriteObject(scope DialogueAssetListAsset()) case .Ok);

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
			"cue lights dim\n");

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
		let gate = MakeProject(dir);

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
			let conversation = source.Conversations[0];
			Test.Assert(conversation.Id == "gate");
			Test.Assert(conversation.Steps[0].Kind == .Line);
			Test.Assert(conversation.Steps.Back.Kind == .End);
			bool cue = false;
			for (let step in conversation.Steps)
				cue |= (step.Kind == .Command) && (step.Name == "cue");
			Test.Assert(cue);
			bool nobody = false;
			for (let line in source.Lines)
				nobody |= (line.Id == "nobody") && (line.Text == "Nobody.");
			Test.Assert(nobody);
		}

		// A file naming a mood the keeper lacks does not cook.
		AddDialogueFile(session.Project, session.Project.SourceDb.RootGroup, "Wrong",
			"conversation wrong\n" +
			"@ keeper angry: Out!\n");
		Test.Assert(Call(server, "asset_cook", JsonValue.MakeObject(), text..Clear()), text);
		{
			let failing = JsonValue.Parse(text);
			defer delete failing;
			Test.Assert(failing.Get("failed").AsInt() == 1, text);
		}

		// File > New: the three creators make their types.
		void Create(StringView creator, StringView name, Type type)
		{
			let arguments = Arguments("creator", creator);
			arguments.Set("name", JsonValue.MakeString(name));
			let made = scope String();
			Test.Assert(Call(server, "asset_create", arguments, made), made);
			let result = JsonValue.Parse(made);
			defer delete result;
			Test.Assert(result.Get("type").AsString() == type.GetFullName(.. scope .()), made);
		}
		Create(DialogueCreators.cDialogueCreator, "Village", typeof(DialogueAsset));
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
