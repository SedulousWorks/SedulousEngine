namespace Sedulous.Script;

/// What a ScriptValue holds. The inline kinds are the ones that cross the boundary by the
/// hundred (see the engine listing); everything else is a class reference or a struct in
/// storage the VM owns.
enum ScriptValueKind : uint8
{
	case Nil;
	case Bool;
	/// Every integer and every enum, widened to int64.
	case Int;
	/// float and double, widened to double.
	case Float;
	/// A borrowed StringView: valid until the callee's owner changes it, so a VM copies.
	case String;
	case Guid;
	case Entity;
	case Float2;
	case Float3;
	case Float4;
	case Quaternion;
	case Color;
	/// A class reference. Ownership follows the call: a constructor's result is the VM's.
	case Object;
	/// Any other struct, by pointer into storage the VM owns: a result the thunk placed
	/// through ScriptCallContext.AllocStruct, or an argument the VM keeps.
	case Struct;
	/// A List<T> of a crossable T, as a ScriptList of its elements in context storage: a
	/// copy in either direction, so a VM renders its own array and the callee its own list.
	case List;
}
