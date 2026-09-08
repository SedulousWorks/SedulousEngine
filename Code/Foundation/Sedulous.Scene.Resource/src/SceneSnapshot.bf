using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// A whole scene in memory, to be put back later.
///
/// What entering play in an editor is built on: snapshot, run, restore. Serialized EXPANDED,
/// so an instance's members are written flat and its state verbatim, and restoring needs no
/// prefab payload to resolve. A snapshot has to be self contained: the thing it protects
/// against is the project changing underneath while the game runs.
///
/// Restoring deserializes back INTO THE SAME scene object, so a page, an edit context or a
/// selection that borrowed it stays valid. Entity guids come back as they were, so a
/// selection by id survives too.
class SceneSnapshot
{
	private List<uint8> mBlob = new .() ~ delete _;

	/// Captures `scene`. Null when the scene could not be serialized, which leaves the
	/// caller to decide rather than handing back a snapshot that would restore a ruin.
	public static SceneSnapshot Capture(Scene scene)
	{
		let buffer = scope MemoryStream();
		{
			let ar = scope BinarySerializer(buffer, .Write);
			SceneSerializer.SerializeScene(ar, scene, .Expanded);
			if (!ar.IsOk)
				return null;
		}

		let snapshot = new SceneSnapshot();
		snapshot.mBlob.AddRange(buffer.Bytes);
		return snapshot;
	}

	/// Drains `scene` and rebuilds it from the snapshot.
	///
	/// `resources` re-binds the component references immediately, which is the same pass a
	/// load runs; leaving it null defers that to the caller.
	public Result<void, ErrorCode> Restore(Scene scene, ResourceManager resources = null)
	{
		// Collect the roots BEFORE destroying any: destroying while walking the entity
		// storage is reading a list something else is rewriting. Destroying a root takes
		// its children with it, so the roots are the whole scene.
		let roots = scope List<EntityHandle>();
		scene.ForEachEntity(scope [&](entity) =>
		{
			if (!scene.GetParent(entity).IsAssigned)
				roots.Add(entity);
		});
		for (let root in roots)
			scene.DestroyEntity(root);

		// The snapshot's expanded section repopulates the instance bookkeeping.
		scene.ClearPrefabInstances();

		let buffer = scope MemoryStream();
		buffer.Write(mBlob);
		buffer.Seek(0, .Begin);

		let ar = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(ar, scene, .Expanded);
		if (!ar.IsOk)
			return ar.Status;

		if (resources != null)
			SceneResolve.ResolveSceneResources(scene, resources);
		return .Ok;
	}
}
