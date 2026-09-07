using System;
using System.Collections;

namespace Sedulous.Shell;

/// Native file and folder dialogs.
///
/// Every Show returns IMMEDIATELY and calls back later, exactly once, on the main thread
/// during the event pump. That is why these carry a callback where the rest of the shell
/// is pull based: a native dialog runs its own loop and there is no frame to poll it on.
///
/// A headless backend calls back at once with nothing, which reads as a cancel, so a
/// caller never has to check whether dialogs exist.
interface IDialogService
{
	/// Shows an open dialog. The paths handed to the callback are valid FOR THE DURATION
	/// of the call; copy any that must outlive it. Empty means cancelled or failed.
	void ShowOpenFile(delegate void(Span<String>) callback, Span<FileFilter> filters,
		StringView defaultPath, bool allowMultiple, uint32 parentWindowId);

	void ShowSaveFile(delegate void(Span<String>) callback, Span<FileFilter> filters,
		StringView defaultPath, uint32 parentWindowId);

	void ShowOpenFolder(delegate void(Span<String>) callback, StringView defaultPath,
		bool allowMultiple, uint32 parentWindowId);

	/// Opens a path with the OS default handler: a folder in the file manager, a file in
	/// its associated application. Fire and forget, and a no-op when headless.
	void OpenPath(StringView path);
}
