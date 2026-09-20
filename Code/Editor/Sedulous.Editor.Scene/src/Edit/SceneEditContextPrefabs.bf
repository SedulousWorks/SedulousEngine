using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Editor.Scene;

/// The prefab verbs: placing an instance, swapping an entity for one, and putting a member's
/// component back to what the template gave it.
extension SceneEditContext
{
	/// Spawns an instance of `prefabId` from `payload` under `parent`, at `rootTransform` when
	/// given, in the slot before `placeBefore` when given. Selects and answers the root; nil
	/// when the payload would not spawn. CONSUMES `payload`.
	public Guid SpawnPrefabInstance(Guid prefabId, List<uint8> payload, Guid parent = .(),
		Transform? rootTransform = null, Guid placeBefore = .())
	{
		let command = new SpawnPrefabCommand(this, prefabId, payload, parent, rootTransform,
			placeBefore);
		if (!mCommands.Execute(command))
			return .();
		let created = command.RootGuid;
		mSelection.Set(created);
		return created;
	}

	/// Swaps `entity` for an instance in its place: same parent, same slot, same placement.
	/// ONE undo step. CONSUMES `payload`.
	public Guid ReplaceWithPrefabInstance(Guid entity, Guid prefabId, List<uint8> payload)
	{
		let live = Resolve(entity);
		if (!live.IsAssigned)
		{
			delete payload;
			return .();
		}
		let parentHandle = mScene.GetParent(live);
		let parent = parentHandle.IsAssigned ? mScene.GetEntityId(parentHandle) : Guid();
		let placement = mScene.GetLocalTransform(live);

		mCommands.BeginGroup("prefab_replace");
		let root = SpawnPrefabInstance(prefabId, payload, parent, placement, entity);
		if (!root.IsNil)
			DestroyEntity(entity);
		mCommands.EndGroup();
		if (!root.IsNil)
			mSelection.Set(root);
		return root;
	}

	/// Puts a member's component back to the template's baseline, or removes it when the
	/// template never gave the member one. False for an entity that is not a member.
	public bool RevertComponentToBaseline(Guid entity, Type componentType)
	{
		PrefabMemberInfo member = ?;
		if (!PrefabOverrides.FindMember(mScene, entity, out member))
			return false;
		let manager = FindManager(componentType);
		if (manager == null)
			return false;
		let sourceId = member.State.SourceIds[member.MemberIndex];
		let baseline = PrefabOverrides.FindBaseline(member.State, sourceId,
			manager.SerializationTypeId);
		if (baseline == null)
		{
			let live = Resolve(entity);
			if (live.IsAssigned && manager.HasComponent(live))
				RemoveComponent(entity, componentType);
			return true;
		}
		// The baseline is the component's bytes; a paste blob is the manager id then those.
		let buffer = scope MemoryStream();
		let ar = scope BinarySerializer(buffer, .Write);
		let typeId = scope String(manager.SerializationTypeId);
		Sedulous.Core.Serialization.Serialize(ar, "type", typeId);
		if (!ar.IsPayloadOk)
			return false;
		buffer.Write(baseline.Blob);
		return PasteComponent(entity, buffer.Bytes);
	}
}
