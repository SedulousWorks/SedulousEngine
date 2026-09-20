using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Spawns a prefab instance. The member guids are pinned on the first Execute, and so are
/// the nested instances it produced, so a redo recreates the SAME identities and later
/// commands naming them keep resolving.
class SpawnPrefabCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mPrefabId;
	private List<uint8> mPayload ~ delete _;
	private Guid mParent;
	/// The sibling slot to take: in the replace flow, the entity being replaced.
	private Guid mPlaceBefore;
	private Transform mRootTransform = .();
	private bool mHasTransform = false;
	private Guid mRootId = .();
	/// Source id to live id, pinned on the first Execute.
	private Dictionary<Guid, Guid> mPreassigned = new .() ~ delete _;
	private List<PendingPrefabInstance> mNestedPins = new .() ~ DeleteContainerAndItems!(_);

	/// CONSUMES `payload`.
	public this(SceneEditContext ctx, Guid prefabId, List<uint8> payload, Guid parent,
		Transform? rootTransform, Guid placeBefore)
	{
		mCtx = ctx;
		mPrefabId = prefabId;
		mPayload = payload;
		mParent = parent;
		mPlaceBefore = placeBefore;
		if (rootTransform.HasValue)
		{
			mRootTransform = rootTransform.Value;
			mHasTransform = true;
		}
	}

	public Guid RootGuid => mRootId;

	public override bool Execute()
	{
		let scene = mCtx.Scene;
		let stream = scope MemoryStream();
		stream.Write(mPayload);
		stream.Seek(0, .Begin);
		let parent = mCtx.Resolve(mParent);
		let root = PrefabSpawn.Spawn(scene, stream, mPrefabId, parent,
			mPreassigned.IsEmpty ? null : mPreassigned, mCtx.PrefabResolver,
			mNestedPins.IsEmpty ? null : mNestedPins);
		if (!root.IsAssigned)
			return false;
		if (mHasTransform)
			scene.SetLocalTransform(root, mRootTransform);
		if (mPlaceBefore != Guid())
		{
			let before = mCtx.Resolve(mPlaceBefore);
			if (before.IsAssigned)
				scene.MoveBefore(root, before);
		}
		mRootId = scene.GetEntityId(root);
		if (mPreassigned.IsEmpty)
		{
			if (let state = scene.FindPrefabInstanceByRoot(mRootId))
			{
				for (int i < state.SourceIds.Count)
					mPreassigned[state.SourceIds[i]] = state.LiveIds[i];
			}
			scene.ForEachPrefabInstance(scope [&](nested) =>
			{
				if (nested.OwnerRootEntityId != mRootId)
					return;
				let pin = new PendingPrefabInstance();
				pin.PrefabId = nested.PrefabId;
				pin.SourceIds.AddRange(nested.SourceIds);
				pin.LiveIds.AddRange(nested.LiveIds);
				pin.NestedRootSourceId = nested.NestedRootSourceId;
				pin.ApplyPlacement = false;
				mNestedPins.Add(pin);
			});
		}
		mCtx.ResolveRestoredResources(); // spawned refs render this frame
		return true;
	}

	public override void Undo()
	{
		let scene = mCtx.Scene;
		for (let kv in mPreassigned)
		{
			let e = scene.FindEntity(kv.value);
			if (e.IsAssigned)
				scene.DestroyEntity(e);
		}
		scene.RemovePrefabInstance(mRootId);
	}

	public override StringView TypeId => "spawn_prefab";
}
