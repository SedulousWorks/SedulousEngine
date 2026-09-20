using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Creates an entity. The Guid is minted on the first Execute and REUSED by every redo, so
/// later commands that name the entity keep resolving.
class CreateEntityCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private String mName = new .() ~ delete _;
	private Guid mParent;
	private Guid mId = .();

	public this(SceneEditContext ctx, StringView name, Guid parent)
	{
		mCtx = ctx;
		mName.Set(name);
		mParent = parent;
	}

	public Guid CreatedId => mId;

	public override bool Execute()
	{
		let scene = mCtx.Scene;
		let parent = mCtx.Resolve(mParent);
		if ((mParent != Guid()) && !parent.IsAssigned)
			return false; // parent gone

		let entity = (mId != Guid()) ? scene.CreateEntity(mId, mName) : scene.CreateEntity(mName);
		if (!entity.IsAssigned)
			return false;
		if (mId == Guid())
			mId = scene.GetEntityId(entity);
		if (parent.IsAssigned)
			scene.SetParent(entity, parent);
		return true;
	}

	public override void Undo() => mCtx.Scene.DestroyEntity(mCtx.Resolve(mId));

	public override StringView TypeId => "create_entity";
}
