using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Pipeline.Registration;
using Sedulous.Script.Pipeline;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// script_validate and script_create over the real cooks: every tier's starter compiles
/// through the tool, broken source reports a line, a created asset's file validates, and
/// names uniquify.
static class ScriptToolsTests
{
	[Test]
	public static void EveryStartersCompilesAndBrokenSourceReportsALine()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let server = scope McpServer();
		ScriptValidateTool.Register(server);

		let cook = ScriptLanguageCooks.Find("angelscript");
		Test.Assert(cook != null);
		// The harvest names `on` handlers; the game's launch/update/exit are invoked by
		// name by the run and are not handlers, so the Game starter proves its class only.
		for (let (tier, className, handler) in scope (ScriptTier, StringView, StringView)[](
			(.Behavior, "NewBehavior", "onUpdate"), (.Level, "Level", "onStart"), (.Game, "Game", "")))
		{
			let starter = scope String();
			cook.NewAssetTemplate(tier, starter);
			let ok = CallOk(server, "script_validate", With(With(With(Obj(), "source", starter), "language", "angelscript"), "name", "Starter.as"));
			defer delete ok;
			Test.Assert(ok.Get("valid").AsBool(), scope $"{tier}: {ok.Get("errors").ToString(.. scope .())}");
			Test.Assert(ok.Get("errors").Count == 0);
			Test.Assert(ok.Get("className").AsString() == className, scope $"{tier} -> {ok.Get("className").AsString()}");
			Test.Assert(handler.IsEmpty || HasString(ok.Get("handlers"), handler), scope $"{tier}: {handler} harvested");
			Test.Assert(ok.Get("checkLevel").AsString() == "compile");
		}

		let bad = CallOk(server, "script_validate", With(With(Obj(), "source", "class Broken {\n  void onUpdate(float dt) { this is not code }\n}\n"), "language", "angelscript"));
		defer delete bad;
		Test.Assert(!bad.Get("valid").AsBool());
		Test.Assert(bad.Get("errors").Count >= 1);
		Test.Assert(bad.Get("errors").At(0).Get("line").AsInt() >= 1, "the line is read off the message");
		Test.Assert(!bad.Get("errors").At(0).Get("message").AsString().IsEmpty);

		// A missing required argument is a PROTOCOL error, -32602, not a tool failure.
		let response = CallResponse(server, "script_validate", With(Obj(), "language", "angelscript"));
		defer delete response;
		Test.Assert((response.Get("error") != null) && (response.Get("error").Get("code").AsInt() == -32602));

		// A backend this host has no cook for is a tool error with guidance; the schema
		// enum stops "cobol" earlier, so the check is on a host with no cooks at all.
		PipelineRegistration.Teardown();
		let bare = scope McpServer();
		ScriptValidateTool.Register(bare);
		let none = CallResponse(bare, "script_validate", With(With(Obj(), "source", "x"), "language", "angelscript"));
		defer delete none;
		Test.Assert((none.Get("error") != null) || none.Get("result").Get("isError").AsBool(), "refused one way or the other");
	}

	[Test]
	public static void ScriptCreateSeedsAStarterAssetThatValidatesAndUniquifies()
	{
		let dir = Scratch("mcp_script_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		AssetTools.Register(server, session);
		ScriptValidateTool.Register(server);
		ScriptCreateTool.Register(server, session);

		// No project: a refusal with guidance.
		let refused = scope String();
		CallErr(server, "script_create", With(With(Obj(), "name", "Mover"), "language", "angelscript"), refused);
		Test.Assert(refused.Contains("project_open"));

		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Scripts"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		let created = CallOk(server, "script_create", With(With(With(Obj(), "name", "Mover"), "language", "angelscript"), "group", "gameplay"));
		defer delete created;
		Test.Assert(created.Get("name").AsString() == "Mover");
		Test.Assert(created.Get("fileName").AsString() == "Mover.as");
		Test.Assert(created.Get("tier").AsString() == "behavior");
		let sourceFile = scope String(created.Get("sourceFile").AsString());
		Test.Assert(FileExists(sourceFile), "the starter is on disk");

		// The file's content validates through the tool: the tools compose.
		let source = scope String();
		Test.Assert(File.ReadAllText(sourceFile, source) case .Ok);
		let validated = CallOk(server, "script_validate", With(With(Obj(), "source", source), "language", "angelscript"));
		defer delete validated;
		Test.Assert(validated.Get("valid").AsBool());
		Test.Assert(validated.Get("className").AsString() == "NewBehavior");

		// The asset is in the source database, in its group.
		let info = CallOk(server, "asset_info", With(Obj(), "guid", created.Get("guid").AsString()));
		defer delete info;
		Test.Assert(info.Get("type").AsString() == typeof(ScriptClassAsset).GetFullName(.. scope .()));
		Test.Assert(info.Get("group").AsString() == "gameplay");

		// A second Mover uniquifies rather than overwriting.
		let second = CallOk(server, "script_create", With(With(With(Obj(), "name", "Mover"), "language", "angelscript"), "group", "gameplay"));
		defer delete second;
		Test.Assert(second.Get("name").AsString() != "Mover");
		Test.Assert(second.Get("guid").AsString() != created.Get("guid").AsString());

		// The game tier seeds the reserved class.
		let game = CallOk(server, "script_create", With(With(With(Obj(), "name", "Main"), "language", "angelscript"), "tier", "game"));
		defer delete game;
		let gameSource = scope String();
		Test.Assert(File.ReadAllText(scope String(game.Get("sourceFile").AsString()), gameSource) case .Ok);
		Test.Assert(gameSource.Contains("class Game"));
	}
}
