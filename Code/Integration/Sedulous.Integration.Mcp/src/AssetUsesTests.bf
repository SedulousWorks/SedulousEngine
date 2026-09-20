using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Render;
using Sedulous.Engine.SceneSurface;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Registration;
using Sedulous.Texture.Pipeline;
using Sedulous.Materials.Pipeline;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// asset_uses across every edge kind on a real project: an asset to asset edge (a material's
/// texture, through the builder's ScanDependencies), a scene to asset edge (a mesh
/// component's Ref, through the full manager load and the factory less collector) and a
/// project settings edge; then project_health finding what broke and healing.
static class AssetUsesTests
{
	private static bool HasEdge(JsonValue use, StringView kind) => HasString(use.Get("edges"), kind);

	[Test]
	public static void AssetUsesFindsEveryEdgeKind()
	{
		let dir = Scratch("mcp_uses_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		let server = scope McpServer();
		let session = scope ProjectSession();
		ProjectTools.Register(server, session);
		AssetUsesTool.Register(server, session, builders);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Uses"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		let root = session.Project.SourceDb.RootGroup;

		// The target: a texture.
		let tex = root.CreateInstance("stone", typeof(TextureAsset).GetFullName(.. scope .()));
		Test.Assert(tex != null);
		{
			let asset = scope TextureAsset();
			Test.Assert(tex.WriteObject(asset) case .Ok);
		}
		let texGuid = tex.Id.ToString(.. scope .());

		// User 1, asset to asset: a material whose slot names the texture.
		let mat = root.CreateInstance("wall", typeof(MaterialAsset).GetFullName(.. scope .()));
		{
			let asset = scope MaterialAsset();
			asset.Source.TextureSlots.Add(new String("albedo"));
			asset.Source.TextureIds.Add(tex.Id);
			Test.Assert(mat.WriteObject(asset) case .Ok);
		}
		let matGuid = mat.Id.ToString(.. scope .());

		// User 2, scene to asset: a mesh component's Ref carrying the texture's guid (any
		// guid a component Ref holds is a scene resource edge).
		let sceneGuid = scope String();
		{
			let authored = scope Scene("arena");
			EngineSceneComposition.AddAllSceneManagers(authored);
			let e = authored.CreateEntity("wall");
			let meshes = authored.GetSystem<MeshComponentManager>();
			Test.Assert(meshes != null);
			meshes.Add(e).Mesh.SetId(tex.Id);
			let instance = root.CreateInstance("arena", McpTools.cSceneDocument);
			Test.Assert(SceneStorage.SaveScene(authored, instance) case .Ok);
			instance.Id.ToString(sceneGuid);
		}

		let uses = CallOk(server, "asset_uses", With(Obj(), "guid", texGuid));
		defer delete uses;
		Test.Assert(uses.Get("useCount").AsInt() == 2, scope $"{uses.Get("useCount").AsInt()} users");
		let matUse = Named(uses.Get("usedBy"), "guid", matGuid);
		Test.Assert((matUse != null) && HasEdge(matUse, "references"));
		let sceneUse = Named(uses.Get("usedBy"), "guid", sceneGuid);
		Test.Assert((sceneUse != null) && HasEdge(sceneUse, "scene-resource"));
		Test.Assert(uses.Get("projectSettingsUses").Count == 0);

		// The project settings edge: the default scene.
		session.Project.Settings.DefaultSceneId = Guid.Parse(sceneGuid).Get();
		let sceneUses = CallOk(server, "asset_uses", With(Obj(), "guid", sceneGuid));
		defer delete sceneUses;
		Test.Assert(sceneUses.Get("useCount").AsInt() == 0);
		Test.Assert((sceneUses.Get("projectSettingsUses").Count == 1)
			&& (sceneUses.Get("projectSettingsUses").At(0).AsString() == "defaultScene"));

		// Nothing uses the material: empty, honestly.
		let matUses = CallOk(server, "asset_uses", With(Obj(), "guid", matGuid));
		defer delete matUses;
		Test.Assert(matUses.Get("useCount").AsInt() == 0);

		// The refusals carry reasons.
		let malformed = scope String();
		CallErr(server, "asset_uses", With(Obj(), "guid", "not-a-guid"), malformed);
		Test.Assert(malformed.Contains("invalid guid"));
		let unknown = scope String();
		CallErr(server, "asset_uses", With(Obj(), "guid", "00000000-0000-0000-0000-000000000001"), unknown);
		Test.Assert(unknown.Contains("asset_list"));
	}

	[Test]
	public static void ProjectHealthFindsWhatBrokeAndHealing()
	{
		let dir = Scratch("mcp_health_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		let server = scope McpServer();
		let session = scope ProjectSession();
		ProjectTools.Register(server, session);
		ProjectHealthTool.Register(server, session, builders);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Health"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		let root = session.Project.SourceDb.RootGroup;

		// An empty project is sound.
		let clean = CallOk(server, "project_health", Obj());
		defer delete clean;
		Test.Assert(clean.Get("sound").AsBool() && (clean.Get("dirty").AsInt() == 0) && (clean.Get("danglingRefs").Count == 0));

		// Intact references while dirty: still sound.
		let tex = root.CreateInstance("stone", typeof(TextureAsset).GetFullName(.. scope .()));
		Test.Assert(tex.WriteObject(scope TextureAsset()) case .Ok);
		let mat = root.CreateInstance("wall", typeof(MaterialAsset).GetFullName(.. scope .()));
		{
			let asset = scope MaterialAsset();
			asset.Source.TextureSlots.Add(new String("albedo"));
			asset.Source.TextureIds.Add(tex.Id);
			Test.Assert(mat.WriteObject(asset) case .Ok);
		}
		let intact = CallOk(server, "project_health", Obj());
		defer delete intact;
		Test.Assert(intact.Get("sound").AsBool() && (intact.Get("dirty").AsInt() >= 2) && (intact.Get("danglingRefs").Count == 0));

		// An empty cue is a WARNING, not a break; a cue with a clip is not flagged.
		let emptyCue = root.CreateInstance("silence", typeof(SoundCueAsset).GetFullName(.. scope .()));
		Test.Assert(emptyCue.WriteObject(scope SoundCueAsset()) case .Ok);
		let filledCue = root.CreateInstance("footstep", typeof(SoundCueAsset).GetFullName(.. scope .()));
		{
			let asset = scope SoundCueAsset();
			asset.Slots[0].ClipId = tex.Id;
			Test.Assert(filledCue.WriteObject(asset) case .Ok);
		}
		let withCues = CallOk(server, "project_health", Obj());
		defer delete withCues;
		Test.Assert(withCues.Get("sound").AsBool());
		Test.Assert((withCues.Get("emptyCues").Count == 1) && (withCues.Get("emptyCues").At(0).Get("name").AsString() == "silence"));

		// Break three things at once: a material referencing a missing texture, a scene
		// component Ref to the same missing guid, and the default scene pointing at it.
		let missing = Guid.Parse("00000000-0000-0000-0000-00000000dead").Get();
		let badMat = root.CreateInstance("cracked", typeof(MaterialAsset).GetFullName(.. scope .()));
		{
			let asset = scope MaterialAsset();
			asset.Source.TextureSlots.Add(new String("albedo"));
			asset.Source.TextureIds.Add(missing);
			Test.Assert(badMat.WriteObject(asset) case .Ok);
		}
		let brokenScene = root.CreateInstance("ruin", McpTools.cSceneDocument);
		{
			let authored = scope Scene("ruin");
			EngineSceneComposition.AddAllSceneManagers(authored);
			let e = authored.CreateEntity("wall");
			authored.GetSystem<MeshComponentManager>().Add(e).Mesh.SetId(missing);
			Test.Assert(SceneStorage.SaveScene(authored, brokenScene) case .Ok);
		}
		session.Project.Settings.DefaultSceneId = missing;

		let broken = CallOk(server, "project_health", Obj());
		defer delete broken;
		Test.Assert(!broken.Get("sound").AsBool());
		Test.Assert(broken.Get("danglingRefs").Count == 2, scope $"{broken.Get("danglingRefs").Count} dangling");
		bool sawReferences = false;
		bool sawSceneResource = false;
		for (int i < broken.Get("danglingRefs").Count)
		{
			let d = broken.Get("danglingRefs").At(i);
			Test.Assert(d.Get("to").AsString() == missing.ToString(.. scope .()));
			if (d.Get("edge").AsString() == "references")
				sawReferences = true;
			if (d.Get("edge").AsString() == "scene-resource")
				sawSceneResource = true;
		}
		Test.Assert(sawReferences && sawSceneResource);
		Test.Assert((broken.Get("projectSettingsDangling").Count == 1)
			&& (broken.Get("projectSettingsDangling").At(0).AsString() == "defaultScene"));

		// Healing flips it back.
		session.Project.Settings.DefaultSceneId = .Empty;
		{
			let asset = scope MaterialAsset();
			asset.Source.TextureSlots.Add(new String("albedo"));
			asset.Source.TextureIds.Add(tex.Id);
			Test.Assert(badMat.WriteObject(asset) case .Ok);
		}
		{
			let authored = scope Scene("ruin");
			EngineSceneComposition.AddAllSceneManagers(authored);
			let e = authored.CreateEntity("wall");
			authored.GetSystem<MeshComponentManager>().Add(e).Mesh.SetId(tex.Id);
			Test.Assert(SceneStorage.SaveScene(authored, brokenScene) case .Ok);
		}
		let healed = CallOk(server, "project_health", Obj());
		defer delete healed;
		Test.Assert(healed.Get("sound").AsBool() && (healed.Get("danglingRefs").Count == 0));
	}
}
