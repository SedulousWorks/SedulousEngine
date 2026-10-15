using System;

namespace Sedulous.Core;

/// The shape of the script function a method's callback parameter takes, in AngelScript's
/// funcdef form: `void NetNumberHandler(int sender, double value)`.
///
/// A callback parameter (a ScriptDelegate) is a `ScriptCallback@`, a function of no
/// arguments, unless its method names another shape here. A backend that types its functions
/// (AngelScript) declares the shape once, the first time a method uses it, and the parameter
/// takes a handle of it, so a script passes `NetNumberHandler(this.onTag)` or a matching
/// global function. The native side calls it with ScriptDelegate.Invoke and the arguments
/// the shape names. Every callback parameter of the method takes this shape.
[AttributeUsage(.Method, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct ScriptCallbackAttribute : Attribute
{
	public String Declaration;

	public this(String declaration)
	{
		Declaration = declaration;
	}
}
