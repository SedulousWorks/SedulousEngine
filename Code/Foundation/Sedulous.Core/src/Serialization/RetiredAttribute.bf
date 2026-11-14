using System;

namespace Sedulous.Core.Serialization;

/// A field the layout no longer has, which data stored before version `Until` still carries:
/// [Serializable]'s body reads it from such data alone (its legacy reader, minReadVersion) and
/// never writes it, so the value an older file held reaches the code that carries it forward
/// while every file saved since, and every copy made through the serializer, holds none.
///
/// `Key` names what the older data stored it under, when that is not the field's own wire key
/// (a field renamed for what it holds now). It stands where the field stood in the older layout,
/// so a positional payload reads it in order.
[AttributeUsage(.Field, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct RetiredAttribute : Attribute
{
	/// The data version that dropped the field.
	public uint32 Until;
	/// The key older data stored it under; null for the field's own.
	public String Key;

	public this(uint32 until, String key = null)
	{
		Until = until;
		Key = key;
	}
}
