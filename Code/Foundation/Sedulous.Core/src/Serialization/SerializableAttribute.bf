using System;
using System.Collections;
using System.Reflection;

namespace Sedulous.Core.Serialization;

/// Generates a Serialize body that walks the type's public instance fields, and adds
/// ISerializable.
///
/// This is the default way to make a type serializable. Raptor cannot do it: describing a
/// type's data there means writing the field list out by hand in Serialize.cppm, or
/// standing up the external RTTI-driven module and registering the type with it. Comptime
/// reflection reads the fields that are already declared, so the declaration IS the
/// description and the two cannot drift.
///
/// A key is emitted for every field whatever the backend is. Binary ignores it and stays
/// positional; a text backend needs it. One shape serves both.
///
/// FIELD ORDER IS THE BINARY FORMAT. Fields are walked in declaration order, so inserting
/// one in the middle changes what old data means. Add at the end, and use dataVersion plus
/// a hand-written body when the shape has to change. Marking the type [Ordered] pins the
/// layout to the declaration order as well.
///
/// The opt-out is to implement ISerializable yourself and not apply this: for a type whose
/// stored shape is not its field list, a hand-written body still wins.
[AttributeUsage(.Class, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct SerializableAttribute : Attribute, IComptimeTypeApply
{
	private uint32 mDataVersion;

	/// dataVersion is the version this type's data is written with. Zero, the default,
	/// means unversioned and writes no envelope at all. Any other value brackets the
	/// payload with its version chain, so a later build reading older data sees the
	/// version that data carries in ar.Version and can branch on it.
	public this(uint32 dataVersion = 0)
	{
		mDataVersion = dataVersion;
	}

	[Comptime]
	public void ApplyToType(Type type)
	{
		// A union has no single field list to walk, so there is nothing honest to emit.
		Runtime.Assert(!type.IsUnion, "[Serializable] cannot describe a union");

		let qualifiedName = scope String();
		type.GetFullName(qualifiedName);

		// A derived stored type has its OWN identity and its own version, so hiding the
		// base's constants is the intent rather than an accident. Said explicitly, because
		// otherwise every serializable subclass compiles with two warnings.
		let hides = InheritsSerializable(type) ? "new " : "";

		let body = scope String();
		body.AppendF("public {}const uint64 TypeId = 0x{:X}UL;\n", hides, Sedulous.Core.Serialization.TypeIdOf(qualifiedName));
		body.AppendF("public {}const uint32 DataVersion = {};\n\n", hides, mDataVersion);
		body.Append("void Sedulous.Core.Serialization.ISerializable.Serialize(Sedulous.Core.Serialization.ISerializer ar)\n{\n");

		// A version envelope costs bytes in every payload, so declaring a version is how
		// you opt into one. An unversioned type writes exactly its fields.
		if (mDataVersion > 0)
			body.Append("\tSedulous.Core.Serialization.BeginVersionedPayload(ar, TypeId, DataVersion);\n");

		body.Append("\tar.BeginObject();\n");

		// Base first, then this type. An inherited field is part of what this object IS,
		// so leaving it out writes an object that cannot be reconstructed: the base state
		// simply vanishes, and a binary read is positional, so it vanishes SILENTLY.
		//
		// The whole chain is walked here rather than delegating to the base's own
		// Serialize, so the object gets ONE version envelope and one key order. A base
		// that also declares [Serializable] keeps its own envelope for when it is stored
		// on its own; it is not nested inside this one.
		let chain = scope List<Type>();
		for (var walk = type; walk != null; walk = walk.BaseType)
		{
			// Object itself declares nothing worth storing, and stopping there keeps the
			// walk off corlib.
			if (walk == typeof(Object))
				break;
			chain.Add(walk);
		}

		for (int i = chain.Count - 1; i >= 0; i--)
		{
			let declaring = chain[i];
			for (let field in declaring.GetFields())
			{
				// Fields declared by THIS link of the chain. Every type reports inherited
				// fields too, so without the filter a base field is written once per
				// level below it.
				if (!field.IsInstanceField || (field.DeclaringType != declaring))
					continue;

				body.AppendF("\tar.Key(\"{}\");\n", field.Name);

				// A type that knows how to describe ITSELF does. That is the escape hatch for
				// anything the dispatcher cannot know about: a resource reference stores only
				// its identity, and Core cannot be told what a resource is.
				if (HasSelfSerialize(field.FieldType))
				{
					body.AppendF("\t{}.Serialize(ar);\n", field.Name);
					continue;
				}

				// A list is count prefixed and walks its elements through the dispatcher.
				// It has to be spelled out here because a List is a reference type, and
				// the reference overload below takes the object itself.
				if (IsList(field.FieldType))
				{
					body.AppendF("\tSedulous.Core.Serialization.SerializeList(ar, {});\n", field.Name);
					continue;
				}

				// A value type goes through the dispatcher, which covers enums too; a
				// reference type IS the handle its overload takes.
				if (field.FieldType.IsValueType)
					body.AppendF("\tSedulous.Core.Serialization.SerializeValue(ar, ref {});\n", field.Name);
				else
					body.AppendF("\tSedulous.Core.Serialization.Serialize(ar, {});\n", field.Name);
			}
		}

		body.Append("\tar.EndObject();\n");
		if (mDataVersion > 0)
			body.Append("\tSedulous.Core.Serialization.EndVersionedPayload(ar);\n");
		body.Append("}");

		Compiler.EmitTypeBody(type, body);
		Compiler.EmitAddInterface(type, typeof(ISerializable));
	}

	/// Whether any ancestor also carries [Serializable], and so declares the constants
	/// this type is about to declare again.
	[Comptime]
	private static bool InheritsSerializable(Type type)
	{
		for (var walk = type.BaseType; walk != null; walk = walk.BaseType)
		{
			if (walk.HasCustomAttribute<SerializableAttribute>())
				return true;
		}
		return false;
	}

	/// Whether a type is a List<T>, which serializes as a counted array rather than as an
	/// object. Matched by name because comptime has no generic definition to compare to.
	[Comptime]
	private static bool IsList(Type type)
	{
		let name = scope String();
		type.GetFullName(name);
		return name.StartsWith("System.Collections.List<");
	}

	/// Whether a type carries its own Serialize, taking just the serializer.
	[Comptime]
	private static bool HasSelfSerialize(Type type)
	{
		if (let instance = type as TypeInstance)
		{
			for (let method in instance.GetMethods())
			{
				if ((method.Name == "Serialize") && (method.ParamCount == 1))
					return true;
			}
		}
		return false;
	}
}
