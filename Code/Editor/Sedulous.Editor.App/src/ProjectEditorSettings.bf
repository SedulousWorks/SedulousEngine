using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// Per-project editor-state persistence, unified on the structured settings store: one
/// file, <project>/Editor/editor.project.settings.xml, holding typed, versioned sections:
/// the dock's layout, the favourites, the open pages, the asset browser view mode. Other
/// modules add their own sections to the same store through
/// EditorContext.ProjectEditorSettings; their types must be registered before the app
/// loads it.
static class ProjectEditorSettings
{
	/// The one per-project editor-state file, hand-editable XML like every settings store.
	public const String cFileName = "editor.project.settings.xml";

	// ---- store to and from live state ------------------------------------------------------

	/// The dock's layout into the store, a copy: the dock goes on changing without it.
	public static void CaptureDockLayout(DockController dock, Settings store)
	{
		let section = store.Section<EditorDockLayoutSettings>();
		section.Document.Layout.Set(dock.Layout);
		section.Captured = true;
		store.MarkChanged<EditorDockLayoutSettings>();
	}

	/// The store's layout into the dock: its registered panels placed where the layout says,
	/// the rest at their defaults. NotFound when none was captured (the caller keeps its default
	/// layout); InvalidArgument when the dock refuses it (a layout that breaks the dock's rules,
	/// a file edited by hand), said in the log, the dock as it was.
	public static Result<void, ErrorCode> ApplyDockLayout(DockController dock, Settings store)
	{
		let section = store.Find<EditorDockLayoutSettings>();
		if ((section == null) || !section.Captured)
			return .Err(.NotFound);
		let outcome = dock.Adopt(section.Document.Layout);
		if (!outcome.Ok)
		{
			GlobalLog(.Warning, "Editor: the saved dock layout was refused ({}); the default stands", outcome.Refused);
			return .Err(.InvalidArgument);
		}
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
