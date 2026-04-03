using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.System.SettingsManagementInfrastructure;

#region Constants
public static
{
	public const String WCM_SETTINGS_ID_NAME = "name";
	public const String WCM_SETTINGS_ID_VERSION = "version";
	public const String WCM_SETTINGS_ID_LANGUAGE = "language";
	public const String WCM_SETTINGS_ID_ARCHITECTURE = "architecture";
	public const String WCM_SETTINGS_ID_TOKEN = "token";
	public const String WCM_SETTINGS_ID_URI = "uri";
	public const String WCM_SETTINGS_ID_VERSION_SCOPE = "versionScope";
	public const uint32 WCM_SETTINGS_ID_FLAG_REFERENCE = 0;
	public const uint32 WCM_SETTINGS_ID_FLAG_DEFINITION = 1;
	public const uint32 LINK_STORE_TO_ENGINE_INSTANCE = 1;
	public const uint32 LIMITED_VALIDATION_MODE = 1;
	public const HRESULT WCM_E_INTERNALERROR = -2145255424;
	public const HRESULT WCM_E_STATENODENOTFOUND = -2145255423;
	public const HRESULT WCM_E_STATENODENOTALLOWED = -2145255422;
	public const HRESULT WCM_E_ATTRIBUTENOTFOUND = -2145255421;
	public const HRESULT WCM_E_ATTRIBUTENOTALLOWED = -2145255420;
	public const HRESULT WCM_E_INVALIDVALUE = -2145255419;
	public const HRESULT WCM_E_INVALIDVALUEFORMAT = -2145255418;
	public const HRESULT WCM_E_TYPENOTSPECIFIED = -2145255417;
	public const HRESULT WCM_E_INVALIDDATATYPE = -2145255416;
	public const HRESULT WCM_E_NOTPOSITIONED = -2145255415;
	public const HRESULT WCM_E_READONLYITEM = -2145255414;
	public const HRESULT WCM_E_INVALIDPATH = -2145255413;
	public const HRESULT WCM_E_WRONGESCAPESTRING = -2145255412;
	public const HRESULT WCM_E_INVALIDVERSIONFORMAT = -2145255411;
	public const HRESULT WCM_E_INVALIDLANGUAGEFORMAT = -2145255410;
	public const HRESULT WCM_E_KEYNOTCHANGEABLE = -2145255409;
	public const HRESULT WCM_E_EXPRESSIONNOTFOUND = -2145255408;
	public const HRESULT WCM_E_SUBSTITUTIONNOTFOUND = -2145255407;
	public const HRESULT WCM_E_USERALREADYREGISTERED = -2145255406;
	public const HRESULT WCM_E_USERNOTFOUND = -2145255405;
	public const HRESULT WCM_E_NAMESPACENOTFOUND = -2145255404;
	public const HRESULT WCM_E_NAMESPACEALREADYREGISTERED = -2145255403;
	public const HRESULT WCM_E_STORECORRUPTED = -2145255402;
	public const HRESULT WCM_E_INVALIDEXPRESSIONSYNTAX = -2145255401;
	public const HRESULT WCM_E_NOTIFICATIONNOTFOUND = -2145255400;
	public const HRESULT WCM_E_CONFLICTINGASSERTION = -2145255399;
	public const HRESULT WCM_E_ASSERTIONFAILED = -2145255398;
	public const HRESULT WCM_E_DUPLICATENAME = -2145255397;
	public const HRESULT WCM_E_INVALIDKEY = -2145255396;
	public const HRESULT WCM_E_INVALIDSTREAM = -2145255395;
	public const HRESULT WCM_E_HANDLERNOTFOUND = -2145255394;
	public const HRESULT WCM_E_INVALIDHANDLERSYNTAX = -2145255393;
	public const HRESULT WCM_E_VALIDATIONFAILED = -2145255392;
	public const HRESULT WCM_E_RESTRICTIONFAILED = -2145255391;
	public const HRESULT WCM_E_MANIFESTCOMPILATIONFAILED = -2145255390;
	public const HRESULT WCM_E_CYCLICREFERENCE = -2145255389;
	public const HRESULT WCM_E_MIXTYPEASSERTION = -2145255388;
	public const HRESULT WCM_E_NOTSUPPORTEDFUNCTION = -2145255387;
	public const HRESULT WCM_E_VALUETOOBIG = -2145255386;
	public const HRESULT WCM_E_INVALIDATTRIBUTECOMBINATION = -2145255385;
	public const HRESULT WCM_E_ABORTOPERATION = -2145255384;
	public const HRESULT WCM_E_MISSINGCONFIGURATION = -2145255383;
	public const HRESULT WCM_E_INVALIDPROCESSORFORMAT = -2145255382;
	public const HRESULT WCM_E_SOURCEMANEMPTYVALUE = -2145255381;
	public const HRESULT WCM_S_INTERNALERROR = 2232320;
	public const HRESULT WCM_S_ATTRIBUTENOTFOUND = 2232321;
	public const HRESULT WCM_S_LEGACYSETTINGWARNING = 2232322;
	public const HRESULT WCM_S_INVALIDATTRIBUTECOMBINATION = 2232324;
	public const HRESULT WCM_S_ATTRIBUTENOTALLOWED = 2232325;
	public const HRESULT WCM_S_NAMESPACENOTFOUND = 2232326;
	public const HRESULT WCM_E_UNKNOWNRESULT = -2145251325;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WcmTargetMode : int32
{
	OfflineMode = 1,
	OnlineMode = 2,
}


[AllowDuplicates]
public enum WcmNamespaceEnumerationFlags : int32
{
	SharedEnumeration = 1,
	UserEnumeration = 2,
	AllEnumeration = 3,
}


[AllowDuplicates]
public enum WcmDataType : int32
{
	dataTypeByte = 1,
	dataTypeSByte = 2,
	dataTypeUInt16 = 3,
	dataTypeInt16 = 4,
	dataTypeUInt32 = 5,
	dataTypeInt32 = 6,
	dataTypeUInt64 = 7,
	dataTypeInt64 = 8,
	dataTypeBoolean = 11,
	dataTypeString = 12,
	dataTypeFlagArray = 32768,
}


[AllowDuplicates]
public enum WcmSettingType : int32
{
	settingTypeScalar = 1,
	settingTypeComplex = 2,
	settingTypeList = 3,
}


[AllowDuplicates]
public enum WcmRestrictionFacets : int32
{
	restrictionFacetMaxLength = 1,
	restrictionFacetEnumeration = 2,
	restrictionFacetMaxInclusive = 4,
	restrictionFacetMinInclusive = 8,
}


[AllowDuplicates]
public enum WcmUserStatus : int32
{
	UnknownStatus = 0,
	UserRegistered = 1,
	UserUnregistered = 2,
	UserLoaded = 3,
	UserUnloaded = 4,
}


[AllowDuplicates]
public enum WcmNamespaceAccess : int32
{
	ReadOnlyAccess = 1,
	ReadWriteAccess = 2,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_SettingsEngine = .(0x9f7d7bb5, 0x20b3, 0x11da, 0x81, 0xa5, 0x00, 0x30, 0xf1, 0x64, 0x2e, 0x3c);


}
#endregion

#region COM Types
[CRepr]struct IItemEnumerator : IUnknown
{
	public new const Guid IID = .(0x9f7d7bb7, 0x20b3, 0x11da, 0x81, 0xa5, 0x00, 0x30, 0xf1, 0x64, 0x2e, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Item) Current;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* ItemValid) MoveNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT Current(VARIANT* Item) mut => VT.[Friend]Current(&this, Item);

	public HRESULT MoveNext(BOOL* ItemValid) mut => VT.[Friend]MoveNext(&this, ItemValid);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct ISettingsIdentity : IUnknown
{
	public new const Guid IID = .(0x9f7d7bb6, 0x20b3, 0x11da, 0x81, 0xa5, 0x00, 0x30, 0xf1, 0x64, 0x2e, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* Reserved, PWSTR Name, BSTR* Value) GetAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* Reserved, PWSTR Name, PWSTR Value) SetAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* Flags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Flags) SetFlags;
	}


	public HRESULT GetAttribute(void* Reserved, PWSTR Name, BSTR* Value) mut => VT.[Friend]GetAttribute(&this, Reserved, Name, Value);

	public HRESULT SetAttribute(void* Reserved, PWSTR Name, PWSTR Value) mut => VT.[Friend]SetAttribute(&this, Reserved, Name, Value);

	public HRESULT GetFlags(uint32* Flags) mut => VT.[Friend]COM_GetFlags(&this, Flags);

	public HRESULT SetFlags(uint32 Flags) mut => VT.[Friend]SetFlags(&this, Flags);
}

[CRepr]struct ITargetInfo : IUnknown
{
	public new const Guid IID = .(0x9f7d7bb8, 0x20b3, 0x11da, 0x81, 0xa5, 0x00, 0x30, 0xf1, 0x64, 0x2e, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WcmTargetMode* TargetMode) GetTargetMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WcmTargetMode TargetMode) SetTargetMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* TemporaryStoreLocation) GetTemporaryStoreLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR TemporaryStoreLocation) SetTemporaryStoreLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* TargetID) GetTargetID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid TargetID) SetTargetID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* ProcessorArchitecture) GetTargetProcessorArchitecture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR ProcessorArchitecture) SetTargetProcessorArchitecture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Offline, PWSTR Property, BSTR* Value) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Offline, PWSTR Property, PWSTR Value) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IItemEnumerator** Enumerator) GetEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Offline, PWSTR Location, BSTR* ExpandedLocation) ExpandTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Offline, PWSTR Location, BSTR* ExpandedLocation) ExpandTargetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Module, PWSTR Path) SetModulePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Module, HINSTANCE* ModuleHandle) LoadModule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR InstallerModule, uint8* Wow64Context) SetWow64Context;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR ClientArchitecture, PWSTR Value, BSTR* TranslatedValue) TranslateWow64;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzHiveDir) SetSchemaHiveLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pHiveLocation) GetSchemaHiveLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzMountName) SetSchemaHiveMountName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pMountName) GetSchemaHiveMountName;
	}


	public HRESULT GetTargetMode(WcmTargetMode* TargetMode) mut => VT.[Friend]GetTargetMode(&this, TargetMode);

	public HRESULT SetTargetMode(WcmTargetMode TargetMode) mut => VT.[Friend]SetTargetMode(&this, TargetMode);

	public HRESULT GetTemporaryStoreLocation(BSTR* TemporaryStoreLocation) mut => VT.[Friend]GetTemporaryStoreLocation(&this, TemporaryStoreLocation);

	public HRESULT SetTemporaryStoreLocation(PWSTR TemporaryStoreLocation) mut => VT.[Friend]SetTemporaryStoreLocation(&this, TemporaryStoreLocation);

	public HRESULT GetTargetID(BSTR* TargetID) mut => VT.[Friend]GetTargetID(&this, TargetID);

	public HRESULT SetTargetID(Guid TargetID) mut => VT.[Friend]SetTargetID(&this, TargetID);

	public HRESULT GetTargetProcessorArchitecture(BSTR* ProcessorArchitecture) mut => VT.[Friend]GetTargetProcessorArchitecture(&this, ProcessorArchitecture);

	public HRESULT SetTargetProcessorArchitecture(PWSTR ProcessorArchitecture) mut => VT.[Friend]SetTargetProcessorArchitecture(&this, ProcessorArchitecture);

	public HRESULT GetProperty(BOOL Offline, PWSTR Property, BSTR* Value) mut => VT.[Friend]GetProperty(&this, Offline, Property, Value);

	public HRESULT SetProperty(BOOL Offline, PWSTR Property, PWSTR Value) mut => VT.[Friend]SetProperty(&this, Offline, Property, Value);

	public HRESULT GetEnumerator(IItemEnumerator** Enumerator) mut => VT.[Friend]GetEnumerator(&this, Enumerator);

	public HRESULT ExpandTarget(BOOL Offline, PWSTR Location, BSTR* ExpandedLocation) mut => VT.[Friend]ExpandTarget(&this, Offline, Location, ExpandedLocation);

	public HRESULT ExpandTargetPath(BOOL Offline, PWSTR Location, BSTR* ExpandedLocation) mut => VT.[Friend]ExpandTargetPath(&this, Offline, Location, ExpandedLocation);

	public HRESULT SetModulePath(PWSTR Module, PWSTR Path) mut => VT.[Friend]SetModulePath(&this, Module, Path);

	public HRESULT LoadModule(PWSTR Module, HINSTANCE* ModuleHandle) mut => VT.[Friend]LoadModule(&this, Module, ModuleHandle);

	public HRESULT SetWow64Context(PWSTR InstallerModule, uint8* Wow64Context) mut => VT.[Friend]SetWow64Context(&this, InstallerModule, Wow64Context);

	public HRESULT TranslateWow64(PWSTR ClientArchitecture, PWSTR Value, BSTR* TranslatedValue) mut => VT.[Friend]TranslateWow64(&this, ClientArchitecture, Value, TranslatedValue);

	public HRESULT SetSchemaHiveLocation(PWSTR pwzHiveDir) mut => VT.[Friend]SetSchemaHiveLocation(&this, pwzHiveDir);

	public HRESULT GetSchemaHiveLocation(BSTR* pHiveLocation) mut => VT.[Friend]GetSchemaHiveLocation(&this, pHiveLocation);

	public HRESULT SetSchemaHiveMountName(PWSTR pwzMountName) mut => VT.[Friend]SetSchemaHiveMountName(&this, pwzMountName);

	public HRESULT GetSchemaHiveMountName(BSTR* pMountName) mut => VT.[Friend]GetSchemaHiveMountName(&this, pMountName);
}

[CRepr]struct ISettingsEngine : IUnknown
{
	public new const Guid IID = .(0x9f7d7bb9, 0x20b3, 0x11da, 0x81, 0xa5, 0x00, 0x30, 0xf1, 0x64, 0x2e, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WcmNamespaceEnumerationFlags Flags, void* Reserved, IItemEnumerator** Namespaces) GetNamespaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISettingsIdentity* SettingsID, WcmNamespaceAccess Access, void* Reserved, ISettingsNamespace** NamespaceItem) GetNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 HResult, BSTR* Message) GetErrorDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISettingsIdentity** SettingsID) CreateSettingsIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* Reserved, WcmUserStatus* Status) GetStoreStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Flags) LoadStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* Reserved) UnloadStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISettingsIdentity* SettingsID, IStream* Stream, BOOL PushSettings, VARIANT* Results) RegisterNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISettingsIdentity* SettingsID, BOOL RemoveSettings) UnregisterNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITargetInfo** Target) CreateTargetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITargetInfo** Target) GetTargetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITargetInfo* Target) SetTargetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Flags, void* Reserved, ISettingsContext** SettingsContext) CreateSettingsContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISettingsContext* SettingsContext) SetSettingsContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISettingsContext* SettingsContext, PWSTR** pppwzIdentities, uint* pcIdentities) ApplySettingsContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISettingsContext** SettingsContext) GetSettingsContext;
	}


	public HRESULT GetNamespaces(WcmNamespaceEnumerationFlags Flags, void* Reserved, IItemEnumerator** Namespaces) mut => VT.[Friend]GetNamespaces(&this, Flags, Reserved, Namespaces);

	public HRESULT GetNamespace(ISettingsIdentity* SettingsID, WcmNamespaceAccess Access, void* Reserved, ISettingsNamespace** NamespaceItem) mut => VT.[Friend]GetNamespace(&this, SettingsID, Access, Reserved, NamespaceItem);

	public HRESULT GetErrorDescription(int32 HResult, BSTR* Message) mut => VT.[Friend]GetErrorDescription(&this, HResult, Message);

	public HRESULT CreateSettingsIdentity(ISettingsIdentity** SettingsID) mut => VT.[Friend]CreateSettingsIdentity(&this, SettingsID);

	public HRESULT GetStoreStatus(void* Reserved, WcmUserStatus* Status) mut => VT.[Friend]GetStoreStatus(&this, Reserved, Status);

	public HRESULT LoadStore(uint32 Flags) mut => VT.[Friend]LoadStore(&this, Flags);

	public HRESULT UnloadStore(void* Reserved) mut => VT.[Friend]UnloadStore(&this, Reserved);

	public HRESULT RegisterNamespace(ISettingsIdentity* SettingsID, IStream* Stream, BOOL PushSettings, VARIANT* Results) mut => VT.[Friend]RegisterNamespace(&this, SettingsID, Stream, PushSettings, Results);

	public HRESULT UnregisterNamespace(ISettingsIdentity* SettingsID, BOOL RemoveSettings) mut => VT.[Friend]UnregisterNamespace(&this, SettingsID, RemoveSettings);

	public HRESULT CreateTargetInfo(ITargetInfo** Target) mut => VT.[Friend]CreateTargetInfo(&this, Target);

	public HRESULT GetTargetInfo(ITargetInfo** Target) mut => VT.[Friend]GetTargetInfo(&this, Target);

	public HRESULT SetTargetInfo(ITargetInfo* Target) mut => VT.[Friend]SetTargetInfo(&this, Target);

	public HRESULT CreateSettingsContext(uint32 Flags, void* Reserved, ISettingsContext** SettingsContext) mut => VT.[Friend]CreateSettingsContext(&this, Flags, Reserved, SettingsContext);

	public HRESULT SetSettingsContext(ISettingsContext* SettingsContext) mut => VT.[Friend]SetSettingsContext(&this, SettingsContext);

	public HRESULT ApplySettingsContext(ISettingsContext* SettingsContext, PWSTR** pppwzIdentities, uint* pcIdentities) mut => VT.[Friend]ApplySettingsContext(&this, SettingsContext, pppwzIdentities, pcIdentities);

	public HRESULT GetSettingsContext(ISettingsContext** SettingsContext) mut => VT.[Friend]GetSettingsContext(&this, SettingsContext);
}

[CRepr]struct ISettingsItem : IUnknown
{
	public new const Guid IID = .(0x9f7d7bbb, 0x20b3, 0x11da, 0x81, 0xa5, 0x00, 0x30, 0xf1, 0x64, 0x2e, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Value) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Value) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WcmSettingType* Type) GetSettingType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WcmDataType* Type) GetDataType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** Data, uint32* DataSize) GetValueRaw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 DataType, uint8* Data, uint32 DataSize) SetValueRaw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* ItemHasChild) HasChild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IItemEnumerator** Children) Children;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Name, ISettingsItem** Child) GetChild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Path, ISettingsItem** Setting) GetSettingByPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Path, ISettingsItem** Setting) CreateSettingByPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Path) RemoveSettingByPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* KeyName, WcmDataType* DataType) GetListKeyInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* KeyData, ISettingsItem** Child) CreateListElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR ElementName) RemoveListElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IItemEnumerator** Attributes) Attributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Name, VARIANT* Value) GetAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Path) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WcmRestrictionFacets* RestrictionFacets) GetRestrictionFacets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WcmRestrictionFacets RestrictionFacet, VARIANT* FacetData) GetRestriction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Value) GetKeyValue;
	}


	public HRESULT GetName(BSTR* Name) mut => VT.[Friend]GetName(&this, Name);

	public HRESULT GetValue(VARIANT* Value) mut => VT.[Friend]GetValue(&this, Value);

	public HRESULT SetValue(VARIANT* Value) mut => VT.[Friend]SetValue(&this, Value);

	public HRESULT GetSettingType(WcmSettingType* Type) mut => VT.[Friend]GetSettingType(&this, Type);

	public HRESULT GetDataType(WcmDataType* Type) mut => VT.[Friend]GetDataType(&this, Type);

	public HRESULT GetValueRaw(uint8** Data, uint32* DataSize) mut => VT.[Friend]GetValueRaw(&this, Data, DataSize);

	public HRESULT SetValueRaw(int32 DataType, uint8* Data, uint32 DataSize) mut => VT.[Friend]SetValueRaw(&this, DataType, Data, DataSize);

	public HRESULT HasChild(BOOL* ItemHasChild) mut => VT.[Friend]HasChild(&this, ItemHasChild);

	public HRESULT Children(IItemEnumerator** Children) mut => VT.[Friend]Children(&this, Children);

	public HRESULT GetChild(PWSTR Name, ISettingsItem** Child) mut => VT.[Friend]GetChild(&this, Name, Child);

	public HRESULT GetSettingByPath(PWSTR Path, ISettingsItem** Setting) mut => VT.[Friend]GetSettingByPath(&this, Path, Setting);

	public HRESULT CreateSettingByPath(PWSTR Path, ISettingsItem** Setting) mut => VT.[Friend]CreateSettingByPath(&this, Path, Setting);

	public HRESULT RemoveSettingByPath(PWSTR Path) mut => VT.[Friend]RemoveSettingByPath(&this, Path);

	public HRESULT GetListKeyInformation(BSTR* KeyName, WcmDataType* DataType) mut => VT.[Friend]GetListKeyInformation(&this, KeyName, DataType);

	public HRESULT CreateListElement(VARIANT* KeyData, ISettingsItem** Child) mut => VT.[Friend]CreateListElement(&this, KeyData, Child);

	public HRESULT RemoveListElement(PWSTR ElementName) mut => VT.[Friend]RemoveListElement(&this, ElementName);

	public HRESULT Attributes(IItemEnumerator** Attributes) mut => VT.[Friend]Attributes(&this, Attributes);

	public HRESULT GetAttribute(PWSTR Name, VARIANT* Value) mut => VT.[Friend]GetAttribute(&this, Name, Value);

	public HRESULT GetPath(BSTR* Path) mut => VT.[Friend]GetPath(&this, Path);

	public HRESULT GetRestrictionFacets(WcmRestrictionFacets* RestrictionFacets) mut => VT.[Friend]GetRestrictionFacets(&this, RestrictionFacets);

	public HRESULT GetRestriction(WcmRestrictionFacets RestrictionFacet, VARIANT* FacetData) mut => VT.[Friend]GetRestriction(&this, RestrictionFacet, FacetData);

	public HRESULT GetKeyValue(VARIANT* Value) mut => VT.[Friend]GetKeyValue(&this, Value);
}

[CRepr]struct ISettingsNamespace : IUnknown
{
	public new const Guid IID = .(0x9f7d7bba, 0x20b3, 0x11da, 0x81, 0xa5, 0x00, 0x30, 0xf1, 0x64, 0x2e, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISettingsIdentity** SettingsID) GetIdentity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IItemEnumerator** Settings) Settings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL PushSettings, ISettingsResult** Result) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Path, ISettingsItem** Setting) GetSettingByPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Path, ISettingsItem** Setting) CreateSettingByPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Path) RemoveSettingByPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Name, VARIANT* Value) GetAttribute;
	}


	public HRESULT GetIdentity(ISettingsIdentity** SettingsID) mut => VT.[Friend]GetIdentity(&this, SettingsID);

	public HRESULT Settings(IItemEnumerator** Settings) mut => VT.[Friend]Settings(&this, Settings);

	public HRESULT Save(BOOL PushSettings, ISettingsResult** Result) mut => VT.[Friend]Save(&this, PushSettings, Result);

	public HRESULT GetSettingByPath(PWSTR Path, ISettingsItem** Setting) mut => VT.[Friend]GetSettingByPath(&this, Path, Setting);

	public HRESULT CreateSettingByPath(PWSTR Path, ISettingsItem** Setting) mut => VT.[Friend]CreateSettingByPath(&this, Path, Setting);

	public HRESULT RemoveSettingByPath(PWSTR Path) mut => VT.[Friend]RemoveSettingByPath(&this, Path);

	public HRESULT GetAttribute(PWSTR Name, VARIANT* Value) mut => VT.[Friend]GetAttribute(&this, Name, Value);
}

[CRepr]struct ISettingsResult : IUnknown
{
	public new const Guid IID = .(0x9f7d7bbc, 0x20b3, 0x11da, 0x81, 0xa5, 0x00, 0x30, 0xf1, 0x64, 0x2e, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* description) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* hrOut) GetErrorCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* description) GetContextDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* dwLine) GetLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* dwColumn) GetColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* file) GetSource;
	}


	public HRESULT GetDescription(BSTR* description) mut => VT.[Friend]GetDescription(&this, description);

	public HRESULT GetErrorCode(HRESULT* hrOut) mut => VT.[Friend]GetErrorCode(&this, hrOut);

	public HRESULT GetContextDescription(BSTR* description) mut => VT.[Friend]GetContextDescription(&this, description);

	public HRESULT GetLine(uint32* dwLine) mut => VT.[Friend]GetLine(&this, dwLine);

	public HRESULT GetColumn(uint32* dwColumn) mut => VT.[Friend]GetColumn(&this, dwColumn);

	public HRESULT GetSource(BSTR* file) mut => VT.[Friend]GetSource(&this, file);
}

[CRepr]struct ISettingsContext : IUnknown
{
	public new const Guid IID = .(0x9f7d7bbd, 0x20b3, 0x11da, 0x81, 0xa5, 0x00, 0x30, 0xf1, 0x64, 0x2e, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, ITargetInfo* pTarget) Serialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, ITargetInfo* pTarget, ISettingsResult*** pppResults, uint* pcResultCount) Deserialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pUserData) SetUserData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void** pUserData) GetUserData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IItemEnumerator** ppNamespaceIds) GetNamespaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISettingsIdentity* pIdentity, IItemEnumerator** ppAddedSettings, IItemEnumerator** ppModifiedSettings, IItemEnumerator** ppDeletedSettings) GetStoredSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISettingsIdentity* pIdentity, PWSTR pwzSetting) RevertSetting;
	}


	public HRESULT Serialize(IStream* pStream, ITargetInfo* pTarget) mut => VT.[Friend]Serialize(&this, pStream, pTarget);

	public HRESULT Deserialize(IStream* pStream, ITargetInfo* pTarget, ISettingsResult*** pppResults, uint* pcResultCount) mut => VT.[Friend]Deserialize(&this, pStream, pTarget, pppResults, pcResultCount);

	public HRESULT SetUserData(void* pUserData) mut => VT.[Friend]SetUserData(&this, pUserData);

	public HRESULT GetUserData(void** pUserData) mut => VT.[Friend]GetUserData(&this, pUserData);

	public HRESULT GetNamespaces(IItemEnumerator** ppNamespaceIds) mut => VT.[Friend]GetNamespaces(&this, ppNamespaceIds);

	public HRESULT GetStoredSettings(ISettingsIdentity* pIdentity, IItemEnumerator** ppAddedSettings, IItemEnumerator** ppModifiedSettings, IItemEnumerator** ppDeletedSettings) mut => VT.[Friend]GetStoredSettings(&this, pIdentity, ppAddedSettings, ppModifiedSettings, ppDeletedSettings);

	public HRESULT RevertSetting(ISettingsIdentity* pIdentity, PWSTR pwzSetting) mut => VT.[Friend]RevertSetting(&this, pIdentity, pwzSetting);
}

#endregion
