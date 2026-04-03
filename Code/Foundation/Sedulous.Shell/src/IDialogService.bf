namespace Sedulous.Shell;

using System;

/// Callback for file/folder dialog results.
/// @param paths Array of selected paths, or null if cancelled/error.
public delegate void DialogResultCallback(Span<StringView> paths);

/// Service for showing native file and folder dialogs.
public interface IDialogService
{
	/// Shows a folder selection dialog.
	/// @param callback Called with the selected folder path, or empty if cancelled.
	/// @param defaultPath Initial directory to show (optional).
	/// @param window Window to be modal for (optional).
	void ShowFolderDialog(DialogResultCallback callback, StringView defaultPath = default, IWindow window = null);

	/// Shows a file open dialog.
	/// @param callback Called with selected file paths, or empty if cancelled.
	/// @param filters File type filters (e.g., "Images|png;jpg;gif").
	/// @param defaultPath Initial directory or file to show (optional).
	/// @param allowMultiple Allow selecting multiple files.
	/// @param window Window to be modal for (optional).
	void ShowOpenFileDialog(DialogResultCallback callback, Span<StringView> filters = default, StringView defaultPath = default, bool allowMultiple = false, IWindow window = null);

	/// Shows a file save dialog.
	/// @param callback Called with the selected file path, or empty if cancelled.
	/// @param filters File type filters.
	/// @param defaultPath Initial directory or file to show (optional).
	/// @param window Window to be modal for (optional).
	void ShowSaveFileDialog(DialogResultCallback callback, Span<StringView> filters = default, StringView defaultPath = default, IWindow window = null);
}
