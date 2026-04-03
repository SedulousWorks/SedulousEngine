namespace Sedulous.Scenes.Resources;

using System;
using System.Collections;
using Sedulous.Scenes;
using Sedulous.Serialization;
using Sedulous.Resources;
using static Sedulous.Resources.ResourceSerializerExtensions;

/// Bridges IComponentSerializer (Scenes layer) to Serializer (Serialization layer).
/// Components call IComponentSerializer methods; this adapter delegates to the concrete Serializer.
class ComponentSerializerAdapter : IComponentSerializer
{
	private Serializer mSerializer;
	private int32 mVersion;

	public this(Serializer serializer, int32 version)
	{
		mSerializer = serializer;
		mVersion = version;
	}

	public bool IsReading => mSerializer.IsReading;
	public bool IsWriting => mSerializer.IsWriting;
	public int32 Version => mVersion;

	// Primitives
	public void Bool(StringView name, ref bool value) { mSerializer.Bool(name, ref value); }
	public void Int8(StringView name, ref int8 value) { mSerializer.Int8(name, ref value); }
	public void Int16(StringView name, ref int16 value) { mSerializer.Int16(name, ref value); }
	public void Int32(StringView name, ref int32 value) { mSerializer.Int32(name, ref value); }
	public void Int64(StringView name, ref int64 value) { mSerializer.Int64(name, ref value); }
	public void UInt8(StringView name, ref uint8 value) { mSerializer.UInt8(name, ref value); }
	public void UInt16(StringView name, ref uint16 value) { mSerializer.UInt16(name, ref value); }
	public void UInt32(StringView name, ref uint32 value) { mSerializer.UInt32(name, ref value); }
	public void UInt64(StringView name, ref uint64 value) { mSerializer.UInt64(name, ref value); }
	public void Float(StringView name, ref float value) { mSerializer.Float(name, ref value); }
	public void Double(StringView name, ref double value) { mSerializer.Double(name, ref value); }
	public void String(StringView name, System.String value) { mSerializer.String(name, value); }
	public void Guid(StringView name, ref System.Guid value) { mSerializer.Guid(name, ref value); }

	// Scene references
	public void EntityRef(StringView name, ref EntityRef value)
	{
		var id = value.PersistentId;
		mSerializer.Guid(name, ref id);

		if (mSerializer.IsReading)
		{
			value.PersistentId = id;
			value.CachedHandle = .Invalid; // resolved after load via EntityRef.Resolve(scene)
		}
	}

	// Nested structures
	public void BeginObject(StringView name) { mSerializer.BeginObject(name); }
	public void EndObject() { mSerializer.EndObject(); }
	public void BeginArray(StringView name, ref int32 count) { mSerializer.BeginArray(name, ref count); }
	public void EndArray() { mSerializer.EndArray(); }
}
