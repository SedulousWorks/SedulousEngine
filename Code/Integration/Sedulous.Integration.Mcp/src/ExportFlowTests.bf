using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Composition;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Registration;
using Sedulous.VFS;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// project_export: a REAL dist from an authored project, its player from a stand in build
/// (StagedPlayerBuilder: no compiler runs), plus the refusals: no project, an unknown preset.
static class ExportFlowTests
{
	[Test]
	public static void ProjectExportMakesARealDistFromAnAuthoredProject()
	{
		let dir = Scratch("mcp_export_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		// Where the stand in builds go: the export's player without a compile.
		let playerDir = Scratch("mcp_export_player", .. scope .());
		defer RemoveDirectoryRecursive(playerDir);
		CreateDirectory(playerDir);
		let players = scope StagedPlayerBuilder(playerDir);
		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");

		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, FindDataRoot(.. scope .()));
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		let operations = scope InlineProjectOperations(session, builders, dataRoot);
		operations.Players = players;
		ProjectExportTool.Register(server, session, operations);

		let noProject = scope String();
		CallErr(server, "project_export", Obj(), noProject);
		Test.Assert(noProject.Contains("project_open"));
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Exportable"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		{
			let authored = scope Scene("main");
			EngineSceneComposition.AddAllSceneManagers(authored);
			authored.CreateEntity("anchor");
			let instance = session.Project.SourceDb.RootGroup.CreateInstance("main", McpTools.cSceneDocument);
			Test.Assert(SceneStorage.SaveScene(authored, instance) case .Ok);
		}
		let unknown = scope String();
		CallErr(server, "project_export", With(Obj(), "preset", "NoSuchPreset"), unknown);
		Test.Assert(unknown.Contains("available"), "the refusal lists the presets");

		let exported = CallOk(server, "project_export", Obj());
		defer delete exported;
		Test.Assert(exported.Get("exported").AsBool());
		Test.Assert(exported.Get("scenesStaged").AsInt() >= 1);
		Test.Assert(exported.Get("cookFailed").AsInt() == 0);
		let outputDir = scope String(exported.Get("outputDir").AsString());
		Test.Assert(!outputDir.IsEmpty);
		Test.Assert(FileExists(PathJoin(outputDir, "Content.pak", .. scope .())) && FileExists(PathJoin(outputDir, "player.xml", .. scope .())));
		Test.Assert(FileExists(PathJoin(outputDir, "Data/Engine/Shaders/shaders.dpak", .. scope .())), "the shader pack cooked from the data root");
		Test.Assert(exported.Get("filesStaged").AsInt() >= 1, "the player staged");
		Test.Assert(players.Builds == 1, "the export built its player");
		// Named by the game, the project's name made an identifier.
		Test.Assert(FileExists(PathJoin(outputDir, BuildLayout.ExecutableName("Exportable", .. scope .()), .. scope .())), "the game's player");
		Test.Assert(FileExists(PathJoin(outputDir, StagedPlayerBuilder.cLibrary, .. scope .())), "the libraries its build left beside it");
		Test.Assert(!FileExists(PathJoin(outputDir, StagedPlayerBuilder.cDxcLibrary, .. scope .())), "and not the shader compiler's");
		// The licences the player's binary carries go with it: a file the build leaves beside it.
		Test.Assert(FileExists(PathJoin(outputDir, BuildLayout.cThirdPartyNotices, .. scope .())), "the third-party notices arrive with the player");
	}
}
