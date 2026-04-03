using Win32.Foundation;
using Win32.Graphics.Gdi;
using Win32.UI.Controls;
using System;

namespace Win32.Graphics.Dwm;

#region Constants
public static
{
	public const uint32 DWM_BB_ENABLE = 1;
	public const uint32 DWM_BB_BLURREGION = 2;
	public const uint32 DWM_BB_TRANSITIONONMAXIMIZED = 4;
	public const uint32 DWMWA_COLOR_DEFAULT = 4294967295;
	public const uint32 DWMWA_COLOR_NONE = 4294967294;
	public const uint32 DWM_CLOAKED_APP = 1;
	public const uint32 DWM_CLOAKED_SHELL = 2;
	public const uint32 DWM_CLOAKED_INHERITED = 4;
	public const uint32 DWM_TNP_RECTDESTINATION = 1;
	public const uint32 DWM_TNP_RECTSOURCE = 2;
	public const uint32 DWM_TNP_OPACITY = 4;
	public const uint32 DWM_TNP_VISIBLE = 8;
	public const uint32 DWM_TNP_SOURCECLIENTAREAONLY = 16;
	public const int32 DWM_FRAME_DURATION_DEFAULT = -1;
	public const uint32 DWM_EC_DISABLECOMPOSITION = 0;
	public const uint32 DWM_EC_ENABLECOMPOSITION = 1;
	public const uint32 DWM_SIT_DISPLAYFRAME = 1;
	public const uint32 c_DwmMaxQueuedBuffers = 8;
	public const uint32 c_DwmMaxMonitors = 16;
	public const uint32 c_DwmMaxAdapters = 16;
}
#endregion

#region Enums

[AllowDuplicates]
public enum DWMWINDOWATTRIBUTE : int32
{
	DWMWA_NCRENDERING_ENABLED = 1,
	DWMWA_NCRENDERING_POLICY = 2,
	DWMWA_TRANSITIONS_FORCEDISABLED = 3,
	DWMWA_ALLOW_NCPAINT = 4,
	DWMWA_CAPTION_BUTTON_BOUNDS = 5,
	DWMWA_NONCLIENT_RTL_LAYOUT = 6,
	DWMWA_FORCE_ICONIC_REPRESENTATION = 7,
	DWMWA_FLIP3D_POLICY = 8,
	DWMWA_EXTENDED_FRAME_BOUNDS = 9,
	DWMWA_HAS_ICONIC_BITMAP = 10,
	DWMWA_DISALLOW_PEEK = 11,
	DWMWA_EXCLUDED_FROM_PEEK = 12,
	DWMWA_CLOAK = 13,
	DWMWA_CLOAKED = 14,
	DWMWA_FREEZE_REPRESENTATION = 15,
	DWMWA_PASSIVE_UPDATE_MODE = 16,
	DWMWA_USE_HOSTBACKDROPBRUSH = 17,
	DWMWA_USE_IMMERSIVE_DARK_MODE = 20,
	DWMWA_WINDOW_CORNER_PREFERENCE = 33,
	DWMWA_BORDER_COLOR = 34,
	DWMWA_CAPTION_COLOR = 35,
	DWMWA_TEXT_COLOR = 36,
	DWMWA_VISIBLE_FRAME_BORDER_THICKNESS = 37,
	DWMWA_LAST = 38,
}


[AllowDuplicates]
public enum DWM_WINDOW_CORNER_PREFERENCE : int32
{
	DWMWCP_DEFAULT = 0,
	DWMWCP_DONOTROUND = 1,
	DWMWCP_ROUND = 2,
	DWMWCP_ROUNDSMALL = 3,
}


[AllowDuplicates]
public enum DWMNCRENDERINGPOLICY : int32
{
	DWMNCRP_USEWINDOWSTYLE = 0,
	DWMNCRP_DISABLED = 1,
	DWMNCRP_ENABLED = 2,
	DWMNCRP_LAST = 3,
}


[AllowDuplicates]
public enum DWMFLIP3DWINDOWPOLICY : int32
{
	DWMFLIP3D_DEFAULT = 0,
	DWMFLIP3D_EXCLUDEBELOW = 1,
	DWMFLIP3D_EXCLUDEABOVE = 2,
	DWMFLIP3D_LAST = 3,
}


[AllowDuplicates]
public enum DWM_SOURCE_FRAME_SAMPLING : int32
{
	DWM_SOURCE_FRAME_SAMPLING_POINT = 0,
	DWM_SOURCE_FRAME_SAMPLING_COVERAGE = 1,
	DWM_SOURCE_FRAME_SAMPLING_LAST = 2,
}


[AllowDuplicates]
public enum DWMTRANSITION_OWNEDWINDOW_TARGET : int32
{
	DWMTRANSITION_OWNEDWINDOW_NULL = -1,
	DWMTRANSITION_OWNEDWINDOW_REPOSITION = 0,
}


[AllowDuplicates]
public enum GESTURE_TYPE : int32
{
	GT_PEN_TAP = 0,
	GT_PEN_DOUBLETAP = 1,
	GT_PEN_RIGHTTAP = 2,
	GT_PEN_PRESSANDHOLD = 3,
	GT_PEN_PRESSANDHOLDABORT = 4,
	GT_TOUCH_TAP = 5,
	GT_TOUCH_DOUBLETAP = 6,
	GT_TOUCH_RIGHTTAP = 7,
	GT_TOUCH_PRESSANDHOLD = 8,
	GT_TOUCH_PRESSANDHOLDABORT = 9,
	GT_TOUCH_PRESSANDTAP = 10,
}


[AllowDuplicates]
public enum DWM_SHOWCONTACT : uint32
{
	DWMSC_DOWN = 1,
	DWMSC_UP = 2,
	DWMSC_DRAG = 4,
	DWMSC_HOLD = 8,
	DWMSC_PENBARREL = 16,
	DWMSC_NONE = 0,
	DWMSC_ALL = 4294967295,
}


[AllowDuplicates]
public enum DWM_TAB_WINDOW_REQUIREMENTS : uint32
{
	DWMTWR_NONE = 0,
	DWMTWR_IMPLEMENTED_BY_SYSTEM = 1,
	DWMTWR_WINDOW_RELATIONSHIP = 2,
	DWMTWR_WINDOW_STYLES = 4,
	DWMTWR_WINDOW_REGION = 8,
	DWMTWR_WINDOW_DWM_ATTRIBUTES = 16,
	DWMTWR_WINDOW_MARGINS = 32,
	DWMTWR_TABBING_ENABLED = 64,
	DWMTWR_USER_POLICY = 128,
	DWMTWR_GROUP_POLICY = 256,
	DWMTWR_APP_COMPAT = 512,
}

#endregion


#region Structs
[CRepr, Packed(1)]
public struct DWM_BLURBEHIND
{
	public uint32 dwFlags;
	public BOOL fEnable;
	public HRGN hRgnBlur;
	public BOOL fTransitionOnMaximized;
}

[CRepr, Packed(1)]
public struct DWM_THUMBNAIL_PROPERTIES
{
	public uint32 dwFlags;
	public RECT rcDestination;
	public RECT rcSource;
	public uint8 opacity;
	public BOOL fVisible;
	public BOOL fSourceClientAreaOnly;
}

[CRepr, Packed(1)]
public struct UNSIGNED_RATIO
{
	public uint32 uiNumerator;
	public uint32 uiDenominator;
}

[CRepr, Packed(1)]
public struct DWM_TIMING_INFO
{
	public uint32 cbSize;
	public UNSIGNED_RATIO rateRefresh;
	public uint64 qpcRefreshPeriod;
	public UNSIGNED_RATIO rateCompose;
	public uint64 qpcVBlank;
	public uint64 cRefresh;
	public uint32 cDXRefresh;
	public uint64 qpcCompose;
	public uint64 cFrame;
	public uint32 cDXPresent;
	public uint64 cRefreshFrame;
	public uint64 cFrameSubmitted;
	public uint32 cDXPresentSubmitted;
	public uint64 cFrameConfirmed;
	public uint32 cDXPresentConfirmed;
	public uint64 cRefreshConfirmed;
	public uint32 cDXRefreshConfirmed;
	public uint64 cFramesLate;
	public uint32 cFramesOutstanding;
	public uint64 cFrameDisplayed;
	public uint64 qpcFrameDisplayed;
	public uint64 cRefreshFrameDisplayed;
	public uint64 cFrameComplete;
	public uint64 qpcFrameComplete;
	public uint64 cFramePending;
	public uint64 qpcFramePending;
	public uint64 cFramesDisplayed;
	public uint64 cFramesComplete;
	public uint64 cFramesPending;
	public uint64 cFramesAvailable;
	public uint64 cFramesDropped;
	public uint64 cFramesMissed;
	public uint64 cRefreshNextDisplayed;
	public uint64 cRefreshNextPresented;
	public uint64 cRefreshesDisplayed;
	public uint64 cRefreshesPresented;
	public uint64 cRefreshStarted;
	public uint64 cPixelsReceived;
	public uint64 cPixelsDrawn;
	public uint64 cBuffersEmpty;
}

[CRepr, Packed(1)]
public struct DWM_PRESENT_PARAMETERS
{
	public uint32 cbSize;
	public BOOL fQueue;
	public uint64 cRefreshStart;
	public uint32 cBuffer;
	public BOOL fUseSourceRate;
	public UNSIGNED_RATIO rateSource;
	public uint32 cRefreshesPerFrame;
	public DWM_SOURCE_FRAME_SAMPLING eSampling;
}

[CRepr, Packed(1)]
public struct MilMatrix3x2D
{
	public double S_11;
	public double S_12;
	public double S_21;
	public double S_22;
	public double DX;
	public double DY;
}

#endregion

#region Functions
public static
{
	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DwmDefWindowProc(HWND hWnd, uint32 msg, WPARAM wParam, LPARAM lParam, LRESULT* plResult);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmEnableBlurBehindWindow(HWND hWnd, DWM_BLURBEHIND* pBlurBehind);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmEnableComposition(uint32 uCompositionAction);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmEnableMMCSS(BOOL fEnableMMCSS);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmExtendFrameIntoClientArea(HWND hWnd, MARGINS* pMarInset);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmGetColorizationColor(uint32* pcrColorization, BOOL* pfOpaqueBlend);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmGetCompositionTimingInfo(HWND hwnd, DWM_TIMING_INFO* pTimingInfo);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmGetWindowAttribute(HWND hwnd, DWMWINDOWATTRIBUTE dwAttribute, void* pvAttribute, uint32 cbAttribute);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmIsCompositionEnabled(BOOL* pfEnabled);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmModifyPreviousDxFrameDuration(HWND hwnd, int32 cRefreshes, BOOL fRelative);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmQueryThumbnailSourceSize(int hThumbnail, SIZE* pSize);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmRegisterThumbnail(HWND hwndDestination, HWND hwndSource, int* phThumbnailId);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmSetDxFrameDuration(HWND hwnd, int32 cRefreshes);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmSetPresentParameters(HWND hwnd, DWM_PRESENT_PARAMETERS* pPresentParams);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmSetWindowAttribute(HWND hwnd, DWMWINDOWATTRIBUTE dwAttribute, void* pvAttribute, uint32 cbAttribute);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmUnregisterThumbnail(int hThumbnailId);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmUpdateThumbnailProperties(int hThumbnailId, DWM_THUMBNAIL_PROPERTIES* ptnProperties);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmSetIconicThumbnail(HWND hwnd, HBITMAP hbmp, uint32 dwSITFlags);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmSetIconicLivePreviewBitmap(HWND hwnd, HBITMAP hbmp, POINT* pptClient, uint32 dwSITFlags);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmInvalidateIconicBitmaps(HWND hwnd);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmAttachMilContent(HWND hwnd);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmDetachMilContent(HWND hwnd);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmFlush();

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmGetGraphicsStreamTransformHint(uint32 uIndex, MilMatrix3x2D* pTransform);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmGetGraphicsStreamClient(uint32 uIndex, Guid* pClientUuid);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmGetTransportAttributes(BOOL* pfIsRemoting, BOOL* pfIsConnected, uint32* pDwGeneration);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmTransitionOwnedWindow(HWND hwnd, DWMTRANSITION_OWNEDWINDOW_TARGET target);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmRenderGesture(GESTURE_TYPE gt, uint32 cContacts, uint32* pdwPointerID, POINT* pPoints);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmTetherContact(uint32 dwPointerID, BOOL fEnable, POINT ptTether);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmShowContact(uint32 dwPointerID, DWM_SHOWCONTACT eShowContact);

	[Import("dwmapi.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DwmGetUnmetTabRequirements(HWND appWindow, DWM_TAB_WINDOW_REQUIREMENTS* value);

}
#endregion
