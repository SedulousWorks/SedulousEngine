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
		/// The entity side of an entity-first method: `other.GetName()`, Self the entity.
		case EntityCall;
		/// A property getter: Field.Get.
		case Get;
		/// A struct field's getter, returning a reference to where the value lives:
		/// Field.Place, asked again on every read.
		case Place;
		/// A property setter: Field.Set.
		case Set;
		/// `X::of(entity)`: a handle to the entity's component, null without one. Owner.IsOn
		/// answers; the handle is the backend's own.
		case ComponentOf;
		/// `X::addTo(entity)`: gives the entity the component when it has none, then a handle as
		/// `of` gives. Owner.AddTo answers.
		case ComponentAddTo;
		/// `X::removeFrom(entity)`: takes the component off, whether there was one. Owner.RemoveFrom
		/// answers.
		case ComponentRemoveFrom;
		/// A component handle's reference count, up and down: the backend's own.
		case ComponentAddRef;
		case ComponentRelease;
		/// A component handle's `IsValid`: whether its entity still has the component. Owner.IsOn
		/// answers; the one use of a gone handle that is not an error.
		case ComponentIsValid;
		/// `X::Of(node)`: the handle narrowed to X, null when it names no X or nothing. Owner.Cast
		/// answers; the box is the backend's own.
		case WeakOf;
		/// A weak handle box's reference count, up and down: the backend's own.
		case WeakAddRef;
		case WeakRelease;
		/// A weak handle's `IsValid`: whether its object is still there. Never an error.
		case WeakIsValid;
		/// `a == b` on weak handles: the same handle, by identity, never resolving.
		case WeakEquals;
		/// A weak handle as a handle to one of its bases: the same box, one more reference.
		case WeakUpcast;
		/// A counted object's reference count, up and down: IScriptCounted's own.
		case CountedAddRef;
		case CountedRelease;
		/// A counted handle as a handle to one of its counted bases: the same object, one more
		/// reference.
		case CountedUpcast;
		/// A value type's construct behaviour: Method is the constructor thunk.
		case Construct;
		/// `scene.Physics`: Owner.FromScene with the scene as Self.
		case Resolve;
		/// `startCoroutine(fn)`: the backend's own.
		case StartCoroutine;
		/// `wait(seconds)` inside a coroutine: the backend's own.
		case Wait;
		/// `yield()`: a wait of nought, resumed on the next advance.
		case Yield;
		/// An operator on an inline math value: OperatorType and Operator.
		case Operator;
	}

	public Role Kind;
	public ScriptTypeInfo Owner;
	public ScriptMethodInfo Method;
	public ScriptFieldInfo Field;
	/// For a Call registered per arity: how many parameters this declaration takes.
	public int Arity;
	/// For an Operator: the value type and which operator.
	public AngelScriptOperatorType OperatorType;
	public AngelScriptOperator Operator;
}
