using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Recreates captured records under a parent with FRESH guids, minted on the first Execute
/// and reused by every redo. The records' original ids serve only to relink parents.
class PasteEntitiesCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private List<SubtreeRecord> mRecords ~ DeleteContainerAndItems!(_);
	private Guid mParent;
	private List<Guid> mNewIds = new .() ~ delete _; // parallel to the records

	/// CONSUMES `records`.
	public this(SceneEditContext ctx, List<SubtreeRecord> records, Guid parent)
	{
		mCtx = ctx;
		mRecords = records;
		mParent = parent;
	}

	public Guid RootGuid => mNewIds.IsEmpty ? Guid() : mNewIds[0];

	public override bool Execute()
	{
		if (mRecords.IsEmpty)
			return false;
		let scene = mCtx.Scene;

		if (mNewIds.IsEmpty)
		{
			for (let record in mRecords)
				mNewIds.Add(scene.GetEntityId(scene.CreateEntity(record.Name)));
		}
		else
		{
			for (int i < mRecords.Count)
				scene.CreateEntity(mNewIds[i], mRecords[i].Name);
		}

		for (int i < mRecords.Count)
		{
			let record = mRecords[i];
			let e = mCtx.Resolve(mNewIds[i]);
			scene.SetLocalTransform(e, record.Local);
			scene.SetActive(e, record.Active);
			var parent = EntityHandle.Invalid;
			if (record.Parent == Guid())
			{
				parent = mCtx.Resolve(mParent);
			}
			else
			{
				for (int j < mRecords.Count)
				{
					if (mRecords[j].Id == record.Parent)
					{
						parent = mCtx.Resolve(mNewIds[j]);
						break;
					}
				}
			}
			if (parent.IsAssigned)
				scene.SetParent(e, parent);
			SubtreeRecords.ApplyComponents(scene, e, record);
		}
		mCtx.ResolveRestoredResources(); // pasted refs render this frame, not next load
		return true;
	}

	public override void Undo()
	{
		let root = mCtx.Resolve(mNewIds[0]);
		if (root.IsAssigned)
			mCtx.Scene.DestroyEntity(root);
	}

	public override StringView TypeId => "paste_entities";
}
