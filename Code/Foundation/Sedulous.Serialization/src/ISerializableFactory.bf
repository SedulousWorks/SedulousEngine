using System;
namespace Sedulous.Serialization;

/// Factory interface for creating instances during deserialization.
/// Used for polymorphic types where the concrete type must be
/// determined from the serialized data.
interface ISerializableFactory
{
	/// Creates an instance of a serializable type based on its type identifier.
	/// Returns null if the type is not recognized.
	ISerializable CreateInstance(StringView typeId);

	/// Gets the type identifier for a serializable object.
	/// This identifier will be stored during serialization and used
	/// to recreate the object during deserialization.
	void GetTypeId(ISerializable obj, String typeId);
}
