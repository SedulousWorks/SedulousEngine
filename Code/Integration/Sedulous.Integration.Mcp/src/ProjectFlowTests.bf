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
		ProjectTools.Register(server, session);

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
		ProjectTools.Register(server, session);
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
		ProjectTools.Register(server, session);
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
		ProjectTools.Register(server, session);
		AssetTools.Register(server, session);
		AssetWriteTools.Register(server, session, builders, importers);
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
		ProjectTools.Register(server, session);
		AssetWriteTools.Register(server, session, builders, importers);
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
	/// surface the cooks compile against contains the runtime's facades.
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
		Test.Assert(reported.Get("typeCount").AsInt() > 100);
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
}
