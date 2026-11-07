using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Script;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Script.Pipeline;
using Sedulous.Engine.Project;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using Sedulous.VFS;
using NativeSample;
using NativeSample.Notes;

namespace Sedulous.Integration.Plugins;

/// The reference game's own plugin package (Data/SampleProjects/NativeSample) in every host. Its
/// four parts are Beef projects of the workspace, linked here as a host links its plugins; a
/// project that enables it loads, in each host, the parts that host's role takes, and each part's
/// contribution arrives with it and leaves with it:
///   - Engine: the spin manager, the Bob behaviour's manager with the system that runs
///     behaviours, and the Arena level, in every scene (where the host offers the engine's
///     service);
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

	/// Bob's manager, and the system that runs behaviours, which the first behaviour brings.
	private static bool BobContributed() => SceneModuleContributions.Global.Contains(GameplayServices.SystemTypeOf<BehaviourManager<Bob>>());
	private static bool BehavioursContributed() => SceneModuleContributions.Global.Contains(GameplayServices.SystemTypeOf<BehaviourSystem>());
	/// The Arena level.
	private static bool ArenaContributed() => SceneModuleContributions.Global.Contains(GameplayServices.SystemTypeOf<Arena>());

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
	/// takes the Engine and Pipeline parts alone, and a host that offers no engine service (an Engine
	/// part finds none and adds nothing) gets no scene manager. Everything leaves as the host unloads.
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
			Test.Assert(BobContributed() && BehavioursContributed(), "Engine: its behaviour, and the system that runs it");
			Test.Assert(ArenaContributed(), "Engine: its level");
			Test.Assert(builders.Find(typeof(NoteAsset)) != null, "Pipeline: the builder");
			Test.Assert(creators.FindByLabel(Notes.cCreator) != null, "and the creator");
			Test.Assert(GlobalSerializableRegistry.IsRegistered(NoteAsset.TypeId), "and its types");
			Test.Assert(server.HasTool(NativeSampleToolingPart.cTool), "Tooling");
			Test.Assert(editor.Actions.Find(NativeSampleEditorPart.cAction) != null, "Editor");
			host.Unload();
			Test.Assert(!SpinContributed());
			Test.Assert(!BobContributed() && !BehavioursContributed(), "the behaviour and its system leave with it");
			Test.Assert(!ArenaContributed(), "and the level");
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
			Test.Assert(!SpinContributed() && !BobContributed() && !ArenaContributed(), "no engine service offered, so no scene manager");
			Test.Assert(!server.HasTool(NativeSampleToolingPart.cTool) && (editor.Actions.Find(NativeSampleEditorPart.cAction) == null),
				"a cook takes no Tooling or Editor part");
			host.Unload();
			Test.Assert(builders.Find(typeof(NoteAsset)) == null);
		}
	}

	/// The package's own script types (the Spin component) are on the process's surfaces only while
	/// it is enabled, tagged with it, and a cook's surface hash follows them; the engine's surface
	/// holds none of them while it is not, and one leaked onto it refuses the plugin's publication.
	[Test]
	public static void ThePackagesScriptTypesAreOnTheSurfaceOnlyWhileItIsEnabled()
	{
		let surface = scope ScriptSurface();
		EngineScriptSurface.Populate(surface);
		ScriptSurfaces.Register(surface);
		defer ScriptSurfaces.Unregister(surface);
		const String cSpin = "NativeSample.SpinComponent";
		for (let t in surface.Types)
			Test.Assert(!t.FullName.StartsWith("NativeSample."), scope $"{t.FullName}: a plugin's type on the engine's surface");
		let before = surface.RuntimeHash();

		let engineServices = scope EnginePluginServices();
		let entries = scope List<EnabledPlugin>();
		defer { ClearAndDeleteItems!(entries); }
		Entries(entries);
		{
			let subsystems = scope SubsystemManager();
			let host = scope PluginHost(subsystems, .Player, EngineVersion.String);
			Test.Assert(engineServices.Attach(host));
			Test.Assert(host.AddRegistered() case .Ok);
			host.Load((Span<EnabledPlugin>)entries, scope .());
			let spin = surface.Find(cSpin);
			Test.Assert((spin != null) && (spin.Plugin == cId));
			Test.Assert(surface.RuntimeHash() != before, "the cooks' hash follows the enabled set");
			host.Unload();
		}
		Test.Assert(surface.Find(cSpin) == null);
		Test.Assert(surface.RuntimeHash() == before);

		// A leak: the type on the surface while the plugin is not enabled refuses its publication.
		surface.AddType(cSpin, .Struct, ScriptDomains.Runtime);
		{
			let subsystems = scope SubsystemManager();
			let host = scope PluginHost(subsystems, .Player, EngineVersion.String);
			Test.Assert(engineServices.Attach(host));
			Test.Assert(host.AddRegistered() case .Ok);
			host.Load((Span<EnabledPlugin>)entries, scope .());
			Test.Assert(NativeSampleEnginePart.ScriptTypesRefused, "refused, loudly");
			Test.Assert(surface.Find(cSpin).Plugin.IsEmpty, "the leaked one untouched, none added");
			host.Unload();
		}
	}

	/// A script using the package's own type cannot run where the project does not enable the
	/// package: an export for that platform is refused naming the script and the plugin, and
	/// script_validate with that platform says so; where it is enabled, both pass.
	[Test]
	public static void AScriptUsingThePackagesTypeIsRefusedWhereThePackageIsNotEnabled()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_plugins_scripts", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Scripted Spins") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let entry = new EnabledPlugin();
		entry.Id.Set(cId);
		entry.Platforms.Add(new .("Linux64"));
		project.Settings.Plugins.Add(entry);
		let source = "class Spinner\n{\n\tSpinComponent@ spin;\n}\n";
		let sources = project.SourcesRoot(.. scope .());
		CreateDirectory(PathJoin(sources, "scripts", .. scope .()));
		Test.Assert(WriteFile(PathJoin(sources, "scripts/Spinner.as", .. scope .()), .((uint8*)source.Ptr, source.Length)) case .Ok);
		let instance = project.SourceDb.RootGroup.CreateInstance("Spinner", typeof(ScriptClassAsset).GetFullName(.. scope .()));
		let asset = scope ScriptClassAsset();
		asset.FileName.Set("scripts/Spinner.as");
		asset.Language.Set("angelscript");
		Test.Assert(instance.WriteObject(asset) case .Ok);

		let engineServices = scope EnginePluginServices();
		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Export, EngineVersion.String);
		Test.Assert(engineServices.Attach(host));
		Test.Assert(host.AddRegistered() case .Ok);
		host.Load((Span<EnabledPlugin>)project.Settings.Plugins, scope .());
		Test.Assert(host.IsLoaded(cId));

		let web = scope String();
		ExportPlugins.CheckScriptsOn(project, host, "Web", web);
		Test.Assert(web.Contains("script 'scripts/Spinner.as' cannot run on Web, where plugin(s) 'nativesample' are not enabled"), web);
		let linux = scope String();
		ExportPlugins.CheckScriptsOn(project, host, "Linux64", linux);
		Test.Assert(linux.IsEmpty, linux);

		// script_validate with a platform: the same check, for an agent.
		let server = scope McpServer();
		let session = scope ProjectSession();
		session.Project = project;
		session.Plugins = host;
		ScriptValidateTool.Register(server, session);
		let arguments = JsonValue.MakeObject();
		arguments.Set("source", JsonValue.MakeString(source));
		arguments.Set("language", JsonValue.MakeString("angelscript"));
		arguments.Set("platform", JsonValue.MakeString("Web"));
		let validated = scope String();
		Test.Assert(Call(server, "script_validate", arguments, validated), validated);
		{
			let result = JsonValue.Parse(validated);
			defer delete result;
			Test.Assert(!result.Get("valid").AsBool(), validated);
			Test.Assert(result.Get("absentPlugins").AsString() == "'nativesample'", validated);
		}
		session.Project = null;
		session.Plugins = null;
		host.Unload();
	}

	/// In a player's host the spin manager joins a scene and turns each spinning entity about its
	/// axis while the scene simulates, and not while it does not.
	[Test]
	public static void InAPlayersHostTheSpinTurnsItsEntitiesWhileTheSceneSimulates()
	{
		let engineServices = scope EnginePluginServices();
		let entries = scope List<EnabledPlugin>();
		defer { ClearAndDeleteItems!(entries); }
		Entries(entries);
		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Player, EngineVersion.String);
		Test.Assert(engineServices.Attach(host));
		Test.Assert(host.AddRegistered() case .Ok);
		host.Load((Span<EnabledPlugin>)entries, scope .());
		Test.Assert(host.IsLoaded(cId));
		{
			let scene = scope Sedulous.Scene.Scene("spinners");
			SceneModuleContributions.Global.InstallAll(scene);
			let spins = scene.GetSystem<SpinManager>();
			Test.Assert(spins != null);
			let entity = scene.CreateEntity("Spinner");
			let spin = spins.Add(entity);
			spin.TurnsPerSecond = 0.25f;
			let tilted = scene.CreateEntity("Tilted");
			let tiltedSpin = spins.Add(tilted);
			tiltedSpin.Axis = .(1.0f, 0.0f, 0.0f);
			tiltedSpin.TurnsPerSecond = 0.5f;
			scene.Update(1.0f);
			// A quarter turn about up, a half about x.
			let quarter = scene.GetLocalTransform(entity).Rotation;
			Test.Assert((Math.Abs(quarter.Y - 0.70710678f) < 1e-4f) && (Math.Abs(quarter.W - 0.70710678f) < 1e-4f), "a quarter turn");
			let half = scene.GetLocalTransform(tilted).Rotation;
			Test.Assert((Math.Abs(Math.Abs(half.X) - 1.0f) < 1e-4f) && (Math.Abs(half.W) < 1e-4f), "a half turn about x");
			scene.SetSimulationEnabled(false);
			scene.Update(1.0f);
			let still = scene.GetLocalTransform(entity).Rotation;
			Test.Assert((Math.Abs(still.Y - quarter.Y) < 1e-6f) && (Math.Abs(still.W - quarter.W) < 1e-6f), "not while it does not simulate");
		}
		host.Unload();
		Test.Assert(!SpinContributed());
	}

	/// A tool's plugins (the cook's) take the Engine and Pipeline parts, offered the engine's service
	/// as the player and the editor offer it: the builder and the scene manager arrive, and leave
	/// with the tool's plugins.
	[Test]
	public static void ACooksPluginsBringTheBuilderAndTheSceneManagerAndTakeThemAway()
	{
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_plugins_cook", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Cook Notes") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		Entries(project.Settings.Plugins);
		let builders = scope BuilderRegistry();
		{
			let plugins = scope ToolPlugins(.Cook, project, PipelineRegistries(builders, null, null));
			Test.Assert(plugins.Host.IsLoaded(cId));
			Test.Assert(builders.Find(typeof(NoteAsset)) != null);
			Test.Assert(SpinContributed(), "a tool offers the engine's service, so its scenes get the manager");
		}
		Test.Assert(builders.Find(typeof(NoteAsset)) == null);
		Test.Assert(!SpinContributed());
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
		SceneTools.Register(server, session);
		SceneReference.RegisterComponentSchemaTool(server, builders);
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

		// The scene tools know the Engine part's component: the schema has it, and a scene holding one
		// validates without a warning.
		let schemaText = scope String();
		Test.Assert(Call(server, "component_schema", Arguments("type", "nativesample.Spin"), schemaText), schemaText);
		{
			let schema = JsonValue.Parse(schemaText);
			defer delete schema;
			Test.Assert(schema.Get("wireName").AsString() == "nativesample.Spin", schemaText);
			let version = schema.Get("dataVersions").At(0);
			let entity = "6d1c1a52-3a51-4f0e-9a1b-2a6c7d8e9f01";
			let xml = scope String();
			xml.AppendF("<root><u32 name=\"magic\">3586350318</u32><u32 name=\"version\">3</u32><string name=\"name\">Spin</string>");
			xml.AppendF("<array name=\"entities\" count=\"1\"><string name=\"id\">{}</string><string name=\"name\">Spinner</string><u8 name=\"active\">1</u8>", entity);
			xml.Append("<string name=\"parent\">00000000-0000-0000-0000-000000000000</string>");
			xml.Append("<object name=\"position\"><f32 name=\"x\">0</f32><f32 name=\"y\">0</f32><f32 name=\"z\">0</f32></object>");
			xml.Append("<object name=\"rotation\"><f32 name=\"x\">0</f32><f32 name=\"y\">0</f32><f32 name=\"z\">0</f32><f32 name=\"w\">1</f32></object>");
			xml.Append("<object name=\"scale\"><f32 name=\"x\">1</f32><f32 name=\"y\">1</f32><f32 name=\"z\">1</f32></object></array>");
			xml.AppendF("<array name=\"components\" count=\"1\"><object><string name=\"owner\">{}</string><string name=\"type\">nativesample.Spin</string>", entity);
			xml.AppendF("<object name=\"data\"><array name=\"dataVersions\" count=\"1\"><u64 name=\"type\">{}</u64><u32 name=\"version\">{}</u32></array>",
				version.Get("type").AsString(), version.Get("version").AsInt());
			xml.Append("<f32 name=\"turnsPerSecond\">0.5</f32><object name=\"axis\"><f32 name=\"x\">0</f32><f32 name=\"y\">1</f32><f32 name=\"z\">0</f32></object>");
			xml.Append("</object></object></array><array name=\"systemSettings\" count=\"0\"/><u8 name=\"prefabMode\">4</u8><array name=\"prefabInstances\" count=\"0\"/></root>");
			let validated = scope String();
			Test.Assert(Call(server, "scene_validate", Arguments("xml", xml), validated), validated);
			let result = JsonValue.Parse(validated);
			defer delete result;
			Test.Assert(result.Get("valid").AsBool() && (result.Get("warnings").Count == 0), validated);
		}

		// And its behaviour, one more component to the tools: its record is the base's Enabled, then
		// its public fields at their defaults, each joined to its reflected field (Enabled to
		// Behaviour's); its private state is not there.
		let bobText = scope String();
		Test.Assert(Call(server, "component_schema", Arguments("type", "nativesample.Bob"), bobText), bobText);
		{
			let schema = JsonValue.Parse(bobText);
			defer delete schema;
			Test.Assert(schema.Get("wireName").AsString() == "nativesample.Bob", bobText);
			Test.Assert(schema.Get("type").Get("name").AsString() == "Bob", bobText);
			let fields = schema.Get("fields");
			Test.Assert(fields.Count == 3, bobText);
			Test.Assert((fields.At(0).Get("key").AsString() == "enabled") && (fields.At(0).Get("kind").AsString() == "bool"), bobText);
			Test.Assert((fields.At(1).Get("key").AsString() == "height") && (fields.At(2).Get("key").AsString() == "speed"), bobText);
			var height = 0.0f;
			if (float.Parse(fields.At(1).Get("default").AsString()) case .Ok(let parsed))
				height = parsed;
			Test.Assert(height == 0.25f, bobText);
			Test.Assert(fields.At(1).Get("description").AsString() == "How far above and below its start it goes.", bobText);
			Test.Assert(fields.At(2).Get("displayName").AsString() == "Cycles Per Second", bobText);
			Test.Assert(schema.Get("unreflected").Count == 0, bobText);
		}

		// And its level, a settings block to the tools under its id: Active first, then its time
		// limit at its default, each joined to its reflected field; its runtime state is not there.
		let arenaText = scope String();
		Test.Assert(Call(server, "component_schema", Arguments("type", "nativesample.arena"), arenaText), arenaText);
		{
			let schema = JsonValue.Parse(arenaText);
			defer delete schema;
			Test.Assert(schema.Get("system").AsString() == "nativesample.arena", arenaText);
			Test.Assert(schema.Get("type").Get("name").AsString() == "Arena", arenaText);
			let fields = schema.Get("fields");
			Test.Assert(fields.Count == 2, arenaText);
			Test.Assert((fields.At(0).Get("key").AsString() == "active") && (fields.At(0).Get("kind").AsString() == "bool"), arenaText);
			Test.Assert(fields.At(1).Get("key").AsString() == "timeLimit", arenaText);
			var limit = 0.0f;
			if (float.Parse(fields.At(1).Get("default").AsString()) case .Ok(let parsed))
				limit = parsed;
			Test.Assert(limit == 60.0f, arenaText);
			Test.Assert(fields.At(1).Get("displayName").AsString() == "Time Limit", arenaText);
			Test.Assert(schema.Get("unreflected").Count == 0, arenaText);
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

	/// The sample's export presets: its desktop preset, which ships the project's own player, so
	/// Build Project makes that player in the preset's config (ShippingRelease) beside Debug.
	[Test]
	public static void TheSamplesDesktopPresetShipsTheProjectsOwnPlayer()
	{
		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		let source = PathJoin(dataRoot, "SampleProjects/NativeSample", .. scope .());
		let presets = scope ExportPresetSet();
		Test.Assert(ExportPresetsFile.Load(scope NativeFileSystem(source), presets) case .Ok);
		Test.Assert(presets.Presets.Count == 1);
		let desktop = presets.Presets[0];
		Test.Assert((desktop.Platform == "Linux64") && desktop.TemplateId.IsEmpty && (desktop.EffectiveConfig == "Release"));
#if BF_PLATFORM_LINUX
		let configs = scope List<String>();
		defer { ClearAndDeleteItems!(configs); }
		ProjectBuild.PlayerConfigs(presets, configs);
		Test.Assert((configs.Count == 2) && (configs[0] == "Debug") && (configs[1] == "ShippingRelease"));
#endif
	}

	/// The sample itself (Data/SampleProjects/NativeSample) reads at the current data versions with
	/// its package loaded, every spin record of its scene resolving into the plugin's manager, its
	/// Bob record into an instance of the behaviour with the scene's values, which moves its
	/// entity as the scene simulates, and its Arena block into the level, on, which counts down
	/// as the scene simulates; and it cooks through the tools an agent uses, its note
	/// through the plugin's builder. A scratch copy of its sources, so nothing writes into the
	/// tracked tree.
	[Test]
	public static void TheSampleReadsWithItsPackageLoadedItsSpinsResolveAndItCooks()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");
		let source = PathJoin(dataRoot, "SampleProjects/NativeSample", .. scope .());
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_nativesample_versions", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		// Its sources and package alone: a local Build Project's .cache stays behind.
		Test.Assert(CreateDirectory(dir));
		Test.Assert(ExportTemplates.CopyFile(source, ProjectLayout.ManifestFile, dir, ProjectLayout.ManifestFile));
		Test.Assert(ExportTemplates.CopyTree(PathJoin(source, ProjectLayout.ContentDir, .. scope .()), PathJoin(dir, ProjectLayout.ContentDir, .. scope .())));
		Test.Assert(ExportTemplates.CopyTree(PathJoin(source, ProjectLayout.PluginsDir, .. scope .()), PathJoin(dir, ProjectLayout.PluginsDir, .. scope .())));

		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, dataRoot);
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllImporters(importers);
		let creators = scope AssetCreatorRegistry();
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			Test.Assert(project.Settings.FindPlugin(cId) != null, "the sample enables its package");
			let engineServices = scope EnginePluginServices();
			let pipelineServices = scope PipelinePluginServices(PipelineRegistries(builders, importers, creators));
			let subsystems = scope SubsystemManager();
			let host = scope PluginHost(subsystems, .Editor, EngineVersion.String);
			Test.Assert(engineServices.Attach(host) && pipelineServices.Attach(host));
			Test.Assert(host.AddRegistered() case .Ok);
			host.Load((Span<EnabledPlugin>)project.Settings.Plugins, scope .());
			Test.Assert(host.IsLoaded(cId));
			int read = 0;
			int spins = 0;
			int bobs = 0;
			ReadAll(project.SourceDb.RootGroup, ref read, ref spins, ref bobs);
			// The Cube and Plane primitives, the Welcome note and the scene Spinners; ten spins: the
			// row of five, the carousel's hub and its four riders; one Bob, on the row's middle cube.
			Test.Assert(read >= 4, scope $"read {read} instances");
			Test.Assert(spins == 10, scope $"{spins} spin records resolved");
			Test.Assert(bobs == 1, scope $"{bobs} bob records resolved");
			host.Unload();
		}

		// And it COOKS, the stdio host enabling the package as it opens the project.
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		owner.PluginRegistries = PipelineRegistries(builders, importers, creators);
		ProjectOpenTools.Register(server, session, owner);
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetWriteTools.Register(server, session, importers, operations);
		let opened = scope String();
		Test.Assert(Call(server, "project_open", Arguments("directory", dir), opened), opened);
		let force = JsonValue.MakeObject();
		force.Set("force", JsonValue.MakeBool(true));
		let cooked = scope String();
		Test.Assert(Call(server, "asset_cook", force, cooked), cooked);
		{
			let cookedJson = JsonValue.Parse(cooked);
			defer delete cookedJson;
			// The two meshes and the note; the scene stages rather than cooks.
			Test.Assert(cookedJson.Get("cooked").AsInt() >= 3, cooked);
			Test.Assert(cookedJson.Get("failed").AsInt() == 0, cooked);
		}
		session.Plugins = null;
		DeleteAndNullify!(owner.Plugins);
		session.Project = null;
		DeleteAndNullify!(owner.Project);
	}

	/// Every instance under `group` reads back, a scene as its stream into a scratch scene of the
	/// full composition and the scene managers the loaded plugins contribute; the spin components
	/// the scenes hold counted into `spins`, and the Bob behaviours into `bobs`, a scene with one
	/// checked by CheckGameCode.
	private static void ReadAll(Group group, ref int read, ref int spins, ref int bobs)
	{
		for (let instance in group.Instances)
		{
			let object = instance.ReadObject();
			Test.Assert(object != null, scope $"sample instance refused: {instance.Name}");
			delete object;
			if (instance.TypeName == McpDocumentNames.cSceneDocument)
			{
				let scratch = scope Sedulous.Scene.Scene(instance.Name);
				EngineSceneComposition.AddAllSceneManagers(scratch); // the plugin's Spin manager among them
				Test.Assert(SceneStorage.LoadScene(instance, scratch) case .Ok, scope $"sample scene stream refused: {instance.Name}");
				spins += (int)scratch.GetSystem<SpinManager>().Count;
				let behaviours = scratch.GetSystem<BehaviourManager<Bob>>();
				Test.Assert(behaviours != null, "the plugin's Bob manager among them");
				bobs += (int)behaviours.Count;
				if (behaviours.Count > 0)
					CheckGameCode(instance);
			}
			read++;
		}
		for (let child in group.Groups)
			ReadAll(child, ref read, ref spins, ref bobs);
	}

	/// The scene `instance` read again into a scene of what the plugins contribute alone (the
	/// rest of its records kept unresolved): each Bob holds the values its record says, and the
	/// scene's first simulated second moves its entity a quarter cycle, to the top of its travel;
	/// the Arena level is on with the scene's time limit, and that second takes one off it.
	private static void CheckGameCode(Instance instance)
	{
		let scene = scope Sedulous.Scene.Scene(instance.Name);
		SceneModuleContributions.Global.InstallAll(scene);
		Test.Assert(SceneStorage.LoadScene(instance, scene) case .Ok, scope $"sample scene stream refused: {instance.Name}");
		let arena = scene.GetSystem<Arena>();
		Test.Assert(arena != null, "the plugin's level came with it");
		Test.Assert(arena.Active && (arena.TimeLimit == 30.0f), "the scene's block, not the defaults");
		Test.Assert(!arena.Started);
		let behaviours = scene.GetSystem<BehaviourManager<Bob>>();
		Test.Assert((behaviours != null) && (behaviours.Count == 1), "the one Bob, on the row's middle cube");
		Test.Assert(scene.GetSystem<BehaviourSystem>() != null, "the system that runs it came with it");
		let bob = behaviours.Instances[0];
		let entity = behaviours.OwnerHandles[0];
		Test.Assert(bob.Entity == entity);
		Test.Assert(scene.GetEntityName(entity) == "Tumble", scope $"on {scene.GetEntityName(entity)}");
		Test.Assert(bob.Enabled && (bob.Height == 0.5f) && (bob.Speed == 0.25f), "the record's values, not the defaults");
		let startY = scene.GetLocalTransform(entity).Position.Y;
		Test.Assert(startY == 1.0f);
		// A quarter cycle at a quarter cycle a second: the full height above the start.
		scene.Update(1.0f);
		let topY = scene.GetLocalTransform(entity).Position.Y;
		Test.Assert(Math.Abs(topY - 1.5f) < 1e-4f, scope $"at {topY} after a second");
		Test.Assert(arena.Started && (arena.Remaining == 29.0f), scope $"{arena.Remaining} seconds left after one");
		// Not while the scene does not simulate.
		scene.SetSimulationEnabled(false);
		scene.Update(1.0f);
		Test.Assert(scene.GetLocalTransform(entity).Position.Y == topY, "still while it does not simulate");
		Test.Assert(arena.Remaining == 29.0f, "its clock stands still with it");
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
