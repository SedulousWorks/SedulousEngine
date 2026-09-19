using System;

namespace Sedulous.Script;

/// One public member of a script class as the language reports it: a property's name and
/// the kind it crosses as, or a method's name and arity. What a cook harvests from.
class ScriptMemberDesc
{
	public String Name = new .() ~ delete _;
	/// A property: how its value crosses; Nil when it cannot.
	public ScriptValueKind Kind = .Nil;
	/// A property: the language's type name, `float`, `Entity`, `AudioClip@`.
	public String TypeName = new .() ~ delete _;
	/// A method: how many parameters. -1 for a property.
	public int Arity = -1;

	public bool IsMethod => Arity >= 0;
}
