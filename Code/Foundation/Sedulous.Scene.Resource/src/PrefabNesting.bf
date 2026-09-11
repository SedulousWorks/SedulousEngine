using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// Prefabs that contain instances of other prefabs.
///
/// A nested instance carries TWO layers of customisation, and keeping them apart is the
/// whole difficulty.
///
/// The OWNER's layer is what the person editing the outer prefab changed about the inner
/// one. It travels in the owner's payload as a nested record, and once applied it becomes
/// the nested instance's BASELINE. That is what makes an edit to the outer template
/// propagate: it is not an override, so nothing pins it.
///
/// The SCENE's layer is what somebody changed about this particular placement. It sits on
/// top as ordinary overrides, and it is the only layer a scene file records.
static class PrefabNesting
{
	/// The prefab instances living INSIDE `root`'s subtree, and every entity they own.
	///
	/// Those entities are excluded when the subtree is captured: a contained instance
	/// persists as a RECORD, so the link survives. Flattening it into plain entities would
	/// quietly turn an instance into a copy, and an edit to the inner prefab would stop
	/// reaching it.
	public static void CollectContained(Scene scene, EntityHandle root,
		List<PrefabInstanceState> outStates, HashSet<Guid> outMembers)
	{
		scene.ForEachPrefabInstance(scope (state) =>
		{
			let entity = scene.FindEntity(state.RootEntityId);
			if (!entity.IsAssigned || (entity == root))
				return;

			var inside = false;
			var parent = scene.GetParent(entity);
			while (parent.IsAssigned)
			{
				if (parent == root)
				{
					inside = true;
					break;
				}
				parent = scene.GetParent(parent);
			}
			if (!inside)
				return;

			outStates.Add(state);
			for (let live in state.LiveIds)
				outMembers.Add(live);
		});
	}

	/// Re-reads an instance's baselines from what it currently is.
	///
	/// Run after the OWNER's deltas are applied to a nested instance, which is what turns
	/// the owner's customisation into the baseline. Without it, everything the outer prefab
	/// says about the inner one would read as a scene override: the scene file would record
	/// it, and editing the outer template afterwards would never reach it again.
	public static void RecaptureBaselines(Scene scene, PrefabInstanceState state)
	{
		ClearAndDeleteItems!(state.ComponentBaselines);

		for (int i = 0; i < state.SourceIds.Count; i++)
		{
			let live = scene.FindEntity(state.LiveIds[i]);
			if (!live.IsAssigned)
				continue;

			if (i < state.BaselineTransforms.Count)
				state.BaselineTransforms[i] = scene.GetLocalTransform(live);

			let sourceId = state.SourceIds[i];
			scene.ForEachManager(scope (manager) =>
			{
				if (!manager.IsSerializable || !manager.HasComponent(live))
					return;

				let baseline = new PrefabComponentBaseline();
				baseline.SourceEntity = sourceId;
				baseline.TypeId.Set(manager.SerializationTypeId);
				SceneStreamFormat.ComponentToBlob(manager, live, baseline.Blob);
				state.ComponentBaselines.Add(baseline);
			});
		}
	}
}
