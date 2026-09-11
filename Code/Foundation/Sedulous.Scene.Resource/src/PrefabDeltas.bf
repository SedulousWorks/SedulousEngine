using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// What an instance has that its template does not.
///
/// Overrides are DERIVED, never tracked. At save time the live state is compared against
/// the baselines captured when the instance spawned, and the difference IS the override
/// set. Nothing records an edit, so there is nothing to get out of step: undo, redo and a
/// script writing a component all produce the right answer for free, because the answer is
/// recomputed rather than remembered.
static class PrefabDeltas
{
	/// Exact equality, deliberately. These are values that were either copied from the
	/// baseline untouched or written by a person, and a tolerance here would swallow a
	/// small deliberate nudge and silently refuse to save it.
	public static bool TransformsEqual(Transform a, Transform b)
	{
		return (a.Position.X == b.Position.X) && (a.Position.Y == b.Position.Y)
			&& (a.Position.Z == b.Position.Z)
			&& (a.Rotation.X == b.Rotation.X) && (a.Rotation.Y == b.Rotation.Y)
			&& (a.Rotation.Z == b.Rotation.Z) && (a.Rotation.W == b.Rotation.W)
			&& (a.Scale.X == b.Scale.X) && (a.Scale.Y == b.Scale.Y) && (a.Scale.Z == b.Scale.Z);
	}

	/// The live state of `state`'s instance as a DESCRIPTOR, ready to be written.
	///
	/// The same type a parked descriptor read from a save uses, deliberately: a computed
	/// delta and a loaded one are the same thing, and giving them separate shapes would
	/// mean two code paths that have to agree.
	public static PendingPrefabInstance Compute(Scene scene, PrefabInstanceState state)
	{
		let delta = new PendingPrefabInstance();
		delta.PrefabId = state.PrefabId;
		delta.RootLiveId = state.RootEntityId;
		delta.OwnerRootEntityId = state.OwnerRootEntityId;
		delta.NestedRootSourceId = state.NestedRootSourceId;

		let root = scene.FindEntity(state.RootEntityId);
		if (root.IsAssigned)
		{
			delta.RootTransform = scene.GetLocalTransform(root);
			let parent = scene.GetParent(root);
			delta.ParentEntityId = parent.IsAssigned ? scene.GetEntityId(parent) : Guid();
		}

		delta.SourceIds.AddRange(state.SourceIds);
		delta.LiveIds.AddRange(state.LiveIds);

		// The root's own placement is an override only when it MOVED. A nested instance
		// whose root still matches its baseline takes the owner template's placement when
		// it respawns, rather than a copy of a position nobody chose.
		for (int i = 0; i < state.LiveIds.Count; i++)
		{
			if (state.LiveIds[i] != state.RootEntityId)
				continue;
			if (root.IsAssigned && (i < state.BaselineTransforms.Count))
				delta.ApplyPlacement = !TransformsEqual(delta.RootTransform, state.BaselineTransforms[i]);
			break;
		}

		for (int i = 0; i < state.SourceIds.Count; i++)
		{
			let live = scene.FindEntity(state.LiveIds[i]);
			if (!live.IsAssigned)
			{
				// The member was deleted out of the instance, which is itself an override:
				// respawning must not bring it back.
				delta.DestroyedMembers.Add(state.SourceIds[i]);
				continue;
			}

			if (live != root)
			{
				let transform = scene.GetLocalTransform(live);
				if (!TransformsEqual(transform, state.BaselineTransforms[i]))
				{
					delta.OverrideTransformIds.Add(state.SourceIds[i]);
					delta.OverrideTransforms.Add(transform);
				}
			}

			CollectComponentOps(scene, state, i, live, delta);
		}

		// An op whose type is still absent passes through untouched, so a build without the
		// plugin does not quietly discard what the instance changed.
		for (let op in state.UnresolvedComponentOps)
			delta.ComponentOps.Add(CopyOp(op));

		return delta;
	}

	private static void CollectComponentOps(Scene scene, PrefabInstanceState state, int memberIndex,
		EntityHandle live, PendingPrefabInstance delta)
	{
		scene.ForEachManager(scope (manager) =>
		{
			if (!manager.IsSerializable)
				return;

			PrefabComponentBaseline baseline = null;
			for (let candidate in state.ComponentBaselines)
			{
				if ((candidate.SourceEntity == state.SourceIds[memberIndex])
					&& (candidate.TypeId == manager.SerializationTypeId))
				{
					baseline = candidate;
					break;
				}
			}

			let op = new PendingPrefabComponentOp();
			op.SourceEntity = state.SourceIds[memberIndex];
			op.TypeId.Set(manager.SerializationTypeId);

			if (manager.HasComponent(live))
			{
				let blob = scope List<uint8>();
				SceneStreamFormat.ComponentToBlob(manager, live, blob);

				if (baseline == null)
				{
					op.Op = .Add;
					op.Blob.AddRange(blob);
				}
				else if (!SceneStreamFormat.BlobsEqual(blob, baseline.Blob))
				{
					op.Op = .Modify;
					op.Blob.AddRange(blob);
				}
				else
				{
					delete op; // unchanged, so there is nothing to say
					return;
				}
			}
			else if (baseline != null)
			{
				op.Op = .Remove;
			}
			else
			{
				delete op; // it never had one
				return;
			}

			delta.ComponentOps.Add(op);
		});
	}

	/// Re-applies a descriptor's deltas onto a FRESHLY spawned instance, whose state maps
	/// the template's source ids to the live entities.
	public static void Apply(Scene scene, PrefabInstanceState state, PendingPrefabInstance delta)
	{
		EntityHandle LiveOf(Guid sourceId)
		{
			if (state == null)
				return .Invalid;
			for (int i = 0; i < state.SourceIds.Count; i++)
			{
				if (state.SourceIds[i] == sourceId)
					return scene.FindEntity(state.LiveIds[i]);
			}
			return .Invalid;
		}

		for (let dead in delta.DestroyedMembers)
		{
			let entity = LiveOf(dead);
			if (entity.IsAssigned)
				scene.DestroyEntity(entity);
		}

		for (int i = 0; (i < delta.OverrideTransformIds.Count) && (i < delta.OverrideTransforms.Count); i++)
		{
			let entity = LiveOf(delta.OverrideTransformIds[i]);
			if (entity.IsAssigned)
				scene.SetLocalTransform(entity, delta.OverrideTransforms[i]);
		}

		for (let op in delta.ComponentOps)
		{
			let entity = LiveOf(op.SourceEntity);
			let manager = scene.FindManagerBySerializationId(op.TypeId);

			if (entity.IsAssigned && (manager == null) && (state != null))
			{
				// Its plugin is absent. Keep the op, so the next save re-emits it and the
				// manager's arrival applies it.
				state.UnresolvedComponentOps.Add(CopyOp(op));
				continue;
			}
			if (!entity.IsAssigned || (manager == null))
				continue;

			if (op.Op == .Remove)
			{
				if (manager.HasComponent(entity))
					manager.RemoveComponent(entity);
				continue;
			}
			SceneStreamFormat.ComponentFromBlob(manager, entity, op.Blob);
		}
	}

	public static PendingPrefabComponentOp CopyOp(PendingPrefabComponentOp source)
	{
		let copy = new PendingPrefabComponentOp();
		copy.SourceEntity = source.SourceEntity;
		copy.TypeId.Set(source.TypeId);
		copy.Op = source.Op;
		copy.Blob.AddRange(source.Blob);
		return copy;
	}
}
