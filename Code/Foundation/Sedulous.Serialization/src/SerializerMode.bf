namespace Sedulous.Serialization;

/// Indicates whether a serializer is reading or writing data.
enum SerializerMode
{
	/// The serializer is writing data (serializing).
	Write,

	/// The serializer is reading data (deserializing).
	Read,
}
