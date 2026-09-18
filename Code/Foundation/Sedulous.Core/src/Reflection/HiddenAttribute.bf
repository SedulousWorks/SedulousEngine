using System;

namespace Sedulous.Core;

/// Keep this out of what a reader presents, without keeping it out of reflection.
///
/// For the member that is public because the engine needs it and meaningless to a person:
/// a cached handle, a dirty flag, a resolved pointer. Marking it beats making it private,
/// because private would also hide it from serialisation and from code that has business
/// with it.
///
/// A PRESENTATION rule, not a security one. Nothing here prevents reading the member.
[AttributeUsage(.Field | .Property | .Method,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct HiddenAttribute : Attribute
{
}
