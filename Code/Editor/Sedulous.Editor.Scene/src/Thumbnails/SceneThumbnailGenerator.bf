using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;
using Sedulous.Editor.Camera;

namespace Sedulous.Editor.Scene;

/// A scene loaded into a private stage, viewed as its page last showed it (the editor camera
/// the page saved when it closed), else in perspective from above, far enough back to hold its
/// bounds. A scene's own camera is often placed by game code at play time, so in the editor it
/// can look at nothing.
class SceneThumbnailGenerator : ISceneThumbnailGenerator
{
	private EditorContext mContext;
	private bool mLoaded = false;
	private ShownAssetScans mScans = new .() ~ delete _;

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
			if ((instance != null) && mScans.WaitForUncooked(mContext, instance))
				return .WaitingForCook;
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
		var bounds = AABB.Empty();
		if (SceneLoading.SceneWorldBounds(stage, let measured))
			bounds = measured;
		ThumbnailStaging.FrameFromBounds(bounds, ref outFraming);
		let camera = scope EditorCamera();
		if (!SceneViewState.RestoreCamera(SavedView(id), camera))
			SceneViewState.FrameWhole(bounds, camera); // never viewed: the whole scene, as its page first shows it
		outFraming.HasView = true;
		outFraming.Eye = camera.DrawEye;
		outFraming.View = Float4x4.LookAtRH(outFraming.Eye, outFraming.Eye + camera.Forward, camera.Up);
		outFraming.Projection = camera.Projection(1.0f); // the thumbnail is square
		outFraming.FarZ = camera.DrawFar;
		return .Ready;
	}

	public void Unstage(Sedulous.Scene.Scene stage) => mLoaded = false; // the scene is per job

	/// No builder cooks a scene document: its envelope and scene stream name its thumbnail,
	/// with the view it is shown from, so a new view is a new thumbnail.
	public uint64 ContentHash(Instance instance)
	{
		var hash = ThumbnailStaging.DocumentHash(instance);
		let view = SavedView(instance.Id);
		if ((view != null) && view.HasCamera)
		{
			let camera = view.Camera;
			float[7] numbers = .(camera.Position.X, camera.Position.Y, camera.Position.Z, camera.Yaw, camera.Pitch,
				camera.FocusDistance, camera.Orthographic ? 1.0f : 0.0f);
			hash = HashBytes(&numbers[0], sizeof(float[7]), hash);
		}
		return (hash != 0) ? hash : 1;
	}

	public void Dependencies(Instance instance, List<Guid> outIds) => mScans.Collect(mContext, instance, outIds);

	/// The view the scene's page saved when it last closed, BORROWED; null when none was.
	private SceneViewPref SavedView(Guid id) => SceneViewPrefs.Find(mContext.ProjectEditorSettings, id);
}
