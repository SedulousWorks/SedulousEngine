using System;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The standard per-page action bar: Save, Undo, Redo, Discard Changes, plus a slot for
/// page-specific buttons. Wired to the page's Save, command stack and DiscardChanges;
/// Refresh syncs the enabled states to the page's dirty and undo/redo availability. A page
/// prepends this to its ContentView and calls Refresh each frame.
class PageToolbar : Toolbar
{
	private EditorPage mPage;
	private ToolbarButton mSave;
	private ToolbarButton mUndo;
	private ToolbarButton mRedo;
	private ToolbarButton mDiscard;
	private bool mPageSlotOpen = false;

	public this(EditorPage page)
	{
		mPage = page;
		mSave = AddButton("Save");
		mSave.OnClick.Add(new (b) => { mPage.Save().IgnoreError(); });
		AddSeparator();
		mUndo = AddButton("Undo");
		mUndo.OnClick.Add(new (b) => { mPage.Commands.Undo(); });
		mRedo = AddButton("Redo");
		mRedo.OnClick.Add(new (b) => { mPage.Commands.Redo(); });
		AddSeparator();
		mDiscard = AddButton("Discard Changes");
		mDiscard.OnClick.Add(new (b) => { mPage.DiscardChanges(); });
		Refresh();
	}

	/// A page-specific action to the right of the standard set ("Audition"). Takes ownership
	/// of the delegate.
	public ToolbarButton AddPageButton(StringView label, delegate void() onClick)
	{
		if (!mPageSlotOpen)
		{
			AddSeparator();
			mPageSlotOpen = true;
		}
		let button = AddButton(label);
		button.OnClick.Add(new [=onClick](b) => { if (onClick != null) onClick(); } ~ delete onClick);
		return button;
	}

	/// Syncs the enabled states to the page; cheap, per frame from the page's OnUpdate.
	public void Refresh()
	{
		let dirty = mPage.IsDirty;
		mSave.IsEnabled = dirty;
		mDiscard.IsEnabled = dirty;
		mUndo.IsEnabled = mPage.Commands.CanUndo;
		mRedo.IsEnabled = mPage.Commands.CanRedo;
	}
}
