using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Pastes a component blob (its manager's id, then the component's bytes) onto an entity,
/// adding or overwriting. Undo removes what was added, or restores the exact prior bytes.
class PasteComponentCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private List<uint8> mBlob = new .() ~ delete _;
	private String mTypeId = new .() ~ delete _;
	private List<uint8> mPrevious = new .() ~ delete _;
	private bool mHadComponent = false;
	private bool mCaptured = false;
	/// Non empty makes consecutive pastes of the SAME key one undo step, which is what turns
	/// a slider drag over a nested value into a single entry. Empty never merges.
	private String mMergeKey = new .() ~ delete _;

	public this(SceneEditContext ctx, Guid entity, Span<uint8> blob, StringView mergeKey = default)
	{
		mCtx = ctx;
		mEntity = entity;
		mBlob.AddRange(blob);
		mMergeKey.Set(mergeKey);
	}

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = previous as PasteComponentCommand;
		if ((prev == null) || mMergeKey.IsEmpty || (prev.mMergeKey != mMergeKey)
			|| (prev.mEntity != mEntity))
			return false;
		// The previous keeps its ORIGINAL prior state and takes over this one's blob.
		prev.mBlob.Clear();
		prev.mBlob.AddRange(mBlob);
		return true;
	}

	public override bool Execute()
	{
		let scene = mCtx.Scene;
		let e = mCtx.Resolve(mEntity);
		if (!e.IsAssigned)
			return false;

		let buffer = scope MemoryStream();
		buffer.Write(mBlob);
		buffer.Seek(0, .Begin);
		let ar = scope BinarySerializer(buffer, .Read);
		Sedulous.Core.Serialization.Serialize(ar, "type", mTypeId);
		let mgr = scene.FindManagerBySerializationId(mTypeId);
		if ((mgr == null) || !ar.IsPayloadOk)
			return false;

		if (!mCaptured)
		{
			mHadComponent = mgr.HasComponent(e);
			if (mHadComponent)
				SceneStreamFormat.ComponentToBlob(mgr, e, mPrevious);
			mCaptured = true;
		}

		mgr.ReadComponent(ar, e); // adds or overwrites
		mCtx.ResolveRestoredResources();
		return ar.IsPayloadOk;
	}

	public override void Undo()
	{
		let e = mCtx.Resolve(mEntity);
		let mgr = mCtx.Scene.FindManagerBySerializationId(mTypeId);
		if (!e.IsAssigned || (mgr == null))
			return;
		if (!mHadComponent)
		{
			mgr.RemoveComponent(e);
			return;
		}
		SceneStreamFormat.ComponentFromBlob(mgr, e, mPrevious);
		mCtx.ResolveRestoredResources();
	}

	public override StringView TypeId => "paste_component";
}
