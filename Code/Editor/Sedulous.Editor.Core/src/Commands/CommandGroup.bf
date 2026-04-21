namespace Sedulous.Editor.Core;

using System;
using System.Collections;

/// Groups multiple commands into a single atomic undo/redo step.
/// Created by EditorCommandStack.BeginGroup/EndGroup.
class CommandGroup : IEditorCommand
{
	private String mDescription = new .() ~ delete _;
	private List<IEditorCommand> mCommands = new .() ~ ClearAndDeleteItems!(_);

	public this(StringView description)
	{
		mDescription.Set(description);
	}

	public StringView Description => mDescription;

	public bool IsEmpty => mCommands.Count == 0;

	/// Add a command to the group (called during BeginGroup..EndGroup).
	public void Add(IEditorCommand command)
	{
		mCommands.Add(command);
	}

	public void Execute()
	{
		for (let cmd in mCommands)
			cmd.Execute();
	}

	public void Undo()
	{
		for (int i = mCommands.Count - 1; i >= 0; i--)
			mCommands[i].Undo();
	}

	public bool CanMergeWith(IEditorCommand other) => false;
	public void MergeWith(IEditorCommand other) { }

	public void Dispose()
	{
	}
}
