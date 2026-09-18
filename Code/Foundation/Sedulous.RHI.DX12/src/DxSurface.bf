#if BF_PLATFORM_WINDOWS
using Sedulous.RHI;
using Win32.Foundation;

namespace Sedulous.RHI.DX12;

/// A window to present to, which on this backend is just its HWND.
///
/// Nothing is created here. DXGI takes the window handle at swap chain creation, so unlike
/// Vulkan there is no surface object to own or destroy.
class DxSurface : ISurface
{
	private HWND mHwnd;

	public this(HWND hwnd) => mHwnd = hwnd;

	public HWND Handle => mHwnd;
}

#endif // BF_PLATFORM_WINDOWS
