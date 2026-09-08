using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene;

/// A component pool whose components PERSIST.
///
/// Serialization is opt in: subclass this rather than ComponentManager when the components
/// should be saved, and a manager that says nothing simply is not written.
///
/// The identity on disk comes from the component's own [SerializableComponent] attribute,
/// not from this manager: the id describes the TYPE, and stating it here would let two
/// managers of the same component disagree about what it is called.
///
/// DIVERGES from Raptor in how the payload is reached. Raptor finds a free Serialize by
/// argument dependent lookup; Beef has no such thing, so the component states it by
/// implementing ISerializable, which the constraint here requires.
class SerializableComponentManager<T> : ComponentManager<T>
	where T : struct, ISerializable
{
	private String mTypeId = new .() ~ delete _;
	private uint32 mDataVersion = 1;

	public this()
	{
		if (typeof(T).GetCustomAttribute<SerializableComponentAttribute>() case .Ok(let attribute))
		{
			mTypeId.Set(attribute.TypeId);
			mDataVersion = attribute.DataVersion;
		}
		else
		{
			// Not a warning: a pool that cannot name itself cannot route a record back on
			// load, so every component it holds would be silently unreadable.
			Runtime.FatalError(scope $"{typeof(T)} is stored by a SerializableComponentManager but carries no [SerializableComponent] attribute");
		}
	}

	public override bool IsSerializable => true;
	public override StringView SerializationTypeId => mTypeId;

	public override void WriteComponent(ISerializer ar, EntityHandle entity)
	{
		var component = Get(entity);
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
