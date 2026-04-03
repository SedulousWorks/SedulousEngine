namespace Sedulous.RHI.DX12;

using Win32.Foundation;
using Sedulous.RHI;

/// DX12 implementation of ISurface. Simply stores the HWND.
class DX12Surface : ISurface
{
	private HWND mHwnd;

	public this(HWND hwnd)
	{
		mHwnd = hwnd;
	}

	public HWND Handle => mHwnd;
}
