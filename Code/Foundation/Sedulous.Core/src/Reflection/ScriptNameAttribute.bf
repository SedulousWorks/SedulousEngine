using System;

namespace Sedulous.Core;

/// The name this is spelled by on the script surface, where the derived one will not do.
///
/// This is Raptor's OverloadedName, and it exists for OVERLOADS: Beef has them and most
/// script languages do not. Two methods that share a name in Beef are one name over there,
/// so one of them has to be spelled differently, and this is where that is said. Raptor's own
/// example is Float3 operator* taking a scalar, exposed as MulScalar beside the vector Mul.
///
/// Even a language that dispatches on argument COUNT does not save the case where the arity
/// matches too: a dynamically typed caller passing a number picks neither the float overload
/// nor the int one. That is the clash [[ScriptableAttribute]]'s overload rule refuses, and
/// renaming is the only way out of it.
///
/// Also the plain override for a derived name that reads badly or collides with a keyword of
/// the target language. Worth applying sparingly either way: every use is a name that has to
/// be looked up rather than guessed.
///
/// NOT Raptor's type level "scriptName" attribute, which names the module a facade is
/// reached through. Facades are not ported, so that use has no counterpart here.
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
