using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Mcp.Reflection;
using Sedulous.Mcp.Script;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The agent shaped project flow, headless, through the tools in the order the guide
/// teaches: create, open, inspect, import, cook, and the whole engine surface in script_api
/// with no device anywhere.
static class ProjectFlowTests
{
	[Test]
	public static void AnAgentCreatesOpensAndInspectsAProject()
	{
		let dir = Scratch("mcp_fixture_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let server = scope McpServer();
		let session = scope ProjectSession();
		ReflectionTools.Register(server);
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);

		// The surface an agent lists before guessing.
		let listed = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}");
		defer delete listed;
		Test.Assert(listed.Get("result").Get("tools").Count >= 5);

		let created = CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Fixture"));
		defer delete created;
		Test.Assert(created.Get("created").AsBool());
		let opened = CallOk(server, "project_open", With(Obj(), "directory", dir));
		defer delete opened;
		Test.Assert(opened.Get("name").AsString() == "Fixture");
		let info = CallOk(server, "project_info", Obj());
		defer delete info;
		Test.Assert(info.Get("name").AsString() == "Fixture");
		Test.Assert(!info.Get("directory").AsString().IsEmpty);
		Test.Assert(!info.Get("sourcesRoot").AsString().IsEmpty);
		Test.Assert(FileExists(PathJoin(dir, "Project.xml", .. scope .())));

		// A second create at the same place is a tool error with real text, not a fault.
		let again = scope String();
		CallErr(server, "project_create", With(With(Obj(), "directory", dir), "name", "Again"), again);
		Test.Assert(again.Contains("could not create"));
	}

	[Test]
	public static void ProjectInfoBeforeAnyProjectIsOpenIsAToolError()
	{
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		let text = scope String();
		CallErr(server, "project_info", Obj(), text);
		Test.Assert(text.Contains("project_open"));
	}

	[Test]
	public static void AssetListAndInfoReadTheOpenProjectsDatabase()
	{
		let dir = Scratch("mcp_asset_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		AssetTools.Register(server, session);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Assets"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		let empty = CallOk(server, "asset_list", Obj());
		defer delete empty;
		Test.Assert(empty.Get("count").AsInt() == 0, "a fresh project has no assets");

		// Seeded straight into the source database, read back through the tools.
		let id = Guid.Parse("12345678-1234-1234-1234-1234567890ab").Get();
		session.Project.SourceDb.RootGroup.CreateGroup("art").CreateInstanceWithId(id, "hero", "Sedulous.Texture.Pipeline.TextureAsset");
		let list = CallOk(server, "asset_list", Obj());
		defer delete list;
		Test.Assert(list.Get("count").AsInt() == 1);
		let first = list.Get("assets").At(0);
		Test.Assert(first.Get("name").AsString() == "hero");
		Test.Assert(first.Get("type").AsString() == "Sedulous.Texture.Pipeline.TextureAsset");
		Test.Assert(first.Get("group").AsString() == "art");
		let seen = CallOk(server, "asset_info", With(Obj(), "guid", "12345678-1234-1234-1234-1234567890ab"));
		defer delete seen;
		Test.Assert(seen.Get("name").AsString() == "hero");
		Test.Assert(seen.Get("group").AsString() == "art");

		// A well formed but absent guid, and a malformed one, are tool errors with text.
		let missing = scope String();
		CallErr(server, "asset_info", With(Obj(), "guid", "00000000-0000-0000-0000-000000000000"), missing);
		Test.Assert(missing.Contains("no asset"));
		let malformed = scope String();
		CallErr(server, "asset_info", With(Obj(), "guid", "not-a-guid"), malformed);
		Test.Assert(malformed.Contains("invalid guid"));
	}

	[Test]
	public static void AnAgentImportsAndCooksAScriptSource()
	{
		let dir = Scratch("mcp_write_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		// The host assembles the registries once, from the composition root.
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		PipelineRegistration.RegisterAllImporters(importers);

		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		AssetTools.Register(server, session);
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetWriteTools.Register(server, session, importers, operations);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Write"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		// A real source file on disk: a trivial class that cooks clean.
		let sourcePath = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "mcp_write_as_src.as", .. scope .());
		defer DeleteFile(sourcePath);
		File.WriteAllText(sourcePath, """
			class Mover
			{
				Entity self;
				Scene@ scene;
				float speed = 2.0f;
				void onUpdate(float dt) { }
			}
			""").IgnoreError();

		let imported = CallOk(server, "asset_import", With(With(Obj(), "source", sourcePath), "group", "scripts"));
		defer delete imported;
		Test.Assert(imported.Get("type").AsString() == "Sedulous.Script.Pipeline.ScriptClassAsset");
		Test.Assert(imported.Get("name").AsString() == "mcp_write_as_src");
		Test.Assert(imported.Get("importer").AsString() == "Script");
		Test.Assert(imported.Get("typeNamespace").AsString() == "Sedulous.Script.Pipeline");
		for (let timing in StringView[?]("deferredWrites", "prepareMs", "mainMs", "flushMs"))
			Test.Assert(imported.Get(timing) != null, scope $"the result reports {timing}");
		Test.Assert(imported.Get("alsoClaimableBy") == null, "one claimant, nothing to choose");
		let guid = scope String(imported.Get("guid").AsString());
		let list = CallOk(server, "asset_list", Obj());
		defer delete list;
		Test.Assert(list.Get("count").AsInt() == 1);
		Test.Assert(list.Get("assets").At(0).Get("group").AsString() == "scripts");
		Test.Assert(FileExists(PathJoin(dir, "Sources/mcp_write_as_src.as", .. scope .())), "copied under Sources/");
		Test.Assert(FileExists(PathJoin(dir, "Content/scripts/mcp_write_as_src.xasset", .. scope .())), "the source envelope");

		let cooked = CallOk(server, "asset_cook", Obj());
		defer delete cooked;
		Test.Assert(cooked.Get("planned").AsInt() == 1, scope $"planned {cooked.Get("planned").AsInt()}");
		Test.Assert(cooked.Get("cooked").AsInt() == 1);
		Test.Assert(cooked.Get("failed").AsInt() == 0);
		Test.Assert(FileExists(PathJoin(dir, "Cooked/scripts/mcp_write_as_src.rasset", .. scope .())), "the product");

		// The product answers in the cooked database by the source's guid.
		let product = CallOk(server, "asset_info", With(With(Obj(), "guid", guid), "database", "cooked"));
		defer delete product;
		Test.Assert(product.Get("guid").AsString() == guid);

		// A second cook finds nothing to do.
		let again = CallOk(server, "asset_cook", Obj());
		defer delete again;
		Test.Assert(again.Get("planned").AsInt() == 0);
		Test.Assert(again.Get("upToDate").AsInt() == 1);
	}

	/// The importer disambiguation ruling: .png is claimed by three importers; the first is
	/// the default and the result names the others, a hint picks one, a bad hint lists them.
	[Test]
	public static void AnAmbiguousExtensionNamesItsClaimantsAndAHintChooses()
	{
		let dir = Scratch("mcp_import_hint_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		PipelineRegistration.RegisterAllImporters(importers);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetWriteTools.Register(server, session, importers, operations);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Hint"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		// A 1x1 PNG, the smallest valid one.
		uint8[?] png = .(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
			0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
			0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
			0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB0, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
			0x44, 0xAE, 0x42, 0x60, 0x82);
		let sourcePath = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "mcp_hint_pixel.png", .. scope .());
		defer DeleteFile(sourcePath);
		Test.Assert(WriteFile(sourcePath, .(&png[0], png.Count)) case .Ok);

		let unhinted = CallOk(server, "asset_import", With(Obj(), "source", sourcePath));
		defer delete unhinted;
		let alternatives = unhinted.Get("alsoClaimableBy");
		Test.Assert(alternatives != null, "the alternatives are named");
		Test.Assert(alternatives.Count >= 1);
		let chosen = scope String(alternatives.At(0).AsString());
		Test.Assert(chosen != unhinted.Get("importer").AsString());

		let hinted = CallOk(server, "asset_import", With(With(With(Obj(), "source", sourcePath), "importer", chosen), "group", "hinted"));
		defer delete hinted;
		Test.Assert(hinted.Get("importer").AsString() == chosen);

		let bad = scope String();
		CallErr(server, "asset_import", With(With(Obj(), "source", sourcePath), "importer", "Nonsense"), bad);
		Test.Assert(bad.Contains("claimants are") && bad.Contains(chosen));
	}

	/// script_api reports the COMPLETE engine surface, headless, no device: the pipeline
	/// surface the cooks compile against contains the runtime's facades and components.
	[Test]
	public static void ScriptApiReportsTheCompleteEngineSurfaceHeadless()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let server = scope McpServer();
		ScriptTools.Register(server, PipelineRegistration.Surface);
		let api = CallOk(server, "script_api", With(Obj(), "language", "angelscript"));
		defer delete api;
		let reported = api.Get("languages").At(0);
		Test.Assert(reported.Get("language").AsString() == "angelscript");
		let types = reported.Get("types");
		for (let name in scope String[]("Scene", "PhysicsFacade", "AudioFacade", "InputFacade", "GameInstance", "UiScript", "Float3", "FontBakeMode"))
			Test.Assert(TypeEndingIn(types, name) != null, name);
		Test.Assert(Named(types, "scriptName", "Entity") != null, "the entity, as a script spells it");
		// The runtime surface and the pipeline's own types: the facades, and the components a
		// script takes from an entity.
		Test.Assert(reported.Get("typeCount").AsInt() > 40);
		Test.Assert(TypeEndingIn(types, "RigidBodyComponent") != null, "components are script types");
		Test.Assert(TypeEndingIn(types, "CharacterComponent") != null);
		// The domain rides along: a pipeline type exists for tools, the facade for the player.
		let bakeMode = TypeEndingIn(types, "FontBakeMode");
		Test.Assert(!bakeMode.Get("inPlayer").AsBool() && (bakeMode.Get("domain").AsString() == "Pipeline"));
		let physics = TypeEndingIn(types, "PhysicsFacade");
		Test.Assert(physics.Get("inPlayer").AsBool() && (physics.Get("scriptName").AsString() == "PhysicsFacade"));
		let run = TypeEndingIn(types, "GameInstance");
		Test.Assert(run.Get("scriptName").AsString() == "GameInstance", "the class; its members spell Run");
	}

	/// The bound type whose surface type name ends in `.name`, or null.
	private static JsonValue TypeEndingIn(JsonValue types, StringView name)
	{
		let suffix = scope $".{name}";
		for (int i < types.Count)
		{
			let full = types.At(i).Get("typeFullName");
			if ((full != null) && full.AsString().EndsWith(suffix))
				return types.At(i);
		}
		return null;
	}

	/// An agent makes the assets File > New makes: listed, created by label or by type, in a
	/// group or the creator's own folder, a taken name and an unknown or ambiguous creator
	/// refused, and what it made cooks.
	[Test]
	public static void AnAgentCreatesAssetsThatCook()
	{
		let dir = Scratch("mcp_create_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		let creators = scope AssetCreatorRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		PipelineRegistration.RegisterAllImporters(importers);
		PipelineRegistration.RegisterAllCreators(creators);

		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		AssetTools.Register(server, session);
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetWriteTools.Register(server, session, importers, operations);
		AssetCreateTools.Register(server, session, creators, operations);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Create"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		let listed = CallOk(server, "asset_creators", Obj());
		defer delete listed;
		Test.Assert(listed.Get("count").AsInt() == creators.Count);
		let inputMap = Named(listed.Get("creators"), "label", "Input Map");
		Test.Assert((inputMap != null) && inputMap.Get("type").AsString().EndsWith("InputMapAsset"));
		Test.Assert(Named(listed.Get("creators"), "label", "PBR Material").Get("defaultGroup").AsString() == "Materials");

		// By label, named, in a group made on the way.
		let controls = CallOk(server, "asset_create", With(With(With(Obj(), "creator", "Input Map"), "name", "Controls"), "group", "Input"));
		defer delete controls;
		Test.Assert((controls.Get("name").AsString() == "Controls") && (controls.Get("path").AsString() == "Input/Controls"));

		// By type, where one creator makes it; the creator's own name.
		let cue = CallOk(server, "asset_create", With(Obj(), "type", typeof(Sedulous.Audio.Pipeline.SoundCueAsset).GetFullName(.. scope .())));
		defer delete cue;
		Test.Assert(cue.Get("path").AsString() == "SoundCue");

		// A label in any case; no group lands in the creator's folder.
		let material = CallOk(server, "asset_create", With(Obj(), "creator", "pbr material"));
		defer delete material;
		Test.Assert(material.Get("path").AsString() == "Materials/Material");

		// Refused: a taken name, an unknown creator, a type two creators make.
		let taken = scope String();
		CallErr(server, "asset_create", With(With(With(Obj(), "creator", "Input Map"), "name", "Controls"), "group", "Input"), taken);
		Test.Assert(taken.Contains("already exists"), taken);
		let unknown = scope String();
		CallErr(server, "asset_create", With(Obj(), "creator", "Nope"), unknown);
		Test.Assert(unknown.Contains("no creator"), unknown);
		let ambiguous = scope String();
		CallErr(server, "asset_create", With(Obj(), "type", typeof(Sedulous.Materials.Pipeline.MaterialAsset).GetFullName(.. scope .())), ambiguous);
		Test.Assert(ambiguous.Contains("no single creator"), ambiguous);

		// What was made cooks.
		let cooked = CallOk(server, "asset_cook", Obj());
		defer delete cooked;
		Test.Assert(cooked.Get("failed").AsInt() == 0, scope $"failed {cooked.Get("failed").AsInt()}");
		Test.Assert(cooked.Get("cooked").AsInt() == 3, scope $"cooked {cooked.Get("cooked").AsInt()}");
	}

	/// asset_data_read hands out an asset's envelope; asset_data_write takes an edited one
	/// back only when it loads, as the engine's own reader reads it: an input map gets a Jump
	/// binding, and a foreign guid, a misspelled key and a changed type are each refused with
	/// the stored file untouched.
	[Test]
	public static void AnAgentEditsADataAssetThroughItsEnvelope()
	{
		let dir = Scratch("mcp_asset_data", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let creators = scope AssetCreatorRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		PipelineRegistration.RegisterAllCreators(creators);

		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetCreateTools.Register(server, session, creators, operations);
		AssetDataTools.Register(server, session);
		int announced = 0;
		session.OnAssetWritten = new [&announced](id) => { announced++; };
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Data"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		let made = CallOk(server, "asset_create", With(With(Obj(), "creator", "Input Map"), "name", "Controls"));
		defer delete made;
		let guid = scope String(made.Get("guid").AsString());
		let read = CallOk(server, "asset_data_read", With(Obj(), "guid", guid));
		defer delete read;
		let original = scope String(read.Get("xml").AsString());
		Test.Assert(original.Contains("<string name=\"typeName\">Sedulous.Input.Pipeline.InputMapAsset</string>"));
		let jumpAt = original.IndexOf("<string name=\"name\">Jump</string>");
		Test.Assert(jumpAt > 0);
		let emptyBindings = "<array name=\"bindings\" count=\"0\"/>";
		let bindingsAt = original.IndexOf(emptyBindings, jumpAt);
		Test.Assert(bindingsAt > jumpAt);

		// Jump on Space: the key binding as the input map page writes one.
		let edited = scope String(original);
		edited.Remove(bindingsAt, StringView(emptyBindings).Length);
		edited.Insert(bindingsAt, scope $"""
			<array name="bindings" count="1">
			<u8 name="source">0</u8>
			<u32 name="code">{(uint32)Sedulous.Shell.KeyCode.Space}</u32>
			<u32 name="modifiers">0</u32>
			<i32 name="device">-1</i32>
			<f32 name="deadZone">0.15</f32>
			<f32 name="scale">1</f32>
			<bool name="invert">false</bool>
			<bool name="normalize">true</bool>
			<u32 name="negX">0</u32>
			<u32 name="posX">0</u32>
			<u32 name="negY">0</u32>
			<u32 name="posY">0</u32>
			<f32 name="regionX">0</f32>
			<f32 name="regionY">0</f32>
			<f32 name="regionW">1</f32>
			<f32 name="regionH">1</f32>
			<f32 name="stickRadius">0.15</f32>
			</array>
			""");
		let stored = session.Project.SourceDb.GetInstance(Guid.Parse(guid));
		let before = scope String();
		{
			let envelope = stored.OpenEnvelope();
			defer delete envelope;
			McpTools.ReadAllText(envelope, before);
		}

		// Refusals: each leaves the stored envelope exactly as it was, and announces nothing.
		{
			let otherGuid = scope String(edited);
			otherGuid.Replace(guid, "00000000-0000-0000-0000-000000000001");
			let refused = scope String();
			CallErr(server, "asset_data_write", With(With(Obj(), "guid", guid), "xml", otherGuid), refused);
			Test.Assert(refused.Contains("is not this asset's"), refused);
			let misspelled = scope String(edited);
			misspelled.Replace("<u8 name=\"source\">", "<u8 name=\"sauce\">");
			refused.Clear();
			CallErr(server, "asset_data_write", With(With(Obj(), "guid", guid), "xml", misspelled), refused);
			Test.Assert(refused.Contains("the payload did not read"), refused);
			let retyped = scope String(edited);
			retyped.Replace("Sedulous.Input.Pipeline.InputMapAsset", "Sedulous.Audio.Pipeline.SoundCueAsset");
			refused.Clear();
			CallErr(server, "asset_data_write", With(With(Obj(), "guid", guid), "xml", retyped), refused);
			Test.Assert(refused.Contains("typeName"), refused);
			let after = scope String();
			let envelope = stored.OpenEnvelope();
			defer delete envelope;
			McpTools.ReadAllText(envelope, after);
			Test.Assert(after == before, "a refusal writes nothing");
			Test.Assert(announced == 0);
		}

		let written = CallOk(server, "asset_data_write", With(With(Obj(), "guid", guid), "xml", edited));
		defer delete written;
		Test.Assert(written.Get("written").AsBool());
		Test.Assert(announced == 1);
		let object = stored.ReadObject();
		defer delete object;
		let map = object as Sedulous.Input.Pipeline.InputMapAsset;
		Test.Assert(map != null);
		Sedulous.Input.InputAction jump = null;
		for (let action in map.Map.Sets[0].Actions)
			if (action.Name == "Jump")
				jump = action;
		Test.Assert((jump != null) && (jump.Bindings.Count == 1));
		Test.Assert(jump.Bindings[0].Code == (uint32)Sedulous.Shell.KeyCode.Space);
		Test.Assert(jump.Bindings[0].Source == .Key);
	}

	/// project_settings_set: the settings the Project Settings dialog edits, typed like its
	/// pickers, checked in full first, saved to the manifest, and read back by project_info.
	[Test]
	public static void AnAgentSetsTheProjectsSettings()
	{
		let dir = Scratch("mcp_settings", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let creators = scope AssetCreatorRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		PipelineRegistration.RegisterAllCreators(creators);

		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetCreateTools.Register(server, session, creators, operations);
		int changed = 0;
		session.OnSettingsChanged = new [&changed]() => { changed++; };
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Settings"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		let map = CallOk(server, "asset_create", With(With(Obj(), "creator", "Input Map"), "name", "Controls"));
		defer delete map;
		let scene = CallOk(server, "asset_create", With(With(Obj(), "creator", "Scene"), "name", "Level1"));
		defer delete scene;
		let mapId = scope String(map.Get("guid").AsString());
		let sceneId = scope String(scene.Get("guid").AsString());

		// A scene where an input map goes is refused, and the scene given beside it with it.
		let refused = scope String();
		CallErr(server, "project_settings_set", With(With(Obj(), "defaultInputMap", sceneId), "defaultScene", sceneId), refused);
		Test.Assert(refused.StartsWith("`defaultInputMap` takes a InputMapAsset; 'Level1' is a"), refused);
		Test.Assert(changed == 0);
		{
			let info = CallOk(server, "project_info", Obj());
			defer delete info;
			Test.Assert(info.Get("settings").Get("defaultScene").IsNull, "nothing changed");
		}

		let set = CallOk(server, "project_settings_set", With(With(With(Obj(), "defaultInputMap", mapId), "defaultScene", sceneId), "msaa", 4));
		defer delete set;
		Test.Assert(changed == 1);
		Test.Assert(set.Get("settings").Get("defaultInputMap").Get("path").AsString() == "Controls");
		Test.Assert(set.Get("settings").Get("defaultScene").Get("path").AsString() == "Scenes/Level1");
		Test.Assert(set.Get("settings").Get("msaa").AsInt() == 4);
		Test.Assert(session.Project.Settings.DefaultScene == "Scenes/Level1", "the path mirror follows");

		// Saved: a reopen reads it from the manifest; then "" clears one and leaves the rest.
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		{
			let info = CallOk(server, "project_info", Obj());
			defer delete info;
			Test.Assert(info.Get("settings").Get("defaultInputMap").Get("guid").AsString() == mapId);
		}
		let cleared = CallOk(server, "project_settings_set", With(Obj(), "defaultInputMap", ""));
		defer delete cleared;
		Test.Assert(cleared.Get("settings").Get("defaultInputMap").IsNull);
		Test.Assert(cleared.Get("settings").Get("defaultScene").Get("guid").AsString() == sceneId);
	}

	/// Every enum an input map stores as a number is one type_info names the cases of: an agent
	/// editing bindings through asset_data_write reads the codes against these.
	[Test]
	public static void TypeInfoNamesEveryInputCode()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);
		(StringView type, StringView ns, StringView someCase)[?] expected = .(
			("KeyCode", "Sedulous.Shell", "Space"),
			("MouseButton", "Sedulous.Shell", "Left"),
			("GamepadButton", "Sedulous.Shell", "South"),
			("GamepadAxis", "Sedulous.Shell", "LeftX"),
			("StickCode", "Sedulous.Input", "Right"),
			("MouseAxisCode", "Sedulous.Input", "Wheel"),
			("BindingSource", "Sedulous.Input", "Composite2D"));
		for (let entry in expected)
		{
			let info = CallOk(server, "type_info", With(With(Obj(), "type", entry.type), "namespace", entry.ns));
			defer delete info;
			let cases = info.Get("enum");
			Test.Assert(cases != null, scope $"{entry.ns}.{entry.type} lists no cases");
			Test.Assert(Named(cases, "name", entry.someCase) != null, scope $"{entry.type} has no case '{entry.someCase}'");
		}
	}
}
