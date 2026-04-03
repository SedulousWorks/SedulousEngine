using Win32.Foundation;
using Win32.Graphics.Gdi;
using System;

namespace Win32.UI.Magnification;

#region Constants
public static
{
	public const String WC_MAGNIFIERA = "Magnifier";
	public const String WC_MAGNIFIERW = "Magnifier";
	public const String WC_MAGNIFIER = "Magnifier";
	public const int32 MS_SHOWMAGNIFIEDCURSOR = 1;
	public const int32 MS_CLIPAROUNDCURSOR = 2;
	public const int32 MS_INVERTCOLORS = 4;
}
#endregion

#region Enums

[AllowDuplicates]
public enum MW_FILTERMODE : uint32
{
	MW_FILTERMODE_EXCLUDE = 0,
	MW_FILTERMODE_INCLUDE = 1,
}

#endregion

#region Function Pointers
public function BOOL MagImageScalingCallback(HWND hwnd, void* srcdata, MAGIMAGEHEADER srcheader, void* destdata, MAGIMAGEHEADER destheader, RECT unclipped, RECT clipped, HRGN dirty);

#endregion

#region Structs
[CRepr]
public struct MAGTRANSFORM
{
	public float[9] v;
}

[CRepr]
public struct MAGIMAGEHEADER
{
	public uint32 width;
	public uint32 height;
	public Guid format;
	public uint32 stride;
	public uint32 offset;
	public uint cbSize;
}

[CRepr]
public struct MAGCOLOREFFECT
{
	public float[25] transform;
}

#endregion

#region Functions
public static
{
	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagInitialize();

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagUninitialize();

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagSetWindowSource(HWND hwnd, RECT rect);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagGetWindowSource(HWND hwnd, RECT* pRect);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagSetWindowTransform(HWND hwnd, MAGTRANSFORM* pTransform);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagGetWindowTransform(HWND hwnd, MAGTRANSFORM* pTransform);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagSetWindowFilterList(HWND hwnd, MW_FILTERMODE dwFilterMode, int32 count, HWND* pHWND);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 MagGetWindowFilterList(HWND hwnd, MW_FILTERMODE* pdwFilterMode, int32 count, HWND* pHWND);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagSetImageScalingCallback(HWND hwnd, MagImageScalingCallback callback);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern MagImageScalingCallback MagGetImageScalingCallback(HWND hwnd);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagSetColorEffect(HWND hwnd, MAGCOLOREFFECT* pEffect);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagGetColorEffect(HWND hwnd, MAGCOLOREFFECT* pEffect);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagSetFullscreenTransform(float magLevel, int32 xOffset, int32 yOffset);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagGetFullscreenTransform(float* pMagLevel, int32* pxOffset, int32* pyOffset);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagSetFullscreenColorEffect(MAGCOLOREFFECT* pEffect);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagGetFullscreenColorEffect(MAGCOLOREFFECT* pEffect);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagSetInputTransform(BOOL fEnabled, RECT* pRectSource, RECT* pRectDest);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagGetInputTransform(BOOL* pfEnabled, RECT* pRectSource, RECT* pRectDest);

	[Import("MAGNIFICATION.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MagShowSystemCursor(BOOL fShowCursor);

}
#endregion
