using System;

namespace Sedulous.Editor.Core;

/// A single reversible edit. Every mutation the editor makes is one of these: a property
/// set, a rename, a reparent, an entity created or destroyed. Nothing mutates directly, so
/// undo covers everything.
///
/// TypeId is the merge and group identity, a stable literal like "set_property"; commands
/// of different types never merge. The stack OWNS a command once it accepts it.
abstract class EditorCommand
{
	/// Applies the edit. False means it did nothing (an invalid target, say) and the stack
	/// DROPS the command rather than pushing it.
	public abstract bool Execute();

	/// Reverts the edit. Only called after a successful Execute.
	public abstract void Undo();

	public abstract StringView TypeId { get; }

	/// Absorbs THIS, the newer command, into `previous`, already on the stack with the same
	/// TypeId: typically copy the new target value into it. True when absorbed; the stack
	/// then re-executes `previous` and discards this one. A slider drag becomes one entry.
	public virtual bool MergeInto(EditorCommand previous) => false;
}
