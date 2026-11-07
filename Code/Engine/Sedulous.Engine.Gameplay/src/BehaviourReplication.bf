using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Net.Replication;

namespace Sedulous.Engine.Gameplay;

/// What a [Replicated] behaviour field may hold: the kinds a script's replicated property
/// travels as, each at a fixed width so every platform reads what another wrote.
enum ReplicatedKind : uint8
{
	None,
	Bool,
	Int,
	Float,
	String,
	Float3,
	Color
}

/// One value off the wire, its text apart (ReadValue writes that into a caller's String).
struct ReplicatedValue
{
	public ReplicatedKind Kind = .None;
	public bool BoolValue = false;
	public int32 IntValue = 0;
	public float FloatValue = 0.0f;
	public Float3 VectorValue = .();
	public Color ColorValue = .();

	public this() {}
}

/// A behaviour's [Replicated] fields on the wire, the bytes its BehaviourManager writes and
/// reads as its IReplicatedStateSource.
///
/// The bytes: a u32 count of entries, each { u64 field name hash, u8 kind, the value by its
/// kind }, in declaration order, base first. The record already names the class (its type
/// id), so an entry names only its field; a reader applies an entry whose name and kind match
/// a replicated field of its own class and passes over the rest, so a peer built from an older
/// class never writes a value into the wrong field.
///
/// The field list and the statements that move each one are generated at compile time
/// (BehaviourManager), so nothing here reflects at run time.
static class BehaviourReplication
{
	/// The kind a field of `type` travels as; None for one the wire does not carry. Fixed
	/// widths only: an `int` is 32 bits on one platform and 64 on another.
	public static ReplicatedKind KindOf(Type type)
	{
		if (type == typeof(bool))
			return .Bool;
		if (type == typeof(int32))
			return .Int;
		if (type == typeof(float))
			return .Float;
		if (type == typeof(String))
			return .String;
		if (type == typeof(Float3))
			return .Float3;
		if (type == typeof(Color))
			return .Color;
		return .None;
	}

	/// The name an entry carries: FNV-1a over the field name's bytes. Callable at compile
	/// time, where the manager bakes each field's hash in.
	public static uint64 FieldHash(StringView name)
	{
		uint64 hash = 14695981039346656037UL;
		for (let c in name.RawChars)
		{
			hash ^= (uint64)(uint8)c;
			hash *= 1099511628211UL;
		}
		return hash;
	}

	// ---- the generated writer's ----

	public static void Write(BinaryWriter writer, uint64 hash, bool value)
	{
		WriteHeader(writer, hash, .Bool);
		writer.Write((uint8)(value ? 1 : 0));
	}

	public static void Write(BinaryWriter writer, uint64 hash, int32 value)
	{
		WriteHeader(writer, hash, .Int);
		writer.Write(value);
	}

	public static void Write(BinaryWriter writer, uint64 hash, float value)
	{
		WriteHeader(writer, hash, .Float);
		writer.Write(value);
	}

	/// A null String travels as an empty one.
	public static void Write(BinaryWriter writer, uint64 hash, String value)
	{
		WriteHeader(writer, hash, .String);
		writer.WriteString(value ?? "");
	}

	public static void Write(BinaryWriter writer, uint64 hash, Float3 value)
	{
		WriteHeader(writer, hash, .Float3);
		writer.Write(value);
	}

	public static void Write(BinaryWriter writer, uint64 hash, Color value)
	{
		WriteHeader(writer, hash, .Color);
		writer.Write(value);
	}

	private static void WriteHeader(BinaryWriter writer, uint64 hash, ReplicatedKind kind)
	{
		writer.Write(hash);
		writer.Write((uint8)kind);
	}

	// ---- the generated reader's ----

	/// One entry's value, of the `kind` its header named, into `value` (its text into `text`,
	/// cleared first). False on a short read or a kind this build does not know: the entries
	/// after it cannot be found, and the reader stops.
	public static bool ReadValue(BinaryReader reader, ReplicatedKind kind, ref ReplicatedValue value, String text)
	{
		value.Kind = kind;
		text.Clear();
		switch (kind)
		{
		case .Bool:
			uint8 flag = 0;
			reader.Read(out flag);
			value.BoolValue = flag != 0;
		case .Int: reader.Read(out value.IntValue);
		case .Float: reader.Read(out value.FloatValue);
		case .String:
			if (!reader.ReadString(text))
				return false;
		case .Float3: reader.Read(out value.VectorValue);
		case .Color: reader.Read(out value.ColorValue);
		default: return false;
		}
		return reader.IsOk;
	}

	// ---- compile time ----

	/// Every [Replicated] field of `type` and its bases, base first, in declaration order: the
	/// order the wire carries them in. Behaviour's own fields are never replicated.
	[Comptime]
	public static void ReplicatedFields(Type type, List<FieldInfo> outFields)
	{
		let chain = scope List<Type>();
		for (var walk = type; (walk != null) && (walk != typeof(Behaviour)); walk = walk.BaseType)
			chain.Add(walk);
		for (int i = chain.Count - 1; i >= 0; i--)
		{
			let declaring = chain[i];
			for (let field in declaring.GetFields())
			{
				if (field.DeclaringType != declaring)
					continue;
				if (field.GetCustomAttribute<ReplicatedAttribute>() case .Ok)
					outFields.Add(field);
			}
		}
	}

	/// Refuses, as a compile error naming the field, a [Replicated] field the wire cannot
	/// carry: a reference to an entity or an asset (which means nothing on another machine),
	/// any other type outside the kinds, or a static or const field (no instance's state).
	[Comptime]
	public static void RefuseUnsupported(Type type)
	{
		let fields = scope List<FieldInfo>();
		ReplicatedFields(type, fields);
		for (let field in fields)
		{
			let reason = scope String();
			if (!field.IsInstanceField)
				reason.Append("it is static, and a replicated field is an instance's state");
			else if (IsReference(field.FieldType))
				reason.Append("an entity or asset reference means nothing on another machine");
			else if (KindOf(field.FieldType) == .None)
				reason.Append("the wire carries bool, int32, float, String, Float3 and Color");
			else
				continue;

			let message = scope String();
			type.GetName(message);
			message.Append(": field '");
			message.Append(field.Name);
			message.Append("' cannot be replicated: ");
			message.Append(reason);
			Runtime.FatalError(message);
		}
	}

	/// An entity handle or reference, an asset reference, or an asset's id.
	[Comptime]
	private static bool IsReference(Type type)
	{
		if ((type == typeof(EntityRef)) || (type == typeof(EntityHandle)) || (type == typeof(Guid)))
			return true;
		let name = scope String();
		type.GetFullName(name);
		return name.StartsWith("Sedulous.Resource.Ref<");
	}
}
