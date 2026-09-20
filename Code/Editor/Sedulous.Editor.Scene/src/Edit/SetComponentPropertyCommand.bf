using System;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Sets one reflected field of a component, by Variant or by raw integer bytes. Consecutive
/// sets of the same field on the same component merge, so a slider drag is one undo step.
///
/// OWNS its Variants. The address is re-resolved on every Execute and Undo: the component
/// lives in a pool that moves as components come and go.
class SetComponentPropertyCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private Type mComponentType;
	private String mProperty = new .() ~ delete _;
	private Variant mNew = .() ~ _.Dispose();
	private Variant mOld = .() ~ _.Dispose();
	private int64 mNewRaw = 0;
	private int64 mOldRaw = 0;
	private bool mRaw = false;
	private bool mHasOld = false;

	/// CONSUMES `value`.
	public this(SceneEditContext ctx, Guid entity, Type componentType, StringView property,
		Variant value)
	{
		mCtx = ctx;
		mEntity = entity;
		mComponentType = componentType;
		mProperty.Set(property);
		mNew = value;
	}

	public this(SceneEditContext ctx, Guid entity, Type componentType, StringView property,
		int64 rawValue)
	{
		mCtx = ctx;
		mEntity = entity;
		mComponentType = componentType;
		mProperty.Set(property);
		mNewRaw = rawValue;
		mRaw = true;
	}

	public override bool Execute()
	{
		void* component = ?;
		FieldInfo field = ?;
		if (!ResolveField(out component, out field))
			return false;

		if (mRaw)
		{
			let address = RawFieldAccess.AddressOf(field, component);
			if (!mHasOld)
			{
				mOldRaw = RawFieldAccess.ReadRawInt(address, field.FieldType.Size);
				mHasOld = true;
			}
			RawFieldAccess.WriteRawInt(address, field.FieldType.Size, mNewRaw);
			return true;
		}

		if (!mHasOld)
		{
			if (!(RawFieldAccess.Read(field, component, mComponentType) case .Ok(let old)))
				return false;
			mOld = old;
			mHasOld = true;
		}
		return RawFieldAccess.Write(field, component, mComponentType, mNew) case .Ok;
	}

	public override void Undo()
	{
		void* component = ?;
		FieldInfo field = ?;
		if (!ResolveField(out component, out field))
			return;
		if (mRaw)
			RawFieldAccess.WriteRawInt(RawFieldAccess.AddressOf(field, component),
				field.FieldType.Size, mOldRaw);
		else
			RawFieldAccess.Write(field, component, mComponentType, mOld).IgnoreError();
	}

	public override StringView TypeId => "set_component_property";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = (SetComponentPropertyCommand)previous;
		if ((prev.mEntity != mEntity) || (prev.mComponentType != mComponentType)
			|| (prev.mRaw != mRaw) || (prev.mProperty != mProperty))
			return false;
		// Previous keeps its ORIGINAL old value and takes over the new one.
		prev.mNew.Dispose();
		prev.mNew = mNew;
		mNew = .();
		prev.mNewRaw = mNewRaw;
		return true;
	}

	private bool ResolveField(out void* component, out FieldInfo field)
	{
		component = null;
		field = ?;
		let e = mCtx.Resolve(mEntity);
		if (!e.IsAssigned)
			return false;
		let mgr = mCtx.FindManager(mComponentType);
		if (mgr == null)
			return false;
		component = mgr.GetComponentAddress(e);
		if (component == null)
			return false;
		if (!(RawFieldAccess.FindField(mComponentType, mProperty) case .Ok(let found)))
			return false;
		field = found;
		return true;
	}
}
