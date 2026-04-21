namespace Sedulous.Editor.Core;

using System;

/// Undoable editor operation. All scene/asset mutations go through commands.
interface IEditorCommand : IDisposable
{
	/// Human-readable description (shown in Edit > Undo "description").
	StringView Description { get; }

	/// Execute the operation (first time or redo).
	void Execute();

	/// Reverse the operation.
	void Undo();

	/// Whether this command can merge with the next command.
	/// Used for continuous operations (e.g., dragging a slider produces
	/// many small changes that should merge into one undo step).
	bool CanMergeWith(IEditorCommand other);

	/// Merge another command into this one. Called when CanMergeWith returns true.
	/// This command absorbs the other's final state.
	void MergeWith(IEditorCommand other);
}
