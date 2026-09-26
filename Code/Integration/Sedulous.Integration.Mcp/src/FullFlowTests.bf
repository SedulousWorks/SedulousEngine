using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.SceneSurface;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Script.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// ONE sequence through the tools in the order the guide teaches: create, open, import a
/// real source (the starter), cook it clean, write a scene from a real save, validate it
/// by guid, and read the project as sound with nothing dirty and nothing failed.
static class FullFlowTests
{
	[Test]
	public static void TheFullAgentFlow()
	{
		let dir = Scratch("mcp_full_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		PipelineRegistration.RegisterAllImporters(importers);

		// The flow runs over the SHARED engine surface (what every host serves) plus the
		// stdio host's project_create and project_open.
		let server = scope McpServer();
		let logBuffer = scope EditorLogBuffer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		let operations = scope InlineProjectOperations(session, builders, "", "");
		EngineTools.Register(server, session, builders, importers, logBuffer, scope EngineToolPaths(), operations);
		ProjectOpenTools.Register(server, session, owner);

		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Full"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		// A real source: the backend's own behavior starter, on disk.
		let starter = scope String();
		ScriptLanguageCooks.Find("angelscript").NewAssetTemplate(.Behavior, starter);
		let sourcePath = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "mcp_full_starter.as", .. scope .());
		defer DeleteFile(sourcePath);
		File.WriteAllText(sourcePath, starter).IgnoreError();
		let imported = CallOk(server, "asset_import", With(With(Obj(), "source", sourcePath), "group", "scripts"));
		defer delete imported;
		Test.Assert(imported.Get("type").AsString() == typeof(ScriptClassAsset).GetFullName(.. scope .()));

		let cooked = CallOk(server, "asset_cook", Obj());
		defer delete cooked;
		Test.Assert(cooked.Get("cooked").AsInt() >= 1);
		Test.Assert(cooked.Get("failed").AsInt() == 0);

		// A scene from a real save, written through the tool and validated by guid.
		let xml = scope String();
		{
			let authored = scope Scene("hub");
			EngineSceneComposition.AddAllSceneManagers(authored);
			let root = authored.CreateEntity("root");
			authored.SetParent(authored.CreateEntity("child"), root);
			let seed = session.Project.SourceDb.RootGroup.CreateInstance("seed", McpTools.cSceneDocument);
			Test.Assert(SceneStorage.SaveScene(authored, seed) case .Ok);
			Test.Assert(McpTools.ReadSceneStream(seed, xml));
			Test.Assert(session.Project.SourceDb.DeleteInstance(seed.Id) case .Ok);
		}
		let written = CallOk(server, "scene_write", With(With(Obj(), "xml", xml), "name", "hub"));
		defer delete written;
		let valid = CallOk(server, "scene_validate", With(Obj(), "guid", written.Get("guid").AsString()));
		defer delete valid;
		Test.Assert(valid.Get("valid").AsBool());
		Test.Assert(valid.Get("componentValidation").AsString() == "full");

		let health = CallOk(server, "project_health", Obj());
		defer delete health;
		Test.Assert(health.Get("sound").AsBool());
		Test.Assert(health.Get("dirty").AsInt() == 0, scope $"{health.Get("dirty").AsInt()} dirty");
		Test.Assert(health.Get("failedCooks").AsInt() == 0);
	}

	/// EngineTools registers exactly cEngineToolCount tools: the surface every host serves,
	/// and only that.
	[Test]
	public static void EngineToolsRegistersExactlyTheSharedSurface()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		let logBuffer = scope EditorLogBuffer();
		let session = scope ProjectSession();

		let server = scope McpServer();
		let operations = scope InlineProjectOperations(session, builders, "", "");
		EngineTools.Register(server, session, builders, importers, logBuffer, scope EngineToolPaths(), operations);
		Test.Assert(server.ToolCount == EngineTools.cEngineToolCount, scope $"{server.ToolCount} tools");

		let listed = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}");
		defer delete listed;
		let tools = listed.Get("result").Get("tools");
		bool Has(StringView name)
		{
			for (int i < tools.Count)
				if (tools.At(i).Get("name").AsString() == name)
					return true;
			return false;
		}
		// Spot checks across the families the root gathers ...
		Test.Assert(Has("type_list"));
		Test.Assert(Has("script_api"));
		Test.Assert(Has("project_info"));
		Test.Assert(Has("asset_cook"));
		Test.Assert(Has("scene_write"));
		Test.Assert(Has("project_export"));
		Test.Assert(Has("known_issues"));
		// ... and what a HOST adds itself: never part of the shared surface.
		Test.Assert(!Has("project_open"));
		Test.Assert(!Has("project_create"));
		Test.Assert(!Has("host_info"));
	}

	/// LocateShippingDocs walks up to the checkout layout, accepts the distribution layout,
	/// and leaves a miss empty.
	[Test]
	public static void LocateShippingDocsFindsTheCheckoutAndTheDistribution()
	{
		RemoveDirectoryRecursive("mcp_docs_checkout");
		RemoveDirectoryRecursive("mcp_docs_dist");
		defer { RemoveDirectoryRecursive("mcp_docs_checkout"); RemoveDirectoryRecursive("mcp_docs_dist"); }
		for (let d in scope String[]("mcp_docs_checkout", "mcp_docs_checkout/Documentation",
			"mcp_docs_checkout/Documentation/Shipping", "mcp_docs_checkout/Bin", "mcp_docs_checkout/Bin/Debug",
			"mcp_docs_dist", "mcp_docs_dist/tool"))
			CreateDirectory(d);
		File.WriteAllText("mcp_docs_checkout/Documentation/Shipping/KnownIssues.md", "# known").IgnoreError();
		File.WriteAllText("mcp_docs_checkout/Documentation/Shipping/McpGuide.md", "# guide").IgnoreError();
		File.WriteAllText("mcp_docs_dist/KnownIssues.md", "# staged").IgnoreError();

		// The engine checkout: the executable sits under Bin, the docs two levels up.
		{
			let paths = scope EngineToolPaths();
			paths.LocateShippingDocs(scope StringView[]("mcp_docs_checkout/Bin/Debug"));
			Test.Assert(paths.ShippingDocsDir == "mcp_docs_checkout/Documentation/Shipping");
			Test.Assert(paths.KnownIssues == "mcp_docs_checkout/Documentation/Shipping/KnownIssues.md");
		}
		// A distribution: KnownIssues.md staged beside the tool, no docs directory at all.
		{
			let paths = scope EngineToolPaths();
			paths.LocateShippingDocs(scope StringView[]("mcp_docs_dist/tool"));
			Test.Assert(paths.KnownIssues == "mcp_docs_dist/KnownIssues.md");
			Test.Assert(paths.ShippingDocsDir.IsEmpty);
		}
		// A later start fills what an earlier one could not.
		{
			let paths = scope EngineToolPaths();
			paths.LocateShippingDocs(scope StringView[]("mcp_docs_dist/tool", "mcp_docs_checkout/Bin/Debug"));
			Test.Assert(paths.KnownIssues == "mcp_docs_dist/KnownIssues.md"); // the first hit stands
			Test.Assert(paths.ShippingDocsDir == "mcp_docs_checkout/Documentation/Shipping");
		}
		// Nowhere: both fields stay empty and nothing is invented.
		{
			let paths = scope EngineToolPaths();
			paths.LocateShippingDocs(scope StringView[]("mcp_docs_nowhere/q"));
			Test.Assert(paths.KnownIssues.IsEmpty);
			Test.Assert(paths.ShippingDocsDir.IsEmpty);
		}
	}

	/// A host whose operations take several pumps: every step answers not yet until the
	/// configured entry, then the outcome. The shape of the editor's background services,
	/// minus the services.
	class SlowOperations : IProjectOperations
	{
		public int AnswerOnEntry = 3;
		public int CookEntries = 0;
		public int ImportEntries = 0;
		public int ExportEntries = 0;
		public bool RefuseCook = false;

		public OperationStep Cook(bool force, ref CookOutcome outOutcome, String outError)
		{
			CookEntries++;
			if (RefuseCook)
			{
				outError.Set("a cook is already running (the editor's build lock)");
				return .Failed;
			}
			if (CookEntries < AnswerOnEntry)
				return .NotYet;
			outOutcome.Planned = force ? 7 : 2;
			outOutcome.Cooked = outOutcome.Planned;
			return .Finished;
		}

		public OperationStep Import(ImportRequest request, ImportOutcome outOutcome, String outError)
		{
			ImportEntries++;
			if (ImportEntries < AnswerOnEntry)
				return .NotYet;
			outOutcome.Name.Set("Mover");
			return .Finished;
		}

		public OperationStep Export(ExportRequest request, ExportResult outResult, String outError)
		{
			ExportEntries++;
			if (ExportEntries < AnswerOnEntry)
				return .NotYet;
			PathJoin(request.OutRoot, request.Preset.Name, outResult.OutputDir);
			outResult.FilesStaged = 1;
			return .Finished;
		}
	}

	private static String ToolCallLine(StringView tool, StringView argumentsJson, String outLine)
	{
		outLine.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", tool, argumentsJson);
		return outLine;
	}

	/// Handles a line expected to be answered: the parsed response, OWNED by the caller.
	private static JsonValue Answered(McpServer server, StringView line)
	{
		let reply = scope String();
		Test.Assert(server.HandleLine(line, reply) == .Answered);
		return JsonValue.Parse(reply);
	}

	/// The write tools ride a host's operations: not finished until the host says so, then the
	/// shared result shape; a refusal is the tool's error.
	[Test]
	public static void TheWriteToolsRideAHostsOperations()
	{
		let dir = Scratch("mcp_slow_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllImporters(importers);

		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		let slow = scope SlowOperations();
		ProjectOpenTools.Register(server, session, owner);
		AssetWriteTools.Register(server, session, importers, slow);
		ProjectExportTool.Register(server, session, slow);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Slow"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		let ignored = scope String();

		// asset_cook: two not yet re-entries with the SAME line, then the counts.
		let cook = ToolCallLine("asset_cook", "{\"force\":true}", .. scope .());
		Test.Assert(server.HandleLine(cook, ignored) == .NotFinished);
		Test.Assert(server.HandleLine(cook, ignored) == .NotFinished);
		{
			let response = Answered(server, cook);
			defer delete response;
			let result = response.Get("result");
			Test.Assert(!result.Get("isError").AsBool());
			let payload = JsonValue.Parse(result.Get("content").At(0).Get("text").AsString());
			defer delete payload;
			Test.Assert(payload.Get("planned").AsInt() == 7);
		}
		Test.Assert(slow.CookEntries == 3);

		// asset_import: the routing refusal never reaches the operations; a routed file does.
		{
			let response = Answered(server, ToolCallLine("asset_import", "{\"source\":\"nothing.zzz\"}", .. scope .()));
			defer delete response;
			let result = response.Get("result");
			Test.Assert(result.Get("isError").AsBool());
		}
		Test.Assert(slow.ImportEntries == 0);
		let import = ToolCallLine("asset_import", "{\"source\":\"Mover.as\"}", .. scope .());
		Test.Assert(server.HandleLine(import, ignored) == .NotFinished);
		Test.Assert(server.HandleLine(import, ignored) == .NotFinished);
		{
			let response = Answered(server, import);
			defer delete response;
			let result = response.Get("result");
			Test.Assert(!result.Get("isError").AsBool());
			let payload = JsonValue.Parse(result.Get("content").At(0).Get("text").AsString());
			defer delete payload;
			Test.Assert(payload.Get("name").AsString() == "Mover");
		}

		// project_export: the preset is resolved by the tool (the synthesized host preset
		// here), the work by the operations.
		let export = ToolCallLine("project_export", "{}", .. scope .());
		Test.Assert(server.HandleLine(export, ignored) == .NotFinished);
		Test.Assert(server.HandleLine(export, ignored) == .NotFinished);
		{
			let response = Answered(server, export);
			defer delete response;
			let result = response.Get("result");
			Test.Assert(!result.Get("isError").AsBool());
			let payload = JsonValue.Parse(result.Get("content").At(0).Get("text").AsString());
			defer delete payload;
			Test.Assert(payload.Get("filesStaged").AsInt() == 1);
		}
		Test.Assert(slow.ExportEntries == 3);

		// A refusal from the operations is the tool's error text, at once.
		slow.RefuseCook = true;
		{
			let response = Answered(server, cook);
			defer delete response;
			let result = response.Get("result");
			Test.Assert(result.Get("isError").AsBool());
			Test.Assert(result.Get("content").At(0).Get("text").AsString() == "a cook is already running (the editor's build lock)");
		}
	}
}
