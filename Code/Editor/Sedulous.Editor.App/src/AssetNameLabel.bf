using System;
using Sedulous.Content;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The name element of every browser row, tile and tree node: an EditableLabel that knows
/// what it names, so one commit handler routes to the instance or the group rename. A slow
/// click, F2 or the menu's Rename edit in place; a double-click is deliberately not an edit
/// trigger since it navigates; single clicks pass through to the list's selection.
class AssetNameLabel : EditableLabel
{
	private Guid mId = .Empty;
	/// Borrowed.
	private Group mGroup = null;

	public void BindTarget(Guid id, Group group)
	{
		mId = id;
		mGroup = group;
	}

	public Guid TargetId => mId;
	public Group TargetGroup => mGroup;

	/// The shared setup: names are file and directory names, so filesystem-hostile
	/// characters never commit; a double-click stays navigation. Takes ownership of the
	/// commit delegate.
	public void Configure(delegate void(AssetNameLabel label, StringView newName) onCommit)
	{
		DoubleClickToEdit.Value = false;
		ValidateRename = new (name) =>
			{
				for (let c in name)
				{
					if ((c == '/') || (c == '\\') || (c == ':') || (c == '*') || (c == '?') ||
						(c == '"') || (c == '<') || (c == '>') || (c == '|'))
						return false;
				}
				return true;
			};
		OnRenameCommitted.Add(new [=onCommit, =this](label, newName) => { onCommit(this, newName); } ~ delete onCommit);
	}
}
