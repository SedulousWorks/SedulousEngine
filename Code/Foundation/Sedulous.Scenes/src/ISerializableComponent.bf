namespace Sedulous.Scenes;

using System;

/// Interface for components that support serialization.
/// Components implement this to participate in scene save/load.
interface ISerializableComponent
{
	/// Serializes or deserializes this component's data.
	/// @param context Provides read/write operations and version info.
	void Serialize(IComponentSerializer context);

	/// Serialization version for backward compatibility.
	int32 SerializationVersion { get; }
}

/// Abstraction over the serialization backend.
/// Components use this interface - they don't depend on Sedulous.Serialization directly.
///
/// For reference type fields (List<T>, custom classes), the component owns them.
/// Use BeginArray/EndArray for lists, BeginObject/EndObject for nested structs.
interface IComponentSerializer
{
	bool IsReading { get; }
	bool IsWriting { get; }
	int32 Version { get; }

	// Primitives
	void Bool(StringView name, ref bool value);
	void Int8(StringView name, ref int8 value);
	void Int16(StringView name, ref int16 value);
	void Int32(StringView name, ref int32 value);
	void Int64(StringView name, ref int64 value);
	void UInt8(StringView name, ref uint8 value);
	void UInt16(StringView name, ref uint16 value);
	void UInt32(StringView name, ref uint32 value);
	void UInt64(StringView name, ref uint64 value);
	void Float(StringView name, ref float value);
	void Double(StringView name, ref double value);
	void String(StringView name, System.String value);
	void Guid(StringView name, ref System.Guid value);

	// Scene references
	void EntityRef(StringView name, ref EntityRef value);

	// Nested structures - for complex fields, lists, custom types
	void BeginObject(StringView name);
	void EndObject();
	void BeginArray(StringView name, ref int32 count);
	void EndArray();
}
