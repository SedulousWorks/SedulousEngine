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
/// bounds. A scene's own camera is often placed by a script at play time, so in the editor it
/// can look at nothing.
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
		ThumbnailStaging.FrameFromBounds(ThumbnailStaging.WorldSceneBounds(stage), ref outFraming);
		let camera = scope EditorCamera();
		if (!SceneViewState.RestoreCamera(SavedView(id), camera))
		{
			// Never viewed: the whole scene in perspective, from 30 degrees above the ground and
			// turned a little, far enough back to hold its bounds: a shot of the place more than a
			// plan of it.
			camera.Yaw = 0.6f;
			camera.Pitch = -0.52f;
			let distance = outFraming.Radius / Sin(0.5f * camera.FovY);
			camera.Position = outFraming.Center - camera.Forward * distance;
			camera.NearZ = Max(0.1f, 0.5f * (distance - outFraming.Radius));
			camera.FarZ = distance + 2.0f * outFraming.Radius;
		}
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

	/// The view the scene's page saved when it last closed, BORROWED; null when none was.
	private SceneViewPref SavedView(Guid id) => SceneViewPrefs.Find(mContext.ProjectEditorSettings, id);
}
