using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene;

/// A component pool whose components PERSIST.
///
/// Serialization is opt in: subclass this instead of ComponentManager when the components
/// should be saved, and a manager that says nothing simply is not written. The component
/// type must be ISerializable, which is what a record's payload is.
///
/// Construct it with a stable id on disk. That id, not the runtime type, is what routes a
/// record back here on load: a runtime type is not stable across builds, and a rename must
/// not silently orphan every saved component.
///
/// DIVERGES from Raptor in how the payload is reached. Raptor finds a free Serialize by
/// argument dependent lookup; Beef has no such thing, so the component states it by
/// implementing ISerializable, which the constraint here requires.
class SerializableComponentManager<T> : ComponentManager<T>
	where T : struct, ISerializable
{
	private String mTypeId = new .() ~ delete _;
	private uint32 mDataVersion;

	/// `typeId` is the stable id on disk; `dataVersion` is the component's own data
	/// version, which a Serialize body gates on to migrate an older scene.
	public this(StringView typeId, uint32 dataVersion = 1)
	{
		mTypeId.Set(typeId);
		mDataVersion = dataVersion;
	}

	public override bool IsSerializable => true;
	public override StringView SerializationTypeId => mTypeId;

	public override void WriteComponent(ISerializer ar, EntityHandle entity)
	{
		let component = Get(entity);
		if (component == null)
			return;

		BeginVersionedPayload(ar, TypeIdOf(mTypeId), mDataVersion);
		component.Serialize(ar);
		EndVersionedPayload(ar);
	}

	public override void ReadComponent(ISerializer ar, EntityHandle entity)
	{
		// OVERWRITE when it is already there. A duplicate record, which is what a corrupt
		// save recovered by the loader produces, has to consume its payload rather than
		// trip the one-per-entity assert in Add and leave the stream mid record.
		var component = Get(entity);
		if (component == null)
			component = Add(entity);

		BeginVersionedPayload(ar, TypeIdOf(mTypeId), mDataVersion);
		component.Serialize(ar);
		EndVersionedPayload(ar);
	}
}
