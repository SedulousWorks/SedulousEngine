using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.Security.Tpm;

#region Constants
public static
{
	public const uint32 TPMVSC_DEFAULT_ADMIN_ALGORITHM_ID = 130;
}
#endregion

#region Enums

[AllowDuplicates]
public enum TPMVSC_ATTESTATION_TYPE : int32
{
	TPMVSC_ATTESTATION_NONE = 0,
	TPMVSC_ATTESTATION_AIK_ONLY = 1,
	TPMVSC_ATTESTATION_AIK_AND_CERTIFICATE = 2,
}


[AllowDuplicates]
public enum TPMVSCMGR_STATUS : int32
{
	TPMVSCMGR_STATUS_VTPMSMARTCARD_INITIALIZING = 0,
	TPMVSCMGR_STATUS_VTPMSMARTCARD_CREATING = 1,
	TPMVSCMGR_STATUS_VTPMSMARTCARD_DESTROYING = 2,
	TPMVSCMGR_STATUS_VGIDSSIMULATOR_INITIALIZING = 3,
	TPMVSCMGR_STATUS_VGIDSSIMULATOR_CREATING = 4,
	TPMVSCMGR_STATUS_VGIDSSIMULATOR_DESTROYING = 5,
	TPMVSCMGR_STATUS_VREADER_INITIALIZING = 6,
	TPMVSCMGR_STATUS_VREADER_CREATING = 7,
	TPMVSCMGR_STATUS_VREADER_DESTROYING = 8,
	TPMVSCMGR_STATUS_GENERATE_WAITING = 9,
	TPMVSCMGR_STATUS_GENERATE_AUTHENTICATING = 10,
	TPMVSCMGR_STATUS_GENERATE_RUNNING = 11,
	TPMVSCMGR_STATUS_CARD_CREATED = 12,
	TPMVSCMGR_STATUS_CARD_DESTROYED = 13,
}


[AllowDuplicates]
public enum TPMVSCMGR_ERROR : int32
{
	TPMVSCMGR_ERROR_IMPERSONATION = 0,
	TPMVSCMGR_ERROR_PIN_COMPLEXITY = 1,
	TPMVSCMGR_ERROR_READER_COUNT_LIMIT = 2,
	TPMVSCMGR_ERROR_TERMINAL_SERVICES_SESSION = 3,
	TPMVSCMGR_ERROR_VTPMSMARTCARD_INITIALIZE = 4,
	TPMVSCMGR_ERROR_VTPMSMARTCARD_CREATE = 5,
	TPMVSCMGR_ERROR_VTPMSMARTCARD_DESTROY = 6,
	TPMVSCMGR_ERROR_VGIDSSIMULATOR_INITIALIZE = 7,
	TPMVSCMGR_ERROR_VGIDSSIMULATOR_CREATE = 8,
	TPMVSCMGR_ERROR_VGIDSSIMULATOR_DESTROY = 9,
	TPMVSCMGR_ERROR_VGIDSSIMULATOR_WRITE_PROPERTY = 10,
	TPMVSCMGR_ERROR_VGIDSSIMULATOR_READ_PROPERTY = 11,
	TPMVSCMGR_ERROR_VREADER_INITIALIZE = 12,
	TPMVSCMGR_ERROR_VREADER_CREATE = 13,
	TPMVSCMGR_ERROR_VREADER_DESTROY = 14,
	TPMVSCMGR_ERROR_GENERATE_LOCATE_READER = 15,
	TPMVSCMGR_ERROR_GENERATE_FILESYSTEM = 16,
	TPMVSCMGR_ERROR_CARD_CREATE = 17,
	TPMVSCMGR_ERROR_CARD_DESTROY = 18,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_TpmVirtualSmartCardManager = .(0x16a18e86, 0x7f6e, 0x4c20, 0xad, 0x89, 0x4f, 0xfc, 0x0d, 0xb7, 0xa9, 0x6a);


	public const Guid CLSID_RemoteTpmVirtualSmartCardManager = .(0x152ea2a8, 0x70dc, 0x4c59, 0x8b, 0x2a, 0x32, 0xaa, 0x3c, 0xa0, 0xdc, 0xac);


}
#endregion

#region COM Types
[CRepr]struct ITpmVirtualSmartCardManagerStatusCallback : IUnknown
{
	public new const Guid IID = .(0x1a1bb35f, 0xabb8, 0x451c, 0xa1, 0xae, 0x33, 0xd9, 0x8f, 0x1b, 0xef, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TPMVSCMGR_STATUS Status) ReportProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TPMVSCMGR_ERROR Error) ReportError;
	}


	public HRESULT ReportProgress(TPMVSCMGR_STATUS Status) mut => VT.[Friend]ReportProgress(&this, Status);

	public HRESULT ReportError(TPMVSCMGR_ERROR Error) mut => VT.[Friend]ReportError(&this, Error);
}

[CRepr]struct ITpmVirtualSmartCardManager : IUnknown
{
	public new const Guid IID = .(0x112b1dff, 0xd9dc, 0x41f7, 0x86, 0x9f, 0xd6, 0x7f, 0xee, 0x7c, 0xb5, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFriendlyName, uint8 bAdminAlgId, uint8* pbAdminKey, uint32 cbAdminKey, uint8* pbAdminKcv, uint32 cbAdminKcv, uint8* pbPuk, uint32 cbPuk, uint8* pbPin, uint32 cbPin, BOOL fGenerate, ITpmVirtualSmartCardManagerStatusCallback* pStatusCallback, PWSTR* ppszInstanceId, BOOL* pfNeedReboot) CreateVirtualSmartCard;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszInstanceId, ITpmVirtualSmartCardManagerStatusCallback* pStatusCallback, BOOL* pfNeedReboot) DestroyVirtualSmartCard;
	}


	public HRESULT CreateVirtualSmartCard(PWSTR pszFriendlyName, uint8 bAdminAlgId, uint8* pbAdminKey, uint32 cbAdminKey, uint8* pbAdminKcv, uint32 cbAdminKcv, uint8* pbPuk, uint32 cbPuk, uint8* pbPin, uint32 cbPin, BOOL fGenerate, ITpmVirtualSmartCardManagerStatusCallback* pStatusCallback, PWSTR* ppszInstanceId, BOOL* pfNeedReboot) mut => VT.[Friend]CreateVirtualSmartCard(&this, pszFriendlyName, bAdminAlgId, pbAdminKey, cbAdminKey, pbAdminKcv, cbAdminKcv, pbPuk, cbPuk, pbPin, cbPin, fGenerate, pStatusCallback, ppszInstanceId, pfNeedReboot);

	public HRESULT DestroyVirtualSmartCard(PWSTR pszInstanceId, ITpmVirtualSmartCardManagerStatusCallback* pStatusCallback, BOOL* pfNeedReboot) mut => VT.[Friend]DestroyVirtualSmartCard(&this, pszInstanceId, pStatusCallback, pfNeedReboot);
}

[CRepr]struct ITpmVirtualSmartCardManager2 : ITpmVirtualSmartCardManager
{
	public new const Guid IID = .(0xfdf8a2b9, 0x02de, 0x47f4, 0xbc, 0x26, 0xaa, 0x85, 0xab, 0x5e, 0x52, 0x67);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITpmVirtualSmartCardManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFriendlyName, uint8 bAdminAlgId, uint8* pbAdminKey, uint32 cbAdminKey, uint8* pbAdminKcv, uint32 cbAdminKcv, uint8* pbPuk, uint32 cbPuk, uint8* pbPin, uint32 cbPin, uint8* pbPinPolicy, uint32 cbPinPolicy, BOOL fGenerate, ITpmVirtualSmartCardManagerStatusCallback* pStatusCallback, PWSTR* ppszInstanceId, BOOL* pfNeedReboot) CreateVirtualSmartCardWithPinPolicy;
	}


	public HRESULT CreateVirtualSmartCardWithPinPolicy(PWSTR pszFriendlyName, uint8 bAdminAlgId, uint8* pbAdminKey, uint32 cbAdminKey, uint8* pbAdminKcv, uint32 cbAdminKcv, uint8* pbPuk, uint32 cbPuk, uint8* pbPin, uint32 cbPin, uint8* pbPinPolicy, uint32 cbPinPolicy, BOOL fGenerate, ITpmVirtualSmartCardManagerStatusCallback* pStatusCallback, PWSTR* ppszInstanceId, BOOL* pfNeedReboot) mut => VT.[Friend]CreateVirtualSmartCardWithPinPolicy(&this, pszFriendlyName, bAdminAlgId, pbAdminKey, cbAdminKey, pbAdminKcv, cbAdminKcv, pbPuk, cbPuk, pbPin, cbPin, pbPinPolicy, cbPinPolicy, fGenerate, pStatusCallback, ppszInstanceId, pfNeedReboot);
}

[CRepr]struct ITpmVirtualSmartCardManager3 : ITpmVirtualSmartCardManager2
{
	public new const Guid IID = .(0x3c745a97, 0xf375, 0x4150, 0xbe, 0x17, 0x59, 0x50, 0xf6, 0x94, 0xc6, 0x99);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITpmVirtualSmartCardManager2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFriendlyName, uint8 bAdminAlgId, uint8* pbAdminKey, uint32 cbAdminKey, uint8* pbAdminKcv, uint32 cbAdminKcv, uint8* pbPuk, uint32 cbPuk, uint8* pbPin, uint32 cbPin, uint8* pbPinPolicy, uint32 cbPinPolicy, TPMVSC_ATTESTATION_TYPE attestationType, BOOL fGenerate, ITpmVirtualSmartCardManagerStatusCallback* pStatusCallback, PWSTR* ppszInstanceId) CreateVirtualSmartCardWithAttestation;
	}


	public HRESULT CreateVirtualSmartCardWithAttestation(PWSTR pszFriendlyName, uint8 bAdminAlgId, uint8* pbAdminKey, uint32 cbAdminKey, uint8* pbAdminKcv, uint32 cbAdminKcv, uint8* pbPuk, uint32 cbPuk, uint8* pbPin, uint32 cbPin, uint8* pbPinPolicy, uint32 cbPinPolicy, TPMVSC_ATTESTATION_TYPE attestationType, BOOL fGenerate, ITpmVirtualSmartCardManagerStatusCallback* pStatusCallback, PWSTR* ppszInstanceId) mut => VT.[Friend]CreateVirtualSmartCardWithAttestation(&this, pszFriendlyName, bAdminAlgId, pbAdminKey, cbAdminKey, pbAdminKcv, cbAdminKcv, pbPuk, cbPuk, pbPin, cbPin, pbPinPolicy, cbPinPolicy, attestationType, fGenerate, pStatusCallback, ppszInstanceId);
}

#endregion
