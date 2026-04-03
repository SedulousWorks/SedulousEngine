namespace Sedulous.Serialization;

using System;

/// Factory for creating serializer instances.
/// Register one implementation at startup (e.g., OpenDDLSerializerProvider).
/// Resource managers and other systems use this to read/write data
/// without depending on a specific serialization format.
interface ISerializerProvider
{
	/// Creates a serializer in write mode.
	/// Caller owns the returned serializer.
	Serializer CreateWriter();

	/// Creates a serializer in read mode from text data.
	/// Caller owns the returned serializer.
	/// Returns null if the data cannot be parsed.
	Serializer CreateReader(StringView text);

	/// Gets the serialized output from a writer as text.
	void GetOutput(Serializer writer, String output);
}
