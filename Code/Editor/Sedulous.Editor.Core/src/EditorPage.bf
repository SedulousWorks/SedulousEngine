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
	protected bool mDirty = false;
	/// Where its asset's record lived when its file went outside the editor, and its stored type;
	/// null while the asset is there.
	private String mDeletedPath = null ~ delete _;
	private String mDeletedTypeName = null ~ delete _;

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

	/// The page's content as it stands, unsaved edits and all, into `outBytes`, never into its
	/// asset: what a relaunch keeps aside so the next editor reopens the page unsaved (TakeBack).
	/// NotSupported (the default) for a page that cannot; its unsaved work is then asked about or
	/// refused as any other.
	public virtual Result<void, ErrorCode> KeepAside(List<uint8> outBytes) => .Err(.NotSupported);
	/// What KeepAside wrote, shown as the page's content and marked unsaved, its history let go.
	/// NotSupported (the default), or another error when it did not read: the page then shows its
	/// asset as it is saved.
	public virtual Result<void, ErrorCode> TakeBack(Span<uint8> bytes) => .Err(.NotSupported);
	/// Writes what the page keeps of its view (a scene's camera, selection and panes) into the
	/// project's editor settings now, as it does when it closes: a relaunch saves it before the
	/// next editor reads it. Nothing by default.
	public virtual void CaptureViewState() {}

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
