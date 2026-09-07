using System;
using Sedulous.Core;

namespace Sedulous.RHI;

/// One graphics API's entry point: it enumerates adapters and makes surfaces.
interface IBackend
{
	bool IsInitialized { get; }

	/// Every adapter, MOST PREFERRED FIRST: discrete, then integrated, then unknown, then
	/// CPU. Backends guarantee the order through AdapterSelection.SortByPreference, so a
	/// caller that just wants the best GPU takes element zero.
	Span<IAdapter> EnumerateAdapters();

	/// A presentable surface from a native window.
	///
	/// `platform` says which windowing system produced the handles so the backend picks the
	/// matching surface type instead of guessing; Unknown asks it to guess. On Win32 the
	/// window handle is an HWND and the display handle is null; on X11 they are the XID and
	/// the Display; on Wayland they are the wl_surface and the wl_display.
	Result<ISurface> CreateSurface(void* windowHandle, void* displayHandle,
		SurfacePlatform platform = .Unknown);

	/// For the platforms where one handle is enough.
	Result<ISurface> CreateSurface(void* windowHandle)
		=> CreateSurface(windowHandle, null, .Unknown);

	/// Tears down the backend and everything it owns.
	void Destroy();
}
