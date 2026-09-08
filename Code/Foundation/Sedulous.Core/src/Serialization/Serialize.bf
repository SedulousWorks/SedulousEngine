using System;
using System.Collections;

namespace Sedulous.Core.Serialization;

/// Describes a type's data once, running either direction and working for any backend.
///
/// Aggregates use named fields and array scopes, so text output stays readable and binary
/// output decomposes rather than copying a struct whose padding and endianness are the
/// compiler's business.
static
{
	// ---- scalars ----
	//
	// One overload apiece rather than Raptor's ScalarKindOf trait cascade: the compiler
	// already knows which is which, and overload resolution says so without the cascade.

	public static void Serialize(ISerializer ar, ref bool value) => ar.Scalar(&value, .Bool);
	public static void Serialize(ISerializer ar, ref int8 value) => ar.Scalar(&value, .Int8);
	public static void Serialize(ISerializer ar, ref uint8 value) => ar.Scalar(&value, .UInt8);
	public static void Serialize(ISerializer ar, ref int16 value) => ar.Scalar(&value, .Int16);
	public static void Serialize(ISerializer ar, ref uint16 value) => ar.Scalar(&value, .UInt16);
	public static void Serialize(ISerializer ar, ref int32 value) => ar.Scalar(&value, .Int32);
	public static void Serialize(ISerializer ar, ref uint32 value) => ar.Scalar(&value, .UInt32);
	public static void Serialize(ISerializer ar, ref int64 value) => ar.Scalar(&value, .Int64);
	public static void Serialize(ISerializer ar, ref uint64 value) => ar.Scalar(&value, .UInt64);
	public static void Serialize(ISerializer ar, ref float value) => ar.Scalar(&value, .Float32);
	public static void Serialize(ISerializer ar, ref double value) => ar.Scalar(&value, .Float64);

	/// int and uint are pointer sized, so they are stored at a fixed width rather than at
	/// whatever the writing machine happened to be. A file written on one target has to
	/// read on another.
	public static void Serialize(ISerializer ar, ref int value)
	{
		var wide = (int64)value;
		ar.Scalar(&wide, .Int64);
		value = (int)wide;
	}

	public static void Serialize(ISerializer ar, ref uint value)
	{
		var wide = (uint64)value;
		ar.Scalar(&wide, .UInt64);
		value = (uint)wide;
	}

	/// Enums move as their underlying integer. The width is what has to survive the round
	/// trip; the kind only tells a text backend which token to write.
	///
	/// Named apart from the Serialize set deliberately. A constrained generic in that set
	/// is picked eagerly when the set is called from another generic body, and its
	/// constraint then fails against a T that was never going to be an enum.
	public static void SerializeEnum<T>(ISerializer ar, ref T value) where T : enum
	{
		SerializeBits(ar, &value, sizeof(T));
	}

	/// Moves a value of a given width, for the callers that know the size but not the type.
	private static void SerializeBits(ISerializer ar, void* data, int size)
	{
		switch (size)
		{
		case 1: ar.Scalar(data, .UInt8);
		case 2: ar.Scalar(data, .UInt16);
		case 8: ar.Scalar(data, .UInt64);
		default: ar.Scalar(data, .Int32);
		}
	}

	// ---- math value types ----
	//
	// Named fields, so text output is readable and binary carries no struct padding.

	public static void Serialize(ISerializer ar, ref Float2 v)
	{
		ar.BeginObject();
		ar.Key("x"); Serialize(ar, ref v.X);
		ar.Key("y"); Serialize(ar, ref v.Y);
		ar.EndObject();
	}

	public static void Serialize(ISerializer ar, ref Float3 v)
	{
		ar.BeginObject();
		ar.Key("x"); Serialize(ar, ref v.X);
		ar.Key("y"); Serialize(ar, ref v.Y);
		ar.Key("z"); Serialize(ar, ref v.Z);
		ar.EndObject();
	}

	public static void Serialize(ISerializer ar, ref Float4 v)
	{
		ar.BeginObject();
		ar.Key("x"); Serialize(ar, ref v.X);
		ar.Key("y"); Serialize(ar, ref v.Y);
		ar.Key("z"); Serialize(ar, ref v.Z);
		ar.Key("w"); Serialize(ar, ref v.W);
		ar.EndObject();
	}

	public static void Serialize(ISerializer ar, ref Quaternion q)
	{
		ar.BeginObject();
		ar.Key("x"); Serialize(ar, ref q.X);
		ar.Key("y"); Serialize(ar, ref q.Y);
		ar.Key("z"); Serialize(ar, ref q.Z);
		ar.Key("w"); Serialize(ar, ref q.W);
		ar.EndObject();
	}

	public static void Serialize(ISerializer ar, ref Color c)
	{
		ar.BeginObject();
		ar.Key("r"); Serialize(ar, ref c.R);
		ar.Key("g"); Serialize(ar, ref c.G);
		ar.Key("b"); Serialize(ar, ref c.B);
		ar.Key("a"); Serialize(ar, ref c.A);
		ar.EndObject();
	}

	/// Sixteen elements, row major.
	public static void Serialize(ISerializer ar, ref Float4x4 m)
	{
		uint32 count = 16;
		ar.BeginArray(ref count);
		let n = (count < 16) ? (int)count : 16;
		for (int i < n)
			Serialize(ar, ref m.M[i / 4][i % 4]);
		ar.EndArray();
	}

	/// A guid is whatever primitive the backend prefers, rather than a decomposed struct.
	/// It is one value everywhere it is used, and it should read as one.
	public static void Serialize(ISerializer ar, ref Guid value) => ar.GuidValue(ref value);

	// ---- reference types ----

	public static void Serialize(ISerializer ar, String value) => ar.Text(value);

	public static void Serialize(ISerializer ar, ISerializable value) => value.Serialize(ar);

	/// The entry point for a body that does not know its type concretely.
	///
	/// Beef resolves an overload set where a generic body is COMPILED rather than once per
	/// instantiation, so a generic caller cannot pick among the concrete overloads above:
	/// it binds to whichever candidate comes first and then fails on the argument. This
	/// dispatches on T instead and hands off. Generated bodies never come through here,
	/// since they know each field's type and call the overload directly.
	public static void SerializeValue<T>(ISerializer ar, ref T value) where T : ValueType
	{
		if (typeof(T).IsEnum)
		{
			SerializeBits(ar, &value, sizeof(T));
			return;
		}

		if (typeof(T) == typeof(bool)) { Serialize(ar, ref *(bool*)&value); return; }
		if (typeof(T) == typeof(int8)) { Serialize(ar, ref *(int8*)&value); return; }
		if (typeof(T) == typeof(uint8)) { Serialize(ar, ref *(uint8*)&value); return; }
		if (typeof(T) == typeof(int16)) { Serialize(ar, ref *(int16*)&value); return; }
		if (typeof(T) == typeof(uint16)) { Serialize(ar, ref *(uint16*)&value); return; }
		if (typeof(T) == typeof(int32)) { Serialize(ar, ref *(int32*)&value); return; }
		if (typeof(T) == typeof(uint32)) { Serialize(ar, ref *(uint32*)&value); return; }
		if (typeof(T) == typeof(int64)) { Serialize(ar, ref *(int64*)&value); return; }
		if (typeof(T) == typeof(uint64)) { Serialize(ar, ref *(uint64*)&value); return; }
		if (typeof(T) == typeof(int)) { Serialize(ar, ref *(int*)&value); return; }
		if (typeof(T) == typeof(uint)) { Serialize(ar, ref *(uint*)&value); return; }
		if (typeof(T) == typeof(float)) { Serialize(ar, ref *(float*)&value); return; }
		if (typeof(T) == typeof(double)) { Serialize(ar, ref *(double*)&value); return; }

		if (typeof(T) == typeof(Float2)) { Serialize(ar, ref *(Float2*)&value); return; }
		if (typeof(T) == typeof(Float3)) { Serialize(ar, ref *(Float3*)&value); return; }
		if (typeof(T) == typeof(Float4)) { Serialize(ar, ref *(Float4*)&value); return; }
		if (typeof(T) == typeof(Quaternion)) { Serialize(ar, ref *(Quaternion*)&value); return; }
		if (typeof(T) == typeof(Color)) { Serialize(ar, ref *(Color*)&value); return; }
		if (typeof(T) == typeof(Float4x4)) { Serialize(ar, ref *(Float4x4*)&value); return; }
		if (typeof(T) == typeof(Guid)) { Serialize(ar, ref *(Guid*)&value); return; }

		Runtime.FatalError(scope $"No Serialize for {typeof(T)}. Add an overload, or give the type a hand written body.");
	}

	/// Count prefixed, each element through the dispatcher. Reading clears the list first,
	/// so a reused one does not accumulate.
	public static void SerializeList<T>(ISerializer ar, List<T> list) where T : ValueType
	{
		uint32 count = (uint32)list.Count;
		ar.BeginArray(ref count);

		if (ar.Mode == .Read)
		{
			list.Clear();
			list.Reserve((int)count);
			for (uint32 i < count)
			{
				T element = default;
				SerializeValue(ar, ref element);
				list.Add(element);
			}
		}
		else
		{
			for (int i < list.Count)
				SerializeValue(ar, ref list[i]);
		}

		ar.EndArray();
	}

	/// The same for a list of STRINGS, which the value type overload cannot take: a string
	/// is a reference, and its BYTES rather than its handle are what get stored.
	///
	/// THE LIST OWNS ITS ITEMS. Reading deletes what was there and allocates fresh ones, so
	/// a reused list neither accumulates nor leaks.
	public static void SerializeList(ISerializer ar, List<String> list)
	{
		uint32 count = (uint32)list.Count;
		ar.BeginArray(ref count);

		if (ar.Mode == .Read)
		{
			ClearAndDeleteItems!(list);
			list.Reserve((int)count);
			for (uint32 i < count)
			{
				let element = new String();
				ar.Text(element);
				list.Add(element);
			}
		}
		else
		{
			for (int i < list.Count)
				ar.Text(list[i]);
		}

		ar.EndArray();
	}

	// ---- named fields ----
	//
	// The key is emitted for every field whatever the backend is: binary ignores it, text
	// needs it, and a body that keys only sometimes would describe two different shapes.

	public static void SerializeValue<T>(ISerializer ar, StringView key, ref T value) where T : ValueType
	{
		ar.Key(key);
		SerializeValue(ar, ref value);
	}

	public static void Serialize(ISerializer ar, StringView key, String value)
	{
		ar.Key(key);
		ar.Text(value);
	}

	public static void Serialize(ISerializer ar, StringView key, ISerializable value)
	{
		ar.Key(key);
		value.Serialize(ar);
	}
}
