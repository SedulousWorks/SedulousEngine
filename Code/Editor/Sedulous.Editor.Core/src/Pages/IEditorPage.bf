namespace Sedulous.Editor.Core;

using System;
using Sedulous.UI;

/// Base interface for all editor pages (scene editors, asset editors, etc.).
/// Pages appear as tabs in the editor. Each has its own undo stack and dirty state.
interface IEditorPage : IDisposable
{
	/// Unique ID for this page instance.
	StringView PageId { get; }

	/// Tab title. Append "*" when dirty.
	StringView Title { get; }

	/// File path being edited (empty for unsaved).
	StringView FilePath { get; }

	/// Root view for the page's content.
	View ContentView { get; }

	/// Whether the page has unsaved changes.
	bool IsDirty { get; }

	/// Per-page undo/redo stack.
	EditorCommandStack CommandStack { get; }

	/// Save to the current file path.
	void Save();

	/// Save to a new path.
	void SaveAs(StringView path);

	/// Called when this page's tab becomes active.
	void OnActivated();

	/// Called when a different tab becomes active.
	void OnDeactivated();

	/// Called each frame while this page is active.
	void Update(float deltaTime);
}
