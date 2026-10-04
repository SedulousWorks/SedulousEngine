using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Script;
using Sedulous.Script.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.VFS;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The tracked sample project (Data/SampleProjects/PaperKid) must stay readable at the
/// CURRENT data versions: a wire version bump or a key rename that forgets to upgrade its
/// sources leaves it refused by the strict readers. This registers the whole pipeline the way
/// the cook tool does, opens a scratch copy (so opening never writes into the tracked tree),
/// reads every instance back, and cooks it through the tools an agent uses. It registers
/// what it needs itself (the pipeline types; the component reflection and the script surface
/// are comptime here), so it holds when run alone.
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
			// Every instance, counted: a floor catches a group silently skipped. PaperKid has
			// 88: 6 scenes (five blocks and the title), 19 kit prefabs, 11 scripts, 18 audio
			// clips, 4 fonts, 5 meshes, 5 navigation zones, 7 UI documents and their theme, 4
			// particle effects and their sprite, 2 animation clips, a material, the two render
			// profiles, the input map and the minimap's render texture. Raise the floor when the
			// sample grows.
			Test.Assert(read >= 88, scope $"read {read} instances");
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
		// Every buildable asset cooked: 63, all but the scenes and the prefabs, which stage rather
		// than cook. And nothing failed.
		Test.Assert(cooked.Get("cooked").AsInt() >= 63, scope $"cooked {cooked.Get("cooked").AsInt()}");
		Test.Assert(cooked.Get("failed").AsInt() == 0, scope $"{cooked.Get("failed").AsInt()} failed");

		// Every script override a scene or prefab stores, a behaviour's or the Level's, names a
		// property its cooked class declares: the key is the property name's hash, so a hash
		// change that forgets to rehash the sources leaves overrides that silently apply to
		// nothing.
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let overrides = CheckOverrides(project, project.SourceDb.RootGroup);
			// 62: the five blocks' Level settings (35), their camera's and minimap's behaviours
			// (15) and the kit's (12).
			Test.Assert(overrides >= 62, scope $"{overrides} overrides checked");
		}
	}

	/// The number of script overrides checked under `group`: a behaviour's against its cooked
	/// class, and a scene's Level script's against its own.
	private static int CheckOverrides(EditorProject project, Group group)
	{
		int count = 0;
		for (let instance in group.Instances)
		{
			if ((instance.TypeName != McpDocumentNames.cSceneDocument) && (instance.TypeName != McpDocumentNames.cPrefabDocument))
				continue;
			let scene = scope Scene(instance.Name);
			EngineSceneComposition.AddAllSceneManagers(scene);
			if (!(SceneStorage.LoadScene(instance, scene) case .Ok))
				continue;
			let scripts = scene.GetSystem<ScriptComponentManager>();
			for (let component in scripts.Dense)
			{
				for (let behavior in component.Behaviors)
					count += CheckDeclared(project, instance.Name, behavior.Script.Id, behavior.Overrides);
			}
			for (let system in scene.Systems)
			{
				if (system.SettingsType != typeof(SceneScriptSettings))
					continue;
				let level = (SceneScriptSettings)Internal.UnsafeCastToObject(system.SettingsInstance);
				if (level.Script.Id != Guid.Empty)
					count += CheckDeclared(project, instance.Name, level.Script.Id, level.Overrides);
			}
		}
		for (let child in group.Groups)
			count += CheckOverrides(project, child);
		return count;
	}

	/// Each override names a property the script's cooked class declares; answers how many.
	private static int CheckDeclared(EditorProject project, StringView owner, Guid script, List<ScriptPropertyOverride> overrides)
	{
		let stored = project.CookedDb.ReadObject(script);
		defer delete stored;
		let source = stored as ScriptClassSource;
		Test.Assert(source != null, scope $"{owner}: the script is cooked");
		if (source == null)
			return 0;
		for (let o in overrides)
		{
			bool declared = false;
			for (let property in source.Properties)
				declared |= property.Hash == o.Hash;
			Test.Assert(declared, scope $"{owner}: override {o.Hash} names no property of {source.ClassName}");
		}
		return overrides.Count;
	}
}
