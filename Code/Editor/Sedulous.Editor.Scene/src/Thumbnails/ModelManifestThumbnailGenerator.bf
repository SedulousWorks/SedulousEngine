using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Materials;
using Sedulous.Engine.Render;
using Sedulous.ModelImporter;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A model manifest rebuilt as its node tree on a private stage, each node's mesh bound by
/// id and the manifest's materials on every one.
class ModelManifestThumbnailGenerator : ISceneThumbnailGenerator
{
	private EditorContext mContext;
	private bool mSpawned = false;

	public this(EditorContext context)
	{
		mContext = context;
	}

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("ModelManifestAsset");

	public bool NeedsPrivateScene => true;

	public ThumbnailStageStep Stage(Guid id, Sedulous.Scene.Scene stage, ResourceManager resources,
		ref ThumbnailFraming outFraming)
	{
		if (!mSpawned)
		{
			let instance = ThumbnailStaging.SourceInstance(mContext, id);
			if (instance == null)
				return .Failed;
			let object = instance.ReadObject();
			defer delete object;
			let asset = object as ModelManifestAsset;
			let meshes = stage.GetSystem<MeshComponentManager>();
			if ((asset == null) || (meshes == null))
				return .Failed;
			let manifest = asset.Manifest;
			let root = stage.CreateEntity(instance.Name);
			let entities = scope List<EntityHandle>();
			let nodeCount = manifest.NodeName.Count;
			for (int i < nodeCount)
			{
				let entity = stage.CreateEntity(manifest.NodeName[i]);
				stage.SetLocalTransform(entity, .(manifest.NodeTranslation[i], manifest.NodeRotation[i],
					manifest.NodeScale[i]));
				entities.Add(entity);
			}
			for (int i < nodeCount)
			{
				let parentIndex = manifest.NodeParent[i];
				let hasParent = (parentIndex >= 0) && (parentIndex < entities.Count);
				stage.SetParent(entities[i], hasParent ? entities[parentIndex] : root, false);
				let meshIndex = manifest.NodeMesh[i];
				if ((meshIndex < 0) || (meshIndex >= manifest.MeshGuid.Count))
					continue;
				let component = meshes.Add(entities[i]);
				component.Mesh.SetId(manifest.MeshGuid[meshIndex]);
				ModelPrefab.BindMeshMaterials(manifest, meshIndex, component.Materials);
			}
			SceneResolve.ResolveSceneResources(stage, resources);
			ThumbnailStaging.AddSun(stage);
			mSpawned = true;
		}
		if (!ThumbnailStaging.MeshRefsSettled(stage))
			return .Pending;
		stage.UpdateTransforms();
		ThumbnailStaging.FrameFromBounds(ThumbnailStaging.WorldMeshBounds(stage), ref outFraming);
		return .Ready;
	}

	public void Unstage(Sedulous.Scene.Scene stage) => mSpawned = false; // the scene is per job
}
