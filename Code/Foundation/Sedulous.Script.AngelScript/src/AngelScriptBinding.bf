using System;
using Sedulous.Script;

namespace Sedulous.Script.AngelScript;

/// One registration with AngelScript: what the trampoline finds behind the auxiliary
/// pointer, and enough to marshal the call. Owned by the runtime.
class AngelScriptBinding
{
	public enum Role
	{
		/// A method, a global function or a constructor: Method with its thunk.
		case Call;
		/// A property getter: Field.Get.
		case Get;
		/// A property setter: Field.Set.
		case Set;
		/// A component value's constructor from an entity: no thunk, the backend's own.
		case ComponentFromEntity;
		/// A value type's construct behaviour: Method is the constructor thunk.
		case Construct;
		/// `scene.Physics`: Owner.FromScene with the scene as Self.
		case Resolve;
		/// `startCoroutine(fn)`: the backend's own.
		case StartCoroutine;
		/// `wait(seconds)` inside a coroutine: the backend's own.
		case Wait;
	}

	public Role Kind;
	public ScriptTypeInfo Owner;
	public ScriptMethodInfo Method;
	public ScriptFieldInfo Field;
	/// For a Call registered per arity: how many parameters this declaration takes.
	public int Arity;
}
