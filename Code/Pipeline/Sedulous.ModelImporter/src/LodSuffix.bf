using System;

namespace Sedulous.ModelImporter;

/// Reading an authored level of detail suffix off a mesh's name.
///
/// A model that ships "Foo", "Foo_LOD1" and "Foo_lod2" is describing one mesh with a chain,
/// and attaching them is the only way to get the author's own levels rather than generated
/// ones.
static class LodSuffix
{
	/// The level a name names, with the base name written out, or NOUGHT for a plain name.
	///
	/// Level nought spelled out is treated as plain: the base of a chain spells itself
	/// plainly, and a mesh named "Foo_LOD0" IS the base rather than a level of some other
	/// "Foo" that may not exist.
	public static uint32 Parse(StringView name, String outBase)
	{
		let length = name.Length;
		var digits = 0;
		while ((digits < length) && (name[length - 1 - digits] >= '0')
			&& (name[length - 1 - digits] <= '9'))
		{
			digits++;
		}
		if ((digits == 0) || (digits > 2) || (length < digits + 4))
			return 0;

		let tag = length - digits - 4; // where "_LOD" would start, whatever its case
		char8 Lower(char8 c) => ((c >= 'A') && (c <= 'Z')) ? (char8)(c + 32) : c;
		if ((name[tag] != '_') || (Lower(name[tag + 1]) != 'l') || (Lower(name[tag + 2]) != 'o')
			|| (Lower(name[tag + 3]) != 'd'))
		{
			return 0;
		}

		uint32 level = 0;
		for (int i < digits)
			level = level * 10 + (uint32)(name[length - digits + i] - '0');
		if (level == 0)
			return 0;

		outBase.Set(name.Substring(0, tag));
		return level;
	}
}
