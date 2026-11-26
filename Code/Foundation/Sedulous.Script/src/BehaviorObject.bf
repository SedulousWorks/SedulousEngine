using System;

namespace Sedulous.Script;

/// A live object a behavior class made, held by the host: the run's game object, a scene's, an
/// entity's behavior. The layer that runs behaviors calls it by method name and reads its
/// properties through its runtime, never knowing what is behind it: today a script object in a
/// language's VM. A backend subclasses it with what it needs to reach the object; the host sees
/// the runtime it belongs to and the class name. Released through the runtime, never deleted
/// directly.
abstract class BehaviorObject
{
	public ScriptRuntime Runtime;
	public String ClassName = new .() ~ delete _;
}
