using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// The web shell's file dialogs, which CANCEL rather than pretend.
///
/// The browser equivalents are a hidden input type=file for open and an anchor download for
/// save, and both are asynchronous in a way the native ones are not. Until that is wired a
/// caller gets the same answer a dismissed dialog gives, which is a path every caller already
/// handles. Kept as the web shell's own service so that wiring has a home rather than
/// arriving as a new type later.
class WebDialogService : IDialogService
{
	public void ShowOpenFile(delegate void(Span<String>) callback, Span<FileFilter> filters,
		StringView defaultPath, bool allowMultiple, uint32 parentWindowId) => Cancel(callback);

	public void ShowSaveFile(delegate void(Span<String>) callback, Span<FileFilter> filters,
		StringView defaultPath, uint32 parentWindowId) => Cancel(callback);

	public void ShowOpenFolder(delegate void(Span<String>) callback, StringView defaultPath,
		bool allowMultiple, uint32 parentWindowId) => Cancel(callback);

	/// A browser has no OS file manager to hand a path to.
	public void OpenPath(StringView path) {}

	private static void Cancel(delegate void(Span<String>) callback)
	{
		if (callback != null)
			callback(.());
	}
}
