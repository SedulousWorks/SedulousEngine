using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Engine.Project;
using Sedulous.Engine.Composition;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using NativeSample;
using NativeSample.Notes;

namespace Sedulous.Integration.Plugins;

/// The reference game's own plugin package (Data/SampleProjects/NativeSample) in every host. Its
/// four parts are Beef projects of the workspace, linked here as a host links its plugins; a
/// project that enables it loads, in each host, the parts that host's role takes, and each part's
/// contribution arrives with it and leaves with it:
///   - Engine: the spin manager, in every scene (where the host offers the engine's service);
///   - Pipeline: the note asset type, its builder and its creator, in the host's registries;
///   - Tooling: the nativesample_notes MCP tool, in every MCP server the host serves;
///   - Editor: the Project > Native Sample Notes action, in the editor.
static class NativeSampleTests
{
	private const String cId = "nativesample";

	private static void Entries(List<EnabledPlugin> outEntries)
	{
		let entry = new EnabledPlugin();
		entry.Id.Set(cId);
		outEntries.Add(entry);
	}

	private static bool SpinContributed() => SceneModuleContributions.Global.Contains(NativeSampleEnginePart.SpinManagerType);

	/// The four parts register themselves with the package's manifest, which reads and passes the
	/// checks for this engine.
	[Test]
	public static void ThePackageRegistersItsFourPartsAndItsManifestReads()
	{
		bool[PluginPartKind.Count] seen = default;
		for (let part in PluginRegistry.Parts)
		{
			if (part.PluginId != cId)
				continue;
			Test.Assert(!seen[(int)part.Kind], "one part a kind");
			seen[(int)part.Kind] = true;
			let manifest = scope PluginManifest();
			Test.Assert(PluginManifest.Read(part.ManifestXml, manifest) case .Ok);
			for (int i < PluginPartKind.Count)
				Test.Assert(manifest.HasPart((PluginPartKind)i));
			let why = scope String();
			Test.Assert(manifest.Check(EngineVersion.String, why), why);
		}
		for (int i < PluginPartKind.Count)
			Test.Assert(seen[i], "every kind linked");
	}

	/// An editor's host loads every part, each contribution arriving through its service; a cook's
	/// takes the Engine and Pipeline parts alone and offers no engine service, so only the builder
	/// arrives. Everything leaves as the host unloads.
	[Test]
	public static void EachHostLoadsItsRolesPartsAndEveryContributionLeavesWithIt()
	{
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		let creators = scope AssetCreatorRegistry();
		let session = scope ProjectSession();
		let server = scope McpServer();
		let editor = scope EditorContext();
		let engineServices = scope EnginePluginServices();
		let pipelineServices = scope PipelinePluginServices(PipelineRegistries(builders, importers, creators));
		let toolServices = scope McpPluginServices();
		toolServices.AttachServer(server, session);
		defer toolServices.DetachServer(server);
		let entries = scope List<EnabledPlugin>();
		defer { ClearAndDeleteItems!(entries); }
		Entries(entries);
		Test.Assert(!SpinContributed());
		{
			let subsystems = scope SubsystemManager();
			let host = scope PluginHost(subsystems, .Editor, EngineVersion.String);
			Test.Assert(engineServices.Attach(host) && pipelineServices.Attach(host) && toolServices.Attach(host));
			Test.Assert(host.Provide(editor));
			Test.Assert(host.AddRegistered() case .Ok);
			host.Load((Span<EnabledPlugin>)entries, scope .());
			Test.Assert(host.IsLoaded(cId));
			Test.Assert(SpinContributed(), "Engine");
			Test.Assert(builders.Find(typeof(NoteAsset)) != null, "Pipeline: the builder");
			Test.Assert(creators.FindByLabel(Notes.cCreator) != null, "and the creator");
			Test.Assert(GlobalSerializableRegistry.IsRegistered(NoteAsset.TypeId), "and its types");
			Test.Assert(server.HasTool(NativeSampleToolingPart.cTool), "Tooling");
			Test.Assert(editor.Actions.Find(NativeSampleEditorPart.cAction) != null, "Editor");
			host.Unload();
			Test.Assert(!SpinContributed());
			Test.Assert(builders.Find(typeof(NoteAsset)) == null);
			Test.Assert(creators.FindByLabel(Notes.cCreator) == null);
			Test.Assert(!GlobalSerializableRegistry.IsRegistered(NoteAsset.TypeId));
			Test.Assert(!server.HasTool(NativeSampleToolingPart.cTool));
			Test.Assert(editor.Actions.Find(NativeSampleEditorPart.cAction) == null);
		}
		{
			let subsystems = scope SubsystemManager();
			let host = scope PluginHost(subsystems, .Cook, EngineVersion.String);
			Test.Assert(pipelineServices.Attach(host) && toolServices.Attach(host));
			Test.Assert(host.Provide(editor));
			Test.Assert(host.AddRegistered() case .Ok);
			host.Load((Span<EnabledPlugin>)entries, scope .());
			Test.Assert(host.IsLoaded(cId));
			Test.Assert(builders.Find(typeof(NoteAsset)) != null, "the cook's builder");
			Test.Assert(!SpinContributed(), "a cook offers no engine service, so no scene manager");
			Test.Assert(!server.HasTool(NativeSampleToolingPart.cTool) && (editor.Actions.Find(NativeSampleEditorPart.cAction) == null),
				"a cook takes no Tooling or Editor part");
			host.Unload();
			Test.Assert(builders.Find(typeof(NoteAsset)) == null);
		}
	}

	/// Through the standalone MCP host: an agent opens a project that enables the package, creates
	/// a note with its creator, cooks it with its builder and reads it with its tool; a project
	/// that does not enable it has neither the tool nor the creator.
	[Test]
	public static void AnAgentCreatesCooksAndReadsTheGamesNotesThroughItsPlugin()
	{
		let cwd = Directory.GetCurrentDirectory(.. scope .());
		let dir = PathJoin(cwd, "scratch_plugins_mcp", .. scope .());
		let plain = PathJoin(cwd, "scratch_plugins_mcp_plain", .. scope .());
		RemoveDirectoryRecursive(dir);
		RemoveDirectoryRecursive(plain);
		defer RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(plain);
		Test.Assert(EditorProject.Create(dir, "Mcp Notes") case .Ok);
		Test.Assert(EditorProject.Create(plain, "Plain") case .Ok);
		{
			let project = EditorProject.Open(dir);
			defer delete project;
			Entries(project.Settings.Plugins);
			Test.Assert(project.SaveSettings() case .Ok);
		}

		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		let creators = scope AssetCreatorRegistry();
		let pluginTools = scope McpPluginServices();
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		owner.PluginRegistries = PipelineRegistries(builders, importers, creators);
		owner.PluginTools = pluginTools;
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetWriteTools.Register(server, session, importers, operations);
		AssetCreateTools.Register(server, session, creators, operations);
		ProjectOpenTools.Register(server, session, owner);
		pluginTools.AttachServer(server, session);

		let opened = scope String();
		Test.Assert(Call(server, "project_open", Arguments("directory", dir), opened), opened);
		Test.Assert((session.Plugins != null) && session.Plugins.IsLoaded(cId));
		let made = scope String();
		let create = JsonValue.MakeObject();
		create.Set("creator", JsonValue.MakeString(Notes.cCreator));
		create.Set("name", JsonValue.MakeString("First"));
		Test.Assert(Call(server, "asset_create", create, made), made);
		let madeJson = JsonValue.Parse(made);
		defer delete madeJson;
		let id = Guid.Parse(madeJson.Get("guid").AsString());
		Test.Assert(id case .Ok);
		let cooked = scope String();
		Test.Assert(Call(server, "asset_cook", JsonValue.MakeObject(), cooked), cooked);
		{
			let cookedJson = JsonValue.Parse(cooked);
			defer delete cookedJson;
			Test.Assert(cookedJson.Get("failed").AsInt() == 0, cooked);
		}
		{
			let read = session.Project.CookedDb.ReadObject(id.Get());
			defer delete read;
			let product = read as NoteProduct;
			Test.Assert((product != null) && (product.Text == "A note from the game's own code"));
		}
		let notes = scope String();
		Test.Assert(Call(server, NativeSampleToolingPart.cTool, JsonValue.MakeObject(), notes), notes);
		{
			let notesJson = JsonValue.Parse(notes);
			defer delete notesJson;
			Test.Assert(notesJson.Get("count").AsInt() == 1, notes);
			Test.Assert(notesJson.Get("notes").At(0).Get("name").AsString() == "First", notes);
			Test.Assert(notesJson.Get("notes").At(0).Get("text").AsString() == "A note from the game's own code", notes);
		}

		// A project that does not enable it: the plugin's tool and creator leave with it.
		Test.Assert(Call(server, "project_open", Arguments("directory", plain), opened..Clear()), opened);
		Test.Assert(!server.HasTool(NativeSampleToolingPart.cTool));
		Test.Assert(creators.FindByLabel(Notes.cCreator) == null);

		session.Plugins = null;
		DeleteAndNullify!(owner.Plugins);
		session.Project = null;
		DeleteAndNullify!(owner.Project);
		pluginTools.DetachServer(server);
	}

	private static JsonValue Arguments(StringView key, StringView value)
	{
		let arguments = JsonValue.MakeObject();
		arguments.Set(key, JsonValue.MakeString(value));
		return arguments;
	}

	/// A tools/call through the real JSON-RPC path; the tool's text into `outText`, true when it
	/// succeeded. The arguments are consumed.
	private static bool Call(McpServer server, StringView tool, JsonValue arguments, String outText)
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
