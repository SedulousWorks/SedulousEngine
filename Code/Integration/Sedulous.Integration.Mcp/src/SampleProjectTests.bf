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

/// The tracked sample projects (Data/SampleProjects: PaperKid, Shader Gallery) must stay
/// readable at the CURRENT data versions: a wire version bump or a key rename that forgets to
/// upgrade their sources leaves them refused by the strict readers. This registers the whole pipeline the way
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

	/// Reads every instance of the sample in Data/SampleProjects/`name` from a scratch copy,
	/// cooks it through the tools an agent uses, and checks every script override it stores names
	/// a property of its cooked class. The floors catch a group silently skipped or a cook that
	/// built less than the sample has.
	private static void CheckSampleProject(StringView name, StringView scratch, int readFloor, int cookedFloor, int overrideFloor)
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();

		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");
		let source = PathJoin(dataRoot, scope $"SampleProjects/{name}", .. scope .());
		Test.Assert(DirectoryExists(source));

		let dir = Scratch(scratch, .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(ExportTemplates.CopyTree(source, dir), "the sample copies to scratch");
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let read = ReadAllInstances(project.SourceDb.RootGroup);
			Test.Assert(read >= readFloor, scope $"{name}: read {read} instances");
		}

		// And it COOKS, through the same tools an agent uses.
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, FindDataRoot(.. scope .()));
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
		Test.Assert(cooked.Get("cooked").AsInt() >= cookedFloor, scope $"{name}: cooked {cooked.Get("cooked").AsInt()}");
		Test.Assert(cooked.Get("failed").AsInt() == 0, scope $"{name}: {cooked.Get("failed").AsInt()} failed");

		// Every script override a scene or prefab stores, a behaviour's or the Level's, names a
		// property its cooked class declares: the key is the property name's hash, so a hash
		// change that forgets to rehash the sources leaves overrides that silently apply to
		// nothing.
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let overrides = CheckOverrides(project, project.SourceDb.RootGroup);
			Test.Assert(overrides >= overrideFloor, scope $"{name}: {overrides} overrides checked");
		}
	}

	[Test]
	public static void EveryPaperKidSourceReadsAtTheCurrentDataVersionsAndCooks()
	{
		// 234 instances: 6 scenes (five blocks and the title), 19 kit prefabs, 13 scripts, 18
		// audio clips, 4 fonts, 5 meshes, 5 navigation zones, 7 UI documents and their theme, 4
		// particle effects and their sprite, 2 animation clips, a material, the two render
		// profiles, the input map, the minimap's render texture, and the 13 Blender models with
		// their prefabs, meshes, materials, skeletons and clips (146). 196 cook: all but the
		// scenes and the prefabs, which stage rather than cook. 107 overrides: the five blocks'
		// Level settings (35), their camera's and minimap's behaviours (15), the kit's (13, the
		// pedestrian's walk clip among them) and the title street's strollers and pets (44).
		// Raise the floors when the sample grows.
		CheckSampleProject("PaperKid", "scratch_paperkid_versions", 234, 196, 107);
	}

	[Test]
	public static void TheShaderGallerySourcesReadAtTheCurrentDataVersionsAndCook()
	{
		// 50 instances: 11 lesson shaders (surface and low-level, every program compiled by the
		// cook) and their materials, the hall's 3 materials, 4 textures and the sky, 4 Blender
		// models with their meshes and prefabs, the 3 primitives, the hall, the camera's script,
		// the list, the font and the input map. 45 cook: all but the hall and the 4 prefabs. The 2
		// overrides are the camera's starting yaw and pitch.
		CheckSampleProject("ShaderGallery", "scratch_shadergallery_versions", 50, 45, 2);
	}

	[Test]
	public static void TheMasqueradeSourcesReadAtTheCurrentDataVersionsAndCook()
	{
		// 326 instances: 3 maps and 3 hunter prefabs, 6 rigged costumes with their clips and
		// materials, the palace, canal and garden kits, 3 navigation zones, 6 scripts, 4 UI
		// documents, the profiles, the input map, the font, the sky and the primitives. 281 cook:
		// all but the maps, the prefabs and the model manifests. The 957 overrides are the
		// guests', bots', player's, camera's and Ball's settings and references. Raise the floors
		// when the sample grows (its look and sound are still to come).
		CheckSampleProject("Masquerade", "scratch_masquerade_versions", 326, 281, 957);
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
