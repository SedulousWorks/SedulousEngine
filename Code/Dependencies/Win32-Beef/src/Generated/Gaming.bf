using Win32.System.Com;
using Win32.Foundation;
using Win32.System.WinRT;
using System;

namespace Win32.Gaming;

#region Constants
public static
{
	public const String ID_GDF_XML_STR = "__GDF_XML";
	public const String ID_GDF_THUMBNAIL_STR = "__GDF_THUMBNAIL";
}
#endregion

#region Enums

[AllowDuplicates]
public enum GAME_INSTALL_SCOPE : int32
{
	GIS_NOT_INSTALLED = 1,
	GIS_CURRENT_USER = 2,
	GIS_ALL_USERS = 3,
}


[AllowDuplicates]
public enum GAMESTATS_OPEN_TYPE : int32
{
	GAMESTATS_OPEN_OPENORCREATE = 0,
	GAMESTATS_OPEN_OPENONLY = 1,
}


[AllowDuplicates]
public enum GAMESTATS_OPEN_RESULT : int32
{
	GAMESTATS_OPEN_CREATED = 0,
	GAMESTATS_OPEN_OPENED = 1,
}


[AllowDuplicates]
public enum GAMING_DEVICE_VENDOR_ID : int32
{
	GAMING_DEVICE_VENDOR_ID_NONE = 0,
	GAMING_DEVICE_VENDOR_ID_MICROSOFT = -1024700366,
}


[AllowDuplicates]
public enum GAMING_DEVICE_DEVICE_ID : int32
{
	GAMING_DEVICE_DEVICE_ID_NONE = 0,
	GAMING_DEVICE_DEVICE_ID_XBOX_ONE = 1988865574,
	GAMING_DEVICE_DEVICE_ID_XBOX_ONE_S = 712204761,
	GAMING_DEVICE_DEVICE_ID_XBOX_ONE_X = 1523980231,
	GAMING_DEVICE_DEVICE_ID_XBOX_ONE_X_DEVKIT = 284675555,
}


[AllowDuplicates]
public enum KnownGamingPrivileges : int32
{
	XPRIVILEGE_BROADCAST = 190,
	XPRIVILEGE_VIEW_FRIENDS_LIST = 197,
	XPRIVILEGE_GAME_DVR = 198,
	XPRIVILEGE_SHARE_KINECT_CONTENT = 199,
	XPRIVILEGE_MULTIPLAYER_PARTIES = 203,
	XPRIVILEGE_COMMUNICATION_VOICE_INGAME = 205,
	XPRIVILEGE_COMMUNICATION_VOICE_SKYPE = 206,
	XPRIVILEGE_CLOUD_GAMING_MANAGE_SESSION = 207,
	XPRIVILEGE_CLOUD_GAMING_JOIN_SESSION = 208,
	XPRIVILEGE_CLOUD_SAVED_GAMES = 209,
	XPRIVILEGE_SHARE_CONTENT = 211,
	XPRIVILEGE_PREMIUM_CONTENT = 214,
	XPRIVILEGE_SUBSCRIPTION_CONTENT = 219,
	XPRIVILEGE_SOCIAL_NETWORK_SHARING = 220,
	XPRIVILEGE_PREMIUM_VIDEO = 224,
	XPRIVILEGE_VIDEO_COMMUNICATIONS = 235,
	XPRIVILEGE_PURCHASE_CONTENT = 245,
	XPRIVILEGE_USER_CREATED_CONTENT = 247,
	XPRIVILEGE_PROFILE_VIEWING = 249,
	XPRIVILEGE_COMMUNICATIONS = 252,
	XPRIVILEGE_MULTIPLAYER_SESSIONS = 254,
	XPRIVILEGE_ADD_FRIEND = 255,
}


[AllowDuplicates]
public enum XBL_IDP_AUTH_TOKEN_STATUS : int32
{
	XBL_IDP_AUTH_TOKEN_STATUS_SUCCESS = 0,
	XBL_IDP_AUTH_TOKEN_STATUS_OFFLINE_SUCCESS = 1,
	XBL_IDP_AUTH_TOKEN_STATUS_NO_ACCOUNT_SET = 2,
	XBL_IDP_AUTH_TOKEN_STATUS_LOAD_MSA_ACCOUNT_FAILED = 3,
	XBL_IDP_AUTH_TOKEN_STATUS_XBOX_VETO = 4,
	XBL_IDP_AUTH_TOKEN_STATUS_MSA_INTERRUPT = 5,
	XBL_IDP_AUTH_TOKEN_STATUS_OFFLINE_NO_CONSENT = 6,
	XBL_IDP_AUTH_TOKEN_STATUS_VIEW_NOT_SET = 7,
	XBL_IDP_AUTH_TOKEN_STATUS_UNKNOWN = -1,
}

#endregion

#region Function Pointers
public function void GameUICompletionRoutine(HRESULT returnCode, void* context);

public function void PlayerPickerUICompletionRoutine(HRESULT returnCode, void* context, HSTRING* selectedXuids, uint selectedXuidsCount);

#endregion

#region Structs
[CRepr]
public struct GAMING_DEVICE_MODEL_INFORMATION
{
	public GAMING_DEVICE_VENDOR_ID vendorId;
	public GAMING_DEVICE_DEVICE_ID deviceId;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_GameExplorer = .(0x9a5ea990, 0x3034, 0x4d6f, 0x91, 0x28, 0x01, 0xf3, 0xc6, 0x10, 0x22, 0xbc);


	public const Guid CLSID_GameStatistics = .(0xdbc85a2c, 0xc0dc, 0x4961, 0xb6, 0xe2, 0xd2, 0x8b, 0x62, 0xc1, 0x1a, 0xd4);


	public const Guid CLSID_XblIdpAuthManager = .(0xce23534b, 0x56d8, 0x4978, 0x86, 0xa2, 0x7e, 0xe5, 0x70, 0x64, 0x04, 0x68);


	public const Guid CLSID_XblIdpAuthTokenResult = .(0x9f493441, 0x744a, 0x410c, 0xae, 0x2b, 0x9a, 0x22, 0xf7, 0xc7, 0x73, 0x1f);


}
#endregion

#region COM Types
[CRepr]struct IGameExplorer : IUnknown
{
	public new const Guid IID = .(0xe7b2fb72, 0xd728, 0x49b3, 0xa5, 0xf2, 0x18, 0xeb, 0xf5, 0xf1, 0x34, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGDFBinaryPath, BSTR bstrGameInstallDirectory, GAME_INSTALL_SCOPE installScope, Guid* pguidInstanceID) AddGame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guidInstanceID) RemoveGame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guidInstanceID) UpdateGame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGDFBinaryPath, BOOL* pfHasAccess) VerifyAccess;
	}


	public HRESULT AddGame(BSTR bstrGDFBinaryPath, BSTR bstrGameInstallDirectory, GAME_INSTALL_SCOPE installScope, Guid* pguidInstanceID) mut => VT.[Friend]AddGame(&this, bstrGDFBinaryPath, bstrGameInstallDirectory, installScope, pguidInstanceID);

	public HRESULT RemoveGame(Guid guidInstanceID) mut => VT.[Friend]RemoveGame(&this, guidInstanceID);

	public HRESULT UpdateGame(Guid guidInstanceID) mut => VT.[Friend]UpdateGame(&this, guidInstanceID);

	public HRESULT VerifyAccess(BSTR bstrGDFBinaryPath, BOOL* pfHasAccess) mut => VT.[Friend]VerifyAccess(&this, bstrGDFBinaryPath, pfHasAccess);
}

[CRepr]struct IGameStatistics : IUnknown
{
	public new const Guid IID = .(0x3887c9ca, 0x04a0, 0x42ae, 0xbc, 0x4c, 0x5f, 0xa6, 0xc7, 0x72, 0x11, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* cch) GetMaxCategoryLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* cch) GetMaxNameLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* cch) GetMaxValueLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pMax) GetMaxCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pMax) GetMaxStatsPerCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 categoryIndex, PWSTR title) SetCategoryTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 categoryIndex, PWSTR* pTitle) GetCategoryTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 categoryIndex, uint16 statIndex, PWSTR* pName, PWSTR* pValue) GetStatistic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 categoryIndex, uint16 statIndex, PWSTR name, PWSTR value) SetStatistic;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL trackChanges) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 categoryIndex) SetLastPlayedCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCategoryIndex) GetLastPlayedCategory;
	}


	public HRESULT GetMaxCategoryLength(uint32* cch) mut => VT.[Friend]GetMaxCategoryLength(&this, cch);

	public HRESULT GetMaxNameLength(uint32* cch) mut => VT.[Friend]GetMaxNameLength(&this, cch);

	public HRESULT GetMaxValueLength(uint32* cch) mut => VT.[Friend]GetMaxValueLength(&this, cch);

	public HRESULT GetMaxCategories(uint16* pMax) mut => VT.[Friend]GetMaxCategories(&this, pMax);

	public HRESULT GetMaxStatsPerCategory(uint16* pMax) mut => VT.[Friend]GetMaxStatsPerCategory(&this, pMax);

	public HRESULT SetCategoryTitle(uint16 categoryIndex, PWSTR title) mut => VT.[Friend]SetCategoryTitle(&this, categoryIndex, title);

	public HRESULT GetCategoryTitle(uint16 categoryIndex, PWSTR* pTitle) mut => VT.[Friend]GetCategoryTitle(&this, categoryIndex, pTitle);

	public HRESULT GetStatistic(uint16 categoryIndex, uint16 statIndex, PWSTR* pName, PWSTR* pValue) mut => VT.[Friend]GetStatistic(&this, categoryIndex, statIndex, pName, pValue);

	public HRESULT SetStatistic(uint16 categoryIndex, uint16 statIndex, PWSTR name, PWSTR value) mut => VT.[Friend]SetStatistic(&this, categoryIndex, statIndex, name, value);

	public HRESULT Save(BOOL trackChanges) mut => VT.[Friend]Save(&this, trackChanges);

	public HRESULT SetLastPlayedCategory(uint32 categoryIndex) mut => VT.[Friend]SetLastPlayedCategory(&this, categoryIndex);

	public HRESULT GetLastPlayedCategory(uint32* pCategoryIndex) mut => VT.[Friend]GetLastPlayedCategory(&this, pCategoryIndex);
}

[CRepr]struct IGameStatisticsMgr : IUnknown
{
	public new const Guid IID = .(0xaff3ea11, 0xe70e, 0x407d, 0x95, 0xdd, 0x35, 0xe6, 0x12, 0xc4, 0x1c, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR GDFBinaryPath, GAMESTATS_OPEN_TYPE openType, GAMESTATS_OPEN_RESULT* pOpenResult, IGameStatistics** ppiStats) GetGameStatistics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR GDFBinaryPath) RemoveGameStatistics;
	}


	public HRESULT GetGameStatistics(PWSTR GDFBinaryPath, GAMESTATS_OPEN_TYPE openType, GAMESTATS_OPEN_RESULT* pOpenResult, IGameStatistics** ppiStats) mut => VT.[Friend]GetGameStatistics(&this, GDFBinaryPath, openType, pOpenResult, ppiStats);

	public HRESULT RemoveGameStatistics(PWSTR GDFBinaryPath) mut => VT.[Friend]RemoveGameStatistics(&this, GDFBinaryPath);
}

[CRepr]struct IGameExplorer2 : IUnknown
{
	public new const Guid IID = .(0x86874aa7, 0xa1ed, 0x450d, 0xa7, 0xeb, 0xb8, 0x9e, 0x20, 0xb2, 0xff, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR binaryGDFPath, PWSTR installDirectory, GAME_INSTALL_SCOPE installScope) InstallGame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR binaryGDFPath) UninstallGame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR binaryGDFPath, BOOL* pHasAccess) CheckAccess;
	}


	public HRESULT InstallGame(PWSTR binaryGDFPath, PWSTR installDirectory, GAME_INSTALL_SCOPE installScope) mut => VT.[Friend]InstallGame(&this, binaryGDFPath, installDirectory, installScope);

	public HRESULT UninstallGame(PWSTR binaryGDFPath) mut => VT.[Friend]UninstallGame(&this, binaryGDFPath);

	public HRESULT CheckAccess(PWSTR binaryGDFPath, BOOL* pHasAccess) mut => VT.[Friend]CheckAccess(&this, binaryGDFPath, pHasAccess);
}

[CRepr]struct IXblIdpAuthManager : IUnknown
{
	public new const Guid IID = .(0xeb5ddb08, 0x8bbf, 0x449b, 0xac, 0x21, 0xb0, 0x2d, 0xde, 0xb3, 0xb1, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR msaAccountId, PWSTR xuid) SetGamerAccount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* msaAccountId, PWSTR* xuid) GetGamerAccount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR appSid, PWSTR msaAccountId) SetAppViewInitialized;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* environment) GetEnvironment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* sandbox) GetSandbox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR msaAccountId, PWSTR appSid, PWSTR msaTarget, PWSTR msaPolicy, PWSTR httpMethod, PWSTR uri, PWSTR headers, uint8* body, uint32 bodySize, BOOL forceRefresh, IXblIdpAuthTokenResult** result) GetTokenAndSignatureWithTokenResult;
	}


	public HRESULT SetGamerAccount(PWSTR msaAccountId, PWSTR xuid) mut => VT.[Friend]SetGamerAccount(&this, msaAccountId, xuid);

	public HRESULT GetGamerAccount(PWSTR* msaAccountId, PWSTR* xuid) mut => VT.[Friend]GetGamerAccount(&this, msaAccountId, xuid);

	public HRESULT SetAppViewInitialized(PWSTR appSid, PWSTR msaAccountId) mut => VT.[Friend]SetAppViewInitialized(&this, appSid, msaAccountId);

	public HRESULT GetEnvironment(PWSTR* environment) mut => VT.[Friend]GetEnvironment(&this, environment);

	public HRESULT GetSandbox(PWSTR* sandbox) mut => VT.[Friend]GetSandbox(&this, sandbox);

	public HRESULT GetTokenAndSignatureWithTokenResult(PWSTR msaAccountId, PWSTR appSid, PWSTR msaTarget, PWSTR msaPolicy, PWSTR httpMethod, PWSTR uri, PWSTR headers, uint8* body, uint32 bodySize, BOOL forceRefresh, IXblIdpAuthTokenResult** result) mut => VT.[Friend]GetTokenAndSignatureWithTokenResult(&this, msaAccountId, appSid, msaTarget, msaPolicy, httpMethod, uri, headers, body, bodySize, forceRefresh, result);
}

[CRepr]struct IXblIdpAuthTokenResult : IUnknown
{
	public new const Guid IID = .(0x46ce0225, 0xf267, 0x4d68, 0xb2, 0x99, 0xb2, 0x76, 0x25, 0x52, 0xde, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XBL_IDP_AUTH_TOKEN_STATUS* status) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* errorCode) GetErrorCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* token) GetToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* signature) GetSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* sandbox) GetSandbox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* environment) GetEnvironment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* msaAccountId) GetMsaAccountId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* xuid) GetXuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* gamertag) GetGamertag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ageGroup) GetAgeGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* privileges) GetPrivileges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* msaTarget) GetMsaTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* msaPolicy) GetMsaPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* msaAppId) GetMsaAppId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* redirect) GetRedirect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* message) GetMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* helpId) GetHelpId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* enforcementBans) GetEnforcementBans;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* restrictions) GetRestrictions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* titleRestrictions) GetTitleRestrictions;
	}


	public HRESULT GetStatus(XBL_IDP_AUTH_TOKEN_STATUS* status) mut => VT.[Friend]GetStatus(&this, status);

	public HRESULT GetErrorCode(HRESULT* errorCode) mut => VT.[Friend]GetErrorCode(&this, errorCode);

	public HRESULT GetToken(PWSTR* token) mut => VT.[Friend]GetToken(&this, token);

	public HRESULT GetSignature(PWSTR* signature) mut => VT.[Friend]GetSignature(&this, signature);

	public HRESULT GetSandbox(PWSTR* sandbox) mut => VT.[Friend]GetSandbox(&this, sandbox);

	public HRESULT GetEnvironment(PWSTR* environment) mut => VT.[Friend]GetEnvironment(&this, environment);

	public HRESULT GetMsaAccountId(PWSTR* msaAccountId) mut => VT.[Friend]GetMsaAccountId(&this, msaAccountId);

	public HRESULT GetXuid(PWSTR* xuid) mut => VT.[Friend]GetXuid(&this, xuid);

	public HRESULT GetGamertag(PWSTR* gamertag) mut => VT.[Friend]GetGamertag(&this, gamertag);

	public HRESULT GetAgeGroup(PWSTR* ageGroup) mut => VT.[Friend]GetAgeGroup(&this, ageGroup);

	public HRESULT GetPrivileges(PWSTR* privileges) mut => VT.[Friend]GetPrivileges(&this, privileges);

	public HRESULT GetMsaTarget(PWSTR* msaTarget) mut => VT.[Friend]GetMsaTarget(&this, msaTarget);

	public HRESULT GetMsaPolicy(PWSTR* msaPolicy) mut => VT.[Friend]GetMsaPolicy(&this, msaPolicy);

	public HRESULT GetMsaAppId(PWSTR* msaAppId) mut => VT.[Friend]GetMsaAppId(&this, msaAppId);

	public HRESULT GetRedirect(PWSTR* redirect) mut => VT.[Friend]GetRedirect(&this, redirect);

	public HRESULT GetMessage(PWSTR* message) mut => VT.[Friend]GetMessage(&this, message);

	public HRESULT GetHelpId(PWSTR* helpId) mut => VT.[Friend]GetHelpId(&this, helpId);

	public HRESULT GetEnforcementBans(PWSTR* enforcementBans) mut => VT.[Friend]GetEnforcementBans(&this, enforcementBans);

	public HRESULT GetRestrictions(PWSTR* restrictions) mut => VT.[Friend]GetRestrictions(&this, restrictions);

	public HRESULT GetTitleRestrictions(PWSTR* titleRestrictions) mut => VT.[Friend]GetTitleRestrictions(&this, titleRestrictions);
}

[CRepr]struct IXblIdpAuthTokenResult2 : IUnknown
{
	public new const Guid IID = .(0x75d760b0, 0x60b9, 0x412d, 0x99, 0x4f, 0x26, 0xb2, 0xcd, 0x5f, 0x78, 0x12);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) GetModernGamertag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) GetModernGamertagSuffix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) GetUniqueModernGamertag;
	}


	public HRESULT GetModernGamertag(PWSTR* value) mut => VT.[Friend]GetModernGamertag(&this, value);

	public HRESULT GetModernGamertagSuffix(PWSTR* value) mut => VT.[Friend]GetModernGamertagSuffix(&this, value);

	public HRESULT GetUniqueModernGamertag(PWSTR* value) mut => VT.[Friend]GetUniqueModernGamertag(&this, value);
}

#endregion

#region Functions
public static
{
	[Import("api-ms-win-gaming-expandedresources-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HasExpandedResources(BOOL* hasExpandedResources);

	[Import("api-ms-win-gaming-expandedresources-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetExpandedResourceExclusiveCpuCount(uint32* exclusiveCpuCount);

	[Import("api-ms-win-gaming-expandedresources-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ReleaseExclusiveCpuSets();

	[Import("api-ms-win-gaming-deviceinformation-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetGamingDeviceModelInformation(GAMING_DEVICE_MODEL_INFORMATION* information);

	[Import("api-ms-win-gaming-tcui-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowGameInviteUI(HSTRING serviceConfigurationId, HSTRING sessionTemplateName, HSTRING sessionId, HSTRING invitationDisplayText, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowPlayerPickerUI(HSTRING promptDisplayText, HSTRING* xuids, uint xuidsCount, HSTRING* preSelectedXuids, uint preSelectedXuidsCount, uint minSelectionCount, uint maxSelectionCount, PlayerPickerUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowProfileCardUI(HSTRING targetUserXuid, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowChangeFriendRelationshipUI(HSTRING targetUserXuid, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowTitleAchievementsUI(uint32 titleId, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ProcessPendingGameUI(BOOL waitForCompletion);

	[Import("api-ms-win-gaming-tcui-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TryCancelPendingGameUI();

	[Import("api-ms-win-gaming-tcui-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CheckGamingPrivilegeWithUI(uint32 privilegeId, HSTRING @scope, HSTRING policy, HSTRING friendlyMessage, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CheckGamingPrivilegeSilently(uint32 privilegeId, HSTRING @scope, HSTRING policy, BOOL* hasPrivilege);

	[Import("api-ms-win-gaming-tcui-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowGameInviteUIForUser(IInspectable* user, HSTRING serviceConfigurationId, HSTRING sessionTemplateName, HSTRING sessionId, HSTRING invitationDisplayText, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowPlayerPickerUIForUser(IInspectable* user, HSTRING promptDisplayText, HSTRING* xuids, uint xuidsCount, HSTRING* preSelectedXuids, uint preSelectedXuidsCount, uint minSelectionCount, uint maxSelectionCount, PlayerPickerUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowProfileCardUIForUser(IInspectable* user, HSTRING targetUserXuid, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowChangeFriendRelationshipUIForUser(IInspectable* user, HSTRING targetUserXuid, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowTitleAchievementsUIForUser(IInspectable* user, uint32 titleId, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CheckGamingPrivilegeWithUIForUser(IInspectable* user, uint32 privilegeId, HSTRING @scope, HSTRING policy, HSTRING friendlyMessage, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CheckGamingPrivilegeSilentlyForUser(IInspectable* user, uint32 privilegeId, HSTRING @scope, HSTRING policy, BOOL* hasPrivilege);

	[Import("api-ms-win-gaming-tcui-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowGameInviteUIWithContext(HSTRING serviceConfigurationId, HSTRING sessionTemplateName, HSTRING sessionId, HSTRING invitationDisplayText, HSTRING customActivationContext, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowGameInviteUIWithContextForUser(IInspectable* user, HSTRING serviceConfigurationId, HSTRING sessionTemplateName, HSTRING sessionId, HSTRING invitationDisplayText, HSTRING customActivationContext, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowGameInfoUI(uint32 titleId, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowGameInfoUIForUser(IInspectable* user, uint32 titleId, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowFindFriendsUI(GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowFindFriendsUIForUser(IInspectable* user, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowCustomizeUserProfileUI(GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowCustomizeUserProfileUIForUser(IInspectable* user, GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowUserSettingsUI(GameUICompletionRoutine completionRoutine, void* context);

	[Import("api-ms-win-gaming-tcui-l1-1-4.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ShowUserSettingsUIForUser(IInspectable* user, GameUICompletionRoutine completionRoutine, void* context);

}
#endregion
