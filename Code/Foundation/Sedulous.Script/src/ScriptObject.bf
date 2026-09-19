using System;

namespace Sedulous.Script;

/// An instance of a script class, held by the host. A backend subclasses it with what it
/// needs to reach the object; the host sees the runtime it belongs to and the class name.
/// Released through the runtime, never deleted directly.
abstract class ScriptObject
{
	public ScriptRuntime Runtime;
	public String ClassName = new .() ~ delete _;
}
