using Win32.Foundation;
using Win32.System.Com;
using Win32.System.Com.StructuredStorage;
using System;

namespace Win32.System.AddressBook;

#region Constants
public static
{
	public const uint32 PROP_ID_SECURE_MIN = 26608;
	public const uint32 PROP_ID_SECURE_MAX = 26623;
	public const uint32 MAPI_DIM = 1;
	public const uint32 fMapiUnicode = 0;
	public const uint32 hrSuccess = 0;
	public const uint32 MAPI_P1 = 268435456;
	public const uint32 MAPI_SUBMITTED = 2147483648;
	public const uint32 MAPI_SHORTTERM = 128;
	public const uint32 MAPI_NOTRECIP = 64;
	public const uint32 MAPI_THISSESSION = 32;
	public const uint32 MAPI_NOW = 16;
	public const uint32 MAPI_NOTRESERVED = 8;
	public const uint32 MAPI_COMPOUND = 128;
	public const uint32 cchProfileNameMax = 64;
	public const uint32 cchProfilePassMax = 64;
	public const uint32 MV_FLAG = 4096;
	public const uint32 PROP_ID_NULL = 0;
	public const uint32 PROP_ID_INVALID = 65535;
	public const uint32 MV_INSTANCE = 8192;
	public const uint32 TABLE_CHANGED = 1;
	public const uint32 TABLE_ERROR = 2;
	public const uint32 TABLE_ROW_ADDED = 3;
	public const uint32 TABLE_ROW_DELETED = 4;
	public const uint32 TABLE_ROW_MODIFIED = 5;
	public const uint32 TABLE_SORT_DONE = 6;
	public const uint32 TABLE_RESTRICT_DONE = 7;
	public const uint32 TABLE_SETCOL_DONE = 8;
	public const uint32 TABLE_RELOAD = 9;
	public const String szMAPINotificationMsg = "MAPI Notify window message";
	public const int32 MAPI_ERROR_VERSION = 0;
	public const uint32 MAPI_USE_DEFAULT = 64;
	public const uint32 MNID_ID = 0;
	public const uint32 MNID_STRING = 1;
	public const uint32 WAB_LOCAL_CONTAINERS = 1048576;
	public const uint32 WAB_PROFILE_CONTENTS = 2097152;
	public const uint32 WAB_IGNORE_PROFILES = 8388608;
	public const uint32 MAPI_ONE_OFF_NO_RICH_INFO = 1;
	public const uint32 UI_SERVICE = 2;
	public const uint32 SERVICE_UI_ALWAYS = 2;
	public const uint32 SERVICE_UI_ALLOWED = 16;
	public const uint32 UI_CURRENT_PROVIDER_FIRST = 4;
	public const uint32 WABOBJECT_LDAPURL_RETURN_MAILUSER = 1;
	public const uint32 WABOBJECT_ME_NEW = 1;
	public const uint32 WABOBJECT_ME_NOCREATE = 2;
	public const uint32 WAB_VCARD_FILE = 0;
	public const uint32 WAB_VCARD_STREAM = 1;
	public const uint32 WAB_USE_OE_SENDMAIL = 1;
	public const uint32 WAB_ENABLE_PROFILES = 4194304;
	public const uint32 WAB_DISPLAY_LDAPURL = 1;
	public const uint32 WAB_CONTEXT_ADRLIST = 2;
	public const uint32 WAB_DISPLAY_ISNTDS = 4;
	public const String WAB_DLL_NAME = "WAB32.DLL";
	public const String WAB_DLL_PATH_KEY = "Software\\Microsoft\\WAB\\DLLPath";
	public const HRESULT E_IMAPI_REQUEST_CANCELLED = -1062600702;
	public const HRESULT E_IMAPI_RECORDER_REQUIRED = -1062600701;
	public const HRESULT S_IMAPI_SPEEDADJUSTED = 11141124;
	public const HRESULT S_IMAPI_ROTATIONADJUSTED = 11141125;
	public const HRESULT S_IMAPI_BOTHADJUSTED = 11141126;
	public const HRESULT E_IMAPI_BURN_VERIFICATION_FAILED = -1062600697;
	public const HRESULT S_IMAPI_COMMAND_HAS_SENSE_DATA = 11141632;
	public const HRESULT E_IMAPI_RECORDER_NO_SUCH_MODE_PAGE = -1062600191;
	public const HRESULT E_IMAPI_RECORDER_MEDIA_NO_MEDIA = -1062600190;
	public const HRESULT E_IMAPI_RECORDER_MEDIA_INCOMPATIBLE = -1062600189;
	public const HRESULT E_IMAPI_RECORDER_MEDIA_UPSIDE_DOWN = -1062600188;
	public const HRESULT E_IMAPI_RECORDER_MEDIA_BECOMING_READY = -1062600187;
	public const HRESULT E_IMAPI_RECORDER_MEDIA_FORMAT_IN_PROGRESS = -1062600186;
	public const HRESULT E_IMAPI_RECORDER_MEDIA_BUSY = -1062600185;
	public const HRESULT E_IMAPI_RECORDER_INVALID_MODE_PARAMETERS = -1062600184;
	public const HRESULT E_IMAPI_RECORDER_MEDIA_WRITE_PROTECTED = -1062600183;
	public const HRESULT E_IMAPI_RECORDER_NO_SUCH_FEATURE = -1062600182;
	public const HRESULT E_IMAPI_RECORDER_FEATURE_IS_NOT_CURRENT = -1062600181;
	public const HRESULT E_IMAPI_RECORDER_GET_CONFIGURATION_NOT_SUPPORTED = -1062600180;
	public const HRESULT E_IMAPI_RECORDER_COMMAND_TIMEOUT = -1062600179;
	public const HRESULT E_IMAPI_RECORDER_DVD_STRUCTURE_NOT_PRESENT = -1062600178;
	public const HRESULT E_IMAPI_RECORDER_MEDIA_SPEED_MISMATCH = -1062600177;
	public const HRESULT E_IMAPI_RECORDER_LOCKED = -1062600176;
	public const HRESULT E_IMAPI_RECORDER_CLIENT_NAME_IS_NOT_VALID = -1062600175;
	public const HRESULT E_IMAPI_RECORDER_MEDIA_NOT_FORMATTED = -1062600174;
	public const HRESULT E_IMAPI_RECORDER_INVALID_RESPONSE_FROM_DEVICE = -1062599937;
	public const HRESULT E_IMAPI_LOSS_OF_STREAMING = -1062599936;
	public const HRESULT E_IMAPI_UNEXPECTED_RESPONSE_FROM_DEVICE = -1062599935;
	public const HRESULT S_IMAPI_WRITE_NOT_IN_PROGRESS = 11141890;
	public const HRESULT E_IMAPI_DF2DATA_WRITE_IN_PROGRESS = -1062599680;
	public const HRESULT E_IMAPI_DF2DATA_WRITE_NOT_IN_PROGRESS = -1062599679;
	public const HRESULT E_IMAPI_DF2DATA_INVALID_MEDIA_STATE = -1062599678;
	public const HRESULT E_IMAPI_DF2DATA_STREAM_NOT_SUPPORTED = -1062599677;
	public const HRESULT E_IMAPI_DF2DATA_STREAM_TOO_LARGE_FOR_CURRENT_MEDIA = -1062599676;
	public const HRESULT E_IMAPI_DF2DATA_MEDIA_NOT_BLANK = -1062599675;
	public const HRESULT E_IMAPI_DF2DATA_MEDIA_IS_NOT_SUPPORTED = -1062599674;
	public const HRESULT E_IMAPI_DF2DATA_RECORDER_NOT_SUPPORTED = -1062599673;
	public const HRESULT E_IMAPI_DF2DATA_CLIENT_NAME_IS_NOT_VALID = -1062599672;
	public const HRESULT E_IMAPI_DF2TAO_WRITE_IN_PROGRESS = -1062599424;
	public const HRESULT E_IMAPI_DF2TAO_WRITE_NOT_IN_PROGRESS = -1062599423;
	public const HRESULT E_IMAPI_DF2TAO_MEDIA_IS_NOT_PREPARED = -1062599422;
	public const HRESULT E_IMAPI_DF2TAO_MEDIA_IS_PREPARED = -1062599421;
	public const HRESULT E_IMAPI_DF2TAO_PROPERTY_FOR_BLANK_MEDIA_ONLY = -1062599420;
	public const HRESULT E_IMAPI_DF2TAO_TABLE_OF_CONTENTS_EMPTY_DISC = -1062599419;
	public const HRESULT E_IMAPI_DF2TAO_MEDIA_IS_NOT_BLANK = -1062599418;
	public const HRESULT E_IMAPI_DF2TAO_MEDIA_IS_NOT_SUPPORTED = -1062599417;
	public const HRESULT E_IMAPI_DF2TAO_TRACK_LIMIT_REACHED = -1062599416;
	public const HRESULT E_IMAPI_DF2TAO_NOT_ENOUGH_SPACE = -1062599415;
	public const HRESULT E_IMAPI_DF2TAO_NO_RECORDER_SPECIFIED = -1062599414;
	public const HRESULT E_IMAPI_DF2TAO_INVALID_ISRC = -1062599413;
	public const HRESULT E_IMAPI_DF2TAO_INVALID_MCN = -1062599412;
	public const HRESULT E_IMAPI_DF2TAO_STREAM_NOT_SUPPORTED = -1062599411;
	public const HRESULT E_IMAPI_DF2TAO_RECORDER_NOT_SUPPORTED = -1062599410;
	public const HRESULT E_IMAPI_DF2TAO_CLIENT_NAME_IS_NOT_VALID = -1062599409;
	public const HRESULT E_IMAPI_DF2RAW_WRITE_IN_PROGRESS = -1062599168;
	public const HRESULT E_IMAPI_DF2RAW_WRITE_NOT_IN_PROGRESS = -1062599167;
	public const HRESULT E_IMAPI_DF2RAW_MEDIA_IS_NOT_PREPARED = -1062599166;
	public const HRESULT E_IMAPI_DF2RAW_MEDIA_IS_PREPARED = -1062599165;
	public const HRESULT E_IMAPI_DF2RAW_CLIENT_NAME_IS_NOT_VALID = -1062599164;
	public const HRESULT E_IMAPI_DF2RAW_MEDIA_IS_NOT_BLANK = -1062599162;
	public const HRESULT E_IMAPI_DF2RAW_MEDIA_IS_NOT_SUPPORTED = -1062599161;
	public const HRESULT E_IMAPI_DF2RAW_NOT_ENOUGH_SPACE = -1062599159;
	public const HRESULT E_IMAPI_DF2RAW_NO_RECORDER_SPECIFIED = -1062599158;
	public const HRESULT E_IMAPI_DF2RAW_STREAM_NOT_SUPPORTED = -1062599155;
	public const HRESULT E_IMAPI_DF2RAW_DATA_BLOCK_TYPE_NOT_SUPPORTED = -1062599154;
	public const HRESULT E_IMAPI_DF2RAW_STREAM_LEADIN_TOO_SHORT = -1062599153;
	public const HRESULT E_IMAPI_DF2RAW_RECORDER_NOT_SUPPORTED = -1062599152;
	public const HRESULT E_IMAPI_ERASE_RECORDER_IN_USE = -2136340224;
	public const HRESULT E_IMAPI_ERASE_ONLY_ONE_RECORDER_SUPPORTED = -2136340223;
	public const HRESULT E_IMAPI_ERASE_DISC_INFORMATION_TOO_SMALL = -2136340222;
	public const HRESULT E_IMAPI_ERASE_MODE_PAGE_2A_TOO_SMALL = -2136340221;
	public const HRESULT E_IMAPI_ERASE_MEDIA_IS_NOT_ERASABLE = -2136340220;
	public const HRESULT E_IMAPI_ERASE_DRIVE_FAILED_ERASE_COMMAND = -2136340219;
	public const HRESULT E_IMAPI_ERASE_TOOK_LONGER_THAN_ONE_HOUR = -2136340218;
	public const HRESULT E_IMAPI_ERASE_UNEXPECTED_DRIVE_RESPONSE_DURING_ERASE = -2136340217;
	public const HRESULT E_IMAPI_ERASE_DRIVE_FAILED_SPINUP_COMMAND = -2136340216;
	public const HRESULT E_IMAPI_ERASE_MEDIA_IS_NOT_SUPPORTED = -1062598391;
	public const HRESULT E_IMAPI_ERASE_RECORDER_NOT_SUPPORTED = -1062598390;
	public const HRESULT E_IMAPI_ERASE_CLIENT_NAME_IS_NOT_VALID = -1062598389;
	public const HRESULT E_IMAPI_RAW_IMAGE_IS_READ_ONLY = -2136339968;
	public const HRESULT E_IMAPI_RAW_IMAGE_TOO_MANY_TRACKS = -2136339967;
	public const HRESULT E_IMAPI_RAW_IMAGE_SECTOR_TYPE_NOT_SUPPORTED = -2136339966;
	public const HRESULT E_IMAPI_RAW_IMAGE_NO_TRACKS = -2136339965;
	public const HRESULT E_IMAPI_RAW_IMAGE_TRACKS_ALREADY_ADDED = -2136339964;
	public const HRESULT E_IMAPI_RAW_IMAGE_INSUFFICIENT_SPACE = -2136339963;
	public const HRESULT E_IMAPI_RAW_IMAGE_TOO_MANY_TRACK_INDEXES = -2136339962;
	public const HRESULT E_IMAPI_RAW_IMAGE_TRACK_INDEX_NOT_FOUND = -2136339961;
	public const HRESULT S_IMAPI_RAW_IMAGE_TRACK_INDEX_ALREADY_EXISTS = 11143688;
	public const HRESULT E_IMAPI_RAW_IMAGE_TRACK_INDEX_OFFSET_ZERO_CANNOT_BE_CLEARED = -2136339959;
	public const HRESULT E_IMAPI_RAW_IMAGE_TRACK_INDEX_TOO_CLOSE_TO_OTHER_INDEX = -2136339958;
	public const uint32 FACILITY_IMAPI2 = 170;
	public const HRESULT IMAPI_E_FSI_INTERNAL_ERROR = -1062555392;
	public const HRESULT IMAPI_E_INVALID_PARAM = -1062555391;
	public const HRESULT IMAPI_E_READONLY = -1062555390;
	public const HRESULT IMAPI_E_NO_OUTPUT = -1062555389;
	public const HRESULT IMAPI_E_INVALID_VOLUME_NAME = -1062555388;
	public const HRESULT IMAPI_E_INVALID_DATE = -1062555387;
	public const HRESULT IMAPI_E_FILE_SYSTEM_NOT_EMPTY = -1062555386;
	public const HRESULT IMAPI_E_NOT_FILE = -1062555384;
	public const HRESULT IMAPI_E_NOT_DIR = -1062555383;
	public const HRESULT IMAPI_E_DIR_NOT_EMPTY = -1062555382;
	public const HRESULT IMAPI_E_NOT_IN_FILE_SYSTEM = -1062555381;
	public const HRESULT IMAPI_E_INVALID_PATH = -1062555376;
	public const HRESULT IMAPI_E_RESTRICTED_NAME_VIOLATION = -1062555375;
	public const HRESULT IMAPI_E_DUP_NAME = -1062555374;
	public const HRESULT IMAPI_E_NO_UNIQUE_NAME = -1062555373;
	public const HRESULT IMAPI_E_ITEM_NOT_FOUND = -1062555368;
	public const HRESULT IMAPI_E_FILE_NOT_FOUND = -1062555367;
	public const HRESULT IMAPI_E_DIR_NOT_FOUND = -1062555366;
	public const HRESULT IMAPI_E_IMAGE_SIZE_LIMIT = -1062555360;
	public const HRESULT IMAPI_E_IMAGE_TOO_BIG = -1062555359;
	public const HRESULT IMAPI_E_DATA_STREAM_INCONSISTENCY = -1062555352;
	public const HRESULT IMAPI_E_DATA_STREAM_READ_FAILURE = -1062555351;
	public const HRESULT IMAPI_E_DATA_STREAM_CREATE_FAILURE = -1062555350;
	public const HRESULT IMAPI_E_DIRECTORY_READ_FAILURE = -1062555349;
	public const HRESULT IMAPI_E_TOO_MANY_DIRS = -1062555344;
	public const HRESULT IMAPI_E_ISO9660_LEVELS = -1062555343;
	public const HRESULT IMAPI_E_DATA_TOO_BIG = -1062555342;
	public const HRESULT IMAPI_E_INCOMPATIBLE_PREVIOUS_SESSION = -1062555341;
	public const HRESULT IMAPI_E_STASHFILE_OPEN_FAILURE = -1062555336;
	public const HRESULT IMAPI_E_STASHFILE_SEEK_FAILURE = -1062555335;
	public const HRESULT IMAPI_E_STASHFILE_WRITE_FAILURE = -1062555334;
	public const HRESULT IMAPI_E_STASHFILE_READ_FAILURE = -1062555333;
	public const HRESULT IMAPI_E_INVALID_WORKING_DIRECTORY = -1062555328;
	public const HRESULT IMAPI_E_WORKING_DIRECTORY_SPACE = -1062555327;
	public const HRESULT IMAPI_E_STASHFILE_MOVE = -1062555326;
	public const HRESULT IMAPI_E_BOOT_IMAGE_DATA = -1062555320;
	public const HRESULT IMAPI_E_BOOT_OBJECT_CONFLICT = -1062555319;
	public const HRESULT IMAPI_E_BOOT_EMULATION_IMAGE_SIZE_MISMATCH = -1062555318;
	public const HRESULT IMAPI_E_EMPTY_DISC = -1062555312;
	public const HRESULT IMAPI_E_NO_SUPPORTED_FILE_SYSTEM = -1062555311;
	public const HRESULT IMAPI_E_FILE_SYSTEM_NOT_FOUND = -1062555310;
	public const HRESULT IMAPI_E_FILE_SYSTEM_READ_CONSISTENCY_ERROR = -1062555309;
	public const HRESULT IMAPI_E_FILE_SYSTEM_FEATURE_NOT_SUPPORTED = -1062555308;
	public const HRESULT IMAPI_E_IMPORT_TYPE_COLLISION_FILE_EXISTS_AS_DIRECTORY = -1062555307;
	public const HRESULT IMAPI_E_IMPORT_SEEK_FAILURE = -1062555306;
	public const HRESULT IMAPI_E_IMPORT_READ_FAILURE = -1062555305;
	public const HRESULT IMAPI_E_DISC_MISMATCH = -1062555304;
	public const HRESULT IMAPI_E_IMPORT_MEDIA_NOT_ALLOWED = -1062555303;
	public const HRESULT IMAPI_E_UDF_NOT_WRITE_COMPATIBLE = -1062555302;
	public const HRESULT IMAPI_E_INCOMPATIBLE_MULTISESSION_TYPE = -1062555301;
	public const HRESULT IMAPI_E_NO_COMPATIBLE_MULTISESSION_TYPE = -1062555300;
	public const HRESULT IMAPI_E_MULTISESSION_NOT_SET = -1062555299;
	public const HRESULT IMAPI_E_IMPORT_TYPE_COLLISION_DIRECTORY_EXISTS_AS_FILE = -1062555298;
	public const HRESULT IMAPI_S_IMAGE_FEATURE_NOT_SUPPORTED = 11186527;
	public const HRESULT IMAPI_E_PROPERTY_NOT_ACCESSIBLE = -1062555296;
	public const HRESULT IMAPI_E_UDF_REVISION_CHANGE_NOT_ALLOWED = -1062555295;
	public const HRESULT IMAPI_E_BAD_MULTISESSION_PARAMETER = -1062555294;
	public const HRESULT IMAPI_E_FILE_SYSTEM_CHANGE_NOT_ALLOWED = -1062555293;
	public const HRESULT IMAPI_E_IMAGEMANAGER_IMAGE_NOT_ALIGNED = -1062555136;
	public const HRESULT IMAPI_E_IMAGEMANAGER_NO_VALID_VD_FOUND = -1062555135;
	public const HRESULT IMAPI_E_IMAGEMANAGER_NO_IMAGE = -1062555134;
	public const HRESULT IMAPI_E_IMAGEMANAGER_IMAGE_TOO_BIG = -1062555133;
	public const int32 MAPI_E_CALL_FAILED = -2147467259;
	public const int32 MAPI_E_NOT_ENOUGH_MEMORY = -2147024882;
	public const int32 MAPI_E_INVALID_PARAMETER = -2147024809;
	public const int32 MAPI_E_INTERFACE_NOT_SUPPORTED = -2147467262;
	public const int32 MAPI_E_NO_ACCESS = -2147024891;
	public const uint32 TAD_ALL_ROWS = 1;
	public const int32 PRILOWEST = -32768;
	public const uint32 PRIHIGHEST = 32767;
	public const uint32 PRIUSER = 0;
	public const String OPENSTREAMONFILE = "OpenStreamOnFile";
	public const String szHrDispatchNotifications = "HrDispatchNotifications";
	public const String szScCreateConversationIndex = "ScCreateConversationIndex";
}
#endregion

#region Enums

[AllowDuplicates]
public enum Gender : int32
{
	genderUnspecified = 0,
	genderFemale = 1,
	genderMale = 2,
}

#endregion

#region Function Pointers
public function int32 LPALLOCATEBUFFER(uint32 cbSize, void** lppBuffer);

public function int32 LPALLOCATEMORE(uint32 cbSize, void* lpObject, void** lppBuffer);

public function uint32 LPFREEBUFFER(void* lpBuffer);

public function int32 LPNOTIFCALLBACK(void* lpvContext, uint32 cNotification, NOTIFICATION* lpNotifications);

public function BOOL LPFNABSDI(uint ulUIParam, void* lpvmsg);

public function void LPFNDISMISS(uint ulUIParam, void* lpvContext);

public function int32 LPFNBUTTON(uint ulUIParam, void* lpvContext, uint32 cbEntryID, ENTRYID* lpSelection, uint32 ulFlags);

public function void CALLERRELEASE(uint32 ulCallerData, ITableData* lpTblData, IMAPITable* lpVue);

public function BOOL PFNIDLE(void* param0);

public function HRESULT LPOPENSTREAMONFILE(LPALLOCATEBUFFER lpAllocateBuffer, LPFREEBUFFER lpFreeBuffer, uint32 ulFlags, int8* lpszFileName, int8* lpszPrefix, IStream** lppStream);

public function HRESULT LPDISPATCHNOTIFICATIONS(uint32 ulFlags);

public function int32 LPCREATECONVERSATIONINDEX(uint32 cbParent, uint8* lpbParent, uint32* lpcbConvIndex, uint8** lppbConvIndex);

public function HRESULT IWABOBJECT_QueryInterface_METHOD(in Guid riid, void** ppvObj);

public function uint32 IWABOBJECT_AddRef_METHOD();

public function uint32 IWABOBJECT_Release_METHOD();

public function HRESULT IWABOBJECT_GetLastError_METHOD(HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError);

public function HRESULT IWABOBJECT_AllocateBuffer_METHOD(uint32 cbSize, void** lppBuffer);

public function HRESULT IWABOBJECT_AllocateMore_METHOD(uint32 cbSize, void* lpObject, void** lppBuffer);

public function HRESULT IWABOBJECT_FreeBuffer_METHOD(void* lpBuffer);

public function HRESULT IWABOBJECT_Backup_METHOD(PSTR lpFileName);

public function HRESULT IWABOBJECT_Import_METHOD(PSTR lpWIP);

public function HRESULT IWABOBJECT_Find_METHOD(IAddrBook* lpIAB, HWND hWnd);

public function HRESULT IWABOBJECT_VCardDisplay_METHOD(IAddrBook* lpIAB, HWND hWnd, PSTR lpszFileName);

public function HRESULT IWABOBJECT_LDAPUrl_METHOD(IAddrBook* lpIAB, HWND hWnd, uint32 ulFlags, PSTR lpszURL, IMailUser** lppMailUser);

public function HRESULT IWABOBJECT_VCardCreate_METHOD(IAddrBook* lpIAB, uint32 ulFlags, PSTR lpszVCard, IMailUser* lpMailUser);

public function HRESULT IWABOBJECT_VCardRetrieve_METHOD(IAddrBook* lpIAB, uint32 ulFlags, PSTR lpszVCard, IMailUser** lppMailUser);

public function HRESULT IWABOBJECT_GetMe_METHOD(IAddrBook* lpIAB, uint32 ulFlags, uint32* lpdwAction, SBinary* lpsbEID, HWND hwnd);

public function HRESULT IWABOBJECT_SetMe_METHOD(IAddrBook* lpIAB, uint32 ulFlags, SBinary sbEID, HWND hwnd);

public function HRESULT LPWABOPEN(IAddrBook** lppAdrBook, IWABObject** lppWABObject, WAB_PARAM* lpWP, uint32 Reserved2);

public function HRESULT LPWABOPENEX(IAddrBook** lppAdrBook, IWABObject** lppWABObject, WAB_PARAM* lpWP, uint32 Reserved, LPALLOCATEBUFFER fnAllocateBuffer, LPALLOCATEMORE fnAllocateMore, LPFREEBUFFER fnFreeBuffer);

public function int32 LPWABALLOCATEBUFFER(IWABObject* lpWABObject, uint32 cbSize, void** lppBuffer);

public function int32 LPWABALLOCATEMORE(IWABObject* lpWABObject, uint32 cbSize, void* lpObject, void** lppBuffer);

public function uint32 LPWABFREEBUFFER(IWABObject* lpWABObject, void* lpBuffer);

#endregion

#region Structs
[CRepr]
public struct ENTRYID
{
	public uint8[4] abFlags;
	public uint8* ab mut => &ab_impl;
	private uint8[ANYSIZE_ARRAY] ab_impl;
}

[CRepr]
public struct MAPIUID
{
	public uint8[16] ab;
}

[CRepr]
public struct SPropTagArray
{
	public uint32 cValues;
	public uint32* aulPropTag mut => &aulPropTag_impl;
	private uint32[ANYSIZE_ARRAY] aulPropTag_impl;
}

[CRepr]
public struct SBinary
{
	public uint32 cb;
	public uint8* lpb;
}

[CRepr]
public struct SShortArray
{
	public uint32 cValues;
	public int16* lpi;
}

[CRepr]
public struct SGuidArray
{
	public uint32 cValues;
	public Guid* lpguid;
}

[CRepr]
public struct SRealArray
{
	public uint32 cValues;
	public float* lpflt;
}

[CRepr]
public struct SLongArray
{
	public uint32 cValues;
	public int32* lpl;
}

[CRepr]
public struct SLargeIntegerArray
{
	public uint32 cValues;
	public LARGE_INTEGER* lpli;
}

[CRepr]
public struct SDateTimeArray
{
	public uint32 cValues;
	public FILETIME* lpft;
}

[CRepr]
public struct SAppTimeArray
{
	public uint32 cValues;
	public double* lpat;
}

[CRepr]
public struct SCurrencyArray
{
	public uint32 cValues;
	public CY* lpcur;
}

[CRepr]
public struct SBinaryArray
{
	public uint32 cValues;
	public SBinary* lpbin;
}

[CRepr]
public struct SDoubleArray
{
	public uint32 cValues;
	public double* lpdbl;
}

[CRepr]
public struct SWStringArray
{
	public uint32 cValues;
	public PWSTR* lppszW;
}

[CRepr]
public struct SLPSTRArray
{
	public uint32 cValues;
	public PSTR* lppszA;
}

[CRepr, Union]
public struct __UPV
{
	public int16 i;
	public int32 l;
	public uint32 ul;
	public float flt;
	public double dbl;
	public uint16 b;
	public CY cur;
	public double at;
	public FILETIME ft;
	public PSTR lpszA;
	public SBinary bin;
	public PWSTR lpszW;
	public Guid* lpguid;
	public LARGE_INTEGER li;
	public SShortArray MVi;
	public SLongArray MVl;
	public SRealArray MVflt;
	public SDoubleArray MVdbl;
	public SCurrencyArray MVcur;
	public SAppTimeArray MVat;
	public SDateTimeArray MVft;
	public SBinaryArray MVbin;
	public SLPSTRArray MVszA;
	public SWStringArray MVszW;
	public SGuidArray MVguid;
	public SLargeIntegerArray MVli;
	public int32 err;
	public int32 x;
}

[CRepr]
public struct SPropValue
{
	public uint32 ulPropTag;
	public uint32 dwAlignPad;
	public __UPV Value;
}

[CRepr]
public struct SPropProblem
{
	public uint32 ulIndex;
	public uint32 ulPropTag;
	public int32 scode;
}

[CRepr]
public struct SPropProblemArray
{
	public uint32 cProblem;
	public SPropProblem* aProblem mut => &aProblem_impl;
	private SPropProblem[ANYSIZE_ARRAY] aProblem_impl;
}

[CRepr]
public struct FLATENTRY
{
	public uint32 cb;
	public uint8* abEntry mut => &abEntry_impl;
	private uint8[ANYSIZE_ARRAY] abEntry_impl;
}

[CRepr]
public struct FLATENTRYLIST
{
	public uint32 cEntries;
	public uint32 cbEntries;
	public uint8* abEntries mut => &abEntries_impl;
	private uint8[ANYSIZE_ARRAY] abEntries_impl;
}

[CRepr]
public struct MTSID
{
	public uint32 cb;
	public uint8* ab mut => &ab_impl;
	private uint8[ANYSIZE_ARRAY] ab_impl;
}

[CRepr]
public struct FLATMTSIDLIST
{
	public uint32 cMTSIDs;
	public uint32 cbMTSIDs;
	public uint8* abMTSIDs mut => &abMTSIDs_impl;
	private uint8[ANYSIZE_ARRAY] abMTSIDs_impl;
}

[CRepr]
public struct ADRENTRY
{
	public uint32 ulReserved1;
	public uint32 cValues;
	public SPropValue* rgPropVals;
}

[CRepr]
public struct ADRLIST
{
	public uint32 cEntries;
	public ADRENTRY* aEntries mut => &aEntries_impl;
	private ADRENTRY[ANYSIZE_ARRAY] aEntries_impl;
}

[CRepr]
public struct SRow
{
	public uint32 ulAdrEntryPad;
	public uint32 cValues;
	public SPropValue* lpProps;
}

[CRepr]
public struct SRowSet
{
	public uint32 cRows;
	public SRow* aRow mut => &aRow_impl;
	private SRow[ANYSIZE_ARRAY] aRow_impl;
}

[CRepr]
public struct MAPIERROR
{
	public uint32 ulVersion;
	public int8* lpszError;
	public int8* lpszComponent;
	public uint32 ulLowLevelError;
	public uint32 ulContext;
}

[CRepr]
public struct ERROR_NOTIFICATION
{
	public uint32 cbEntryID;
	public ENTRYID* lpEntryID;
	public int32 scode;
	public uint32 ulFlags;
	public MAPIERROR* lpMAPIError;
}

[CRepr]
public struct NEWMAIL_NOTIFICATION
{
	public uint32 cbEntryID;
	public ENTRYID* lpEntryID;
	public uint32 cbParentID;
	public ENTRYID* lpParentID;
	public uint32 ulFlags;
	public int8* lpszMessageClass;
	public uint32 ulMessageFlags;
}

[CRepr]
public struct OBJECT_NOTIFICATION
{
	public uint32 cbEntryID;
	public ENTRYID* lpEntryID;
	public uint32 ulObjType;
	public uint32 cbParentID;
	public ENTRYID* lpParentID;
	public uint32 cbOldID;
	public ENTRYID* lpOldID;
	public uint32 cbOldParentID;
	public ENTRYID* lpOldParentID;
	public SPropTagArray* lpPropTagArray;
}

[CRepr]
public struct TABLE_NOTIFICATION
{
	public uint32 ulTableEvent;
	public HRESULT hResult;
	public SPropValue propIndex;
	public SPropValue propPrior;
	public SRow row;
	public uint32 ulPad;
}

[CRepr]
public struct EXTENDED_NOTIFICATION
{
	public uint32 ulEvent;
	public uint32 cb;
	public uint8* pbEventParameters;
}

[CRepr]
public struct STATUS_OBJECT_NOTIFICATION
{
	public uint32 cbEntryID;
	public ENTRYID* lpEntryID;
	public uint32 cValues;
	public SPropValue* lpPropVals;
}

[CRepr]
public struct NOTIFICATION
{
	[CRepr, Union]
	public struct _info_e__Union
	{
		public ERROR_NOTIFICATION err;
		public NEWMAIL_NOTIFICATION newmail;
		public OBJECT_NOTIFICATION obj;
		public TABLE_NOTIFICATION tab;
		public EXTENDED_NOTIFICATION ext;
		public STATUS_OBJECT_NOTIFICATION statobj;
	}
	public uint32 ulEventType;
	public uint32 ulAlignPad;
	public _info_e__Union info;
}

[CRepr]
public struct MAPINAMEID
{
	[CRepr, Union]
	public struct _Kind_e__Union
	{
		public int32 lID;
		public PWSTR lpwstrName;
	}
	public Guid* lpguid;
	public uint32 ulKind;
	public _Kind_e__Union Kind;
}

[CRepr]
public struct SSortOrder
{
	public uint32 ulPropTag;
	public uint32 ulOrder;
}

[CRepr]
public struct SSortOrderSet
{
	public uint32 cSorts;
	public uint32 cCategories;
	public uint32 cExpanded;
	public SSortOrder* aSort mut => &aSort_impl;
	private SSortOrder[ANYSIZE_ARRAY] aSort_impl;
}

[CRepr]
public struct SAndRestriction
{
	public uint32 cRes;
	public SRestriction* lpRes;
}

[CRepr]
public struct SOrRestriction
{
	public uint32 cRes;
	public SRestriction* lpRes;
}

[CRepr]
public struct SNotRestriction
{
	public uint32 ulReserved;
	public SRestriction* lpRes;
}

[CRepr]
public struct SContentRestriction
{
	public uint32 ulFuzzyLevel;
	public uint32 ulPropTag;
	public SPropValue* lpProp;
}

[CRepr]
public struct SBitMaskRestriction
{
	public uint32 relBMR;
	public uint32 ulPropTag;
	public uint32 ulMask;
}

[CRepr]
public struct SPropertyRestriction
{
	public uint32 relop;
	public uint32 ulPropTag;
	public SPropValue* lpProp;
}

[CRepr]
public struct SComparePropsRestriction
{
	public uint32 relop;
	public uint32 ulPropTag1;
	public uint32 ulPropTag2;
}

[CRepr]
public struct SSizeRestriction
{
	public uint32 relop;
	public uint32 ulPropTag;
	public uint32 cb;
}

[CRepr]
public struct SExistRestriction
{
	public uint32 ulReserved1;
	public uint32 ulPropTag;
	public uint32 ulReserved2;
}

[CRepr]
public struct SSubRestriction
{
	public uint32 ulSubObject;
	public SRestriction* lpRes;
}

[CRepr]
public struct SCommentRestriction
{
	public uint32 cValues;
	public SRestriction* lpRes;
	public SPropValue* lpProp;
}

[CRepr]
public struct SRestriction
{
	[CRepr, Union]
	public struct _res_e__Union
	{
		public SComparePropsRestriction resCompareProps;
		public SAndRestriction resAnd;
		public SOrRestriction resOr;
		public SNotRestriction resNot;
		public SContentRestriction resContent;
		public SPropertyRestriction resProperty;
		public SBitMaskRestriction resBitMask;
		public SSizeRestriction resSize;
		public SExistRestriction resExist;
		public SSubRestriction resSub;
		public SCommentRestriction resComment;
	}
	public uint32 rt;
	public _res_e__Union res;
}

[CRepr]
public struct FlagList
{
	public uint32 cFlags;
	public uint32* ulFlag mut => &ulFlag_impl;
	private uint32[ANYSIZE_ARRAY] ulFlag_impl;
}

[CRepr]
public struct ADRPARM
{
	public uint32 cbABContEntryID;
	public ENTRYID* lpABContEntryID;
	public uint32 ulFlags;
	public void* lpReserved;
	public uint32 ulHelpContext;
	public int8* lpszHelpFileName;
	public LPFNABSDI lpfnABSDI;
	public LPFNDISMISS lpfnDismiss;
	public void* lpvDismissContext;
	public int8* lpszCaption;
	public int8* lpszNewEntryTitle;
	public int8* lpszDestWellsTitle;
	public uint32 cDestFields;
	public uint32 nDestFieldFocus;
	public int8** lppszDestTitles;
	public uint32* lpulDestComps;
	public SRestriction* lpContRestriction;
	public SRestriction* lpHierRestriction;
}

[CRepr]
public struct DTBLLABEL
{
	public uint32 ulbLpszLabelName;
	public uint32 ulFlags;
}

[CRepr]
public struct DTBLEDIT
{
	public uint32 ulbLpszCharsAllowed;
	public uint32 ulFlags;
	public uint32 ulNumCharsAllowed;
	public uint32 ulPropTag;
}

[CRepr]
public struct DTBLLBX
{
	public uint32 ulFlags;
	public uint32 ulPRSetProperty;
	public uint32 ulPRTableName;
}

[CRepr]
public struct DTBLCOMBOBOX
{
	public uint32 ulbLpszCharsAllowed;
	public uint32 ulFlags;
	public uint32 ulNumCharsAllowed;
	public uint32 ulPRPropertyName;
	public uint32 ulPRTableName;
}

[CRepr]
public struct DTBLDDLBX
{
	public uint32 ulFlags;
	public uint32 ulPRDisplayProperty;
	public uint32 ulPRSetProperty;
	public uint32 ulPRTableName;
}

[CRepr]
public struct DTBLCHECKBOX
{
	public uint32 ulbLpszLabel;
	public uint32 ulFlags;
	public uint32 ulPRPropertyName;
}

[CRepr]
public struct DTBLGROUPBOX
{
	public uint32 ulbLpszLabel;
	public uint32 ulFlags;
}

[CRepr]
public struct DTBLBUTTON
{
	public uint32 ulbLpszLabel;
	public uint32 ulFlags;
	public uint32 ulPRControl;
}

[CRepr]
public struct DTBLPAGE
{
	public uint32 ulbLpszLabel;
	public uint32 ulFlags;
	public uint32 ulbLpszComponent;
	public uint32 ulContext;
}

[CRepr]
public struct DTBLRADIOBUTTON
{
	public uint32 ulbLpszLabel;
	public uint32 ulFlags;
	public uint32 ulcButtons;
	public uint32 ulPropTag;
	public int32 lReturnValue;
}

[CRepr]
public struct DTBLMVLISTBOX
{
	public uint32 ulFlags;
	public uint32 ulMVPropTag;
}

[CRepr]
public struct DTBLMVDDLBX
{
	public uint32 ulFlags;
	public uint32 ulMVPropTag;
}

[CRepr]
public struct DTCTL
{
	[CRepr, Union]
	public struct _ctl_e__Union
	{
		public void* lpv;
		public DTBLLABEL* lplabel;
		public DTBLEDIT* lpedit;
		public DTBLLBX* lplbx;
		public DTBLCOMBOBOX* lpcombobox;
		public DTBLDDLBX* lpddlbx;
		public DTBLCHECKBOX* lpcheckbox;
		public DTBLGROUPBOX* lpgroupbox;
		public DTBLBUTTON* lpbutton;
		public DTBLRADIOBUTTON* lpradiobutton;
		public DTBLMVLISTBOX* lpmvlbx;
		public DTBLMVDDLBX* lpmvddlbx;
		public DTBLPAGE* lppage;
	}
	public uint32 ulCtlType;
	public uint32 ulCtlFlags;
	public uint8* lpbNotif;
	public uint32 cbNotif;
	public int8* lpszFilter;
	public uint32 ulItemID;
	public _ctl_e__Union ctl;
}

[CRepr]
public struct DTPAGE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public int8* lpszComponent;
		public uint32 ulItemID;
	}
	public uint32 cctl;
	public int8* lpszResourceName;
	public using _Anonymous_e__Union Anonymous;
	public DTCTL* lpctl;
}

[CRepr]
public struct _WABACTIONITEM
{
}

[CRepr]
public struct WAB_PARAM
{
	public uint32 cbSize;
	public HWND hwnd;
	public PSTR szFileName;
	public uint32 ulFlags;
	public Guid guidPSExt;
}

[CRepr]
public struct WABIMPORTPARAM
{
	public uint32 cbSize;
	public IAddrBook* lpAdrBook;
	public HWND hWnd;
	public uint32 ulFlags;
	public PSTR lpszFileName;
}

[CRepr]
public struct WABEXTDISPLAY
{
	public uint32 cbSize;
	public IWABObject* lpWABObject;
	public IAddrBook* lpAdrBook;
	public IMAPIProp* lpPropObj;
	public BOOL fReadOnly;
	public BOOL fDataChanged;
	public uint32 ulFlags;
	public void* lpv;
	public int8* lpsz;
}

[CRepr]
public struct NOTIFKEY
{
	public uint32 cb;
	public uint8* ab mut => &ab_impl;
	private uint8[ANYSIZE_ARRAY] ab_impl;
}

#endregion

#region COM Types
[CRepr]struct IMAPIAdviseSink : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, uint32 cNotif, NOTIFICATION* lpNotifications) OnNotify;
	}


	public uint32 OnNotify(uint32 cNotif, NOTIFICATION* lpNotifications) mut => VT.[Friend]OnNotify(&this, cNotif, lpNotifications);
}

[CRepr]struct IMAPIProgress : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulValue, uint32 ulCount, uint32 ulTotal) Progress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpulFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpulMax) GetMax;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpulMin) GetMin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpulMin, uint32* lpulMax, uint32* lpulFlags) SetLimits;
	}


	public HRESULT Progress(uint32 ulValue, uint32 ulCount, uint32 ulTotal) mut => VT.[Friend]Progress(&this, ulValue, ulCount, ulTotal);

	public HRESULT GetFlags(uint32* lpulFlags) mut => VT.[Friend]COM_GetFlags(&this, lpulFlags);

	public HRESULT GetMax(uint32* lpulMax) mut => VT.[Friend]GetMax(&this, lpulMax);

	public HRESULT GetMin(uint32* lpulMin) mut => VT.[Friend]GetMin(&this, lpulMin);

	public HRESULT SetLimits(uint32* lpulMin, uint32* lpulMax, uint32* lpulFlags) mut => VT.[Friend]SetLimits(&this, lpulMin, lpulMax, lpulFlags);
}

[CRepr]struct IMAPIProp : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) GetLastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags) SaveChanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropTagArray* lpPropTagArray, uint32 ulFlags, uint32* lpcValues, SPropValue** lppPropArray) GetProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, SPropTagArray** lppPropTagArray) GetPropList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulPropTag, Guid* lpiid, uint32 ulInterfaceOptions, uint32 ulFlags, IUnknown** lppUnk) OpenProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cValues, SPropValue* lpPropArray, SPropProblemArray** lppProblems) SetProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropTagArray* lpPropTagArray, SPropProblemArray** lppProblems) DeleteProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ciidExclude, Guid* rgiidExclude, SPropTagArray* lpExcludeProps, uint ulUIParam, IMAPIProgress* lpProgress, Guid* lpInterface, void* lpDestObj, uint32 ulFlags, SPropProblemArray** lppProblems) CopyTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropTagArray* lpIncludeProps, uint ulUIParam, IMAPIProgress* lpProgress, Guid* lpInterface, void* lpDestObj, uint32 ulFlags, SPropProblemArray** lppProblems) CopyProps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropTagArray** lppPropTags, Guid* lpPropSetGuid, uint32 ulFlags, uint32* lpcPropNames, MAPINAMEID*** lpppPropNames) GetNamesFromIDs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cPropNames, MAPINAMEID** lppPropNames, uint32 ulFlags, SPropTagArray** lppPropTags) GetIDsFromNames;
	}


	public HRESULT GetLastError(HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) mut => VT.[Friend]GetLastError(&this, hResult, ulFlags, lppMAPIError);

	public HRESULT SaveChanges(uint32 ulFlags) mut => VT.[Friend]SaveChanges(&this, ulFlags);

	public HRESULT GetProps(SPropTagArray* lpPropTagArray, uint32 ulFlags, uint32* lpcValues, SPropValue** lppPropArray) mut => VT.[Friend]GetProps(&this, lpPropTagArray, ulFlags, lpcValues, lppPropArray);

	public HRESULT GetPropList(uint32 ulFlags, SPropTagArray** lppPropTagArray) mut => VT.[Friend]GetPropList(&this, ulFlags, lppPropTagArray);

	public HRESULT OpenProperty(uint32 ulPropTag, Guid* lpiid, uint32 ulInterfaceOptions, uint32 ulFlags, IUnknown** lppUnk) mut => VT.[Friend]OpenProperty(&this, ulPropTag, lpiid, ulInterfaceOptions, ulFlags, lppUnk);

	public HRESULT SetProps(uint32 cValues, SPropValue* lpPropArray, SPropProblemArray** lppProblems) mut => VT.[Friend]SetProps(&this, cValues, lpPropArray, lppProblems);

	public HRESULT DeleteProps(SPropTagArray* lpPropTagArray, SPropProblemArray** lppProblems) mut => VT.[Friend]DeleteProps(&this, lpPropTagArray, lppProblems);

	public HRESULT CopyTo(uint32 ciidExclude, Guid* rgiidExclude, SPropTagArray* lpExcludeProps, uint ulUIParam, IMAPIProgress* lpProgress, Guid* lpInterface, void* lpDestObj, uint32 ulFlags, SPropProblemArray** lppProblems) mut => VT.[Friend]CopyTo(&this, ciidExclude, rgiidExclude, lpExcludeProps, ulUIParam, lpProgress, lpInterface, lpDestObj, ulFlags, lppProblems);

	public HRESULT CopyProps(SPropTagArray* lpIncludeProps, uint ulUIParam, IMAPIProgress* lpProgress, Guid* lpInterface, void* lpDestObj, uint32 ulFlags, SPropProblemArray** lppProblems) mut => VT.[Friend]CopyProps(&this, lpIncludeProps, ulUIParam, lpProgress, lpInterface, lpDestObj, ulFlags, lppProblems);

	public HRESULT GetNamesFromIDs(SPropTagArray** lppPropTags, Guid* lpPropSetGuid, uint32 ulFlags, uint32* lpcPropNames, MAPINAMEID*** lpppPropNames) mut => VT.[Friend]GetNamesFromIDs(&this, lppPropTags, lpPropSetGuid, ulFlags, lpcPropNames, lpppPropNames);

	public HRESULT GetIDsFromNames(uint32 cPropNames, MAPINAMEID** lppPropNames, uint32 ulFlags, SPropTagArray** lppPropTags) mut => VT.[Friend]GetIDsFromNames(&this, cPropNames, lppPropNames, ulFlags, lppPropTags);
}

[CRepr]struct IMAPITable : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) GetLastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulEventMask, IMAPIAdviseSink* lpAdviseSink, uint32* lpulConnection) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulConnection) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpulTableStatus, uint32* lpulTableType) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropTagArray* lpPropTagArray, uint32 ulFlags) SetColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, SPropTagArray** lpPropTagArray) QueryColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, uint32* lpulCount) GetRowCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 bkOrigin, int32 lRowCount, int32* lplRowsSought) SeekRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulNumerator, uint32 ulDenominator) SeekRowApprox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpulRow, uint32* lpulNumerator, uint32* lpulDenominator) QueryPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SRestriction* lpRestriction, uint32 bkOrigin, uint32 ulFlags) FindRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SRestriction* lpRestriction, uint32 ulFlags) Restrict;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpbkPosition) CreateBookmark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 bkPosition) FreeBookmark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SSortOrderSet* lpSortCriteria, uint32 ulFlags) SortTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SSortOrderSet** lppSortCriteria) QuerySortOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRowCount, uint32 ulFlags, SRowSet** lppRows) QueryRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbInstanceKey, uint8* pbInstanceKey, uint32 ulRowCount, uint32 ulFlags, SRowSet** lppRows, uint32* lpulMoreRows) ExpandRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbInstanceKey, uint8* pbInstanceKey, uint32 ulFlags, uint32* lpulRowCount) CollapseRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, uint32 ulTimeout, uint32* lpulTableStatus) WaitForCompletion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, uint32 cbInstanceKey, uint8* lpbInstanceKey, uint32* lpcbCollapseState, uint8** lppbCollapseState) GetCollapseState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, uint32 cbCollapseState, uint8* pbCollapseState, uint32* lpbkLocation) SetCollapseState;
	}


	public HRESULT GetLastError(HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) mut => VT.[Friend]GetLastError(&this, hResult, ulFlags, lppMAPIError);

	public HRESULT Advise(uint32 ulEventMask, IMAPIAdviseSink* lpAdviseSink, uint32* lpulConnection) mut => VT.[Friend]Advise(&this, ulEventMask, lpAdviseSink, lpulConnection);

	public HRESULT Unadvise(uint32 ulConnection) mut => VT.[Friend]Unadvise(&this, ulConnection);

	public HRESULT GetStatus(uint32* lpulTableStatus, uint32* lpulTableType) mut => VT.[Friend]GetStatus(&this, lpulTableStatus, lpulTableType);

	public HRESULT SetColumns(SPropTagArray* lpPropTagArray, uint32 ulFlags) mut => VT.[Friend]SetColumns(&this, lpPropTagArray, ulFlags);

	public HRESULT QueryColumns(uint32 ulFlags, SPropTagArray** lpPropTagArray) mut => VT.[Friend]QueryColumns(&this, ulFlags, lpPropTagArray);

	public HRESULT GetRowCount(uint32 ulFlags, uint32* lpulCount) mut => VT.[Friend]GetRowCount(&this, ulFlags, lpulCount);

	public HRESULT SeekRow(uint32 bkOrigin, int32 lRowCount, int32* lplRowsSought) mut => VT.[Friend]SeekRow(&this, bkOrigin, lRowCount, lplRowsSought);

	public HRESULT SeekRowApprox(uint32 ulNumerator, uint32 ulDenominator) mut => VT.[Friend]SeekRowApprox(&this, ulNumerator, ulDenominator);

	public HRESULT QueryPosition(uint32* lpulRow, uint32* lpulNumerator, uint32* lpulDenominator) mut => VT.[Friend]QueryPosition(&this, lpulRow, lpulNumerator, lpulDenominator);

	public HRESULT FindRow(SRestriction* lpRestriction, uint32 bkOrigin, uint32 ulFlags) mut => VT.[Friend]FindRow(&this, lpRestriction, bkOrigin, ulFlags);

	public HRESULT Restrict(SRestriction* lpRestriction, uint32 ulFlags) mut => VT.[Friend]Restrict(&this, lpRestriction, ulFlags);

	public HRESULT CreateBookmark(uint32* lpbkPosition) mut => VT.[Friend]CreateBookmark(&this, lpbkPosition);

	public HRESULT FreeBookmark(uint32 bkPosition) mut => VT.[Friend]FreeBookmark(&this, bkPosition);

	public HRESULT SortTable(SSortOrderSet* lpSortCriteria, uint32 ulFlags) mut => VT.[Friend]SortTable(&this, lpSortCriteria, ulFlags);

	public HRESULT QuerySortOrder(SSortOrderSet** lppSortCriteria) mut => VT.[Friend]QuerySortOrder(&this, lppSortCriteria);

	public HRESULT QueryRows(int32 lRowCount, uint32 ulFlags, SRowSet** lppRows) mut => VT.[Friend]QueryRows(&this, lRowCount, ulFlags, lppRows);

	public HRESULT Abort() mut => VT.[Friend]Abort(&this);

	public HRESULT ExpandRow(uint32 cbInstanceKey, uint8* pbInstanceKey, uint32 ulRowCount, uint32 ulFlags, SRowSet** lppRows, uint32* lpulMoreRows) mut => VT.[Friend]ExpandRow(&this, cbInstanceKey, pbInstanceKey, ulRowCount, ulFlags, lppRows, lpulMoreRows);

	public HRESULT CollapseRow(uint32 cbInstanceKey, uint8* pbInstanceKey, uint32 ulFlags, uint32* lpulRowCount) mut => VT.[Friend]CollapseRow(&this, cbInstanceKey, pbInstanceKey, ulFlags, lpulRowCount);

	public HRESULT WaitForCompletion(uint32 ulFlags, uint32 ulTimeout, uint32* lpulTableStatus) mut => VT.[Friend]WaitForCompletion(&this, ulFlags, ulTimeout, lpulTableStatus);

	public HRESULT GetCollapseState(uint32 ulFlags, uint32 cbInstanceKey, uint8* lpbInstanceKey, uint32* lpcbCollapseState, uint8** lppbCollapseState) mut => VT.[Friend]GetCollapseState(&this, ulFlags, cbInstanceKey, lpbInstanceKey, lpcbCollapseState, lppbCollapseState);

	public HRESULT SetCollapseState(uint32 ulFlags, uint32 cbCollapseState, uint8* pbCollapseState, uint32* lpbkLocation) mut => VT.[Friend]SetCollapseState(&this, ulFlags, cbCollapseState, pbCollapseState, lpbkLocation);
}

[CRepr]struct IProfSect : IMAPIProp
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIProp.VTable
	{
	}

}

[CRepr]struct IMAPIStatus : IMAPIProp
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIProp.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ulUIParam, uint32 ulFlags) ValidateState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ulUIParam, uint32 ulFlags) SettingsDialog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int8* lpOldPass, int8* lpNewPass, uint32 ulFlags) ChangePassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ulUIParam, uint32 cbTargetTransport, ENTRYID* lpTargetTransport, uint32 ulFlags) FlushQueues;
	}


	public HRESULT ValidateState(uint ulUIParam, uint32 ulFlags) mut => VT.[Friend]ValidateState(&this, ulUIParam, ulFlags);

	public HRESULT SettingsDialog(uint ulUIParam, uint32 ulFlags) mut => VT.[Friend]SettingsDialog(&this, ulUIParam, ulFlags);

	public HRESULT ChangePassword(int8* lpOldPass, int8* lpNewPass, uint32 ulFlags) mut => VT.[Friend]ChangePassword(&this, lpOldPass, lpNewPass, ulFlags);

	public HRESULT FlushQueues(uint ulUIParam, uint32 cbTargetTransport, ENTRYID* lpTargetTransport, uint32 ulFlags) mut => VT.[Friend]FlushQueues(&this, ulUIParam, cbTargetTransport, lpTargetTransport, ulFlags);
}

[CRepr]struct IMAPIContainer : IMAPIProp
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIProp.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, IMAPITable** lppTable) GetContentsTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, IMAPITable** lppTable) GetHierarchyTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, Guid* lpInterface, uint32 ulFlags, uint32* lpulObjType, IUnknown** lppUnk) OpenEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SRestriction* lpRestriction, SBinaryArray* lpContainerList, uint32 ulSearchFlags) SetSearchCriteria;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, SRestriction** lppRestriction, SBinaryArray** lppContainerList, uint32* lpulSearchState) GetSearchCriteria;
	}


	public HRESULT GetContentsTable(uint32 ulFlags, IMAPITable** lppTable) mut => VT.[Friend]GetContentsTable(&this, ulFlags, lppTable);

	public HRESULT GetHierarchyTable(uint32 ulFlags, IMAPITable** lppTable) mut => VT.[Friend]GetHierarchyTable(&this, ulFlags, lppTable);

	public HRESULT OpenEntry(uint32 cbEntryID, ENTRYID* lpEntryID, Guid* lpInterface, uint32 ulFlags, uint32* lpulObjType, IUnknown** lppUnk) mut => VT.[Friend]OpenEntry(&this, cbEntryID, lpEntryID, lpInterface, ulFlags, lpulObjType, lppUnk);

	public HRESULT SetSearchCriteria(SRestriction* lpRestriction, SBinaryArray* lpContainerList, uint32 ulSearchFlags) mut => VT.[Friend]SetSearchCriteria(&this, lpRestriction, lpContainerList, ulSearchFlags);

	public HRESULT GetSearchCriteria(uint32 ulFlags, SRestriction** lppRestriction, SBinaryArray** lppContainerList, uint32* lpulSearchState) mut => VT.[Friend]GetSearchCriteria(&this, ulFlags, lppRestriction, lppContainerList, lpulSearchState);
}

[CRepr]struct IABContainer : IMAPIContainer
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIContainer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulCreateFlags, IMAPIProp** lppMAPIPropEntry) CreateEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SBinaryArray* lpEntries, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) CopyEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SBinaryArray* lpEntries, uint32 ulFlags) DeleteEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropTagArray* lpPropTagArray, uint32 ulFlags, ADRLIST* lpAdrList, FlagList* lpFlagList) ResolveNames;
	}


	public HRESULT CreateEntry(uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulCreateFlags, IMAPIProp** lppMAPIPropEntry) mut => VT.[Friend]CreateEntry(&this, cbEntryID, lpEntryID, ulCreateFlags, lppMAPIPropEntry);

	public HRESULT CopyEntries(SBinaryArray* lpEntries, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) mut => VT.[Friend]CopyEntries(&this, lpEntries, ulUIParam, lpProgress, ulFlags);

	public HRESULT DeleteEntries(SBinaryArray* lpEntries, uint32 ulFlags) mut => VT.[Friend]DeleteEntries(&this, lpEntries, ulFlags);

	public HRESULT ResolveNames(SPropTagArray* lpPropTagArray, uint32 ulFlags, ADRLIST* lpAdrList, FlagList* lpFlagList) mut => VT.[Friend]ResolveNames(&this, lpPropTagArray, ulFlags, lpAdrList, lpFlagList);
}

[CRepr]struct IMailUser : IMAPIProp
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIProp.VTable
	{
	}

}

[CRepr]struct IDistList : IMAPIContainer
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIContainer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulCreateFlags, IMAPIProp** lppMAPIPropEntry) CreateEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SBinaryArray* lpEntries, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) CopyEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SBinaryArray* lpEntries, uint32 ulFlags) DeleteEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropTagArray* lpPropTagArray, uint32 ulFlags, ADRLIST* lpAdrList, FlagList* lpFlagList) ResolveNames;
	}


	public HRESULT CreateEntry(uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulCreateFlags, IMAPIProp** lppMAPIPropEntry) mut => VT.[Friend]CreateEntry(&this, cbEntryID, lpEntryID, ulCreateFlags, lppMAPIPropEntry);

	public HRESULT CopyEntries(SBinaryArray* lpEntries, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) mut => VT.[Friend]CopyEntries(&this, lpEntries, ulUIParam, lpProgress, ulFlags);

	public HRESULT DeleteEntries(SBinaryArray* lpEntries, uint32 ulFlags) mut => VT.[Friend]DeleteEntries(&this, lpEntries, ulFlags);

	public HRESULT ResolveNames(SPropTagArray* lpPropTagArray, uint32 ulFlags, ADRLIST* lpAdrList, FlagList* lpFlagList) mut => VT.[Friend]ResolveNames(&this, lpPropTagArray, ulFlags, lpAdrList, lpFlagList);
}

[CRepr]struct IMAPIFolder : IMAPIContainer
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIContainer.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* lpInterface, uint32 ulFlags, IMessage** lppMessage) CreateMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SBinaryArray* lpMsgList, Guid* lpInterface, void* lpDestFolder, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) CopyMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SBinaryArray* lpMsgList, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) DeleteMessages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFolderType, int8* lpszFolderName, int8* lpszFolderComment, Guid* lpInterface, uint32 ulFlags, IMAPIFolder** lppFolder) CreateFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, Guid* lpInterface, void* lpDestFolder, int8* lpszNewFolderName, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) CopyFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) DeleteFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SBinaryArray* lpMsgList, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) SetReadFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulFlags, uint32* lpulMessageStatus) GetMessageStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulNewStatus, uint32 ulNewStatusMask, uint32* lpulOldStatus) SetMessageStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SSortOrderSet* lpSortCriteria, uint32 ulFlags) SaveContentsSort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) EmptyFolder;
	}


	public HRESULT CreateMessage(Guid* lpInterface, uint32 ulFlags, IMessage** lppMessage) mut => VT.[Friend]CreateMessage(&this, lpInterface, ulFlags, lppMessage);

	public HRESULT CopyMessages(SBinaryArray* lpMsgList, Guid* lpInterface, void* lpDestFolder, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) mut => VT.[Friend]CopyMessages(&this, lpMsgList, lpInterface, lpDestFolder, ulUIParam, lpProgress, ulFlags);

	public HRESULT DeleteMessages(SBinaryArray* lpMsgList, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) mut => VT.[Friend]DeleteMessages(&this, lpMsgList, ulUIParam, lpProgress, ulFlags);

	public HRESULT CreateFolder(uint32 ulFolderType, int8* lpszFolderName, int8* lpszFolderComment, Guid* lpInterface, uint32 ulFlags, IMAPIFolder** lppFolder) mut => VT.[Friend]CreateFolder(&this, ulFolderType, lpszFolderName, lpszFolderComment, lpInterface, ulFlags, lppFolder);

	public HRESULT CopyFolder(uint32 cbEntryID, ENTRYID* lpEntryID, Guid* lpInterface, void* lpDestFolder, int8* lpszNewFolderName, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) mut => VT.[Friend]CopyFolder(&this, cbEntryID, lpEntryID, lpInterface, lpDestFolder, lpszNewFolderName, ulUIParam, lpProgress, ulFlags);

	public HRESULT DeleteFolder(uint32 cbEntryID, ENTRYID* lpEntryID, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) mut => VT.[Friend]DeleteFolder(&this, cbEntryID, lpEntryID, ulUIParam, lpProgress, ulFlags);

	public HRESULT SetReadFlags(SBinaryArray* lpMsgList, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) mut => VT.[Friend]SetReadFlags(&this, lpMsgList, ulUIParam, lpProgress, ulFlags);

	public HRESULT GetMessageStatus(uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulFlags, uint32* lpulMessageStatus) mut => VT.[Friend]GetMessageStatus(&this, cbEntryID, lpEntryID, ulFlags, lpulMessageStatus);

	public HRESULT SetMessageStatus(uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulNewStatus, uint32 ulNewStatusMask, uint32* lpulOldStatus) mut => VT.[Friend]SetMessageStatus(&this, cbEntryID, lpEntryID, ulNewStatus, ulNewStatusMask, lpulOldStatus);

	public HRESULT SaveContentsSort(SSortOrderSet* lpSortCriteria, uint32 ulFlags) mut => VT.[Friend]SaveContentsSort(&this, lpSortCriteria, ulFlags);

	public HRESULT EmptyFolder(uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) mut => VT.[Friend]EmptyFolder(&this, ulUIParam, lpProgress, ulFlags);
}

[CRepr]struct IMsgStore : IMAPIProp
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIProp.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulEventMask, IMAPIAdviseSink* lpAdviseSink, uint32* lpulConnection) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulConnection) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID1, ENTRYID* lpEntryID1, uint32 cbEntryID2, ENTRYID* lpEntryID2, uint32 ulFlags, uint32* lpulResult) CompareEntryIDs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, Guid* lpInterface, uint32 ulFlags, uint32* lpulObjType, IUnknown** ppUnk) OpenEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int8* lpszMessageClass, uint32 ulFlags, uint32 cbEntryID, ENTRYID* lpEntryID) SetReceiveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int8* lpszMessageClass, uint32 ulFlags, uint32* lpcbEntryID, ENTRYID** lppEntryID, int8** lppszExplicitClass) GetReceiveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, IMAPITable** lppTable) GetReceiveFolderTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpulFlags) StoreLogoff;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulFlags) AbortSubmit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, IMAPITable** lppTable) GetOutgoingQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMessage* lpMessage, uint32 ulLockState) SetLockState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, uint32 cbEntryID, ENTRYID* lpEntryID) FinishedMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NOTIFICATION* lpNotification) NotifyNewMail;
	}


	public HRESULT Advise(uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulEventMask, IMAPIAdviseSink* lpAdviseSink, uint32* lpulConnection) mut => VT.[Friend]Advise(&this, cbEntryID, lpEntryID, ulEventMask, lpAdviseSink, lpulConnection);

	public HRESULT Unadvise(uint32 ulConnection) mut => VT.[Friend]Unadvise(&this, ulConnection);

	public HRESULT CompareEntryIDs(uint32 cbEntryID1, ENTRYID* lpEntryID1, uint32 cbEntryID2, ENTRYID* lpEntryID2, uint32 ulFlags, uint32* lpulResult) mut => VT.[Friend]CompareEntryIDs(&this, cbEntryID1, lpEntryID1, cbEntryID2, lpEntryID2, ulFlags, lpulResult);

	public HRESULT OpenEntry(uint32 cbEntryID, ENTRYID* lpEntryID, Guid* lpInterface, uint32 ulFlags, uint32* lpulObjType, IUnknown** ppUnk) mut => VT.[Friend]OpenEntry(&this, cbEntryID, lpEntryID, lpInterface, ulFlags, lpulObjType, ppUnk);

	public HRESULT SetReceiveFolder(int8* lpszMessageClass, uint32 ulFlags, uint32 cbEntryID, ENTRYID* lpEntryID) mut => VT.[Friend]SetReceiveFolder(&this, lpszMessageClass, ulFlags, cbEntryID, lpEntryID);

	public HRESULT GetReceiveFolder(int8* lpszMessageClass, uint32 ulFlags, uint32* lpcbEntryID, ENTRYID** lppEntryID, int8** lppszExplicitClass) mut => VT.[Friend]GetReceiveFolder(&this, lpszMessageClass, ulFlags, lpcbEntryID, lppEntryID, lppszExplicitClass);

	public HRESULT GetReceiveFolderTable(uint32 ulFlags, IMAPITable** lppTable) mut => VT.[Friend]GetReceiveFolderTable(&this, ulFlags, lppTable);

	public HRESULT StoreLogoff(uint32* lpulFlags) mut => VT.[Friend]StoreLogoff(&this, lpulFlags);

	public HRESULT AbortSubmit(uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulFlags) mut => VT.[Friend]AbortSubmit(&this, cbEntryID, lpEntryID, ulFlags);

	public HRESULT GetOutgoingQueue(uint32 ulFlags, IMAPITable** lppTable) mut => VT.[Friend]GetOutgoingQueue(&this, ulFlags, lppTable);

	public HRESULT SetLockState(IMessage* lpMessage, uint32 ulLockState) mut => VT.[Friend]SetLockState(&this, lpMessage, ulLockState);

	public HRESULT FinishedMsg(uint32 ulFlags, uint32 cbEntryID, ENTRYID* lpEntryID) mut => VT.[Friend]FinishedMsg(&this, ulFlags, cbEntryID, lpEntryID);

	public HRESULT NotifyNewMail(NOTIFICATION* lpNotification) mut => VT.[Friend]NotifyNewMail(&this, lpNotification);
}

[CRepr]struct IMessage : IMAPIProp
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIProp.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, IMAPITable** lppTable) GetAttachmentTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulAttachmentNum, Guid* lpInterface, uint32 ulFlags, IAttach** lppAttach) OpenAttach;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* lpInterface, uint32 ulFlags, uint32* lpulAttachmentNum, IAttach** lppAttach) CreateAttach;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulAttachmentNum, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) DeleteAttach;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, IMAPITable** lppTable) GetRecipientTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, ADRLIST* lpMods) ModifyRecipients;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags) SubmitMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags) SetReadFlag;
	}


	public HRESULT GetAttachmentTable(uint32 ulFlags, IMAPITable** lppTable) mut => VT.[Friend]GetAttachmentTable(&this, ulFlags, lppTable);

	public HRESULT OpenAttach(uint32 ulAttachmentNum, Guid* lpInterface, uint32 ulFlags, IAttach** lppAttach) mut => VT.[Friend]OpenAttach(&this, ulAttachmentNum, lpInterface, ulFlags, lppAttach);

	public HRESULT CreateAttach(Guid* lpInterface, uint32 ulFlags, uint32* lpulAttachmentNum, IAttach** lppAttach) mut => VT.[Friend]CreateAttach(&this, lpInterface, ulFlags, lpulAttachmentNum, lppAttach);

	public HRESULT DeleteAttach(uint32 ulAttachmentNum, uint ulUIParam, IMAPIProgress* lpProgress, uint32 ulFlags) mut => VT.[Friend]DeleteAttach(&this, ulAttachmentNum, ulUIParam, lpProgress, ulFlags);

	public HRESULT GetRecipientTable(uint32 ulFlags, IMAPITable** lppTable) mut => VT.[Friend]GetRecipientTable(&this, ulFlags, lppTable);

	public HRESULT ModifyRecipients(uint32 ulFlags, ADRLIST* lpMods) mut => VT.[Friend]ModifyRecipients(&this, ulFlags, lpMods);

	public HRESULT SubmitMessage(uint32 ulFlags) mut => VT.[Friend]SubmitMessage(&this, ulFlags);

	public HRESULT SetReadFlag(uint32 ulFlags) mut => VT.[Friend]SetReadFlag(&this, ulFlags);
}

[CRepr]struct IAttach : IMAPIProp
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIProp.VTable
	{
	}

}

[CRepr]struct IMAPIControl : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) GetLastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, uint ulUIParam) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, uint32* lpulState) GetState;
	}


	public HRESULT GetLastError(HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) mut => VT.[Friend]GetLastError(&this, hResult, ulFlags, lppMAPIError);

	public HRESULT Activate(uint32 ulFlags, uint ulUIParam) mut => VT.[Friend]Activate(&this, ulFlags, ulUIParam);

	public HRESULT GetState(uint32 ulFlags, uint32* lpulState) mut => VT.[Friend]GetState(&this, ulFlags, lpulState);
}

[CRepr]struct IProviderAdmin : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) GetLastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, IMAPITable** lppTable) GetProviderTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int8* lpszProvider, uint32 cValues, SPropValue* lpProps, uint ulUIParam, uint32 ulFlags, MAPIUID* lpUID) CreateProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MAPIUID* lpUID) DeleteProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MAPIUID* lpUID, Guid* lpInterface, uint32 ulFlags, IProfSect** lppProfSect) OpenProfileSection;
	}


	public HRESULT GetLastError(HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) mut => VT.[Friend]GetLastError(&this, hResult, ulFlags, lppMAPIError);

	public HRESULT GetProviderTable(uint32 ulFlags, IMAPITable** lppTable) mut => VT.[Friend]GetProviderTable(&this, ulFlags, lppTable);

	public HRESULT CreateProvider(int8* lpszProvider, uint32 cValues, SPropValue* lpProps, uint ulUIParam, uint32 ulFlags, MAPIUID* lpUID) mut => VT.[Friend]CreateProvider(&this, lpszProvider, cValues, lpProps, ulUIParam, ulFlags, lpUID);

	public HRESULT DeleteProvider(MAPIUID* lpUID) mut => VT.[Friend]DeleteProvider(&this, lpUID);

	public HRESULT OpenProfileSection(MAPIUID* lpUID, Guid* lpInterface, uint32 ulFlags, IProfSect** lppProfSect) mut => VT.[Friend]OpenProfileSection(&this, lpUID, lpInterface, ulFlags, lppProfSect);
}

[CRepr]struct ITableData : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SSortOrderSet* lpSSortOrderSet, CALLERRELEASE* lpfCallerRelease, uint32 ulCallerData, IMAPITable** lppMAPITable) HrGetView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SRow* param0) HrModifyRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropValue* lpSPropValue) HrDeleteRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropValue* lpsPropValue, SRow** lppSRow, uint32* lpuliRow) HrQueryRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulRowNumber, SRow** lppSRow) HrEnumRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, uint32 cValues, SPropValue* lpSPropValue) HrNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uliRow, SRow* lpSRow) HrInsertRow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, SRowSet* lpSRowSet) HrModifyRows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, SRowSet* lprowsetToDelete, uint32* cRowsDeleted) HrDeleteRows;
	}


	public HRESULT HrGetView(SSortOrderSet* lpSSortOrderSet, CALLERRELEASE* lpfCallerRelease, uint32 ulCallerData, IMAPITable** lppMAPITable) mut => VT.[Friend]HrGetView(&this, lpSSortOrderSet, lpfCallerRelease, ulCallerData, lppMAPITable);

	public HRESULT HrModifyRow(SRow* param0) mut => VT.[Friend]HrModifyRow(&this, param0);

	public HRESULT HrDeleteRow(SPropValue* lpSPropValue) mut => VT.[Friend]HrDeleteRow(&this, lpSPropValue);

	public HRESULT HrQueryRow(SPropValue* lpsPropValue, SRow** lppSRow, uint32* lpuliRow) mut => VT.[Friend]HrQueryRow(&this, lpsPropValue, lppSRow, lpuliRow);

	public HRESULT HrEnumRow(uint32 ulRowNumber, SRow** lppSRow) mut => VT.[Friend]HrEnumRow(&this, ulRowNumber, lppSRow);

	public HRESULT HrNotify(uint32 ulFlags, uint32 cValues, SPropValue* lpSPropValue) mut => VT.[Friend]HrNotify(&this, ulFlags, cValues, lpSPropValue);

	public HRESULT HrInsertRow(uint32 uliRow, SRow* lpSRow) mut => VT.[Friend]HrInsertRow(&this, uliRow, lpSRow);

	public HRESULT HrModifyRows(uint32 ulFlags, SRowSet* lpSRowSet) mut => VT.[Friend]HrModifyRows(&this, ulFlags, lpSRowSet);

	public HRESULT HrDeleteRows(uint32 ulFlags, SRowSet* lprowsetToDelete, uint32* cRowsDeleted) mut => VT.[Friend]HrDeleteRows(&this, ulFlags, lprowsetToDelete, cRowsDeleted);
}

[CRepr]struct IPropData : IMAPIProp
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIProp.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulAccess) HrSetObjAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropTagArray* lpPropTagArray, uint32* rgulAccess) HrSetPropAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropTagArray** lppPropTagArray, uint32** lprgulAccess) HrGetPropAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPropTagArray* lppPropTagArray, SPropProblemArray** lprgulAccess) HrAddObjProps;
	}


	public HRESULT HrSetObjAccess(uint32 ulAccess) mut => VT.[Friend]HrSetObjAccess(&this, ulAccess);

	public HRESULT HrSetPropAccess(SPropTagArray* lpPropTagArray, uint32* rgulAccess) mut => VT.[Friend]HrSetPropAccess(&this, lpPropTagArray, rgulAccess);

	public HRESULT HrGetPropAccess(SPropTagArray** lppPropTagArray, uint32** lprgulAccess) mut => VT.[Friend]HrGetPropAccess(&this, lppPropTagArray, lprgulAccess);

	public HRESULT HrAddObjProps(SPropTagArray* lppPropTagArray, SPropProblemArray** lprgulAccess) mut => VT.[Friend]HrAddObjProps(&this, lppPropTagArray, lprgulAccess);
}

[CRepr]struct IAddrBook : IMAPIProp
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMAPIProp.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, Guid* lpInterface, uint32 ulFlags, uint32* lpulObjType, IUnknown** lppUnk) OpenEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID1, ENTRYID* lpEntryID1, uint32 cbEntryID2, ENTRYID* lpEntryID2, uint32 ulFlags, uint32* lpulResult) CompareEntryIDs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulEventMask, IMAPIAdviseSink* lpAdviseSink, uint32* lpulConnection) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulConnection) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int8* lpszName, int8* lpszAdrType, int8* lpszAddress, uint32 ulFlags, uint32* lpcbEntryID, ENTRYID** lppEntryID) CreateOneOff;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulUIParam, uint32 ulFlags, uint32 cbEIDContainer, ENTRYID* lpEIDContainer, uint32 cbEIDNewEntryTpl, ENTRYID* lpEIDNewEntryTpl, uint32* lpcbEIDNewEntry, ENTRYID** lppEIDNewEntry) NewEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint ulUIParam, uint32 ulFlags, int8* lpszNewEntryTitle, ADRLIST* lpAdrList) ResolveName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpulUIParam, ADRPARM* lpAdrParms, ADRLIST** lppAdrList) Address;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* lpulUIParam, LPFNDISMISS lpfnDismiss, void* lpvDismissContext, uint32 cbEntryID, ENTRYID* lpEntryID, LPFNBUTTON lpfButtonCallback, void* lpvButtonContext, int8* lpszButtonText, uint32 ulFlags) Details;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulUIParam, uint32 ulFlags, ADRENTRY* lpRecip) RecipOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int8* lpszAdrType, uint32 ulFlags, uint32* lpcValues, SPropValue** lppOptions) QueryDefaultRecipOpt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpcbEntryID, ENTRYID** lppEntryID) GetPAB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID) SetPAB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpcbEntryID, ENTRYID** lppEntryID) GetDefaultDir;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbEntryID, ENTRYID* lpEntryID) SetDefaultDir;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, SRowSet** lppSearchPath) GetSearchPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, SRowSet* lpSearchPath) SetSearchPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulFlags, SPropTagArray* lpPropTagArray, ADRLIST* lpRecipList) PrepareRecips;
	}


	public HRESULT OpenEntry(uint32 cbEntryID, ENTRYID* lpEntryID, Guid* lpInterface, uint32 ulFlags, uint32* lpulObjType, IUnknown** lppUnk) mut => VT.[Friend]OpenEntry(&this, cbEntryID, lpEntryID, lpInterface, ulFlags, lpulObjType, lppUnk);

	public HRESULT CompareEntryIDs(uint32 cbEntryID1, ENTRYID* lpEntryID1, uint32 cbEntryID2, ENTRYID* lpEntryID2, uint32 ulFlags, uint32* lpulResult) mut => VT.[Friend]CompareEntryIDs(&this, cbEntryID1, lpEntryID1, cbEntryID2, lpEntryID2, ulFlags, lpulResult);

	public HRESULT Advise(uint32 cbEntryID, ENTRYID* lpEntryID, uint32 ulEventMask, IMAPIAdviseSink* lpAdviseSink, uint32* lpulConnection) mut => VT.[Friend]Advise(&this, cbEntryID, lpEntryID, ulEventMask, lpAdviseSink, lpulConnection);

	public HRESULT Unadvise(uint32 ulConnection) mut => VT.[Friend]Unadvise(&this, ulConnection);

	public HRESULT CreateOneOff(int8* lpszName, int8* lpszAdrType, int8* lpszAddress, uint32 ulFlags, uint32* lpcbEntryID, ENTRYID** lppEntryID) mut => VT.[Friend]CreateOneOff(&this, lpszName, lpszAdrType, lpszAddress, ulFlags, lpcbEntryID, lppEntryID);

	public HRESULT NewEntry(uint32 ulUIParam, uint32 ulFlags, uint32 cbEIDContainer, ENTRYID* lpEIDContainer, uint32 cbEIDNewEntryTpl, ENTRYID* lpEIDNewEntryTpl, uint32* lpcbEIDNewEntry, ENTRYID** lppEIDNewEntry) mut => VT.[Friend]NewEntry(&this, ulUIParam, ulFlags, cbEIDContainer, lpEIDContainer, cbEIDNewEntryTpl, lpEIDNewEntryTpl, lpcbEIDNewEntry, lppEIDNewEntry);

	public HRESULT ResolveName(uint ulUIParam, uint32 ulFlags, int8* lpszNewEntryTitle, ADRLIST* lpAdrList) mut => VT.[Friend]ResolveName(&this, ulUIParam, ulFlags, lpszNewEntryTitle, lpAdrList);

	public HRESULT Address(uint32* lpulUIParam, ADRPARM* lpAdrParms, ADRLIST** lppAdrList) mut => VT.[Friend]Address(&this, lpulUIParam, lpAdrParms, lppAdrList);

	public HRESULT Details(uint* lpulUIParam, LPFNDISMISS lpfnDismiss, void* lpvDismissContext, uint32 cbEntryID, ENTRYID* lpEntryID, LPFNBUTTON lpfButtonCallback, void* lpvButtonContext, int8* lpszButtonText, uint32 ulFlags) mut => VT.[Friend]Details(&this, lpulUIParam, lpfnDismiss, lpvDismissContext, cbEntryID, lpEntryID, lpfButtonCallback, lpvButtonContext, lpszButtonText, ulFlags);

	public HRESULT RecipOptions(uint32 ulUIParam, uint32 ulFlags, ADRENTRY* lpRecip) mut => VT.[Friend]RecipOptions(&this, ulUIParam, ulFlags, lpRecip);

	public HRESULT QueryDefaultRecipOpt(int8* lpszAdrType, uint32 ulFlags, uint32* lpcValues, SPropValue** lppOptions) mut => VT.[Friend]QueryDefaultRecipOpt(&this, lpszAdrType, ulFlags, lpcValues, lppOptions);

	public HRESULT GetPAB(uint32* lpcbEntryID, ENTRYID** lppEntryID) mut => VT.[Friend]GetPAB(&this, lpcbEntryID, lppEntryID);

	public HRESULT SetPAB(uint32 cbEntryID, ENTRYID* lpEntryID) mut => VT.[Friend]SetPAB(&this, cbEntryID, lpEntryID);

	public HRESULT GetDefaultDir(uint32* lpcbEntryID, ENTRYID** lppEntryID) mut => VT.[Friend]GetDefaultDir(&this, lpcbEntryID, lppEntryID);

	public HRESULT SetDefaultDir(uint32 cbEntryID, ENTRYID* lpEntryID) mut => VT.[Friend]SetDefaultDir(&this, cbEntryID, lpEntryID);

	public HRESULT GetSearchPath(uint32 ulFlags, SRowSet** lppSearchPath) mut => VT.[Friend]GetSearchPath(&this, ulFlags, lppSearchPath);

	public HRESULT SetSearchPath(uint32 ulFlags, SRowSet* lpSearchPath) mut => VT.[Friend]SetSearchPath(&this, ulFlags, lpSearchPath);

	public HRESULT PrepareRecips(uint32 ulFlags, SPropTagArray* lpPropTagArray, ADRLIST* lpRecipList) mut => VT.[Friend]PrepareRecips(&this, ulFlags, lpPropTagArray, lpRecipList);
}

[CRepr]struct IWABObject : IUnknown
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) GetLastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbSize, void** lppBuffer) AllocateBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbSize, void* lpObject, void** lppBuffer) AllocateMore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer) FreeBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR lpFileName) Backup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR lpWIP) Import;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, HWND hWnd) Find;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, HWND hWnd, PSTR lpszFileName) VCardDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, HWND hWnd, uint32 ulFlags, PSTR lpszURL, IMailUser** lppMailUser) LDAPUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, uint32 ulFlags, PSTR lpszVCard, IMailUser* lpMailUser) VCardCreate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, uint32 ulFlags, PSTR lpszVCard, IMailUser** lppMailUser) VCardRetrieve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, uint32 ulFlags, uint32* lpdwAction, SBinary* lpsbEID, HWND hwnd) GetMe;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, uint32 ulFlags, SBinary sbEID, HWND hwnd) SetMe;
	}


	public HRESULT GetLastError(HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) mut => VT.[Friend]GetLastError(&this, hResult, ulFlags, lppMAPIError);

	public HRESULT AllocateBuffer(uint32 cbSize, void** lppBuffer) mut => VT.[Friend]AllocateBuffer(&this, cbSize, lppBuffer);

	public HRESULT AllocateMore(uint32 cbSize, void* lpObject, void** lppBuffer) mut => VT.[Friend]AllocateMore(&this, cbSize, lpObject, lppBuffer);

	public HRESULT FreeBuffer(void* lpBuffer) mut => VT.[Friend]FreeBuffer(&this, lpBuffer);

	public HRESULT Backup(PSTR lpFileName) mut => VT.[Friend]Backup(&this, lpFileName);

	public HRESULT Import(PSTR lpWIP) mut => VT.[Friend]Import(&this, lpWIP);

	public HRESULT Find(IAddrBook* lpIAB, HWND hWnd) mut => VT.[Friend]Find(&this, lpIAB, hWnd);

	public HRESULT VCardDisplay(IAddrBook* lpIAB, HWND hWnd, PSTR lpszFileName) mut => VT.[Friend]VCardDisplay(&this, lpIAB, hWnd, lpszFileName);

	public HRESULT LDAPUrl(IAddrBook* lpIAB, HWND hWnd, uint32 ulFlags, PSTR lpszURL, IMailUser** lppMailUser) mut => VT.[Friend]LDAPUrl(&this, lpIAB, hWnd, ulFlags, lpszURL, lppMailUser);

	public HRESULT VCardCreate(IAddrBook* lpIAB, uint32 ulFlags, PSTR lpszVCard, IMailUser* lpMailUser) mut => VT.[Friend]VCardCreate(&this, lpIAB, ulFlags, lpszVCard, lpMailUser);

	public HRESULT VCardRetrieve(IAddrBook* lpIAB, uint32 ulFlags, PSTR lpszVCard, IMailUser** lppMailUser) mut => VT.[Friend]VCardRetrieve(&this, lpIAB, ulFlags, lpszVCard, lppMailUser);

	public HRESULT GetMe(IAddrBook* lpIAB, uint32 ulFlags, uint32* lpdwAction, SBinary* lpsbEID, HWND hwnd) mut => VT.[Friend]GetMe(&this, lpIAB, ulFlags, lpdwAction, lpsbEID, hwnd);

	public HRESULT SetMe(IAddrBook* lpIAB, uint32 ulFlags, SBinary sbEID, HWND hwnd) mut => VT.[Friend]SetMe(&this, lpIAB, ulFlags, sbEID, hwnd);
}

[CRepr]struct IWABOBJECT_
{
	public VTable* VT { get => (.)mVT; }

	protected VTable* mVT;

	[CRepr]public struct VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvObj) QueryInterface;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) AddRef;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) Release;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) GetLastError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbSize, void** lppBuffer) AllocateBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbSize, void* lpObject, void** lppBuffer) AllocateMore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer) FreeBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR lpFileName) Backup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR lpWIP) Import;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, HWND hWnd) Find;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, HWND hWnd, PSTR lpszFileName) VCardDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, HWND hWnd, uint32 ulFlags, PSTR lpszURL, IMailUser** lppMailUser) LDAPUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, uint32 ulFlags, PSTR lpszVCard, IMailUser* lpMailUser) VCardCreate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, uint32 ulFlags, PSTR lpszVCard, IMailUser** lppMailUser) VCardRetrieve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, uint32 ulFlags, uint32* lpdwAction, SBinary* lpsbEID, HWND hwnd) GetMe;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAddrBook* lpIAB, uint32 ulFlags, SBinary sbEID, HWND hwnd) SetMe;
	}


	public HRESULT QueryInterface(in Guid riid, void** ppvObj) mut => VT.[Friend]QueryInterface(&this, riid, ppvObj);

	public uint32 AddRef() mut => VT.[Friend]AddRef(&this);

	public uint32 Release() mut => VT.[Friend]Release(&this);

	public HRESULT GetLastError(HRESULT hResult, uint32 ulFlags, MAPIERROR** lppMAPIError) mut => VT.[Friend]GetLastError(&this, hResult, ulFlags, lppMAPIError);

	public HRESULT AllocateBuffer(uint32 cbSize, void** lppBuffer) mut => VT.[Friend]AllocateBuffer(&this, cbSize, lppBuffer);

	public HRESULT AllocateMore(uint32 cbSize, void* lpObject, void** lppBuffer) mut => VT.[Friend]AllocateMore(&this, cbSize, lpObject, lppBuffer);

	public HRESULT FreeBuffer(void* lpBuffer) mut => VT.[Friend]FreeBuffer(&this, lpBuffer);

	public HRESULT Backup(PSTR lpFileName) mut => VT.[Friend]Backup(&this, lpFileName);

	public HRESULT Import(PSTR lpWIP) mut => VT.[Friend]Import(&this, lpWIP);

	public HRESULT Find(IAddrBook* lpIAB, HWND hWnd) mut => VT.[Friend]Find(&this, lpIAB, hWnd);

	public HRESULT VCardDisplay(IAddrBook* lpIAB, HWND hWnd, PSTR lpszFileName) mut => VT.[Friend]VCardDisplay(&this, lpIAB, hWnd, lpszFileName);

	public HRESULT LDAPUrl(IAddrBook* lpIAB, HWND hWnd, uint32 ulFlags, PSTR lpszURL, IMailUser** lppMailUser) mut => VT.[Friend]LDAPUrl(&this, lpIAB, hWnd, ulFlags, lpszURL, lppMailUser);

	public HRESULT VCardCreate(IAddrBook* lpIAB, uint32 ulFlags, PSTR lpszVCard, IMailUser* lpMailUser) mut => VT.[Friend]VCardCreate(&this, lpIAB, ulFlags, lpszVCard, lpMailUser);

	public HRESULT VCardRetrieve(IAddrBook* lpIAB, uint32 ulFlags, PSTR lpszVCard, IMailUser** lppMailUser) mut => VT.[Friend]VCardRetrieve(&this, lpIAB, ulFlags, lpszVCard, lppMailUser);

	public HRESULT GetMe(IAddrBook* lpIAB, uint32 ulFlags, uint32* lpdwAction, SBinary* lpsbEID, HWND hwnd) mut => VT.[Friend]GetMe(&this, lpIAB, ulFlags, lpdwAction, lpsbEID, hwnd);

	public HRESULT SetMe(IAddrBook* lpIAB, uint32 ulFlags, SBinary sbEID, HWND hwnd) mut => VT.[Friend]SetMe(&this, lpIAB, ulFlags, sbEID, hwnd);
}

[CRepr]struct IWABExtInit : IUnknown
{
	public new const Guid IID = .(0xea22ebf0, 0x87a4, 0x11d1, 0x9a, 0xcf, 0x00, 0xa0, 0xc9, 0x1f, 0x9c, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WABEXTDISPLAY* lpWABExtDisplay) Initialize;
	}


	public HRESULT Initialize(WABEXTDISPLAY* lpWABExtDisplay) mut => VT.[Friend]Initialize(&this, lpWABExtDisplay);
}

#endregion

#region Functions
public static
{
	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CreateTable(Guid* lpInterface, LPALLOCATEBUFFER lpAllocateBuffer, LPALLOCATEMORE lpAllocateMore, LPFREEBUFFER lpFreeBuffer, void* lpvReserved, uint32 ulTableType, uint32 ulPropTagIndexColumn, SPropTagArray* lpSPropTagArrayColumns, ITableData** lppTableData);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 CreateIProp(Guid* lpInterface, LPALLOCATEBUFFER lpAllocateBuffer, LPALLOCATEMORE lpAllocateMore, LPFREEBUFFER lpFreeBuffer, void* lpvReserved, IPropData** lppPropData);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 MAPIInitIdle(void* lpvReserved);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void MAPIDeinitIdle();

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* FtgRegisterIdleRoutine(PFNIDLE lpfnIdle, void* lpvIdleParam, int16 priIdle, uint32 csecIdle, uint16 iroIdle);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DeregisterIdleRoutine(void* ftg);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void EnableIdleRoutine(void* ftg, BOOL fEnable);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ChangeIdleRoutine(void* ftg, PFNIDLE lpfnIdle, void* lpvIdleParam, int16 priIdle, uint32 csecIdle, uint16 iroIdle, uint16 ircIdle);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IMalloc* MAPIGetDefaultMalloc();

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OpenStreamOnFile(LPALLOCATEBUFFER lpAllocateBuffer, LPFREEBUFFER lpFreeBuffer, uint32 ulFlags, int8* lpszFileName, int8* lpszPrefix, IStream** lppStream);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PropCopyMore(SPropValue* lpSPropValueDest, SPropValue* lpSPropValueSrc, LPALLOCATEMORE lpfAllocMore, void* lpvObject);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 UlPropSize(SPropValue* lpSPropValue);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FEqualNames(MAPINAMEID* lpName1, MAPINAMEID* lpName2);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FPropContainsProp(SPropValue* lpSPropValueDst, SPropValue* lpSPropValueSrc, uint32 ulFuzzyLevel);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FPropCompareProp(SPropValue* lpSPropValue1, uint32 ulRelOp, SPropValue* lpSPropValue2);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 LPropCompareProp(SPropValue* lpSPropValueA, SPropValue* lpSPropValueB);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HrAddColumns(IMAPITable* lptbl, SPropTagArray* lpproptagColumnsNew, LPALLOCATEBUFFER lpAllocateBuffer, LPFREEBUFFER lpFreeBuffer);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HrAddColumnsEx(IMAPITable* lptbl, SPropTagArray* lpproptagColumnsNew, LPALLOCATEBUFFER lpAllocateBuffer, LPFREEBUFFER lpFreeBuffer, int lpfnFilterColumns);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HrAllocAdviseSink(LPNOTIFCALLBACK lpfnCallback, void* lpvContext, IMAPIAdviseSink** lppAdviseSink);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HrThisThreadAdviseSink(IMAPIAdviseSink* lpAdviseSink, IMAPIAdviseSink** lppAdviseSink);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HrDispatchNotifications(uint32 ulFlags);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BuildDisplayTable(LPALLOCATEBUFFER lpAllocateBuffer, LPALLOCATEMORE lpAllocateMore, LPFREEBUFFER lpFreeBuffer, IMalloc* lpMalloc, HINSTANCE hInstance, uint32 cPages, DTPAGE* lpPage, uint32 ulFlags, IMAPITable** lppTable, ITableData** lppTblData);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScCountNotifications(int32 cNotifications, NOTIFICATION* lpNotifications, uint32* lpcb);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScCopyNotifications(int32 cNotification, NOTIFICATION* lpNotifications, void* lpvDst, uint32* lpcb);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScRelocNotifications(int32 cNotification, NOTIFICATION* lpNotifications, void* lpvBaseOld, void* lpvBaseNew, uint32* lpcb);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScCountProps(int32 cValues, SPropValue* lpPropArray, uint32* lpcb);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SPropValue* LpValFindProp(uint32 ulPropTag, uint32 cValues, SPropValue* lpPropArray);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScCopyProps(int32 cValues, SPropValue* lpPropArray, void* lpvDst, uint32* lpcb);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScRelocProps(int32 cValues, SPropValue* lpPropArray, void* lpvBaseOld, void* lpvBaseNew, uint32* lpcb);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScDupPropset(int32 cValues, SPropValue* lpPropArray, LPALLOCATEBUFFER lpAllocateBuffer, SPropValue** lppPropArray);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 UlAddRef(void* lpunk);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 UlRelease(void* lpunk);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HrGetOneProp(IMAPIProp* lpMapiProp, uint32 ulPropTag, SPropValue** lppProp);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HrSetOneProp(IMAPIProp* lpMapiProp, SPropValue* lpProp);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL FPropExists(IMAPIProp* lpMapiProp, uint32 ulPropTag);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern SPropValue* PpropFindProp(SPropValue* lpPropArray, uint32 cValues, uint32 ulPropTag);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreePadrlist(ADRLIST* lpAdrlist);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void FreeProws(SRowSet* lpRows);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HrQueryAllRows(IMAPITable* lpTable, SPropTagArray* lpPropTags, SRestriction* lpRestriction, SSortOrderSet* lpSortOrderSet, int32 crowsMax, SRowSet** lppRows);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8* SzFindCh(int8* lpsz, uint16 ch);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8* SzFindLastCh(int8* lpsz, uint16 ch);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int8* SzFindSz(int8* lpsz, int8* lpszKey);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 UFromSz(int8* lpsz);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScUNCFromLocalPath(PSTR lpszLocal, uint8* lpszUNC, uint32 cchUNC);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScLocalPathFromUNC(PSTR lpszUNC, uint8* lpszLocal, uint32 cchLocal);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FILETIME FtAddFt(FILETIME ftAddend1, FILETIME ftAddend2);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FILETIME FtMulDwDw(uint32 ftMultiplicand, uint32 ftMultiplier);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FILETIME FtMulDw(uint32 ftMultiplier, FILETIME ftMultiplicand);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FILETIME FtSubFt(FILETIME ftMinuend, FILETIME ftSubtrahend);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern FILETIME FtNegFt(FILETIME ft);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScCreateConversationIndex(uint32 cbParent, uint8* lpbParent, uint32* lpcbConvIndex, uint8** lppbConvIndex);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WrapStoreEntryID(uint32 ulFlags, int8* lpszDLLName, uint32 cbOrigEntry, ENTRYID* lpOrigEntry, uint32* lpcbWrappedEntry, ENTRYID** lppWrappedEntry);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RTFSync(IMessage* lpMessage, uint32 ulFlags, BOOL* lpfMessageUpdated);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WrapCompressedRTFStream(IStream* lpCompressedRTFStream, uint32 ulFlags, IStream** lpUncompressedRTFStream);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HrIStorageFromStream(IUnknown* lpUnkIn, Guid* lpInterface, uint32 ulFlags, IStorage** lppStorageOut);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ScInitMapiUtil(uint32 ulFlags);

	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DeinitMapiUtil();

}
#endregion
