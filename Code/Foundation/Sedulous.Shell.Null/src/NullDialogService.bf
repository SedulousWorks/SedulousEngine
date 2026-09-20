using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Shell.Null;

/// Dialogs that cancel immediately.
///
/// The callback still fires, with nothing, so a caller drives the whole dialog path
/// headless without a backend check. Not firing at all would leave that caller waiting for
/// a result it will never get, which is a far worse headless failure than a cancel.
class NullDialogService : IDialogService
{
	public void ShowOpenFile(delegate void(Span<String>) callback, Span<FileFilter> filters,
		StringView defaultPath, bool allowMultiple, uint32 parentWindowId) => Cancel(callback);

	public void ShowSaveFile(delegate void(Span<String>) callback, Span<FileFilter> filters,
		StringView defaultPath, uint32 parentWindowId) => Cancel(callback);

	public void ShowOpenFolder(delegate void(Span<String>) callback, StringView defaultPath,
		bool allowMultiple, uint32 parentWindowId) => Cancel(callback);

	/// Nothing to open a path with.
	public void OpenPath(StringView path) {}

	/// CONSUMES the callback, as the SDL service does once its dialog closes.
	private static void Cancel(delegate void(Span<String>) callback)
	{
		if (callback != null)
			callback(.());
		delete callback;
	}
}
