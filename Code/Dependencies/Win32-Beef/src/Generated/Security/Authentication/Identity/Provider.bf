using Win32.System.Com;
using Win32.Foundation;
using Win32.UI.Shell.PropertiesSystem;
using Win32.System.Com.StructuredStorage;
using System;

namespace Win32.Security.Authentication.Identity.Provider;

#region Constants
public static
{
	public const String IDENTITY_KEYWORD_ASSOCIATED = "associated";
	public const String IDENTITY_KEYWORD_LOCAL = "local";
	public const String IDENTITY_KEYWORD_HOMEGROUP = "homegroup";
	public const String IDENTITY_KEYWORD_CONNECTED = "connected";
	public const Guid OID_OAssociatedIdentityProviderObject = .(0x98c5a3dd, 0xdb68, 0x4f1a, 0x8d, 0x2b, 0x90, 0x79, 0xcd, 0xfe, 0xaf, 0x61);
	public const String STR_OUT_OF_BOX_EXPERIENCE = "OutOfBoxExperience";
	public const String STR_MODERN_SETTINGS_ADD_USER = "ModernSettingsAddUser";
	public const String STR_OUT_OF_BOX_UPGRADE_EXPERIENCE = "OutOfBoxUpgradeExperience";
	public const String STR_COMPLETE_ACCOUNT = "CompleteAccount";
	public const String STR_NTH_USER_FIRST_AUTH = "NthUserFirstAuth";
	public const String STR_USER_NAME = "Username";
	public const String STR_PROPERTY_STORE = "PropertyStore";
}
#endregion

#region Enums

[AllowDuplicates]
public enum IDENTITY_TYPE : int32
{
	IDENTITIES_ALL = 0,
	IDENTITIES_ME_ONLY = 1,
}


[AllowDuplicates]
public enum IdentityUpdateEvent : uint32
{
	IDENTITY_ASSOCIATED = 1,
	IDENTITY_DISASSOCIATED = 2,
	IDENTITY_CREATED = 4,
	IDENTITY_IMPORTED = 8,
	IDENTITY_DELETED = 16,
	IDENTITY_PROPCHANGED = 32,
	IDENTITY_CONNECTED = 64,
	IDENTITY_DISCONNECTED = 128,
}


[AllowDuplicates]
public enum IDENTITY_URL : int32
{
	IDENTITY_URL_CREATE_ACCOUNT_WIZARD = 0,
	IDENTITY_URL_SIGN_IN_WIZARD = 1,
	IDENTITY_URL_CHANGE_PASSWORD_WIZARD = 2,
	IDENTITY_URL_IFEXISTS_WIZARD = 3,
	IDENTITY_URL_ACCOUNT_SETTINGS = 4,
	IDENTITY_URL_RESTORE_WIZARD = 5,
	IDENTITY_URL_CONNECT_WIZARD = 6,
}


[AllowDuplicates]
public enum ACCOUNT_STATE : int32
{
	NOT_CONNECTED = 0,
	CONNECTING = 1,
	CONNECT_COMPLETED = 2,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_CoClassIdentityStore = .(0x30d49246, 0xd217, 0x465f, 0xb0, 0x0b, 0xac, 0x9d, 0xdd, 0x65, 0x2e, 0xb7);


	public const Guid CLSID_CIdentityProfileHandler = .(0xecf5bf46, 0xe3b6, 0x449a, 0xb5, 0x6b, 0x43, 0xf5, 0x8f, 0x86, 0x78, 0x14);


}
#endregion

#region COM Types
[CRepr]struct IIdentityAdvise : IUnknown
{
	public new const Guid IID = .(0x4e982fed, 0xd14b, 0x440c, 0xb8, 0xd6, 0xbb, 0x38, 0x64, 0x53, 0xd3, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IdentityUpdateEvent dwIdentityUpdateEvents, PWSTR lpszUniqueID) IdentityUpdated;
	}


	public HRESULT IdentityUpdated(IdentityUpdateEvent dwIdentityUpdateEvents, PWSTR lpszUniqueID) mut => VT.[Friend]IdentityUpdated(&this, dwIdentityUpdateEvents, lpszUniqueID);
}

[CRepr]struct AsyncIIdentityAdvise : IUnknown
{
	public new const Guid IID = .(0x3ab4c8da, 0xd038, 0x4830, 0x8d, 0xd9, 0x32, 0x53, 0xc5, 0x5a, 0x12, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIdentityUpdateEvents, PWSTR lpszUniqueID) Begin_IdentityUpdated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_IdentityUpdated;
	}


	public HRESULT Begin_IdentityUpdated(uint32 dwIdentityUpdateEvents, PWSTR lpszUniqueID) mut => VT.[Friend]Begin_IdentityUpdated(&this, dwIdentityUpdateEvents, lpszUniqueID);

	public HRESULT Finish_IdentityUpdated() mut => VT.[Friend]Finish_IdentityUpdated(&this);
}

[CRepr]struct IIdentityProvider : IUnknown
{
	public new const Guid IID = .(0x0d1b9e0c, 0xe8ba, 0x4f55, 0xa8, 0x1b, 0xbc, 0xe9, 0x34, 0xb9, 0x48, 0xf5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDENTITY_TYPE eIdentityType, PROPERTYKEY* pFilterkey, PROPVARIANT* pFilterPropVarValue, IEnumUnknown** ppIdentityEnum) GetIdentityEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszUserName, IPropertyStore** ppPropertyStore, PROPVARIANT* pKeywordsToAdd) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore* pPropertyStore) Import;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszUniqueID, PROPVARIANT* pKeywordsToDelete) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszUniqueID, IPropertyStore** ppPropertyStore) FindByUniqueID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore** ppPropertyStore) GetProviderPropertyStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IIdentityAdvise* pIdentityAdvise, IdentityUpdateEvent dwIdentityUpdateEvents, uint32* pdwCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) UnAdvise;
	}


	public HRESULT GetIdentityEnum(IDENTITY_TYPE eIdentityType, PROPERTYKEY* pFilterkey, PROPVARIANT* pFilterPropVarValue, IEnumUnknown** ppIdentityEnum) mut => VT.[Friend]GetIdentityEnum(&this, eIdentityType, pFilterkey, pFilterPropVarValue, ppIdentityEnum);

	public HRESULT Create(PWSTR lpszUserName, IPropertyStore** ppPropertyStore, PROPVARIANT* pKeywordsToAdd) mut => VT.[Friend]Create(&this, lpszUserName, ppPropertyStore, pKeywordsToAdd);

	public HRESULT Import(IPropertyStore* pPropertyStore) mut => VT.[Friend]Import(&this, pPropertyStore);

	public HRESULT Delete(PWSTR lpszUniqueID, PROPVARIANT* pKeywordsToDelete) mut => VT.[Friend]Delete(&this, lpszUniqueID, pKeywordsToDelete);

	public HRESULT FindByUniqueID(PWSTR lpszUniqueID, IPropertyStore** ppPropertyStore) mut => VT.[Friend]FindByUniqueID(&this, lpszUniqueID, ppPropertyStore);

	public HRESULT GetProviderPropertyStore(IPropertyStore** ppPropertyStore) mut => VT.[Friend]GetProviderPropertyStore(&this, ppPropertyStore);

	public HRESULT Advise(IIdentityAdvise* pIdentityAdvise, IdentityUpdateEvent dwIdentityUpdateEvents, uint32* pdwCookie) mut => VT.[Friend]Advise(&this, pIdentityAdvise, dwIdentityUpdateEvents, pdwCookie);

	public HRESULT UnAdvise(uint32 dwCookie) mut => VT.[Friend]UnAdvise(&this, dwCookie);
}

[CRepr]struct AsyncIIdentityProvider : IUnknown
{
	public new const Guid IID = .(0xc6fc9901, 0xc433, 0x4646, 0x8f, 0x48, 0x4e, 0x46, 0x87, 0xaa, 0xe2, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDENTITY_TYPE eIdentityType, PROPERTYKEY* pFilterkey, PROPVARIANT* pFilterPropVarValue) Begin_GetIdentityEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumUnknown** ppIdentityEnum) Finish_GetIdentityEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszUserName, PROPVARIANT* pKeywordsToAdd) Begin_Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore** ppPropertyStore) Finish_Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore* pPropertyStore) Begin_Import;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_Import;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszUniqueID, PROPVARIANT* pKeywordsToDelete) Begin_Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszUniqueID) Begin_FindByUniqueID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore** ppPropertyStore) Finish_FindByUniqueID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Begin_GetProviderPropertyStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore** ppPropertyStore) Finish_GetProviderPropertyStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IIdentityAdvise* pIdentityAdvise, uint32 dwIdentityUpdateEvents) Begin_Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCookie) Finish_Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) Begin_UnAdvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_UnAdvise;
	}


	public HRESULT Begin_GetIdentityEnum(IDENTITY_TYPE eIdentityType, PROPERTYKEY* pFilterkey, PROPVARIANT* pFilterPropVarValue) mut => VT.[Friend]Begin_GetIdentityEnum(&this, eIdentityType, pFilterkey, pFilterPropVarValue);

	public HRESULT Finish_GetIdentityEnum(IEnumUnknown** ppIdentityEnum) mut => VT.[Friend]Finish_GetIdentityEnum(&this, ppIdentityEnum);

	public HRESULT Begin_Create(PWSTR lpszUserName, PROPVARIANT* pKeywordsToAdd) mut => VT.[Friend]Begin_Create(&this, lpszUserName, pKeywordsToAdd);

	public HRESULT Finish_Create(IPropertyStore** ppPropertyStore) mut => VT.[Friend]Finish_Create(&this, ppPropertyStore);

	public HRESULT Begin_Import(IPropertyStore* pPropertyStore) mut => VT.[Friend]Begin_Import(&this, pPropertyStore);

	public HRESULT Finish_Import() mut => VT.[Friend]Finish_Import(&this);

	public HRESULT Begin_Delete(PWSTR lpszUniqueID, PROPVARIANT* pKeywordsToDelete) mut => VT.[Friend]Begin_Delete(&this, lpszUniqueID, pKeywordsToDelete);

	public HRESULT Finish_Delete() mut => VT.[Friend]Finish_Delete(&this);

	public HRESULT Begin_FindByUniqueID(PWSTR lpszUniqueID) mut => VT.[Friend]Begin_FindByUniqueID(&this, lpszUniqueID);

	public HRESULT Finish_FindByUniqueID(IPropertyStore** ppPropertyStore) mut => VT.[Friend]Finish_FindByUniqueID(&this, ppPropertyStore);

	public HRESULT Begin_GetProviderPropertyStore() mut => VT.[Friend]Begin_GetProviderPropertyStore(&this);

	public HRESULT Finish_GetProviderPropertyStore(IPropertyStore** ppPropertyStore) mut => VT.[Friend]Finish_GetProviderPropertyStore(&this, ppPropertyStore);

	public HRESULT Begin_Advise(IIdentityAdvise* pIdentityAdvise, uint32 dwIdentityUpdateEvents) mut => VT.[Friend]Begin_Advise(&this, pIdentityAdvise, dwIdentityUpdateEvents);

	public HRESULT Finish_Advise(uint32* pdwCookie) mut => VT.[Friend]Finish_Advise(&this, pdwCookie);

	public HRESULT Begin_UnAdvise(uint32 dwCookie) mut => VT.[Friend]Begin_UnAdvise(&this, dwCookie);

	public HRESULT Finish_UnAdvise() mut => VT.[Friend]Finish_UnAdvise(&this);
}

[CRepr]struct IAssociatedIdentityProvider : IUnknown
{
	public new const Guid IID = .(0x2af066b3, 0x4cbb, 0x4cba, 0xa7, 0x98, 0x20, 0x4b, 0x6a, 0xf6, 0x8c, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, IPropertyStore** ppPropertyStore) AssociateIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR lpszUniqueID) DisassociateIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR lpszUniqueID) ChangeCredential;
	}


	public HRESULT AssociateIdentity(HWND hwndParent, IPropertyStore** ppPropertyStore) mut => VT.[Friend]AssociateIdentity(&this, hwndParent, ppPropertyStore);

	public HRESULT DisassociateIdentity(HWND hwndParent, PWSTR lpszUniqueID) mut => VT.[Friend]DisassociateIdentity(&this, hwndParent, lpszUniqueID);

	public HRESULT ChangeCredential(HWND hwndParent, PWSTR lpszUniqueID) mut => VT.[Friend]ChangeCredential(&this, hwndParent, lpszUniqueID);
}

[CRepr]struct AsyncIAssociatedIdentityProvider : IUnknown
{
	public new const Guid IID = .(0x2834d6ed, 0x297e, 0x4e72, 0x8a, 0x51, 0x96, 0x1e, 0x86, 0xf0, 0x51, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent) Begin_AssociateIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore** ppPropertyStore) Finish_AssociateIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR lpszUniqueID) Begin_DisassociateIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_DisassociateIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, PWSTR lpszUniqueID) Begin_ChangeCredential;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_ChangeCredential;
	}


	public HRESULT Begin_AssociateIdentity(HWND hwndParent) mut => VT.[Friend]Begin_AssociateIdentity(&this, hwndParent);

	public HRESULT Finish_AssociateIdentity(IPropertyStore** ppPropertyStore) mut => VT.[Friend]Finish_AssociateIdentity(&this, ppPropertyStore);

	public HRESULT Begin_DisassociateIdentity(HWND hwndParent, PWSTR lpszUniqueID) mut => VT.[Friend]Begin_DisassociateIdentity(&this, hwndParent, lpszUniqueID);

	public HRESULT Finish_DisassociateIdentity() mut => VT.[Friend]Finish_DisassociateIdentity(&this);

	public HRESULT Begin_ChangeCredential(HWND hwndParent, PWSTR lpszUniqueID) mut => VT.[Friend]Begin_ChangeCredential(&this, hwndParent, lpszUniqueID);

	public HRESULT Finish_ChangeCredential() mut => VT.[Friend]Finish_ChangeCredential(&this);
}

[CRepr]struct IConnectedIdentityProvider : IUnknown
{
	public new const Guid IID = .(0xb7417b54, 0xe08c, 0x429b, 0x96, 0xc8, 0x67, 0x8d, 0x13, 0x69, 0xec, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* AuthBuffer, uint32 AuthBufferSize) ConnectIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisconnectIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* Connected) IsConnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDENTITY_URL Identifier, IBindCtx* Context, VARIANT* PostData, PWSTR* Url) GetUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ACCOUNT_STATE* pState) GetAccountState;
	}


	public HRESULT ConnectIdentity(uint8* AuthBuffer, uint32 AuthBufferSize) mut => VT.[Friend]ConnectIdentity(&this, AuthBuffer, AuthBufferSize);

	public HRESULT DisconnectIdentity() mut => VT.[Friend]DisconnectIdentity(&this);

	public HRESULT IsConnected(BOOL* Connected) mut => VT.[Friend]IsConnected(&this, Connected);

	public HRESULT GetUrl(IDENTITY_URL Identifier, IBindCtx* Context, VARIANT* PostData, PWSTR* Url) mut => VT.[Friend]GetUrl(&this, Identifier, Context, PostData, Url);

	public HRESULT GetAccountState(ACCOUNT_STATE* pState) mut => VT.[Friend]GetAccountState(&this, pState);
}

[CRepr]struct AsyncIConnectedIdentityProvider : IUnknown
{
	public new const Guid IID = .(0x9ce55141, 0xbce9, 0x4e15, 0x82, 0x4d, 0x43, 0xd7, 0x9f, 0x51, 0x2f, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* AuthBuffer, uint32 AuthBufferSize) Begin_ConnectIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_ConnectIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Begin_DisconnectIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_DisconnectIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Begin_IsConnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* Connected) Finish_IsConnected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDENTITY_URL Identifier, IBindCtx* Context) Begin_GetUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* PostData, PWSTR* Url) Finish_GetUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Begin_GetAccountState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ACCOUNT_STATE* pState) Finish_GetAccountState;
	}


	public HRESULT Begin_ConnectIdentity(uint8* AuthBuffer, uint32 AuthBufferSize) mut => VT.[Friend]Begin_ConnectIdentity(&this, AuthBuffer, AuthBufferSize);

	public HRESULT Finish_ConnectIdentity() mut => VT.[Friend]Finish_ConnectIdentity(&this);

	public HRESULT Begin_DisconnectIdentity() mut => VT.[Friend]Begin_DisconnectIdentity(&this);

	public HRESULT Finish_DisconnectIdentity() mut => VT.[Friend]Finish_DisconnectIdentity(&this);

	public HRESULT Begin_IsConnected() mut => VT.[Friend]Begin_IsConnected(&this);

	public HRESULT Finish_IsConnected(BOOL* Connected) mut => VT.[Friend]Finish_IsConnected(&this, Connected);

	public HRESULT Begin_GetUrl(IDENTITY_URL Identifier, IBindCtx* Context) mut => VT.[Friend]Begin_GetUrl(&this, Identifier, Context);

	public HRESULT Finish_GetUrl(VARIANT* PostData, PWSTR* Url) mut => VT.[Friend]Finish_GetUrl(&this, PostData, Url);

	public HRESULT Begin_GetAccountState() mut => VT.[Friend]Begin_GetAccountState(&this);

	public HRESULT Finish_GetAccountState(ACCOUNT_STATE* pState) mut => VT.[Friend]Finish_GetAccountState(&this, pState);
}

[CRepr]struct IIdentityAuthentication : IUnknown
{
	public new const Guid IID = .(0x5e7ef254, 0x979f, 0x43b5, 0xb7, 0x4e, 0x06, 0xe4, 0xeb, 0x7d, 0xf0, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* CredBuffer, uint32 CredBufferLength) SetIdentityCredential;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* CredBuffer, uint32 CredBufferLength, IPropertyStore** ppIdentityProperties) ValidateIdentityCredential;
	}


	public HRESULT SetIdentityCredential(uint8* CredBuffer, uint32 CredBufferLength) mut => VT.[Friend]SetIdentityCredential(&this, CredBuffer, CredBufferLength);

	public HRESULT ValidateIdentityCredential(uint8* CredBuffer, uint32 CredBufferLength, IPropertyStore** ppIdentityProperties) mut => VT.[Friend]ValidateIdentityCredential(&this, CredBuffer, CredBufferLength, ppIdentityProperties);
}

[CRepr]struct AsyncIIdentityAuthentication : IUnknown
{
	public new const Guid IID = .(0xf9a2f918, 0xfeca, 0x4e9c, 0x96, 0x33, 0x61, 0xcb, 0xf1, 0x3e, 0xd3, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* CredBuffer, uint32 CredBufferLength) Begin_SetIdentityCredential;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_SetIdentityCredential;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* CredBuffer, uint32 CredBufferLength, IPropertyStore** ppIdentityProperties) Begin_ValidateIdentityCredential;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore** ppIdentityProperties) Finish_ValidateIdentityCredential;
	}


	public HRESULT Begin_SetIdentityCredential(uint8* CredBuffer, uint32 CredBufferLength) mut => VT.[Friend]Begin_SetIdentityCredential(&this, CredBuffer, CredBufferLength);

	public HRESULT Finish_SetIdentityCredential() mut => VT.[Friend]Finish_SetIdentityCredential(&this);

	public HRESULT Begin_ValidateIdentityCredential(uint8* CredBuffer, uint32 CredBufferLength, IPropertyStore** ppIdentityProperties) mut => VT.[Friend]Begin_ValidateIdentityCredential(&this, CredBuffer, CredBufferLength, ppIdentityProperties);

	public HRESULT Finish_ValidateIdentityCredential(IPropertyStore** ppIdentityProperties) mut => VT.[Friend]Finish_ValidateIdentityCredential(&this, ppIdentityProperties);
}

[CRepr]struct IIdentityStore : IUnknown
{
	public new const Guid IID = .(0xdf586fa5, 0x6f35, 0x44f1, 0xb2, 0x09, 0xb3, 0x8e, 0x16, 0x97, 0x72, 0xeb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwProviders) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProvider, Guid* pProvGuid, IUnknown** ppIdentityProvider) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszUniqueID, in Guid ProviderGUID) AddToCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszUniqueID, in Guid ProviderGUID, uint16 cbSid, uint8* pSid, uint16* pcbRequiredSid) ConvertToSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDENTITY_TYPE eIdentityType, PROPERTYKEY* pFilterkey, PROPVARIANT* pFilterPropVarValue, IEnumUnknown** ppIdentityEnum) EnumerateIdentities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT GetCount(uint32* pdwProviders) mut => VT.[Friend]GetCount(&this, pdwProviders);

	public HRESULT GetAt(uint32 dwProvider, Guid* pProvGuid, IUnknown** ppIdentityProvider) mut => VT.[Friend]GetAt(&this, dwProvider, pProvGuid, ppIdentityProvider);

	public HRESULT AddToCache(PWSTR lpszUniqueID, in Guid ProviderGUID) mut => VT.[Friend]AddToCache(&this, lpszUniqueID, ProviderGUID);

	public HRESULT ConvertToSid(PWSTR lpszUniqueID, in Guid ProviderGUID, uint16 cbSid, uint8* pSid, uint16* pcbRequiredSid) mut => VT.[Friend]ConvertToSid(&this, lpszUniqueID, ProviderGUID, cbSid, pSid, pcbRequiredSid);

	public HRESULT EnumerateIdentities(IDENTITY_TYPE eIdentityType, PROPERTYKEY* pFilterkey, PROPVARIANT* pFilterPropVarValue, IEnumUnknown** ppIdentityEnum) mut => VT.[Friend]EnumerateIdentities(&this, eIdentityType, pFilterkey, pFilterPropVarValue, ppIdentityEnum);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct AsyncIIdentityStore : IUnknown
{
	public new const Guid IID = .(0xeefa1616, 0x48de, 0x4872, 0xaa, 0x64, 0x6e, 0x62, 0x06, 0x53, 0x5a, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Begin_GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwProviders) Finish_GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProvider, Guid* pProvGuid) Begin_GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pProvGuid, IUnknown** ppIdentityProvider) Finish_GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszUniqueID, in Guid ProviderGUID) Begin_AddToCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_AddToCache;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszUniqueID, in Guid ProviderGUID, uint16 cbSid, uint8* pSid) Begin_ConvertToSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pSid, uint16* pcbRequiredSid) Finish_ConvertToSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDENTITY_TYPE eIdentityType, PROPERTYKEY* pFilterkey, PROPVARIANT* pFilterPropVarValue) Begin_EnumerateIdentities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumUnknown** ppIdentityEnum) Finish_EnumerateIdentities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Begin_Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_Reset;
	}


	public HRESULT Begin_GetCount() mut => VT.[Friend]Begin_GetCount(&this);

	public HRESULT Finish_GetCount(uint32* pdwProviders) mut => VT.[Friend]Finish_GetCount(&this, pdwProviders);

	public HRESULT Begin_GetAt(uint32 dwProvider, Guid* pProvGuid) mut => VT.[Friend]Begin_GetAt(&this, dwProvider, pProvGuid);

	public HRESULT Finish_GetAt(Guid* pProvGuid, IUnknown** ppIdentityProvider) mut => VT.[Friend]Finish_GetAt(&this, pProvGuid, ppIdentityProvider);

	public HRESULT Begin_AddToCache(PWSTR lpszUniqueID, in Guid ProviderGUID) mut => VT.[Friend]Begin_AddToCache(&this, lpszUniqueID, ProviderGUID);

	public HRESULT Finish_AddToCache() mut => VT.[Friend]Finish_AddToCache(&this);

	public HRESULT Begin_ConvertToSid(PWSTR lpszUniqueID, in Guid ProviderGUID, uint16 cbSid, uint8* pSid) mut => VT.[Friend]Begin_ConvertToSid(&this, lpszUniqueID, ProviderGUID, cbSid, pSid);

	public HRESULT Finish_ConvertToSid(uint8* pSid, uint16* pcbRequiredSid) mut => VT.[Friend]Finish_ConvertToSid(&this, pSid, pcbRequiredSid);

	public HRESULT Begin_EnumerateIdentities(IDENTITY_TYPE eIdentityType, PROPERTYKEY* pFilterkey, PROPVARIANT* pFilterPropVarValue) mut => VT.[Friend]Begin_EnumerateIdentities(&this, eIdentityType, pFilterkey, pFilterPropVarValue);

	public HRESULT Finish_EnumerateIdentities(IEnumUnknown** ppIdentityEnum) mut => VT.[Friend]Finish_EnumerateIdentities(&this, ppIdentityEnum);

	public HRESULT Begin_Reset() mut => VT.[Friend]Begin_Reset(&this);

	public HRESULT Finish_Reset() mut => VT.[Friend]Finish_Reset(&this);
}

[CRepr]struct IIdentityStoreEx : IUnknown
{
	public new const Guid IID = .(0xf9f9eb98, 0x8f7f, 0x4e38, 0x95, 0x77, 0x69, 0x80, 0x11, 0x4c, 0xe3, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR LocalName, PWSTR ConnectedName, in Guid ProviderGUID) CreateConnectedIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR ConnectedName, in Guid ProviderGUID) DeleteConnectedIdentity;
	}


	public HRESULT CreateConnectedIdentity(PWSTR LocalName, PWSTR ConnectedName, in Guid ProviderGUID) mut => VT.[Friend]CreateConnectedIdentity(&this, LocalName, ConnectedName, ProviderGUID);

	public HRESULT DeleteConnectedIdentity(PWSTR ConnectedName, in Guid ProviderGUID) mut => VT.[Friend]DeleteConnectedIdentity(&this, ConnectedName, ProviderGUID);
}

[CRepr]struct AsyncIIdentityStoreEx : IUnknown
{
	public new const Guid IID = .(0xfca3af9a, 0x8a07, 0x4eae, 0x86, 0x32, 0xec, 0x3d, 0xe6, 0x58, 0xa3, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR LocalName, PWSTR ConnectedName, in Guid ProviderGUID) Begin_CreateConnectedIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_CreateConnectedIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR ConnectedName, in Guid ProviderGUID) Begin_DeleteConnectedIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finish_DeleteConnectedIdentity;
	}


	public HRESULT Begin_CreateConnectedIdentity(PWSTR LocalName, PWSTR ConnectedName, in Guid ProviderGUID) mut => VT.[Friend]Begin_CreateConnectedIdentity(&this, LocalName, ConnectedName, ProviderGUID);

	public HRESULT Finish_CreateConnectedIdentity() mut => VT.[Friend]Finish_CreateConnectedIdentity(&this);

	public HRESULT Begin_DeleteConnectedIdentity(PWSTR ConnectedName, in Guid ProviderGUID) mut => VT.[Friend]Begin_DeleteConnectedIdentity(&this, ConnectedName, ProviderGUID);

	public HRESULT Finish_DeleteConnectedIdentity() mut => VT.[Friend]Finish_DeleteConnectedIdentity(&this);
}

#endregion
