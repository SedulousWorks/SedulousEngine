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
	/// The default as written in the declaration, empty when the parameter has none. Beef
	/// source, so generated code can pass it through as is.
	public String Default = new .() ~ delete _;

	public bool HasDefault => !Default.IsEmpty;
}
