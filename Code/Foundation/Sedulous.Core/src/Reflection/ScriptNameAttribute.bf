using System;

namespace Sedulous.Core;

/// The name a SCRIPT should use, where the derived one is wrong.
///
/// A binding generator derives a script name from the identifier, and the derivation is a
/// convention: Vec3Length becomes vec3_length, or whatever the target language spells. That
/// works until it does not, and this is the override for when it does not.
///
/// Worth applying sparingly. Every use is a name that has to be looked up rather than
/// guessed, so it earns its place when the derived name would collide, shadow a keyword of
/// the target language, or read badly enough to matter.
[AttributeUsage(.Types | .Field | .Property | .Method,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ScriptNameAttribute : Attribute
{
	public String Name;

	public this(String name)
	{
		Name = name;
	}
}
