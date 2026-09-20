using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Materials.Resource;

namespace Sedulous.Editor.Scene;

/// The material page's edits on a MaterialSource, kept off the page so they run headless:
/// the packed uniform defaults by property name, the texture slot table, and the binary
/// snapshot the undo command carries.
static class MaterialSourceEdit
{
	/// Copies `bytes` of the named property's default out of the packed blob; false, `outValue`
	/// untouched, when the property is absent or the blob too short.
	public static bool ReadUniform(MaterialSource source, StringView name, void* outValue, int bytes)
	{
		let index = IndexOf(source, name);
		if (index < 0)
			return false;
		let offset = (index < source.PropertyOffsets.Count) ? (int)source.PropertyOffsets[index] : 0;
		if (offset + bytes > source.UniformDefaults.Count)
			return false;
		Internal.MemCpy(outValue, source.UniformDefaults.Ptr + offset, bytes);
		return true;
	}

	public static bool WriteUniform(MaterialSource source, StringView name, void* value, int bytes)
	{
		let index = IndexOf(source, name);
		if (index < 0)
			return false;
		let offset = (index < source.PropertyOffsets.Count) ? (int)source.PropertyOffsets[index] : 0;
		if (offset + bytes > source.UniformDefaults.Count)
			return false;
		Internal.MemCpy(source.UniformDefaults.Ptr + offset, value, bytes);
		return true;
	}

	public static float ReadFloat(MaterialSource source, StringView name, float fallback = 0.0f)
	{
		var value = fallback;
		ReadUniform(source, name, &value, sizeof(float));
		return value;
	}

	public static Float4 ReadFloat4(MaterialSource source, StringView name, Float4 fallback = .(1, 1, 1, 1))
	{
		var value = fallback;
		ReadUniform(source, name, &value, sizeof(Float4));
		return value;
	}

	public static bool WriteFloat(MaterialSource source, StringView name, float value)
	{
		var v = value;
		return WriteUniform(source, name, &v, sizeof(float));
	}

	public static bool WriteFloat4(MaterialSource source, StringView name, Float4 value)
	{
		var v = value;
		return WriteUniform(source, name, &v, sizeof(Float4));
	}

	/// The texture bound to `slot`, nil when the slot is unbound.
	public static Guid TextureFor(MaterialSource source, StringView slot)
	{
		for (int i = 0; (i < source.TextureSlots.Count) && (i < source.TextureIds.Count); i++)
		{
			if (source.TextureSlots[i] == slot)
				return source.TextureIds[i];
		}
		return .();
	}

	/// Binds `id` to `slot`, adding the slot when it is new; a nil id unbinds it, dropping
	/// the slot entirely so the source stays the sparse table the cook expects.
	public static void SetTexture(MaterialSource source, StringView slot, Guid id)
	{
		for (int i < source.TextureSlots.Count)
		{
			if (source.TextureSlots[i] != slot)
				continue;
			if (id.IsNil)
			{
				delete source.TextureSlots[i];
				source.TextureSlots.RemoveAt(i);
				if (i < source.TextureIds.Count)
					source.TextureIds.RemoveAt(i);
			}
			else if (i < source.TextureIds.Count)
				source.TextureIds[i] = id;
			else
				source.TextureIds.Add(id);
			return;
		}
		if (id.IsNil)
			return;
		source.TextureSlots.Add(new String(slot));
		source.TextureIds.Add(id);
	}

	/// The whole source as its binary form, what an undo step keeps.
	public static void Snapshot(MaterialSource source, List<uint8> outBlob)
	{
		outBlob.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		ISerializable serializable = source;
		serializable.Serialize(ar);
		outBlob.AddRange(stream.Bytes);
	}

	/// Restores a snapshot over `source`.
	public static void Apply(MaterialSource source, Span<uint8> blob)
	{
		let stream = scope MemoryStream();
		stream.Write(blob);
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		ISerializable serializable = source;
		serializable.Serialize(ar);
	}

	private static int IndexOf(MaterialSource source, StringView name)
	{
		for (int i < source.PropertyNames.Count)
		{
			if (source.PropertyNames[i] == name)
				return i;
		}
		return -1;
	}
}
