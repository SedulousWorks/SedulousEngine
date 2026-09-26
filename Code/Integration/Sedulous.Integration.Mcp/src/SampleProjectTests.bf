using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.SceneSurface;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.VFS;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The tracked sample project (Data/SampleProjects/PaperKid) must stay readable at the
/// CURRENT data versions: a wire version bump or a key rename that forgets to upgrade its
/// sources leaves it refused by the strict readers. This registers the whole pipeline the way
/// the cook tool does, opens a scratch copy (so opening never writes into the tracked tree),
/// reads every instance back, and cooks it through the tools an agent uses.
static class SampleProjectTests
{
	/// Every instance under a group, recursively, reads back. A scene or prefab is its STREAM,
	/// not its document: the entities, components and system settings carry their own data
	/// versions, so the stream loads into a scratch scene of the full composition the way a
	/// page opens it.
	private static int ReadAllInstances(Group group)
	{
		int read = 0;
		for (let instance in group.Instances)
		{
			let object = instance.ReadObject();
			Test.Assert(object != null, scope $"sample project instance refused: {instance.Name}");
			if (object != null)
				delete object;
			if ((instance.TypeName == McpDocumentNames.cSceneDocument) || (instance.TypeName == McpDocumentNames.cPrefabDocument))
			{
				let scratch = scope Scene(instance.Name);
				EngineSceneComposition.AddAllSceneManagers(scratch);
				Test.Assert(SceneStorage.LoadScene(instance, scratch) case .Ok, scope $"sample project scene stream refused: {instance.Name}");
			}
			read++;
		}
		for (let child in group.Groups)
			read += ReadAllInstances(child);
		return read;
	}

	[Test]
	public static void EveryPaperKidSourceReadsAtTheCurrentDataVersionsAndCooks()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();

		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");
		let source = PathJoin(dataRoot, "SampleProjects/PaperKid", .. scope .());
		Test.Assert(DirectoryExists(source));

		let dir = Scratch("scratch_paperkid_versions", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(ExportTemplates.CopyTree(source, dir), "the sample copies to scratch");
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let read = ReadAllInstances(project.SourceDb.RootGroup);
			Test.Assert(read > 0);
		}

		// And it COOKS, through the same tools an agent uses.
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllImporters(importers);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetWriteTools.Register(server, session, importers, operations);
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		let force = Obj();
		force.Set("force", JsonValue.MakeBool(true));
		let cooked = CallOk(server, "asset_cook", force);
		defer delete cooked;
		Test.Assert(cooked.Get("cooked").AsInt() > 0);
		Test.Assert(cooked.Get("failed").AsInt() == 0, scope $"{cooked.Get("failed").AsInt()} failed");
	}
}
