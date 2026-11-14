using System;
using System.Collections;
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
	/// Changed without a step in the history.
	private bool mMarkedDirty = false;
	/// Where its asset's record lived when its file went outside the editor, and its stored type;
	/// null while the asset is there.
	private String mDeletedPath = null ~ delete _;
	private String mDeletedTypeName = null ~ delete _;

	/// The tab title, typically the instance name.
	public abstract StringView Title { get; }

	/// Persists the edited objects back to the source database, clearing dirty on success.
	public abstract Result<void, ErrorCode> Save();

	/// Unsaved: the history has left the point last saved, or the page changed without a step
	/// (MarkDirty).
	public bool IsDirty => mMarkedDirty || !mCommands.IsAtSaved;
	/// The page changed without a step in its history.
	public void MarkDirty() => mMarkedDirty = true;
	/// What the page shows is what its file holds (after a save or a load).
	public void ClearDirty()
	{
		mMarkedDirty = false;
		mCommands.MarkSaved();
	}

	/// Puts the page back to what its file holds (the toolbar's Discard Changes): the history goes
	/// back to the point last saved, or, when it no longer holds that point or the page changed
	/// without a step, the page reads its file again (ReloadFromSource). The history is dropped
	/// after. False, with the edits kept, when neither can be done: the history is locked (a scene
	/// page stops Simulate first), or the page cannot read its file.
	public virtual bool DiscardChanges()
	{
		if (mCommands.IsLocked)
			return false;
		if (mMarkedDirty || !mCommands.ReturnToSaved())
		{
			if (!ReloadFromSource())
				return false;
		}
		mCommands.Clear();
		ClearDirty();
		return true;
	}

	/// Reads the page's file again and shows it, dropping the history. False, with nothing
	/// changed, when the page has no file or it does not read.
	public virtual bool ReloadFromSource() => false;

	public EditorCommandStack Commands => mCommands;

	/// Unsaved work the page holds that is not its asset (a clip its animation panel edits, with a
	/// history and a Save of its own; any panel of its like): each named for the prompts ("The clip
	/// 'Bounce'"), added to `outNames` (the caller's to delete), none when all is saved. The page's
	/// unsaved mark never covers it; closing the page and leaving the editor name each beside the
	/// page's own changes.
	public virtual void ListUnsavedBesides(List<String> outNames) {}
	/// Saves all of that work; what the saves said (the first that failed).
	public virtual Result<void, ErrorCode> SaveBesides() => .Ok;
	/// The page's changes or that work unsaved: what the close and the exit ask about.
	public bool HasUnsavedWork => IsDirty || HasUnsavedBesides;
	/// Whether the page holds unsaved work besides its asset.
	public bool HasUnsavedBesides
	{
		get
		{
			let besides = scope List<String>();
			defer { ClearAndDeleteItems!(besides); }
			ListUnsavedBesides(besides);
			return !besides.IsEmpty;
		}
	}

	/// The asset this page edits changed OUTSIDE the page: an apply to prefab, a re-import.
	/// A page that caches loaded content overrides to refresh itself.
	public virtual void OnAssetExternallyModified() {}

	/// Its asset's file went outside the editor (a pull, another tool) and the source database
	/// let its record go (EditorContext.NotifyAssetDeleted): the page stays open with what it
	/// shows, marked unsaved, and saving it (EditorContext.SavePage) writes the file back. A page
	/// with more to say of it overrides.
	public virtual void OnAssetDeleted() {}

	/// Its asset's file went outside the editor and has not been written back.
	public bool IsAssetDeleted => mDeletedPath != null;
	/// Where its asset's record lived ("group/name") while IsAssetDeleted; empty otherwise.
	public StringView DeletedRecordPath => (mDeletedPath != null) ? (StringView)mDeletedPath : "";
	/// Its asset's stored type while IsAssetDeleted; empty otherwise.
	public StringView DeletedTypeName => (mDeletedTypeName != null) ? (StringView)mDeletedTypeName : "";

	internal void NoteAssetDeleted(StringView recordPath, StringView typeName)
	{
		String.NewOrSet!(mDeletedPath, recordPath);
		String.NewOrSet!(mDeletedTypeName, typeName);
	}

	/// The asset is back (written again, or returned on disk).
	internal void ForgetAssetDeleted()
	{
		DeleteAndNullify!(mDeletedPath);
		DeleteAndNullify!(mDeletedTypeName);
	}

	/// Rebinds the page to a DIFFERENT source instance, Save As: the caller created it and
	/// calls Save next, so the page's current content lands there. A page caching the
	/// asset's name overrides, calling the base, to refresh it.
	public virtual void OnSavedAs(Instance instance)
	{
		mInstanceId = instance.Id;
		ForgetAssetDeleted(); // it edits an asset that is there now
	}

	/// The source database instance this page edits, Empty for an instance less page.
	public Guid InstanceId
	{
		get => mInstanceId;
		set => mInstanceId = value;
	}
}
