namespace Sedulous.Editor.Core;

using System;
using Sedulous.Scenes;
using Sedulous.Core.Mathematics;

/// Command to create an entity.
class CreateEntityCommand : IEditorCommand
{
	private Scene mScene;
	private EntityHandle mEntity;
	private String mName = new .() ~ delete _;
	private bool mCreated;

	public this(Scene scene, StringView name)
	{
		mScene = scene;
		mName.Set(name);
	}

	public StringView Description => "Create Entity";
	public EntityHandle Entity => mEntity;

	public void Execute()
	{
		mEntity = mScene.CreateEntity(mName);
		mCreated = true;
	}

	public void Undo()
	{
		if (mCreated && mScene.IsValid(mEntity))
		{
			mScene.DestroyEntity(mEntity);
			mCreated = false;
		}
	}

	public bool CanMergeWith(IEditorCommand other) => false;
	public void MergeWith(IEditorCommand other) { }
	public void Dispose() { }
}

/// Command to destroy an entity.
class DestroyEntityCommand : IEditorCommand
{
	private Scene mScene;
	private EntityHandle mEntity;
	private String mName = new .() ~ delete _;
	private Transform mTransform;
	private bool mDestroyed;

	public this(Scene scene, EntityHandle entity)
	{
		mScene = scene;
		mEntity = entity;
		// Snapshot name + transform for undo.
		mName.Set(mScene.GetEntityName(entity));
		mTransform = mScene.GetLocalTransform(entity);
	}

	public StringView Description => "Delete Entity";

	public void Execute()
	{
		if (mScene.IsValid(mEntity))
		{
			mScene.DestroyEntity(mEntity);
			mDestroyed = true;
		}
	}

	public void Undo()
	{
		if (mDestroyed)
		{
			// Recreate entity with saved name and transform
			// TODO: Restore components and children from serialized data
			mEntity = mScene.CreateEntity(mName);
			mScene.SetLocalTransform(mEntity, mTransform);
			mDestroyed = false;
		}
	}

	public bool CanMergeWith(IEditorCommand other) => false;
	public void MergeWith(IEditorCommand other) { }
	public void Dispose() { }
}

/// Command to set an entity's transform.
class SetTransformCommand : IEditorCommand
{
	private Scene mScene;
	private EntityHandle mEntity;
	private Transform mOldTransform;
	private Transform mNewTransform;

	public this(Scene scene, EntityHandle entity, Transform newTransform)
	{
		mScene = scene;
		mEntity = entity;
		mOldTransform = scene.GetLocalTransform(entity);
		mNewTransform = newTransform;
	}

	public StringView Description => "Set Transform";

	public void Execute()
	{
		if (mScene.IsValid(mEntity))
			mScene.SetLocalTransform(mEntity, mNewTransform);
	}

	public void Undo()
	{
		if (mScene.IsValid(mEntity))
			mScene.SetLocalTransform(mEntity, mOldTransform);
	}

	public bool CanMergeWith(IEditorCommand other)
	{
		if (let otherXform = other as SetTransformCommand)
			return otherXform.mEntity == mEntity && otherXform.mScene === mScene;
		return false;
	}

	public void MergeWith(IEditorCommand other)
	{
		if (let otherXform = other as SetTransformCommand)
			mNewTransform = otherXform.mNewTransform;
	}

	public void Dispose() { }
}
