using System;

namespace Sedulous.Core;

/// What a script's weak handle resolves through: a table of slots with generations, so a
/// handle to an object since destroyed (its slot freed, perhaps reused) answers null rather
/// than a dangling reference. A script's handle keeps one reference on the table, so the
/// table outlives every handle even when its owner closes it. The two counting members are
/// corlib RefCounted's own public ones, so any RefCounted table has them (its IRefCounted.Release
/// is explicit, which an inherited IRefCounted would not accept).
interface IScriptWeakTable
{
	void AddRef();
	void ReleaseRef();

	/// The object in `slot` when its generation is still `generation`, else null.
	Object ResolveWeak(uint32 slot, uint32 generation);
}

/// A class scripts hold only weakly: its owner makes and destroys it, and a script's handle
/// to it may outlive it. The surface walker gives it, and every class derived from it, the
/// Weak role.
interface IScriptWeaklyHeld
{
	/// The handle to this object, empty (a null table) when it is in no table.
	ScriptWeakRef TakeScriptWeak();
}

/// One weak handle: the table, the slot and the generation it was taken at. Copied freely;
/// it holds no reference of its own, so whoever stores one long term keeps the table alive.
[CRepr]
struct ScriptWeakRef
{
	public IScriptWeakTable Table;
	public uint32 Slot;
	public uint32 Generation;

	public this(IScriptWeakTable table, uint32 slot, uint32 generation)
	{
		Table = table;
		Slot = slot;
		Generation = generation;
	}

	public Object Resolve() => (Table != null) ? Table.ResolveWeak(Slot, Generation) : null;

	public bool IsEmpty => Table == null;

	/// Identity, never resolving: a gone handle still compares.
	public bool SameAs(ScriptWeakRef other) => (Table === other.Table) && (Slot == other.Slot) && (Generation == other.Generation);
}
