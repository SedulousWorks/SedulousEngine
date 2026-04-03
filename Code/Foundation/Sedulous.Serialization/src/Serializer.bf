using System;
using System.Collections;

namespace Sedulous.Serialization;

/// Abstract base class for serializers.
/// Provides a unified API for both reading and writing data.
/// Concrete implementations (like OpenDDLSerializer) handle the actual format.
abstract class Serializer
{
	protected SerializerMode mMode;
	protected int32 mCurrentVersion;

	/// Gets the serialization mode (Read or Write).
	public SerializerMode Mode => mMode;

	/// Returns true if the serializer is in read (deserialization) mode.
	public bool IsReading => mMode == .Read;

	/// Returns true if the serializer is in write (serialization) mode.
	public bool IsWriting => mMode == .Write;

	/// Gets the version of the data being read.
	/// Only valid during deserialization.
	public int32 CurrentVersion => mCurrentVersion;

	// ---- Primitive Types ----

	/// Serializes a boolean value.
	public abstract SerializationResult Bool(StringView name, ref bool value);

	/// Serializes an 8-bit signed integer.
	public abstract SerializationResult Int8(StringView name, ref int8 value);

	/// Serializes a 16-bit signed integer.
	public abstract SerializationResult Int16(StringView name, ref int16 value);

	/// Serializes a 32-bit signed integer.
	public abstract SerializationResult Int32(StringView name, ref int32 value);

	/// Serializes a 64-bit signed integer.
	public abstract SerializationResult Int64(StringView name, ref int64 value);

	/// Serializes an 8-bit unsigned integer.
	public abstract SerializationResult UInt8(StringView name, ref uint8 value);

	/// Serializes a 16-bit unsigned integer.
	public abstract SerializationResult UInt16(StringView name, ref uint16 value);

	/// Serializes a 32-bit unsigned integer.
	public abstract SerializationResult UInt32(StringView name, ref uint32 value);

	/// Serializes a 64-bit unsigned integer.
	public abstract SerializationResult UInt64(StringView name, ref uint64 value);

	/// Serializes a 32-bit floating-point value.
	public abstract SerializationResult Float(StringView name, ref float value);

	/// Serializes a 64-bit floating-point value.
	public abstract SerializationResult Double(StringView name, ref double value);

	/// Serializes a string value.
	/// The string is modified in place during deserialization.
	public abstract SerializationResult String(StringView name, String value);

	// ---- Enum Support ----

	/// Serializes an enum value as its underlying integer type.
	public SerializationResult Enum<T>(StringView name, ref T value) where T : enum
	{
		var intValue = (int32)value.Underlying;
		let result = Int32(name, ref intValue);
		if (result != .Ok)
			return result;
		if (IsReading)
			value = (T)intValue;
		return .Ok;
	}

	// ---- Fixed Arrays ----

	/// Serializes a fixed-size array of floats.
	/// Useful for vectors, matrices, and other fixed-size numeric data.
	public abstract SerializationResult FixedFloatArray(StringView name, float* data, int32 count);

	/// Serializes a fixed-size array of int32s.
	public abstract SerializationResult FixedInt32Array(StringView name, int32* data, int32 count);

	// ---- Dynamic Arrays ----

	/// Serializes a list of 32-bit integers.
	public abstract SerializationResult ArrayInt32(StringView name, List<int32> values);

	/// Serializes a list of 32-bit floats.
	public abstract SerializationResult ArrayFloat(StringView name, List<float> values);

	/// Serializes a list of strings.
	public abstract SerializationResult ArrayString(StringView name, List<String> values);

	// ---- Nested Objects ----

	/// Begins a nested object scope.
	/// Call EndObject() when done serializing the object's fields.
	public abstract SerializationResult BeginObject(StringView name, StringView typeName = default);

	/// Ends a nested object scope.
	public abstract SerializationResult EndObject();

	/// Serializes a nested object that implements ISerializable.
	/// For reading: creates the object if null.
	/// For writing: serializes the object's data.
	public SerializationResult Object<T>(StringView name, ref T value) where T : ISerializable, class, new, delete
	{
		if (IsWriting)
		{
			if (value == null)
				return .NullValue;

			var result = BeginObject(name);
			if (result != .Ok)
				return result;

			mCurrentVersion = value.SerializationVersion;
			result = value.Serialize(this);
			if (result != .Ok)
				return result;

			return EndObject();
		}
		else
		{
			var result = BeginObject(name);
			if (result != .Ok)
				return result;

			if (value == null)
				value = new T();

			result = value.Serialize(this);
			if (result != .Ok)
				return result;

			return EndObject();
		}
	}

	/// Serializes an optional object (may be null).
	/// During reading, creates the object only if data exists.
	public SerializationResult OptionalObject<T>(StringView name, ref T value) where T : ISerializable, class, new, delete
	{
		if (IsWriting)
		{
			if (value == null)
				return .Ok;  // Don't write anything for null

			return Object(name, ref value);
		}
		else
		{
			if (!HasField(name))
				return .Ok;  // Field not present, leave as null

			return Object(name, ref value);
		}
	}

	// ---- Collections ----

	/// Begins a collection/array scope.
	/// For writing: count should be set to the number of elements.
	/// For reading: count will be set to the number of elements in the data.
	public abstract SerializationResult BeginArray(StringView name, ref int32 count);

	/// Ends a collection/array scope.
	public abstract SerializationResult EndArray();

	/// Serializes a list of objects that implement ISerializable.
	public SerializationResult ObjectList<T>(StringView name, List<T> list) where T : ISerializable, class, new, delete
	{
		int32 count = IsWriting ? (int32)list.Count : 0;

		var result = BeginArray(name, ref count);
		if (result != .Ok)
			return result;

		if (IsReading)
		{
			list.Clear();
			for (int32 i = 0; i < count; i++)
			{
				result = BeginObject("");
				if (result != .Ok)
					return result;

				T item = new T();
				result = item.Serialize(this);
				if (result != .Ok)
				{
					delete item;
					return result;
				}
				list.Add(item);

				result = EndObject();
				if (result != .Ok)
					return result;
			}
		}
		else
		{
			for (let item in list)
			{
				result = BeginObject("");
				if (result != .Ok)
					return result;

				mCurrentVersion = item.SerializationVersion;
				result = item.Serialize(this);
				if (result != .Ok)
					return result;

				result = EndObject();
				if (result != .Ok)
					return result;
			}
		}

		return EndArray();
	}

	// ---- Utility ----

	/// Checks if a field exists in the current scope.
	/// Only meaningful during deserialization.
	public abstract bool HasField(StringView name);

	/// Gets the names of all child fields/objects in the current scope.
	/// Only meaningful during deserialization; does nothing in write mode.
	/// Caller owns the allocated String objects in outNames.
	public abstract void GetFieldNames(List<String> outNames);

	/// Captures all children of the current scope as a format-specific text string.
	/// Used for preserving unknown/unrecognized data during roundtrip serialization.
	/// excludeField: optionally skip a named child from capture.
	/// Returns true if capture was successful.
	public abstract bool CaptureScope(String output, StringView excludeField = default);

	/// Restores previously captured scope data into the current write scope.
	/// Takes the same format-specific text string produced by CaptureScope.
	/// Returns true if restore was successful.
	public abstract bool RestoreScope(StringView data);

	/// Serializes a version number for the current object.
	/// Should be called at the start of Serialize() for versioned types.
	public SerializationResult Version(ref int32 version)
	{
		var result = Int32("_version", ref version);
		if (result != .Ok)
			return result;
		if (IsReading)
			mCurrentVersion = version;
		return .Ok;
	}
}
