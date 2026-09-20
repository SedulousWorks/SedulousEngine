using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// Spawns prefabs into its scene at runtime, by id: what a script's Spawn reaches.
///
/// The scene knows nothing of content, so this is where the content database and the
/// resource manager meet it. The host that owns them wires a scene's system once it is
/// composed; a scene with no source spawns nothing and says so with an unassigned handle.
///
/// One recipe for every runtime spawn, the network's included: read the payload, spawn it
/// with the database resolving what it nests, place the root, bind the subtree. The
/// instance is recorded on the scene like any other, so a saved scene restores it.
class PrefabSpawnSystem : SceneSystem
{
	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	/// BORROWED from the host.
	private ContentDatabase mDatabase = null;
	private ResourceManager mResources = null;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// The database the prefabs come from and the manager their resources bind through.
	/// Either may be null: no database spawns nothing, no manager leaves the subtree
	/// unbound until a resolve.
	public void SetSource(ContentDatabase database, ResourceManager resources)
	{
		mDatabase = database;
		mResources = resources;
	}

	public bool HasSource => mDatabase != null;

	/// Spawns the prefab under `parent`, its root placed at `position` and `rotation` in
	/// the parent's space. An unassigned handle when the prefab is unknown, the payload is
	/// unreadable, or there is no source.
	public EntityHandle Spawn(Guid prefab, Float3 position, Quaternion rotation = .Identity,
		EntityHandle parent = .Invalid)
	{
		let root = SpawnInto(mScene, mDatabase, mResources, prefab, parent);
		if (!root.IsAssigned)
			return .Invalid;

		var transform = mScene.GetLocalTransform(root);
		transform.Position = position;
		transform.Rotation = rotation;
		mScene.SetLocalTransform(root, transform);
		return root;
	}

	/// The recipe, as a function of what it needs, so a host without a scene system (the
	/// replicated spawn resolver) runs the same one.
	public static EntityHandle SpawnInto(Scene scene, ContentDatabase database, ResourceManager resources,
		Guid prefab, EntityHandle parent = .Invalid)
	{
		if ((scene == null) || (database == null) || (prefab == Guid.Empty))
			return .Invalid;

		let instance = database.GetInstance(prefab);
		if (instance == null)
			return .Invalid;

		// THE CALLER OWNS the stream.
		let payload = instance.ReadData("scene");
		if (payload == null)
			return .Invalid;
		defer delete payload;

		// The prefabs this one nests come from the same database.
		ScenePrefabs.PayloadResolver resolver = scope [&] (id) =>
			{
				let nested = database.GetInstance(id);
				return (nested != null) ? nested.ReadData("scene") : null;
			};
		let root = PrefabSpawn.Spawn(scene, payload, prefab, parent, null, resolver);

		// The subtree names its resources by id and nothing has bound them yet.
		if (root.IsAssigned && (resources != null))
			SceneResolve.ResolveEntityResources(scene, root, resources);

		return root;
	}
}
