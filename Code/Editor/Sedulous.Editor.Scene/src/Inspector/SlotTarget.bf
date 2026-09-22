using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// One element of a reflected container property, as an inspector target in its own right.
///
/// The rows a slot shows are the ELEMENT type's own, so every row builder works unchanged:
/// Address is the element and TargetType is its type. What differs is the write, which has
/// no field on the component to land on, so it goes through the parent's Mutate: the whole
/// component is snapshotted, the element's field written by name, and the result re-applied
/// as one undoable step. The merge key carries the slot, so dragging a slider on slot one
/// never collapses into an edit of slot two.
///
/// The accessor is generated at compile time by the row emitter, which knows the element
/// type; nothing here indexes a container by reflection.
class SlotTarget : InspectorTarget
{
	private InspectorTarget mParent;
	private Type mElementType;
	private int mSlot;
	private String mContainer = new .() ~ delete _;
	/// Resolves the element's address from the OWNING instance's address, re-read every time
	/// because the pool and the list both move.
	private delegate void*(void* owner, int slot) mResolve ~ delete _;

	/// CONSUMES `resolve`.
	public this(InspectorTarget parent, Type elementType, StringView container, int slot,
		delegate void*(void* owner, int slot) resolve) : base(parent.Edit)
	{
		mParent = parent;
		mElementType = elementType;
		mContainer.Set(container);
		mSlot = slot;
		mResolve = resolve;
	}

	public override Type TargetType => mElementType;

	public override void* Address
	{
		get
		{
			let owner = mParent.Address;
			return (owner != null) ? mResolve(owner, mSlot) : null;
		}
	}

	/// The merge key of one field of one slot, so consecutive edits of it are one undo step.
	private void MergeKey(StringView field, String outKey)
	{
		outKey.AppendF("{}[{}].{}", mContainer, mSlot, field);
	}

	public override void SetProperty(StringView field, Variant value)
	{
		let name = scope String(field);
		var value;
		defer value.Dispose();
		let type = mElementType;
		let slot = mSlot;
		let resolve = mResolve;
		mParent.Mutate(scope [&](owner) =>
		{
			let element = resolve(owner, slot);
			if (element == null)
				return;
			if (type.GetField(name) case .Ok(let f))
				RawFieldAccess.Write(f, element, type, value).IgnoreError();
		}, MergeKey(field, .. scope .()));
	}

	public override void SetPropertyRaw(StringView field, int64 raw)
	{
		let name = scope String(field);
		let type = mElementType;
		let slot = mSlot;
		let resolve = mResolve;
		mParent.Mutate(scope [&](owner) =>
		{
			let element = resolve(owner, slot);
			if (element == null)
				return;
			if (type.GetField(name) case .Ok(let f))
				RawFieldAccess.WriteRawInt(RawFieldAccess.AddressOf(f, element), f.FieldType.Size,
					raw);
		}, MergeKey(field, .. scope .()));
	}

	public override void SetEntityRef(StringView field, Guid target)
	{
		let name = scope String(field);
		let type = mElementType;
		let slot = mSlot;
		let resolve = mResolve;
		mParent.Mutate(scope [&](owner) =>
		{
			let element = resolve(owner, slot);
			if (element == null)
				return;
			if (type.GetField(name) case .Ok(let f))
			{
				let address = RawFieldAccess.AddressOf(f, element);
				if (address != null)
					*(Guid*)address = target;
			}
		}, MergeKey(field, .. scope .()));
	}

	/// An in place edit of the element itself, still one step on the owning component.
	public override void Mutate(delegate void(void* instance) mutate, StringView mergeKey)
	{
		let slot = mSlot;
		let resolve = mResolve;
		mParent.Mutate(scope [&](owner) =>
		{
			let element = resolve(owner, slot);
			if (element != null)
				mutate(element);
		}, mergeKey);
	}
}
