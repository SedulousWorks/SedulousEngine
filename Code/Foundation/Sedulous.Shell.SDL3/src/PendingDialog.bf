using System;
using System.Collections;
using SDL3;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// One dialog SDL has been asked to show, and everything it must outlive the call for.
///
/// A dialog is asynchronous, so the callback, the filter strings and the default path all
/// have to survive past the Show that started it. This owns them and frees them once SDL
/// has called back.
class PendingDialog
{
	private SDL3DialogService mOwner;
	private delegate void(Span<String>) mCallback ~ delete _;
	private List<String> mStrings = new .() ~ DeleteContainerAndItems!(_);
	private SDL_DialogFileFilter* mFilters ~ delete _;
	private int mFilterCount;
	private String mDefaultPath = new .() ~ delete _;
	/// The result, carried to the main thread.
	private List<String> mPaths = new .() ~ DeleteContainerAndItems!(_);

	public this(SDL3DialogService owner, delegate void(Span<String>) callback,
		Span<FileFilter> filters, StringView defaultPath)
	{
		mOwner = owner;
		mCallback = callback;
		mDefaultPath.Set(defaultPath);

		mFilterCount = filters.Length;
		if (mFilterCount > 0)
		{
			// SDL keeps the pointers rather than copying, so the strings live here for as
			// long as the dialog does.
			mFilters = new SDL_DialogFileFilter[mFilterCount]*;
			for (int i < mFilterCount)
			{
				let name = new String(filters[i].Name);
				let pattern = new String(filters[i].Pattern);
				mStrings.Add(name);
				mStrings.Add(pattern);
				mFilters[i] = .() { name = name.CStr(), pattern = pattern.CStr() };
			}
		}
	}

	public SDL_DialogFileFilter* SdlFilters => mFilters;
	public int FilterCount => mFilterCount;

	/// Null rather than an empty string, which is how SDL spells "no preference".
	public char8* DefaultPathOrNull => mDefaultPath.IsEmpty ? null : mDefaultPath.CStr();

	/// What the user chose; empty when they cancelled. Filled where SDL calls back.
	public List<String> Paths => mPaths;

	/// Runs the callback and retires, on the main thread: SDL is finished with this dialog
	/// either way, whether the user chose something or cancelled.
	public void Complete()
	{
		if (mCallback != null)
			mCallback(.(mPaths.Ptr, mPaths.Count));
		mOwner.[Friend]Retire(this);
	}
}
