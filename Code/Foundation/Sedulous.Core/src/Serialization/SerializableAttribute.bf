using System;
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

	/// dataVersion is the version this type's data is written with, for a body that has to
	/// read an older layout. Zero means unversioned.
	public this(uint32 dataVersion = 0)
	{
		mDataVersion = dataVersion;
	}

	[Comptime]
	public void ApplyToType(Type type)
	{
		// A union has no single field list to walk, so there is nothing honest to emit.
		Runtime.Assert(!type.IsUnion, "[Serializable] cannot describe a union");

		let body = scope String();
		body.AppendF("public const uint32 DataVersion = {};\n\n", mDataVersion);
		body.Append("void Sedulous.Core.Serialization.ISerializable.Serialize(Sedulous.Core.Serialization.ISerializer ar)\n{\n");
		body.Append("\tar.BeginObject();\n");

		for (let field in type.GetFields())
		{
			// Instance fields declared HERE. An inherited field belongs to the base's own
			// body, and walking it again would write it twice.
			if (!field.IsInstanceField || (field.DeclaringType != type))
				continue;

			body.AppendF("\tar.Key(\"{}\");\n", field.Name);
			// A value type goes through the dispatcher, which covers enums too; a
			// reference type IS the handle its overload takes.
			if (field.FieldType.IsValueType)
				body.AppendF("\tSedulous.Core.Serialization.SerializeValue(ar, ref {});\n", field.Name);
			else
				body.AppendF("\tSedulous.Core.Serialization.Serialize(ar, {});\n", field.Name);
		}

		body.Append("\tar.EndObject();\n}");

		Compiler.EmitTypeBody(type, body);
		Compiler.EmitAddInterface(type, typeof(ISerializable));
	}
}
