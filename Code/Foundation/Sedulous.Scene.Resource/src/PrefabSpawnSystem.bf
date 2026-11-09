using System;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// Spawns prefabs into its scene at runtime, by id or by reference: what a script's Spawn
/// reaches.
///
/// The scene knows nothing of content, so this is where the resource manager meets it. The
/// host that owns the manager wires a scene's system once it is composed; a scene with no
/// source spawns nothing and says so with an unassigned handle.
///
/// A prefab spawns from its loaded form (PrefabResource), bound through the manager: the
/// file is read once, when the prefab first loads, and a change to it reaches a spawn only
/// through a reload of that prefab (the editor reloads it when it is saved or changed on
/// disk, and evicts it when it is deleted). Two spawns of one prefab may therefore differ
/// across a reload.
///
/// One recipe for every runtime spawn, the network's included: open the loaded prefab's
/// payload, spawn it with the prefabs it nests resolved through the manager, place the root,
/// bind the subtree. The instance is recorded on the scene like any other, so a saved scene
/// restores it.
class PrefabSpawnSystem : SceneSystem
{
	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	/// BORROWED from the host.
	private ResourceManager mResources = null;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// The manager the prefabs load through and their subtrees' resources bind through; null
	/// spawns nothing. It needs the prefab factory (PrefabFactory) and a database holding the
	/// prefabs.
	public void SetSource(ResourceManager resources)
	{
		mResources = resources;
	}

	public bool HasSource => mResources != null;

	/// Spawns the prefab under `parent`, its root placed at `position` and `rotation` in the
	/// parent's space. A prefab not loaded yet is loaded now, synchronously, so the spawn is
	/// never a frame late. An unassigned handle when the prefab is unknown, deleted, its
	/// payload unreadable, or there is no source.
	public EntityHandle Spawn(Guid prefab, Float3 position, Quaternion rotation = .Identity,
		EntityHandle parent = .Invalid)
	{
		return Place(SpawnInto(mScene, mResources, prefab, parent), position, rotation);
	}

	/// Spawns the prefab a reference names, as Spawn by id does: from the prefab it is bound to,
	/// or, when it is not bound yet (or its load is still in flight), bound through the manager
	/// at once.
	public EntityHandle Spawn(Ref<PrefabResource> prefab, Float3 position, Quaternion rotation = .Identity,
		EntityHandle parent = .Invalid)
	{
		if ((mScene == null) || (mResources == null))
			return .Invalid;
		let payloads = scope PrefabPayloads(mResources);
		var loaded = prefab.Get;
		if (loaded == null)
			loaded = payloads.Load(prefab.Id);
		return Place(SpawnInto(mScene, mResources, payloads, loaded, parent), position, rotation);
	}

	/// The spawned root at its place; unassigned stays unassigned.
	private EntityHandle Place(EntityHandle root, Float3 position, Quaternion rotation)
	{
		if (!root.IsAssigned)
			return .Invalid;
		var transform = mScene.GetLocalTransform(root);
		transform.Position = position;
		transform.Rotation = rotation;
		mScene.SetLocalTransform(root, transform);
		return root;
	}

	/// The recipe by id, as a function of what it needs, so a host without a scene system (the
	/// replicated spawn resolver) runs the same one. The prefab is bound through the manager
	/// when it is not yet, synchronously: a replicated spawn must produce its entity in the
	/// frame its message arrives, or the replication that follows names nothing. A prefab that
	/// does not load (unknown, deleted, evicted) is refused with the manager's warning.
	public static EntityHandle SpawnInto(Scene scene, ResourceManager resources, Guid prefab,
		EntityHandle parent = .Invalid)
	{
		if ((scene == null) || (resources == null) || (prefab == Guid.Empty))
			return .Invalid;
		let payloads = scope PrefabPayloads(resources);
		return SpawnInto(scene, resources, payloads, payloads.Load(prefab), parent);
	}

	/// The recipe: `prefab`'s payload spawned under `parent`, the prefabs it nests resolved
	/// through `payloads` (scoped to this spawn, so one nesting itself is refused), then the
	/// subtree's resources bound. Unassigned when `prefab` is null or its payload unreadable.
	public static EntityHandle SpawnInto(Scene scene, ResourceManager resources, PrefabPayloads payloads,
		PrefabResource prefab, EntityHandle parent = .Invalid)
	{
		if ((scene == null) || (resources == null) || (payloads == null) || (prefab == null))
			return .Invalid;

		// THE CALLER OWNS the stream; it stays open, for the nesting check, while it spawns.
		let payload = payloads.Open(prefab);
		if (payload == null)
			return .Invalid;
		let root = PrefabSpawn.Spawn(scene, payload, prefab.Id, parent, null, payloads.Resolver);
		delete payload;

		// The subtree names its resources by id and nothing has bound them yet.
		if (root.IsAssigned)
			SceneResolve.ResolveEntityResources(scene, root, resources);

		return root;
	}
}
