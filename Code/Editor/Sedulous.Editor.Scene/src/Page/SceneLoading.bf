using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A scene document into a live scene, as the editor opens one: the document read, its resource
/// references bound to their cooked products (asynchronously: the content pops in over the next
/// frames, never stalling the UI thread), and its prefab instances respawned from the source
/// database (the edited payloads, not the cooked ones) and bound in turn. The scene page opens
/// its scene this way, and a profile page's preview loads the scene it previews on the same way,
/// so both show a scene alike.
static class SceneLoading
{
	/// Loads `instance` (a scene document) into `scene`. NotFound for a scene with no stream yet
	/// (a new scene); another error when the document does not read.
	public static Result<void, ErrorCode> LoadEditorScene(EditorContext context, Instance instance, Sedulous.Scene.Scene scene)
	{
		let loaded = SceneStorage.LoadScene(instance, scene);
		if (loaded case .Ok)
			ResolveAll(context, scene);
		return loaded;
	}

	/// Binds the scene's references on the async path, spawns any parked prefab instances from
	/// the source database, and binds what they brought.
	public static void ResolveAll(EditorContext context, Sedulous.Scene.Scene scene)
	{
		let resources = context.Resources;
		if (resources != null)
		{
			let async = AsyncBindScope(resources);
			defer async.Dispose();
			SceneResolve.ResolveSceneResources(scene, resources);
		}
		if ((scene.PendingPrefabInstanceCount > 0) && (context.Project != null))
		{
			let resolver = ProjectPrefabResolver(context);
			defer delete resolver;
			ScenePrefabs.ResolveScenePrefabs(scene, resolver);
			if (resources != null)
			{
				let async = AsyncBindScope(resources);
				defer async.Dispose();
				SceneResolve.ResolveSceneResources(scene, resources);
			}
		}
	}

	/// The world bounds of everything the scene's systems measure (meshes, colliders), merged;
	/// false when nothing has a size. What a view frames to show the whole scene.
	public static bool SceneWorldBounds(Sedulous.Scene.Scene scene, out AABB outBounds)
	{
		var bounds = AABB();
		var any = false;
		scene.ForEachEntity(scope [&] (entity) =>
			{
				if (!scene.EntityWorldBounds(entity, let part))
					return;
				bounds = any ? Merge(bounds, part) : part;
				any = true;
			});
		outBounds = bounds;
		return any;
	}

	/// A prefab payload resolver over the project's source database. The caller owns it.
	public static ScenePrefabs.PayloadResolver ProjectPrefabResolver(EditorContext context)
	{
		return new [=context](prefabId) =>
		{
			if (context.Project == null)
				return null;
			let prefab = context.Project.SourceDb.GetInstance(prefabId);
			return (prefab != null) ? prefab.ReadData("scene") : null;
		};
	}
}
