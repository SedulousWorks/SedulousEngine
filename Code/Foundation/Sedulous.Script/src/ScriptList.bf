using System;

namespace Sedulous.Script;

/// A List<T> crossing the boundary: its elements as values, in storage the call context
/// owns for the call. Both sides copy: the thunk packs a Beef list into one of these and
/// unpacks one into a Beef list, and a VM does the same with its own array, so neither
/// holds the other's container. ElementType names T in full, which is what a slot checks.
[CRepr]
struct ScriptList
{
	public ScriptValue* Items;
	public int32 Count;
	public ScriptValueKind ElementKind;
	public StringView ElementType;

	public Span<ScriptValue> Values => .(Items, Count);
}
