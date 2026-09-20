using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A scene loaded into a private stage, preferring its own camera for the shot.
class SceneThumbnailGenerator : ISceneThumbnailGenerator
{
	private EditorContext mContext;
	private bool mLoaded = false;

	public this(EditorContext context)
	{
		mContext = context;
	}

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("SceneDocument");

	public bool NeedsPrivateScene => true;

	public ThumbnailStageStep Stage(Guid id, Sedulous.Scene.Scene stage, ResourceManager resources,
		ref ThumbnailFraming outFraming)
	{
		if (!mLoaded)
		{
			let instance = ThumbnailStaging.SourceInstance(mContext, id);
			if ((instance == null) || !(SceneStorage.LoadScene(instance, stage) case .Ok))
				return .Failed;
			let resolver = ThumbnailStaging.PayloadResolver(mContext);
			defer delete resolver;
			ScenePrefabs.ResolveScenePrefabs(stage, resolver);
			SceneResolve.ResolveSceneResources(stage, resources);
			mLoaded = true;
		}
		if (!ThumbnailStaging.MeshRefsSettled(stage))
			return .Pending;
		stage.UpdateTransforms();
		ThumbnailStaging.FrameFromBounds(ThumbnailStaging.WorldMeshBounds(stage), ref outFraming);
		outFraming.PreferSceneCamera = true;
		return .Ready;
	}

	public void Unstage(Sedulous.Scene.Scene stage) => mLoaded = false; // the scene is per job
}
