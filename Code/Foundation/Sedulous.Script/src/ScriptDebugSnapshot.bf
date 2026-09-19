using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Script;

/// One frame of a captured call stack.
///
/// The snapshot types are plain data and WIRE SYMMETRIC: one Serialize runs identically in
/// both directions, because a remote debug transport moves them across a socket.
class ScriptStackFrame : ISerializable
{
	public String File = new .() ~ delete _;
	public String Function = new .() ~ delete _;
	public int32 Line = -1;

	public void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "file", File);
		Sedulous.Core.Serialization.Serialize(ar, "function", Function);
		SerializeValue(ar, "line", ref Line);
	}
}

/// One captured named value: a local, an argument, or an object member. `Value` is the
/// display text; a non zero `ObjectRef` marks it as an object whose members are fetched
/// lazily with IScriptDebugger.CaptureObject.
class ScriptVariable : ISerializable
{
	public String Name = new .() ~ delete _;
	public String TypeName = new .() ~ delete _;
	public String Value = new .() ~ delete _;
	/// Nought is a leaf scalar; anything else an expandable object handle, stable for the
	/// duration of one break.
	public uint64 ObjectRef = 0;

	public void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "name", Name);
		Sedulous.Core.Serialization.Serialize(ar, "typeName", TypeName);
		Sedulous.Core.Serialization.Serialize(ar, "value", Value);
		SerializeValue(ar, "objectRef", ref ObjectRef);
	}
}

/// A lazily expandable object handle in a capture: its opaque reference and a short
/// display text.
class ScriptValueObject : ISerializable
{
	public uint64 Ref = 0;
	public String Text = new .() ~ delete _;

	public void Serialize(ISerializer ar)
	{
		SerializeValue(ar, "ref", ref Ref);
		Sedulous.Core.Serialization.Serialize(ar, "text", Text);
	}
}
