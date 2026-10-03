using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Composition;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// asset_delete: an unused asset goes; one the project still uses is refused with its users
/// named, and nothing changes; force deletes it anyway.
static class AssetDeleteToolTests
{
	private static Guid AuthorScene(ProjectSession session, StringView name)
	{
		let authored = scope Scene(name);
		EngineSceneComposition.AddAllSceneManagers(authored);
		authored.CreateEntity("anchor");
		let instance = session.Project.SourceDb.RootGroup.CreateInstance(name, McpTools.cSceneDocument);
		Test.Assert(SceneStorage.SaveScene(authored, instance) case .Ok);
		return instance.Id;
	}

	[Test]
	public static void AnUnusedAssetGoesAndAUsedOneIsRefusedUnlessForced()
	{
		let dir = Scratch("mcp_asset_delete", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetDeleteTool.Register(server, session, builders, operations);

		let noProject = scope String();
		CallErr(server, "asset_delete", With(Obj(), "guid", "00000000-0000-0000-0000-000000000001"), noProject);
		Test.Assert(noProject.Contains("project_open"));
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Deleting"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		let main = AuthorScene(session, "main");
		let spare = AuthorScene(session, "spare");
		session.Project.Settings.DefaultSceneId = main;
		let db = session.Project.SourceDb;

		// Unused: it goes.
		{
			let deleted = CallOk(server, "asset_delete", With(Obj(), "guid", spare.ToString(.. scope .())));
			defer delete deleted;
			Test.Assert(deleted.Get("deleted").AsBool());
			Test.Assert(deleted.Get("name").AsString() == "spare");
			Test.Assert(db.GetInstance(spare) == null);
		}

		// The default scene: refused, its user named, and still there.
		let refusal = scope String();
		CallErr(server, "asset_delete", With(Obj(), "guid", main.ToString(.. scope .())), refusal);
		Test.Assert(refusal.Contains("defaultSceneId"), refusal);
		Test.Assert(refusal.Contains("Nothing was deleted"));
		Test.Assert(db.GetInstance(main) != null);

		// Forced: it goes, the reference left for the agent to fix.
		{
			let args = With(Obj(), "guid", main.ToString(.. scope .()));
			args.Set("force", JsonValue.MakeBool(true));
			let deleted = CallOk(server, "asset_delete", args);
			defer delete deleted;
			Test.Assert(db.GetInstance(main) == null);
		}

		let unknown = scope String();
		CallErr(server, "asset_delete", With(Obj(), "guid", spare.ToString(.. scope .())), unknown);
		Test.Assert(unknown.Contains("no asset"));
	}
}
