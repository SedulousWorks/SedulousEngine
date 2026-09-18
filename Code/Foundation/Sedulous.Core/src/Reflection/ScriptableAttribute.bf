using System;

namespace Sedulous.Core;

/// Exposed to scripting. Nothing else is.
///
/// OPT IN, and that is the whole point. Raptor's reflection is manual, so a type exists on
/// the script surface only because someone wrote REFLECT_MEMBERS for it and a member only
/// because someone wrote .Property or .Method. Beef reflects everything by default, which
/// would turn every public member into API the moment a generator ran. This restores the
/// property Raptor gets for free: the surface is what someone decided it is.
///
/// Apply to a TYPE to bind the type, and to each MEMBER to expose it. A bound type with no
/// marked members is legal and useful: a value a script passes through without reaching
/// into.
///
/// THE OVERLOAD RULE, which a generator has to enforce rather than discover: no two exposed
/// methods on a type may share name, ARITY and staticness. Same name with different arity is
/// fine and every backend can dispatch it by argument count. Same name with the SAME arity
/// is not, because a dynamically typed caller passing a number picks neither the float nor
/// the int overload, and it has to be split with [[ScriptNameAttribute]].
[AttributeUsage(.Types | .Field | .Property | .Method,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ScriptableAttribute : Attribute
{
}
