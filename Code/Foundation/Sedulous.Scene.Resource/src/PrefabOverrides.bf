using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// Asking what an instance has changed.
///
/// What an inspector needs to mark a field as overridden, and it asks the same question
/// saving does: is this different from the baseline captured at spawn? Deriving the answer
/// rather than reading a flag is what keeps the inspector and the save file agreeing.
static class PrefabOverrides
{
	/// The instance `entityId` is a member of, if it is one at all.
	public static bool FindMember(Scene scene, Guid entityId, out PrefabMemberInfo member)
	{
		PrefabMemberInfo found = .();
		var wasFound = false;

		scene.ForEachPrefabInstance(scope [&](state) =>
		{
			if (wasFound)
				return;
			for (int i = 0; i < state.LiveIds.Count; i++)
			{
				if (state.LiveIds[i] != entityId)
					continue;
				found = .(state, i);
				wasFound = true;
				return;
			}
		});

		member = found;
		return wasFound;
	}

	/// The baseline for one member's component, or null when the template never gave it one.
	public static PrefabComponentBaseline FindBaseline(PrefabInstanceState state, Guid sourceId,
		StringView typeId)
	{
		for (let baseline in state.ComponentBaselines)
		{
			if ((baseline.SourceEntity == sourceId) && (baseline.TypeId == typeId))
				return baseline;
		}
		return null;
	}

	/// Whether a member's component differs from what the template gave it.
	///
	/// Three ways it can: the bytes changed, it was ADDED where the template had none, or
	/// it was REMOVED where the template had one. All three are overrides, and an inspector
	/// that only noticed the first would show a field as clean after somebody deleted it.
	public static bool IsComponentOverridden(Scene scene, PrefabMemberInfo member,
		ComponentManagerBase manager)
	{
		let sourceId = member.State.SourceIds[member.MemberIndex];
		let baseline = FindBaseline(member.State, sourceId, manager.SerializationTypeId);

		let live = scene.FindEntity(member.State.LiveIds[member.MemberIndex]);
		let has = live.IsAssigned && manager.HasComponent(live);

		if (!has)
			return baseline != null; // removed, if the template had one

		if (baseline == null)
			return true; // added, where the template had none

		let current = scope List<uint8>();
		SceneStreamFormat.ComponentToBlob(manager, live, current);
		return !SceneStreamFormat.BlobsEqual(current, baseline.Blob);
	}

	/// Whether a member's local transform differs from the template's.
	public static bool IsTransformOverridden(Scene scene, PrefabMemberInfo member)
	{
		let live = scene.FindEntity(member.State.LiveIds[member.MemberIndex]);
		if (!live.IsAssigned)
			return false;
		if (member.MemberIndex >= member.State.BaselineTransforms.Count)
			return false;

		return !PrefabDeltas.TransformsEqual(scene.GetLocalTransform(live),
			member.State.BaselineTransforms[member.MemberIndex]);
	}
}
