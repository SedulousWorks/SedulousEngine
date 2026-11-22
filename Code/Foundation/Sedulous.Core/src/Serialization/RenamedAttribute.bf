using System;

namespace Sedulous.Core.Serialization;

/// A field whose wire key changed at data version `Since`, which data stored before it still
/// carries under `FormerKey`: [Serializable]'s body reads such data (its legacy reader,
/// minReadVersion) from the former key and writes only the field's own, so a file saved again
/// holds the new key alone. The field keeps its place, so a positional payload reads it as before.
[AttributeUsage(.Field, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct RenamedAttribute : Attribute
{
	/// The data version that took the field's current key.
	public uint32 Since;
	/// The key data stored before `Since` carries the field under.
	public String FormerKey;

	public this(uint32 since, String formerKey)
	{
		Since = since;
		FormerKey = formerKey;
	}
}
