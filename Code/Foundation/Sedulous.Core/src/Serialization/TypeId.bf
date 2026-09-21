using System;

namespace Sedulous.Core.Serialization;

/// A stable identity for a serialized type.
static
{
	/// A stable type id, hashed from the type's qualified name with FNV-1a.
	///
	/// A hand-maintained number per type would be one more thing to get wrong and one more
	/// thing to remember. A name hash needs nobody to maintain it and is stable across
	/// builds, which a runtime type id is not. The only thing that changes it is renaming
	/// or moving the type, and that IS a format change.
	public static uint64 TypeIdOf(StringView qualifiedName)
	{
		var hash = 0xCBF29CE484222325UL;
		for (let c in qualifiedName)
		{
			hash ^= (uint64)(uint8)c;
			// &* rather than *, because FNV RELIES on the multiply wrapping. Plain
			// arithmetic traps on overflow wherever those checks are on, and this runs for
			// every stored type: it would take the whole format down at once, through a
			// build configuration rather than a code change.
			hash = hash &* 0x100000001B3UL;
		}
		return hash;
	}
}
