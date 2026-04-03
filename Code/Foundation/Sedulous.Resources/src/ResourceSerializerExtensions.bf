namespace Sedulous.Resources;

using System;
using Sedulous.Serialization;

/// Extension methods for serializing resource-related types via the Serializer.
static class ResourceSerializerExtensions
{
	/// Serializes a GUID as a string.
	public static SerializationResult Guid(this Serializer s, StringView name, ref Guid value)
	{
		let guidStr = scope String();
		if (s.IsWriting)
			value.ToString(guidStr);
		s.String(name, guidStr);
		if (s.IsReading)
			value = System.Guid.Parse(guidStr).GetValueOrDefault();
		return .Ok;
	}

	/// Serializes a ResourceRefArray as a nested object with a count and indexed refs.
	public static SerializationResult ResourceRefArray<TCapacity>(this Serializer s, StringView name, ref ResourceRefArray<TCapacity> value) where TCapacity : const int
	{
		var result = s.BeginObject(name);
		if (result != .Ok)
			return result;

		s.Int32("count", ref value.Count);
		for (int32 i = 0; i < value.Count; i++)
		{
			let elemName = scope String();
			elemName.AppendF("ref{}", i);
			s.ResourceRef(elemName, ref value.Refs[i]);
		}

		return s.EndObject();
	}

	/// Serializes a ResourceRef as a nested object with "_id" and "path" fields.
	public static SerializationResult ResourceRef(this Serializer s, StringView name, ref ResourceRef value)
	{
		var result = s.BeginObject(name);
		if (result != .Ok)
			return result;

		s.Guid("_id", ref value.Id);

		if (s.IsReading && value.Path == null)
			value.Path = new String();
		if (value.Path != null)
			s.String("path", value.Path);

		return s.EndObject();
	}
}
