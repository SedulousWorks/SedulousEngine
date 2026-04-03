namespace Sedulous.Serialization;

/// Interface for types that can be serialized and deserialized.
/// Implementing types should handle both read and write operations
/// in the same Serialize method by checking the serializer's mode.
interface ISerializable
{
	/// Serializes or deserializes this object's data.
	/// The serializer's Mode property indicates whether data is being
	/// read (deserialized) or written (serialized).
	SerializationResult Serialize(Serializer serializer);

	/// Gets the serialization version for this type.
	/// Used for backward compatibility when the format changes.
	int32 SerializationVersion { get; }
}
