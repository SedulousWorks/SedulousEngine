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
using Sedulous.VFS;

namespace Sedulous.Integration.Mcp;

/// asset_rename, the Assets browser's Rename for an agent: the asset keeps its guid, so what used
/// it still does, and the default scene's path follows; a name the rule refuses or one taken in
/// the group is refused, saying why.
static class AssetRenameToolTests
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
	public static void ItKeepsTheGuidTheDefaultScenesPathFollowsBadAndTakenNamesRefused()
	{
		let dir = Scratch("mcp_asset_rename", .. scope .());
		defer RemoveDirectoryRecursive(dir);

		PipelineRegistration.RegisterPipelineTypes();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, FindDataRoot(.. scope .()));
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		let operations = scope InlineProjectOperations(session, builders, "");
		AssetRenameTool.Register(server, session, operations);

		let noProject = scope String();
		CallErr(server, "asset_rename", With(With(Obj(), "guid", "00000000-0000-0000-0000-000000000001"), "name", "x"), noProject);
		Test.Assert(noProject.Contains("project_open"));
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Renaming"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		let level = AuthorScene(session, "level");
		let spare = AuthorScene(session, "spare");
		session.Project.Settings.DefaultSceneId = level;
		session.Project.Settings.DefaultScene.Set("level");
		let db = session.Project.SourceDb;
		JsonValue Rename(Guid id, StringView name) => With(With(Obj(), "guid", id.ToString(.. scope .())), "name", name);

		// Renamed, the guid kept.
		{
			let renamed = CallOk(server, "asset_rename", Rename(spare, "granite"));
			defer delete renamed;
			Test.Assert(renamed.Get("name").AsString() == "granite");
			Test.Assert(renamed.Get("path").AsString() == "granite");
			Test.Assert((db.GetInstance(spare) != null) && (db.GetInstance(spare).Name == "granite"));
			Test.Assert(db.GetInstanceByPath("spare") == null);
		}

		// The default scene's path follows its rename.
		delete CallOk(server, "asset_rename", Rename(level, "Level1"));
		Test.Assert(session.Project.Settings.DefaultSceneId == level);
		Test.Assert(session.Project.Settings.DefaultScene == "Level1");

		// Refused, saying why; nothing renamed.
		let taken = scope String();
		CallErr(server, "asset_rename", Rename(level, "granite"), taken);
		Test.Assert(taken.StartsWith("an asset named 'granite' already exists"), taken);
		let slash = scope String();
		CallErr(server, "asset_rename", Rename(level, "a/b"), slash);
		Test.Assert(slash == "A name cannot hold /.", slash);
		let dot = scope String();
		CallErr(server, "asset_rename", Rename(level, "level."), dot);
		Test.Assert(dot == "A name cannot start or end with a space, or end with a dot.", dot);
		Test.Assert(db.GetInstance(level).Name == "Level1");
		let unknown = scope String();
		CallErr(server, "asset_rename", Rename(Guid(0x31, 0x32, 0, 0, 0, 0, 0, 0, 0, 0, 0), "x"), unknown);
		Test.Assert(unknown.StartsWith("no asset with guid"), unknown);
		let bad = scope String();
		CallErr(server, "asset_rename", With(With(Obj(), "guid", "not-a-guid"), "name", "x"), bad);
		Test.Assert(bad.Contains("invalid guid"), bad);
	}
}
