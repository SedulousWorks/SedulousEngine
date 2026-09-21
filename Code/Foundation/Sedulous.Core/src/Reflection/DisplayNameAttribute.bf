using System;

namespace Sedulous.Core;

/// The name a HUMAN should see, where the identifier is not it.
///
/// `castShadows` is the identity and is what serialisation and script both address; "Cast
/// Shadows" is what an inspector row is labelled. Absent, a reader derives one from the
/// identifier, so this is for the cases where deriving gets it wrong.
///
/// On types and properties alike, and by far the most used of the reflection marks.
[AttributeUsage(.Types | .Field | .Property | .Method,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct DisplayNameAttribute : Attribute
{
	public String Name;

	public this(String name)
	{
		Name = name;
	}
}
