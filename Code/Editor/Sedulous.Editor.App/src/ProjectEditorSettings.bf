using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// Per-project editor-state persistence, unified on the structured settings store: one
/// file, <project>/Editor/editor.project.settings.xml, holding typed, versioned sections:
/// the dock tree, the favourites, the open pages, the asset browser view mode. Other
/// modules add their own sections to the same store through
/// EditorContext.ProjectEditorSettings; their types must be registered before the app
/// loads it.
static class ProjectEditorSettings
{
	/// The one per-project editor-state file, hand-editable XML like every settings store.
	public const String cFileName = "editor.project.settings.xml";

	// ---- store to and from live state ------------------------------------------------------

	/// Snapshots the dock's current layout into the store. NotFound when the dock tree is
	/// empty.
	public static Result<void, ErrorCode> CaptureDockLayout(DockManager dock, Settings store)
	{
		let layout = dock.ExportLayout();
		if (layout == null)
			return .Err(.NotFound);
		let section = store.Section<EditorDockLayoutSettings>();
		delete section.Root;
		section.Root = layout;
		store.MarkChanged<EditorDockLayoutSettings>();
		return .Ok;
	}

	/// Rebuilds the dock from the store's snapshot, panels matched by PersistenceId.
	/// NotFound when no snapshot was ever captured; the caller keeps its default layout.
	public static Result<void, ErrorCode> ApplyDockLayout(DockManager dock, Settings store)
	{
		let section = store.Find<EditorDockLayoutSettings>();
		if ((section == null) || (section.Root == null))
			return .Err(.NotFound);
		dock.ApplyLayout(section.Root);
		return .Ok;
	}

	public static void CaptureFavorites(EditorContext context, Settings store)
	{
		let section = store.Section<EditorFavoritesSettings>();
		section.Favorites.Clear();
		section.Favorites.AddRange(context.Favorites);
		store.MarkChanged<EditorFavoritesSettings>();
	}

	public static void ApplyFavorites(EditorContext context, Settings store)
	{
		if (let section = store.Find<EditorFavoritesSettings>())
			context.SetFavorites(section.Favorites);
	}

	public static void CaptureOpenPages(Settings store, Span<Guid> pages, Guid activePage)
	{
		let section = store.Section<EditorOpenPagesSettings>();
		section.Pages.Clear();
		section.Pages.AddRange(pages);
		section.Active = activePage;
		store.MarkChanged<EditorOpenPagesSettings>();
	}

	/// NotFound when no page set was ever saved: a first launch, the caller opens the
	/// default document.
	public static Result<void, ErrorCode> ApplyOpenPages(Settings store, List<Guid> outPages, out Guid outActivePage)
	{
		outActivePage = .Empty;
		let section = store.Find<EditorOpenPagesSettings>();
		if (section == null)
			return .Err(.NotFound);
		outPages.Clear();
		outPages.AddRange(section.Pages);
		outActivePage = section.Active;
		return .Ok;
	}

	// ---- file I/O --------------------------------------------------------------------------

	/// Loads the per-project store from <directory>/editor.project.settings.xml. NotFound
	/// when absent (a fresh project): the store stays empty and every section reads as its
	/// defaults. Section types must be registered first.
	public static Result<void, ErrorCode> Load(Settings store, StringView directory)
	{
		let root = scope NativeFileSystem(directory);
		return EditorSettingsStore.Load(root, store, cFileName);
	}

	/// Persists the per-project store.
	public static Result<void, ErrorCode> Save(Settings store, StringView directory)
	{
		let root = scope NativeFileSystem(directory);
		return EditorSettingsStore.Save(root, store, cFileName);
	}
}
