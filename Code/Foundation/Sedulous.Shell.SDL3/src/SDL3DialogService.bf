using System;
using System.Collections;
using SDL3;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// Native file and folder dialogs.
///
/// ASYNC: every Show returns at once and SDL calls back later, during the shell's event
/// pump. So a caller must not block waiting for a result, and the callback runs on the main
/// thread like everything else the pump delivers.
class SDL3DialogService : IDialogService
{
	private SDL3WindowManager mWindows;
	/// The pending calls, kept alive until SDL is done with them. A dialog outlives the
	/// call that opened it, so neither the callback nor the filter array can be scoped to
	/// that call.
	private List<PendingDialog> mPending = new .() ~ DeleteContainerAndItems!(_);

	public this(SDL3WindowManager windows)
	{
		mWindows = windows;
	}

	public void ShowOpenFile(delegate void(Span<String>) callback, Span<FileFilter> filters,
		StringView defaultPath, bool allowMultiple, uint32 parentWindowId)
	{
		let pending = Begin(callback, filters, defaultPath);
		SDL3.SDL_ShowOpenFileDialog(=> Trampoline, Internal.UnsafeCastToPtr(pending),
			ParentHandle(parentWindowId), pending.SdlFilters, (int32)pending.FilterCount,
			pending.DefaultPathOrNull, allowMultiple);
	}

	public void ShowSaveFile(delegate void(Span<String>) callback, Span<FileFilter> filters,
		StringView defaultPath, uint32 parentWindowId)
	{
		let pending = Begin(callback, filters, defaultPath);
		SDL3.SDL_ShowSaveFileDialog(=> Trampoline, Internal.UnsafeCastToPtr(pending),
			ParentHandle(parentWindowId), pending.SdlFilters, (int32)pending.FilterCount,
			pending.DefaultPathOrNull);
	}

	public void ShowOpenFolder(delegate void(Span<String>) callback, StringView defaultPath,
		bool allowMultiple, uint32 parentWindowId)
	{
		let pending = Begin(callback, .(), defaultPath);
		SDL3.SDL_ShowOpenFolderDialog(=> Trampoline, Internal.UnsafeCastToPtr(pending),
			ParentHandle(parentWindowId), pending.DefaultPathOrNull, allowMultiple);
	}

	/// Hands a path to whatever the desktop opens it with.
	public void OpenPath(StringView path)
	{
		let owned = scope String(path);
		SDL3.SDL_OpenURL(owned);
	}

	private PendingDialog Begin(delegate void(Span<String>) callback, Span<FileFilter> filters,
		StringView defaultPath)
	{
		let pending = new PendingDialog(this, callback, filters, defaultPath);
		mPending.Add(pending);
		return pending;
	}

	/// Called from the pending dialog once SDL is done with it.
	internal void Retire(PendingDialog pending)
	{
		mPending.Remove(pending);
		delete pending;
	}

	private SDL_Window* ParentHandle(uint32 id)
	{
		if (id == 0)
			return null;
		let window = mWindows.Find(id);
		return (window != null) ? window.Handle : null;
	}

	/// SDL hands back a null terminated list of paths, or null when the user cancelled.
	/// Cancelling still calls back, with nothing, so a caller can re-enable its UI.
	private static void Trampoline(void* userData, char8** fileList, int32 filter)
	{
		let pending = (PendingDialog)Internal.UnsafeCastToObject(userData);
		let paths = scope List<String>();
		defer { ClearAndDeleteItems!(paths); }

		if (fileList != null)
		{
			var cursor = fileList;
			while (*cursor != null)
			{
				paths.Add(new String(StringView(*cursor)));
				cursor++;
			}
		}

		pending.Complete(paths);
	}
}
