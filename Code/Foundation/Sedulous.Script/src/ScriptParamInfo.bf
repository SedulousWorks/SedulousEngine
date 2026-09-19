using System;

namespace Sedulous.Script;

/// One parameter of a surface method.
class ScriptParamInfo
{
	public String Name = new .() ~ delete _;
	public String TypeName = new .() ~ delete _;
	/// How it crosses: the ScriptValue kind the slot takes. Object and Struct are typed by
	/// TypeName; a Ref<T> is Guid.
	public ScriptValueKind Kind = .Nil;
	/// Passed by reference: `ref`, `out`, or `in`.
	public bool IsByRef = false;
	/// Declared with a default, so a call may leave it out and every one after it. The
	/// value itself is not carried: the thunk calls the shorter arity and the compiler
	/// supplies it, in the declaring context.
	public bool HasDefault = false;
}
