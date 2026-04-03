using Win32.Foundation;
using Win32.System.Com;
using Win32.System.Registry;
using Win32.System.Com.StructuredStorage;
using Win32.System.Ole;
using System;

namespace Win32.UI.LegacyWindowsEnvironmentFeatures;

#region Constants
public static
{
	public const uint32 EVCCBF_LASTNOTIFICATION = 1;
	public const uint32 STATEBITS_FLAT = 1;
	public const HRESULT REC_S_IDIDTHEUPDATES = 266240;
	public const HRESULT REC_S_NOTCOMPLETE = 266241;
	public const HRESULT REC_S_NOTCOMPLETEBUTPROPAGATE = 266242;
	public const HRESULT REC_E_ABORTED = -2147217408;
	public const HRESULT REC_E_NOCALLBACK = -2147217407;
	public const HRESULT REC_E_NORESIDUES = -2147217406;
	public const HRESULT REC_E_TOODIFFERENT = -2147217405;
	public const HRESULT REC_E_INEEDTODOTHEUPDATES = -2147217404;
}
#endregion

#region Enums

[AllowDuplicates]
public enum EMPTY_VOLUME_CACHE_FLAGS : uint32
{
	EVCF_HASSETTINGS = 1,
	EVCF_ENABLEBYDEFAULT = 2,
	EVCF_REMOVEFROMLIST = 4,
	EVCF_ENABLEBYDEFAULT_AUTO = 8,
	EVCF_DONTSHOWIFZERO = 16,
	EVCF_SETTINGSMODE = 32,
	EVCF_OUTOFDISKSPACE = 64,
	EVCF_USERCONSENTOBTAINED = 128,
	EVCF_SYSTEMAUTORUN = 256,
}


[AllowDuplicates]
public enum RECONCILEF : int32
{
	RECONCILEF_MAYBOTHERUSER = 1,
	RECONCILEF_FEEDBACKWINDOWVALID = 2,
	RECONCILEF_NORESIDUESOK = 4,
	RECONCILEF_OMITSELFRESIDUE = 8,
	RECONCILEF_RESUMERECONCILIATION = 16,
	RECONCILEF_YOUMAYDOTHEUPDATES = 32,
	RECONCILEF_ONLYYOUWERECHANGED = 64,
	ALL_RECONCILE_FLAGS = 127,
}

#endregion


#region COM Types
[CRepr]struct IEmptyVolumeCacheCallBack : IUnknown
{
	public new const Guid IID = .(0x6e793361, 0x73c6, 0x11d0, 0x84, 0x69, 0x00, 0xaa, 0x00, 0x44, 0x29, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 dwlSpaceUsed, uint32 dwFlags, PWSTR pcwszStatus) ScanProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 dwlSpaceFreed, uint64 dwlSpaceToFree, uint32 dwFlags, PWSTR pcwszStatus) PurgeProgress;
	}


	public HRESULT ScanProgress(uint64 dwlSpaceUsed, uint32 dwFlags, PWSTR pcwszStatus) mut => VT.[Friend]ScanProgress(&this, dwlSpaceUsed, dwFlags, pcwszStatus);

	public HRESULT PurgeProgress(uint64 dwlSpaceFreed, uint64 dwlSpaceToFree, uint32 dwFlags, PWSTR pcwszStatus) mut => VT.[Friend]PurgeProgress(&this, dwlSpaceFreed, dwlSpaceToFree, dwFlags, pcwszStatus);
}

[CRepr]struct IEmptyVolumeCache : IUnknown
{
	public new const Guid IID = .(0x8fce5227, 0x04da, 0x11d1, 0xa0, 0x04, 0x00, 0x80, 0x5f, 0x8a, 0xbe, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HKEY hkRegKey, PWSTR pcwszVolume, PWSTR* ppwszDisplayName, PWSTR* ppwszDescription, EMPTY_VOLUME_CACHE_FLAGS* pdwFlags) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pdwlSpaceUsed, IEmptyVolumeCacheCallBack* picb) GetSpaceUsed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 dwlSpaceToFree, IEmptyVolumeCacheCallBack* picb) Purge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd) ShowProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EMPTY_VOLUME_CACHE_FLAGS* pdwFlags) Deactivate;
	}


	public HRESULT Initialize(HKEY hkRegKey, PWSTR pcwszVolume, PWSTR* ppwszDisplayName, PWSTR* ppwszDescription, EMPTY_VOLUME_CACHE_FLAGS* pdwFlags) mut => VT.[Friend]Initialize(&this, hkRegKey, pcwszVolume, ppwszDisplayName, ppwszDescription, pdwFlags);

	public HRESULT GetSpaceUsed(uint64* pdwlSpaceUsed, IEmptyVolumeCacheCallBack* picb) mut => VT.[Friend]GetSpaceUsed(&this, pdwlSpaceUsed, picb);

	public HRESULT Purge(uint64 dwlSpaceToFree, IEmptyVolumeCacheCallBack* picb) mut => VT.[Friend]Purge(&this, dwlSpaceToFree, picb);

	public HRESULT ShowProperties(HWND hwnd) mut => VT.[Friend]ShowProperties(&this, hwnd);

	public HRESULT Deactivate(EMPTY_VOLUME_CACHE_FLAGS* pdwFlags) mut => VT.[Friend]Deactivate(&this, pdwFlags);
}

[CRepr]struct IEmptyVolumeCache2 : IEmptyVolumeCache
{
	public new const Guid IID = .(0x02b7e3ba, 0x4db3, 0x11d2, 0xb2, 0xd9, 0x00, 0xc0, 0x4f, 0x8e, 0xec, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IEmptyVolumeCache.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HKEY hkRegKey, PWSTR pcwszVolume, PWSTR pcwszKeyName, PWSTR* ppwszDisplayName, PWSTR* ppwszDescription, PWSTR* ppwszBtnText, EMPTY_VOLUME_CACHE_FLAGS* pdwFlags) InitializeEx;
	}


	public HRESULT InitializeEx(HKEY hkRegKey, PWSTR pcwszVolume, PWSTR pcwszKeyName, PWSTR* ppwszDisplayName, PWSTR* ppwszDescription, PWSTR* ppwszBtnText, EMPTY_VOLUME_CACHE_FLAGS* pdwFlags) mut => VT.[Friend]InitializeEx(&this, hkRegKey, pcwszVolume, pcwszKeyName, ppwszDisplayName, ppwszDescription, ppwszBtnText, pdwFlags);
}

[CRepr]struct IReconcileInitiator : IUnknown
{
	public new const Guid IID = .(0x99180161, 0xda16, 0x101a, 0x93, 0x5c, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkForAbort) SetAbortCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulProgress, uint32 ulProgressMax) SetProgressFeedback;
	}


	public HRESULT SetAbortCallback(IUnknown* punkForAbort) mut => VT.[Friend]SetAbortCallback(&this, punkForAbort);

	public HRESULT SetProgressFeedback(uint32 ulProgress, uint32 ulProgressMax) mut => VT.[Friend]SetProgressFeedback(&this, ulProgress, ulProgressMax);
}

[CRepr]struct IReconcilableObject : IUnknown
{
	public new const Guid IID = .(0x99180162, 0xda16, 0x101a, 0x93, 0x5c, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IReconcileInitiator* pInitiator, uint32 dwFlags, HWND hwndOwner, HWND hwndProgressFeedback, uint32 ulcInput, IMoniker** rgpmkOtherInput, int32* plOutIndex, IStorage* pstgNewResidues, void* pvReserved) Reconcile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulProgressMax) GetProgressFeedbackMaxEstimate;
	}


	public HRESULT Reconcile(IReconcileInitiator* pInitiator, uint32 dwFlags, HWND hwndOwner, HWND hwndProgressFeedback, uint32 ulcInput, IMoniker** rgpmkOtherInput, int32* plOutIndex, IStorage* pstgNewResidues, void* pvReserved) mut => VT.[Friend]Reconcile(&this, pInitiator, dwFlags, hwndOwner, hwndProgressFeedback, ulcInput, rgpmkOtherInput, plOutIndex, pstgNewResidues, pvReserved);

	public HRESULT GetProgressFeedbackMaxEstimate(uint32* pulProgressMax) mut => VT.[Friend]GetProgressFeedbackMaxEstimate(&this, pulProgressMax);
}

[CRepr]struct IBriefcaseInitiator : IUnknown
{
	public new const Guid IID = .(0x99180164, 0xda16, 0x101a, 0x93, 0x5c, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pmk) IsMonikerInBriefcase;
	}


	public HRESULT IsMonikerInBriefcase(IMoniker* pmk) mut => VT.[Friend]IsMonikerInBriefcase(&this, pmk);
}

[CRepr]struct IActiveDesktopP : IUnknown
{
	public new const Guid IID = .(0x52502ee0, 0xec80, 0x11d0, 0x89, 0xab, 0x00, 0xc0, 0x4f, 0xc2, 0x97, 0x2d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) SetSafeMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnsureUpdateHTML;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszSchemeName, uint32 dwFlags) SetScheme;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszSchemeName, uint32* pdwcchBuffer, uint32 dwFlags) GetScheme;
	}


	public HRESULT SetSafeMode(uint32 dwFlags) mut => VT.[Friend]SetSafeMode(&this, dwFlags);

	public HRESULT EnsureUpdateHTML() mut => VT.[Friend]EnsureUpdateHTML(&this);

	public HRESULT SetScheme(PWSTR pwszSchemeName, uint32 dwFlags) mut => VT.[Friend]SetScheme(&this, pwszSchemeName, dwFlags);

	public HRESULT GetScheme(char16* pwszSchemeName, uint32* pdwcchBuffer, uint32 dwFlags) mut => VT.[Friend]GetScheme(&this, pwszSchemeName, pdwcchBuffer, dwFlags);
}

[CRepr]struct IADesktopP2 : IUnknown
{
	public new const Guid IID = .(0xb22754e2, 0x4574, 0x11d1, 0x98, 0x88, 0x00, 0x60, 0x97, 0xde, 0xac, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReReadWallpaper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags, uint32 dwMask) GetADObjectFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UpdateAllDesktopSubscriptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleObject* pOleObj) MakeDynamicChanges;
	}


	public HRESULT ReReadWallpaper() mut => VT.[Friend]ReReadWallpaper(&this);

	public HRESULT GetADObjectFlags(uint32* pdwFlags, uint32 dwMask) mut => VT.[Friend]GetADObjectFlags(&this, pdwFlags, dwMask);

	public HRESULT UpdateAllDesktopSubscriptions() mut => VT.[Friend]UpdateAllDesktopSubscriptions(&this);

	public HRESULT MakeDynamicChanges(IOleObject* pOleObj) mut => VT.[Friend]MakeDynamicChanges(&this, pOleObj);
}

#endregion
