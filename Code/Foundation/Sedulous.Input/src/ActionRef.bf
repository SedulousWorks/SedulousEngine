using Sedulous.Core;

namespace Sedulous.Input;

/// A resolved action name.
///
/// The lookup happens once, at Resolve; a query is then an array index. A game asks about
/// the same handful of actions every frame, and doing string compares across every set for
/// each of them is work with nothing to show for it.
[Scriptable(.AllPublic)]
struct ActionRef
{
	public const uint32 cInvalid = 0xFFFFFFFF;

	/// Into the runtime's candidate table.
	public uint32 Index = cInvalid;

	public this() {}
	public this(uint32 index) { Index = index; }

	public bool IsValid => Index != cInvalid;
}
