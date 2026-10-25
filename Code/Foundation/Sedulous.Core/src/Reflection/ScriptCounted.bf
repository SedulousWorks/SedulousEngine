using System;

namespace Sedulous.Core;

/// A class scripts hold by a counted reference: a script's handle keeps one, so the object
/// lives while any script or native holder does, and the last release frees it. What the
/// GUI's tweens and list models are, which no owner destroys out from under a script. The
/// two members are corlib RefCounted's own public ones, so any RefCounted class has them
/// (its IRefCounted.Release is explicit, which an inherited IRefCounted would not accept).
/// The surface walker gives such a class, and every class derived from it, the Counted role.
interface IScriptCounted
{
	void AddRef();
	void ReleaseRef();
}

/// The counted result of this method carries a reference the caller takes: a factory's new
/// object, its one reference handed over. Without it a counted result is lent, and a
/// script that keeps it takes a reference of its own. A constructor's result always carries
/// one. Only a method whose result is IScriptCounted may say so; the walk refuses any other.
[AttributeUsage(.Method, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ScriptReturnsReferenceAttribute : Attribute
{
}
