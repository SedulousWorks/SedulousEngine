using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Destroys a subtree, remembering every entity and serializable component in it so undo
/// rebuilds it exactly: same guids, same parents, same transforms, same component bytes.
class DestroyEntityCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private List<SubtreeRecord> mRecords = new .() ~ DeleteContainerAndItems!(_);

	public this(SceneEditContext ctx, Guid entity)
	{
		mCtx = ctx;
		mEntity = entity;
	}

	public override bool Execute()
	{
		let scene = mCtx.Scene;
		let root = mCtx.Resolve(mEntity);
		if (!root.IsAssigned)
			return false;

		ClearAndDeleteItems(mRecords);
		SubtreeRecords.Capture(scene, root, mRecords, false);
		scene.DestroyEntity(root);
		return true;
	}

	public override void Undo()
	{
		let scene = mCtx.Scene;
		// Parents before children, so each record's parent is already back.
		for (let record in mRecords)
		{
			let e = scene.CreateEntity(record.Id, record.Name);
			scene.SetLocalTransform(e, record.Local);
			scene.SetActive(e, record.Active);
			let parent = mCtx.Resolve(record.Parent);
			if (parent.IsAssigned)
				scene.SetParent(e, parent);
			SubtreeRecords.ApplyComponents(scene, e, record);
		}
		mCtx.ResolveRestoredResources();
	}

	public override StringView TypeId => "destroy_entity";
}
