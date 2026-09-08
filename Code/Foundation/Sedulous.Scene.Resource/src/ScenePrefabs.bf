using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// Respawning the prefab instances a load parked.
///
/// The scene serializer cannot do this itself: resolving a prefab means reaching a content
/// database, and a serializer that knew about one could not be used to transcode a stream
/// with nothing mounted. So a load parks descriptors and this pass, given a resolver,
/// turns them back into live instances.
static class ScenePrefabs
{
	/// Hands back the payload for a prefab, or null when it cannot be reached. The CALLER
	/// owns what comes back; this pass deletes each stream once it has spawned from it.
	public typealias PayloadResolver = delegate IStream(Guid prefabId);

	/// Respawns every parked descriptor, applying its deltas.
	public static void ResolveScenePrefabs(Scene scene, PayloadResolver resolver)
	{
		let pending = scope List<PendingPrefabInstance>();
		defer { ClearAndDeleteItems!(pending); }
		scene.TakePendingPrefabInstances(pending);

		let order = scope List<(Guid entity, Guid nextSibling)>();

		for (let descriptor in pending)
		{
			// A NESTED record does not spawn on its own: its owner's spawn consumes it.
			// Nesting lands later; until then such a record is left for the orphan pass
			// below rather than spawned twice.
			if (descriptor.OwnerRootEntityId != Guid())
				continue;

			let root = Respawn(scene, descriptor, resolver);
			if (!root.IsAssigned)
				continue;

			order.Add((scene.GetEntityId(root), descriptor.NextSiblingId));
		}

		RestoreSiblingOrder(scene, order);
	}

	private static EntityHandle Respawn(Scene scene, PendingPrefabInstance descriptor,
		PayloadResolver resolver)
	{
		let payload = (resolver != null) ? resolver(descriptor.PrefabId) : null;
		if (payload == null)
		{
			GlobalLog(.Warning,
				"ScenePrefabs: an instance was skipped, the payload for its prefab did not resolve");
			return .Invalid;
		}
		defer delete payload;

		// The SAVED member guids are handed back to the spawn, so an instance keeps its
		// identity across a load: everything else in the scene that named one of its
		// members still resolves.
		let preassigned = scope Dictionary<Guid, Guid>();
		for (int i = 0; (i < descriptor.SourceIds.Count) && (i < descriptor.LiveIds.Count); i++)
			preassigned[descriptor.SourceIds[i]] = descriptor.LiveIds[i];

		let parent = (descriptor.ParentEntityId != Guid())
			? scene.FindEntity(descriptor.ParentEntityId) : EntityHandle.Invalid;

		let root = PrefabSpawn.Spawn(scene, payload, descriptor.PrefabId, parent, preassigned);
		if (!root.IsAssigned)
			return .Invalid;

		scene.SetLocalTransform(root, descriptor.RootTransform);

		let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(root));
		PrefabDeltas.Apply(scene, state, descriptor);
		return root;
	}

	/// Puts the respawned instances back where they were in their parents' lists.
	///
	/// A spawn APPENDS, so an instance that was not last comes back at the end. Each fix
	/// moves an entity immediately before the sibling that followed it at capture. A target
	/// that is itself still moving settles over several passes, since a chain has to anchor
	/// on something that does not move; a parent mismatch is skipped, because restoring an
	/// ORDER must never reparent.
	private static void RestoreSiblingOrder(Scene scene, List<(Guid entity, Guid nextSibling)> fixes)
	{
		for (int pass = 0; pass <= fixes.Count; pass++)
		{
			var changed = false;
			for (let fix in fixes)
			{
				if (fix.nextSibling == Guid())
					continue;

				let entity = scene.FindEntity(fix.entity);
				let sibling = scene.FindEntity(fix.nextSibling);
				if (!entity.IsAssigned || !sibling.IsAssigned)
					continue;
				if (scene.GetParent(entity) != scene.GetParent(sibling))
					continue;
				if (scene.GetNextSibling(entity) == sibling)
					continue;

				scene.MoveBefore(entity, sibling);
				changed = true;
			}
			if (!changed)
				break;
		}
	}
}
