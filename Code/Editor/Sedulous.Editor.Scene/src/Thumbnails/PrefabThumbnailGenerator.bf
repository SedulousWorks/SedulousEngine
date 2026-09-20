using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A prefab spawned into a private stage, framed on its meshes once they resolve.
class PrefabThumbnailGenerator : ISceneThumbnailGenerator
{
	private EditorContext mContext;
	private bool mSpawned = false;

	public this(EditorContext context)
	{
		mContext = context;
	}

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("PrefabDocument");

	public bool NeedsPrivateScene => true;

	public ThumbnailStageStep Stage(Guid id, Sedulous.Scene.Scene stage, ResourceManager resources,
		ref ThumbnailFraming outFraming)
	{
		if (!mSpawned)
		{
			let instance = ThumbnailStaging.SourceInstance(mContext, id);
			let payload = (instance != null) ? instance.ReadData("scene") : null;
			if (payload == null)
				return .Failed;
			defer delete payload;
			let resolver = ThumbnailStaging.PayloadResolver(mContext);
			defer delete resolver;
			let root = PrefabSpawn.Spawn(stage, payload, id, .Invalid, null, resolver);
			if (!root.IsAssigned)
				return .Failed;
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
