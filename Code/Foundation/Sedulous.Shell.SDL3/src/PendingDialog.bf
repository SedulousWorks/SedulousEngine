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

	/// Runs the callback and retires: SDL is finished with this dialog either way, whether
	/// the user chose something or cancelled.
	public void Complete(List<String> paths)
	{
		if (mCallback != null)
			mCallback(.(paths.Ptr, paths.Count));
		mOwner.[Friend]Retire(this);
	}
}
