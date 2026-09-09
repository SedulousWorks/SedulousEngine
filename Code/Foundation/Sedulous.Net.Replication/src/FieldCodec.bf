using System;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Net;

namespace Sedulous.Net.Replication;

/// The field codec: one reflected field between memory and the bit stream.
///
/// DIVERGES from Raptor, which passes values through a Variant. Beef's Variant allocates, and
/// this is a per frame path for every replicated field of every networked entity, so the
/// codec reads and writes the field's storage DIRECTLY at its offset. The wire format is
/// unchanged; only the way the value is reached differs.
static class FieldCodec
{
	/// Encodes one field value read from `address`. False, writing nothing, for an
	/// unsupported type.
	public static bool WriteValue(BitWriter writer, Type type, void* address)
	{
		if (type == typeof(bool)) { writer.WriteBool(*(bool*)address); return true; }
		if (type == typeof(float)) { writer.WriteFloat(*(float*)address); return true; }
		if (type == typeof(double)) { writer.WriteDouble(*(double*)address); return true; }
		if (type == typeof(int8)) { writer.WriteU8((uint8)*(int8*)address); return true; }
		if (type == typeof(uint8)) { writer.WriteU8(*(uint8*)address); return true; }
		if (type == typeof(int16)) { writer.WriteU16((uint16)*(int16*)address); return true; }
		if (type == typeof(uint16)) { writer.WriteU16(*(uint16*)address); return true; }
		if (type == typeof(int32)) { writer.WriteI32(*(int32*)address); return true; }
		if (type == typeof(uint32)) { writer.WriteU32(*(uint32*)address); return true; }
		if (type == typeof(int64)) { writer.WriteU64((uint64)*(int64*)address); return true; }
		if (type == typeof(uint64)) { writer.WriteU64(*(uint64*)address); return true; }

		if (type == typeof(Float2))
		{
			let value = *(Float2*)address;
			writer.WriteFloat(value.X);
			writer.WriteFloat(value.Y);
			return true;
		}
		if (type == typeof(Float3))
		{
			let value = *(Float3*)address;
			writer.WriteFloat(value.X);
			writer.WriteFloat(value.Y);
			writer.WriteFloat(value.Z);
			return true;
		}
		if (type == typeof(Float4))
		{
			let value = *(Float4*)address;
			writer.WriteFloat(value.X);
			writer.WriteFloat(value.Y);
			writer.WriteFloat(value.Z);
			writer.WriteFloat(value.W);
			return true;
		}
		if (type == typeof(Quaternion))
		{
			let value = *(Quaternion*)address;
			writer.WriteFloat(value.X);
			writer.WriteFloat(value.Y);
			writer.WriteFloat(value.Z);
			writer.WriteFloat(value.W);
			return true;
		}
		return false;
	}

	/// Decodes one field of the given type into `address`. False, reading nothing, for an
	/// unsupported type.
	///
	/// The stream is self describing only by POSITION, so the reader has to know the layout.
	/// It does, from the shared harvest.
	public static bool ReadValue(BitReader reader, Type type, void* address)
	{
		if (type == typeof(bool)) { *(bool*)address = reader.ReadBool(); return true; }
		if (type == typeof(float)) { *(float*)address = reader.ReadFloat(); return true; }
		if (type == typeof(double)) { *(double*)address = reader.ReadDouble(); return true; }
		if (type == typeof(int8)) { *(int8*)address = (int8)reader.ReadU8(); return true; }
		if (type == typeof(uint8)) { *(uint8*)address = reader.ReadU8(); return true; }
		if (type == typeof(int16)) { *(int16*)address = (int16)reader.ReadU16(); return true; }
		if (type == typeof(uint16)) { *(uint16*)address = reader.ReadU16(); return true; }
		if (type == typeof(int32)) { *(int32*)address = reader.ReadI32(); return true; }
		if (type == typeof(uint32)) { *(uint32*)address = reader.ReadU32(); return true; }
		if (type == typeof(int64)) { *(int64*)address = (int64)reader.ReadU64(); return true; }
		if (type == typeof(uint64)) { *(uint64*)address = reader.ReadU64(); return true; }

		if (type == typeof(Float2))
		{
			Float2 value = ?;
			value.X = reader.ReadFloat();
			value.Y = reader.ReadFloat();
			*(Float2*)address = value;
			return true;
		}
		if (type == typeof(Float3))
		{
			Float3 value = ?;
			value.X = reader.ReadFloat();
			value.Y = reader.ReadFloat();
			value.Z = reader.ReadFloat();
			*(Float3*)address = value;
			return true;
		}
		if (type == typeof(Float4))
		{
			Float4 value = ?;
			value.X = reader.ReadFloat();
			value.Y = reader.ReadFloat();
			value.Z = reader.ReadFloat();
			value.W = reader.ReadFloat();
			*(Float4*)address = value;
			return true;
		}
		if (type == typeof(Quaternion))
		{
			Quaternion value = ?;
			value.X = reader.ReadFloat();
			value.Y = reader.ReadFloat();
			value.Z = reader.ReadFloat();
			value.W = reader.ReadFloat();
			*(Quaternion*)address = value;
			return true;
		}
		return false;
	}

	/// Writes every replicated field of the component at `address`, in layout order.
	/// Returns the field count written.
	public static int WriteState(BitWriter writer, Type type, void* address)
	{
		if ((type == null) || (address == null))
			return 0;

		var written = 0;
		for (let field in ReplicatedLayout.Fields(type))
		{
			if (WriteValue(writer, field.FieldType, (uint8*)address + field.MemberOffset))
				written++;
		}
		return written;
	}

	/// Reads and applies the fields WriteState wrote, in the same order. Returns the count
	/// applied.
	///
	/// A read past the end stops EARLY and applies nothing further: the wire is overflow safe,
	/// and applying a garbage read would corrupt live state rather than merely lose an update.
	/// The caller sees the short count.
	public static int ReadState(BitReader reader, Type type, void* address)
	{
		if ((type == null) || (address == null))
			return 0;

		// Hoisted: a `scope` allocation inside a loop body lives until the method returns, so
		// one buffer is reused rather than one per field. Sixteen bytes covers the widest
		// supported type (Float4 and Quaternion).
		let scratch = scope uint8[16]();

		var applied = 0;
		for (let field in ReplicatedLayout.Fields(type))
		{
			// Decoded into scratch first, so an overflow never half writes the live field.
			if (!ReadValue(reader, field.FieldType, &scratch[0]))
				break;
			if (!reader.Ok)
				break;

			Internal.MemCpy((uint8*)address + field.MemberOffset, &scratch[0],
				field.FieldType.Size);
			applied++;
		}
		return applied;
	}
}
