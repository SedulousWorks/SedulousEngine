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
/// exposed members is legal and useful: a value a script passes through without reaching into.
///
/// A type may instead say [Scriptable(.AllPublic)] and expose its whole public surface, which
/// is what a closed value type wants; see [[ScriptMemberPolicy]] for when that is right. The
/// default stays MarkedOnly, so the strict answer is the one you get by writing nothing.
///
/// THE OVERLOAD RULE, which a generator has to enforce rather than discover: no two exposed
/// methods on a type may share name, ARITY and staticness. Same name with different arity is
/// fine and every backend can dispatch it by argument count. Same name with the SAME arity
/// is not, because a dynamically typed caller passing a number picks neither the float nor
/// the int overload, and it has to be split with [[ScriptNameAttribute]].
/// StaticField and Constructor are in the target list on purpose. Raptor exposes named
/// constants (.Constant("Zero", Float3::Zero)) and constructors (.Constructor<f32, f32, f32>)
/// alongside methods, and a script surface for a value type is poor without both. Beef spells
/// a static field and an instance field differently in AttributeUsage, so listing Field alone
/// would silently refuse every constant.
[AttributeUsage(.Types | .Field | .StaticField | .Property | .Method | .Constructor,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ScriptableAttribute : Attribute
{
	/// Only meaningful on a type; a member carrying this is exposed either way.
	public ScriptMemberPolicy Members;

	public this()
	{
		Members = .MarkedOnly;
	}

	public this(ScriptMemberPolicy members)
	{
		Members = members;
	}
}
