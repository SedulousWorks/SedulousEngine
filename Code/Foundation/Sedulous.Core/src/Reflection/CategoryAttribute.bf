using System;

namespace Sedulous.Core;

/// The group this belongs under, for a reader that presents many things at once.
///
/// On a TYPE it is the bucket a creation menu files it in. On a MEMBER it is the section
/// an inspector groups it into, which is how a component with thirty fields stays legible.
///
/// Grouping is the READER's job, not the author's: members carrying the same category need
/// not be adjacent, and a reader that cares should gather them. Legacy Sedulous grouped
/// only adjacent fields and said so; that is a limitation to not repeat.
[AttributeUsage(.Types | .Field | .Property | .Method,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct CategoryAttribute : Attribute
{
	public String Name;

	public this(String name)
	{
		Name = name;
	}
}
