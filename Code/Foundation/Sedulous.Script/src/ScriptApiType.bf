using System;
using System.Collections;

namespace Sedulous.Script;

/// What kind of member a bound API entry is, in the language's own terms.
enum ScriptApiMemberKind : uint8
{
	/// A callable member or a free function.
	Method,
	/// A field like accessor, get or get and set.
	Property,
	/// A named constant value.
	Constant
}

/// One script visible member of a bound type, spelled the way the backend presents it:
/// the signature is language formatted, `float Float3::Dot(const Float3 &in a, const
/// Float3 &in b)` for AngelScript, and a method bound once per arity appears once per
/// arity.
class ScriptApiMember
{
	public String Name = new .() ~ delete _;
	public String Signature = new .() ~ delete _;
	public bool IsStatic = false;
	public ScriptApiMemberKind Kind = .Method;
}

/// One script visible type, or namespace, the backend ACTUALLY bound, with its members
/// as it spelled them. The surface says what exists; this says what a script can write,
/// which differs per language and drops what a backend could not bind. `ScriptName` is
/// the exact name a script uses; `IsNamespace` marks a namespace a backend synthesised,
/// the global one included, rather than a class.
class ScriptApiType
{
	public String ScriptName = new .() ~ delete _;
	/// The surface type behind the binding, empty for a synthesised namespace: tooling
	/// maps it back to the surface's metadata, the domain say.
	public String TypeFullName = new .() ~ delete _;
	public bool IsNamespace = false;
	public List<ScriptApiMember> Members = new .() ~ DeleteContainerAndItems!(_);

	public ScriptApiMember Find(StringView name)
	{
		for (let m in Members)
			if (m.Name == name)
				return m;
		return null;
	}
}
