using System;
using Sedulous.Core;
using Sedulous.Content;

namespace Sedulous.Editor.Core;

/// One open document: a dock tab with its OWN command stack, the per page undo Sedulous
/// and Traktor both settled on, dirty tracking, and Save. This is the HEADLESS half;
/// concrete pages live in the UI modules and add their widget tree on top.
///
/// Pages come from an IEditorPageFactory, dispatched by the instance's primary object type
/// with nearest type matching along the base chain, through EditorPageRegistry.
abstract class EditorPage
{
	protected EditorCommandStack mCommands = new .() ~ delete _;
	protected Guid mInstanceId = .Empty;
	protected bool mDirty = false;

	public this()
	{
		mCommands.OnChanged = new () => { mDirty = true; };
	}

	/// The tab title, typically the instance name.
	public abstract StringView Title { get; }

	/// Persists the edited objects back to the source database, clearing dirty on success.
	public abstract Result<void, ErrorCode> Save();

	public bool IsDirty => mDirty;
	public void MarkDirty() => mDirty = true;
	public void ClearDirty() => mDirty = false;

	/// Reverts every unsaved edit to the last saved state, the toolbar's Discard Changes.
	/// The default undoes the whole command stack then clears it and the flag, right for a
	/// page that routes every edit through commands; a page that caches loaded content
	/// overrides to reload from the source database.
	public virtual void DiscardChanges()
	{
		while (mCommands.CanUndo)
			mCommands.Undo();
		mCommands.Clear();
		ClearDirty();
	}

	public EditorCommandStack Commands => mCommands;

	/// The asset this page edits changed OUTSIDE the page: an apply to prefab, a re-import.
	/// A page that caches loaded content overrides to refresh itself.
	public virtual void OnAssetExternallyModified() {}

	/// Rebinds the page to a DIFFERENT source instance, Save As: the caller created it and
	/// calls Save next, so the page's current content lands there. A page caching the
	/// asset's name overrides, calling the base, to refresh it.
	public virtual void OnSavedAs(Instance instance)
	{
		mInstanceId = instance.Id;
	}

	/// The source database instance this page edits, Empty for an instance less page.
	public Guid InstanceId
	{
		get => mInstanceId;
		set => mInstanceId = value;
	}
}
