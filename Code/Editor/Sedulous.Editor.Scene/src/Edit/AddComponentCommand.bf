using System;
using Sedulous.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Adds a default component; dropped when the entity already has one.
class AddComponentCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private Type mType;

	public this(SceneEditContext ctx, Guid entity, Type componentType)
	{
		mCtx = ctx;
		mEntity = entity;
		mType = componentType;
	}

	public override bool Execute()
	{
		let e = mCtx.Resolve(mEntity);
		let mgr = mCtx.FindManager(mType);
		if (!e.IsAssigned || (mgr == null))
			return false;
		return mgr.AddDefaultComponent(e);
	}

	public override void Undo()
	{
		let e = mCtx.Resolve(mEntity);
		let mgr = mCtx.FindManager(mType);
		if (e.IsAssigned && (mgr != null))
			mgr.RemoveComponent(e);
	}

	public override StringView TypeId => "add_component";
}
