using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// Putting an instance back to its template, and carrying a template edit out to every
/// instance of it.
///
/// Both work the same way, because they are the same operation with different inputs: tear
/// the instance down, spawn it again from the template, and put back exactly as much as
/// should survive. A revert puts back nothing but the placement; a rebuild puts back the
/// overrides too.
///
/// Neither touches an instance's guids. The members are respawned under their SAVED ids, so
/// anything elsewhere in the scene that named one still resolves afterwards.
static class PrefabRebuild
{
	/// A plain entity a user parented under an instance member.
	///
	/// It is not part of the template and must survive the rebuild, but destroying a member
	/// destroys its whole subtree. So it is detached first, keeping its place in the world,
	/// and re-attached after.
	private struct RescuedChild
	{
		public Guid Child;
		public Guid ParentLiveId;

		public this(Guid child, Guid parentLiveId)
		{
			Child = child;
			ParentLiveId = parentLiveId;
		}
	}

	/// Drops every override on one instance: it becomes its template again, where it is.
	///
	/// Its placement and its position among its siblings are kept, because those are
	/// properties of where the instance was PUT rather than of what it was changed into.
	public static bool Revert(Scene scene, Guid rootEntityId, Span<uint8> payload,
		ScenePrefabs.PayloadResolver resolver = null)
	{
		let state = scene.FindPrefabInstanceByRoot(rootEntityId);
		if (state == null)
			return false;

		let root = scene.FindEntity(rootEntityId);
		if (!root.IsAssigned)
			return false;

		let prefabId = state.PrefabId;
		let parentHandle = scene.GetParent(root);
		let parentId = parentHandle.IsAssigned ? scene.GetEntityId(parentHandle) : Guid();
		let placement = scene.GetLocalTransform(root);
		let nextSibling = scene.GetNextSibling(root);
		let nextSiblingId = nextSibling.IsAssigned ? scene.GetEntityId(nextSibling) : Guid();

		let preassigned = scope Dictionary<Guid, Guid>();
		for (int i = 0; i < state.SourceIds.Count; i++)
			preassigned[state.SourceIds[i]] = state.LiveIds[i];

		// A contained instance reverts WITH its owner: it keeps its member guids, so
		// cross references stay valid, but none of its deltas, and the owner template's
		// placement wins. Reverting is asking for the template back, all the way down.
		let subs = scope List<PendingPrefabInstance>();
		defer { ClearAndDeleteItems!(subs); }
		StripContained(scene, root, subs, false);

		let rescued = scope List<RescuedChild>();
		DetachUserChildren(scene, state.LiveIds, rescued);
		TearDown(scene, state.LiveIds, rootEntityId);

		let stream = scope MemoryStream();
		stream.Write(payload);
		stream.Seek(0, .Begin);

		let parent = (parentId != Guid()) ? scene.FindEntity(parentId) : EntityHandle.Invalid;
		let spawned = PrefabSpawn.Spawn(scene, stream, prefabId, parent, preassigned, resolver, subs);
		if (!spawned.IsAssigned)
			return false;

		scene.SetLocalTransform(spawned, placement);
		ReattachUserChildren(scene, rescued, spawned);

		let order = scope List<(Guid entity, Guid nextSibling)>();
		order.Add((scene.GetEntityId(spawned), nextSiblingId));
		ScenePrefabs.RestoreSiblingOrder(scene, order);
		return true;
	}

	/// Carries an edited template out to every instance of it, returning how many rebuilt.
	///
	/// Each instance's overrides are captured BEFORE anything is destroyed, so a failure
	/// part way through cannot leave one stripped of what the user changed.
	public static uint32 Rebuild(Scene scene, Guid prefabId, Span<uint8> payload,
		ScenePrefabs.PayloadResolver resolver = null)
	{
		// The snapshot phase. Nothing is torn down until every affected instance has been
		// described, because a teardown destroys the state the description comes from.
		let deltas = scope List<PendingPrefabInstance>();
		defer { ClearAndDeleteItems!(deltas); }
		let rescuedPerInstance = scope List<List<RescuedChild>>();
		defer
		{
			for (let list in rescuedPerInstance)
				delete list;
		}
		let subsPerInstance = scope List<List<PendingPrefabInstance>>();
		defer
		{
			for (let list in subsPerInstance)
			{
				ClearAndDeleteItems!(list);
				delete list;
			}
		}
		let roots = scope List<Guid>();

		scene.ForEachPrefabInstance(scope [&](state) =>
		{
			// A nested instance rebuilds with its owner rather than on its own. Nesting
			// itself is not ported yet, so this is the guard rather than the mechanism.
			if (state.OwnerRootEntityId != Guid())
				return;

			var affected = state.PrefabId == prefabId;
			if (!affected)
			{
				for (let referenced in state.ReferencedPrefabIds)
				{
					if (referenced == prefabId)
					{
						affected = true;
						break;
					}
				}
			}
			if (!affected)
				return;
			if (!scene.FindEntity(state.RootEntityId).IsAssigned)
				return;

			roots.Add(state.RootEntityId);
			deltas.Add(PrefabDeltas.Compute(scene, state));

			// A contained instance rebuilds with its owner, keeping its guids and its own
			// deltas so nothing anybody changed about it is lost to the outer edit.
			let subs = new List<PendingPrefabInstance>();
			StripContained(scene, scene.FindEntity(state.RootEntityId), subs, true);
			subsPerInstance.Add(subs);

			let rescued = new List<RescuedChild>();
			DetachUserChildren(scene, state.LiveIds, rescued);
			rescuedPerInstance.Add(rescued);
		});

		uint32 rebuilt = 0;
		let order = scope List<(Guid entity, Guid nextSibling)>();

		for (int i = 0; i < deltas.Count; i++)
		{
			let delta = deltas[i];
			TearDown(scene, delta.LiveIds, roots[i]);

			// The changed bytes when this IS the edited prefab, otherwise its own template
			// through the resolver: an instance can be affected by referencing it.
			let stream = scope:: MemoryStream();
			if (delta.PrefabId == prefabId)
			{
				stream.Write(payload);
			}
			else
			{
				let own = (resolver != null) ? resolver(delta.PrefabId) : null;
				if (own == null)
				{
					GlobalLog(.Warning,
						"PrefabRebuild: an instance referencing the changed prefab could not rebuild, its own template did not resolve");
					continue;
				}
				defer:: delete own;
				let bytes = scope:: List<uint8>();
				bytes.Resize((int)own.Size());
				if (!bytes.IsEmpty)
					own.Read(bytes);
				stream.Write(bytes);
			}
			stream.Seek(0, .Begin);

			let preassigned = scope:: Dictionary<Guid, Guid>();
			for (int m = 0; (m < delta.SourceIds.Count) && (m < delta.LiveIds.Count); m++)
				preassigned[delta.SourceIds[m]] = delta.LiveIds[m];

			let parent = (delta.ParentEntityId != Guid())
				? scene.FindEntity(delta.ParentEntityId) : EntityHandle.Invalid;

			let root = PrefabSpawn.Spawn(scene, stream, delta.PrefabId, parent, preassigned,
				resolver, subsPerInstance[i]);
			if (!root.IsAssigned)
				continue;

			order.Add((scene.GetEntityId(root), delta.NextSiblingId));
			scene.SetLocalTransform(root, delta.RootTransform);

			// The overrides go back on: a template edit changes what the user did NOT
			// customise, and leaves what they did.
			let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(root));
			PrefabDeltas.Apply(scene, state, delta);

			ReattachUserChildren(scene, rescuedPerInstance[i], root);
			rebuilt++;
		}

		ScenePrefabs.RestoreSiblingOrder(scene, order);
		return rebuilt;
	}

	/// Detaches the plain entities parented under an instance's members, keeping each where
	/// it is in the world so re-attaching does not move it.
	private static void DetachUserChildren(Scene scene, List<Guid> memberIds,
		List<RescuedChild> outRescued)
	{
		let members = scope HashSet<Guid>();
		for (let live in memberIds)
			members.Add(live);

		for (let live in memberIds)
		{
			let member = scene.FindEntity(live);
			if (!member.IsAssigned)
				continue;

			let children = scope:: List<EntityHandle>();
			var child = scene.GetFirstChild(member);
			while (child.IsAssigned)
			{
				children.Add(child);
				child = scene.GetNextSibling(child);
			}

			for (let candidate in children)
			{
				let childId = scene.GetEntityId(candidate);
				if (members.Contains(childId))
					continue; // a member of the instance, which the respawn brings back
				outRescued.Add(.(childId, live));
				scene.SetParent(candidate, EntityHandle.Invalid, true);
			}
		}
	}

	/// Re-attaches them. The member guid survived the respawn, so a plain lookup finds the
	/// new parent. A member the template no longer HAS falls back to the instance root, so
	/// the child stays with the instance rather than being orphaned at the scene root.
	private static void ReattachUserChildren(Scene scene, List<RescuedChild> rescued,
		EntityHandle root)
	{
		for (let rescue in rescued)
		{
			let child = scene.FindEntity(rescue.Child);
			if (!child.IsAssigned)
				continue;
			let member = scene.FindEntity(rescue.ParentLiveId);
			scene.SetParent(child, member.IsAssigned ? member : root, true);
		}
	}

	private static void TearDown(Scene scene, List<Guid> memberIds, Guid rootEntityId)
	{
		for (let live in memberIds)
		{
			let entity = scene.FindEntity(live);
			if (entity.IsAssigned)
				scene.DestroyEntity(entity);
		}
		scene.RemovePrefabInstance(rootEntityId);
	}

	/// Takes the instances contained in `root`'s subtree out of the scene, describing each
	/// so the respawn can put it back.
	///
	/// `keepDeltas` says whether what somebody changed about a contained instance survives.
	/// A rebuild keeps it, because an edit to the outer template should not discard work on
	/// the inner one. A revert drops it, because reverting is asking for the template back
	/// all the way down; the member guids are still kept, so cross references stay valid.
	private static void StripContained(Scene scene, EntityHandle root,
		List<PendingPrefabInstance> outSubs, bool keepDeltas)
	{
		if (!root.IsAssigned)
			return;

		let contained = scope List<PrefabInstanceState>();
		let members = scope HashSet<Guid>();
		PrefabNesting.CollectContained(scene, root, contained, members);

		let subRoots = scope List<Guid>();
		for (let nested in contained)
		{
			PendingPrefabInstance record;
			if (keepDeltas)
			{
				record = PrefabDeltas.Compute(scene, nested);
			}
			else
			{
				record = new PendingPrefabInstance();
				record.PrefabId = nested.PrefabId;
				record.SourceIds.AddRange(nested.SourceIds);
				record.LiveIds.AddRange(nested.LiveIds);
				// The owner template's placement wins, since the scene is asking for the
				// template back rather than for where this one happened to sit.
				record.ApplyPlacement = false;
			}
			record.RootLiveId = nested.RootEntityId;
			record.NestedRootSourceId = (nested.NestedRootSourceId != Guid())
				? nested.NestedRootSourceId : nested.RootEntityId;
			outSubs.Add(record);
			subRoots.Add(nested.RootEntityId);

			for (let live in nested.LiveIds)
			{
				let entity = scene.FindEntity(live);
				if (entity.IsAssigned)
					scene.DestroyEntity(entity);
			}
		}

		for (let subRoot in subRoots)
			scene.RemovePrefabInstance(subRoot);
	}
}
