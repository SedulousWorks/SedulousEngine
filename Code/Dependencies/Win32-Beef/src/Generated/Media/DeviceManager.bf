using Win32.Foundation;
using Win32.System.Com.StructuredStorage;
using Win32.System.Com;
using Win32.Media.Audio;
using Win32.Media.MediaFoundation;
using Win32.System.Ole;
using System;

namespace Win32.Media.DeviceManager;

#region Constants
public static
{
	public const uint32 IOCTL_MTP_CUSTOM_COMMAND = 827348045;
	public const uint32 MTP_NEXTPHASE_READ_DATA = 1;
	public const uint32 MTP_NEXTPHASE_WRITE_DATA = 2;
	public const uint32 MTP_NEXTPHASE_NO_DATA = 3;
	public const uint32 RSA_KEY_LEN = 64;
	public const uint32 SAC_SESSION_KEYLEN = 8;
	public const uint32 SAC_PROTOCOL_WMDM = 1;
	public const uint32 SAC_PROTOCOL_V1 = 2;
	public const uint32 SAC_CERT_X509 = 1;
	public const uint32 SAC_CERT_V1 = 2;
	public const Guid WMDM_DEVICE_PROTOCOL_MTP = .(0x979e54e5, 0x0afc, 0x4604, 0x8d, 0x93, 0xdc, 0x79, 0x8a, 0x4b, 0xcf, 0x45);
	public const Guid WMDM_DEVICE_PROTOCOL_RAPI = .(0x2a11ed91, 0x8c8f, 0x41e4, 0x82, 0xd1, 0x83, 0x86, 0xe0, 0x03, 0x56, 0x1c);
	public const Guid WMDM_DEVICE_PROTOCOL_MSC = .(0xa4d2c26c, 0xa881, 0x44bb, 0xbd, 0x5d, 0x1f, 0x70, 0x3c, 0x71, 0xf7, 0xa9);
	public const Guid WMDM_SERVICE_PROVIDER_VENDOR_MICROSOFT = .(0x7de8686d, 0x78ee, 0x43ea, 0xa4, 0x96, 0xc6, 0x25, 0xac, 0x91, 0xcc, 0x5d);
	public const uint32 WMDMID_LENGTH = 128;
	public const uint32 WMDM_MAC_LENGTH = 8;
	public const int32 WMDM_S_NOT_ALL_PROPERTIES_APPLIED = 282625;
	public const int32 WMDM_S_NOT_ALL_PROPERTIES_RETRIEVED = 282626;
	public const int32 WMDM_E_BUSY = -2147201024;
	public const int32 WMDM_E_INTERFACEDEAD = -2147201023;
	public const int32 WMDM_E_INVALIDTYPE = -2147201022;
	public const int32 WMDM_E_PROCESSFAILED = -2147201021;
	public const int32 WMDM_E_NOTSUPPORTED = -2147201020;
	public const int32 WMDM_E_NOTCERTIFIED = -2147201019;
	public const int32 WMDM_E_NORIGHTS = -2147201018;
	public const int32 WMDM_E_CALL_OUT_OF_SEQUENCE = -2147201017;
	public const int32 WMDM_E_BUFFERTOOSMALL = -2147201016;
	public const int32 WMDM_E_MOREDATA = -2147201015;
	public const int32 WMDM_E_MAC_CHECK_FAILED = -2147201014;
	public const int32 WMDM_E_USER_CANCELLED = -2147201013;
	public const int32 WMDM_E_SDMI_TRIGGER = -2147201012;
	public const int32 WMDM_E_SDMI_NOMORECOPIES = -2147201011;
	public const int32 WMDM_E_REVOKED = -2147201010;
	public const int32 WMDM_E_LICENSE_NOTEXIST = -2147201009;
	public const int32 WMDM_E_INCORRECT_APPSEC = -2147201008;
	public const int32 WMDM_E_INCORRECT_RIGHTS = -2147201007;
	public const int32 WMDM_E_LICENSE_EXPIRED = -2147201006;
	public const int32 WMDM_E_CANTOPEN_PMSN_SERVICE_PIPE = -2147201005;
	public const int32 WMDM_E_TOO_MANY_SESSIONS = -2147201005;
	public const uint32 WMDM_WMDM_REVOKED = 1;
	public const uint32 WMDM_APP_REVOKED = 2;
	public const uint32 WMDM_SP_REVOKED = 4;
	public const uint32 WMDM_SCP_REVOKED = 8;
	public const uint32 WMDM_GET_FORMAT_SUPPORT_AUDIO = 1;
	public const uint32 WMDM_GET_FORMAT_SUPPORT_VIDEO = 2;
	public const uint32 WMDM_GET_FORMAT_SUPPORT_FILE = 4;
	public const uint32 WMDM_RIGHTS_PLAYBACKCOUNT = 1;
	public const uint32 WMDM_RIGHTS_EXPIRATIONDATE = 2;
	public const uint32 WMDM_RIGHTS_GROUPID = 4;
	public const uint32 WMDM_RIGHTS_FREESERIALIDS = 8;
	public const uint32 WMDM_RIGHTS_NAMEDSERIALIDS = 16;
	public const uint32 WMDM_DEVICE_TYPE_PLAYBACK = 1;
	public const uint32 WMDM_DEVICE_TYPE_RECORD = 2;
	public const uint32 WMDM_DEVICE_TYPE_DECODE = 4;
	public const uint32 WMDM_DEVICE_TYPE_ENCODE = 8;
	public const uint32 WMDM_DEVICE_TYPE_STORAGE = 16;
	public const uint32 WMDM_DEVICE_TYPE_VIRTUAL = 32;
	public const uint32 WMDM_DEVICE_TYPE_SDMI = 64;
	public const uint32 WMDM_DEVICE_TYPE_NONSDMI = 128;
	public const uint32 WMDM_DEVICE_TYPE_NONREENTRANT = 256;
	public const uint32 WMDM_DEVICE_TYPE_FILELISTRESYNC = 512;
	public const uint32 WMDM_DEVICE_TYPE_VIEW_PREF_METADATAVIEW = 1024;
	public const uint32 WMDM_POWER_CAP_BATTERY = 1;
	public const uint32 WMDM_POWER_CAP_EXTERNAL = 2;
	public const uint32 WMDM_POWER_IS_BATTERY = 4;
	public const uint32 WMDM_POWER_IS_EXTERNAL = 8;
	public const uint32 WMDM_POWER_PERCENT_AVAILABLE = 16;
	public const uint32 WMDM_STATUS_READY = 1;
	public const uint32 WMDM_STATUS_BUSY = 2;
	public const uint32 WMDM_STATUS_DEVICE_NOTPRESENT = 4;
	public const uint32 WMDM_STATUS_DEVICECONTROL_PLAYING = 8;
	public const uint32 WMDM_STATUS_DEVICECONTROL_RECORDING = 16;
	public const uint32 WMDM_STATUS_DEVICECONTROL_PAUSED = 32;
	public const uint32 WMDM_STATUS_DEVICECONTROL_REMOTE = 64;
	public const uint32 WMDM_STATUS_DEVICECONTROL_STREAM = 128;
	public const uint32 WMDM_STATUS_STORAGE_NOTPRESENT = 256;
	public const uint32 WMDM_STATUS_STORAGE_INITIALIZING = 512;
	public const uint32 WMDM_STATUS_STORAGE_BROKEN = 1024;
	public const uint32 WMDM_STATUS_STORAGE_NOTSUPPORTED = 2048;
	public const uint32 WMDM_STATUS_STORAGE_UNFORMATTED = 4096;
	public const uint32 WMDM_STATUS_STORAGECONTROL_INSERTING = 8192;
	public const uint32 WMDM_STATUS_STORAGECONTROL_DELETING = 16384;
	public const uint32 WMDM_STATUS_STORAGECONTROL_APPENDING = 32768;
	public const uint32 WMDM_STATUS_STORAGECONTROL_MOVING = 65536;
	public const uint32 WMDM_STATUS_STORAGECONTROL_READING = 131072;
	public const uint32 WMDM_DEVICECAP_CANPLAY = 1;
	public const uint32 WMDM_DEVICECAP_CANSTREAMPLAY = 2;
	public const uint32 WMDM_DEVICECAP_CANRECORD = 4;
	public const uint32 WMDM_DEVICECAP_CANSTREAMRECORD = 8;
	public const uint32 WMDM_DEVICECAP_CANPAUSE = 16;
	public const uint32 WMDM_DEVICECAP_CANRESUME = 32;
	public const uint32 WMDM_DEVICECAP_CANSTOP = 64;
	public const uint32 WMDM_DEVICECAP_CANSEEK = 128;
	public const uint32 WMDM_DEVICECAP_HASSECURECLOCK = 256;
	public const uint32 WMDM_SEEK_REMOTECONTROL = 1;
	public const uint32 WMDM_SEEK_STREAMINGAUDIO = 2;
	public const uint32 WMDM_STORAGE_ATTR_FILESYSTEM = 1;
	public const uint32 WMDM_STORAGE_ATTR_REMOVABLE = 2;
	public const uint32 WMDM_STORAGE_ATTR_NONREMOVABLE = 4;
	public const uint32 WMDM_FILE_ATTR_FOLDER = 8;
	public const uint32 WMDM_FILE_ATTR_LINK = 16;
	public const uint32 WMDM_FILE_ATTR_FILE = 32;
	public const uint32 WMDM_FILE_ATTR_VIDEO = 64;
	public const uint32 WMDM_STORAGE_ATTR_CANEDITMETADATA = 128;
	public const uint32 WMDM_STORAGE_ATTR_FOLDERS = 256;
	public const uint32 WMDM_FILE_ATTR_AUDIO = 4096;
	public const uint32 WMDM_FILE_ATTR_DATA = 8192;
	public const uint32 WMDM_FILE_ATTR_CANPLAY = 16384;
	public const uint32 WMDM_FILE_ATTR_CANDELETE = 32768;
	public const uint32 WMDM_FILE_ATTR_CANMOVE = 65536;
	public const uint32 WMDM_FILE_ATTR_CANRENAME = 131072;
	public const uint32 WMDM_FILE_ATTR_CANREAD = 262144;
	public const uint32 WMDM_FILE_ATTR_MUSIC = 524288;
	public const uint32 WMDM_FILE_CREATE_OVERWRITE = 1048576;
	public const uint32 WMDM_FILE_ATTR_AUDIOBOOK = 2097152;
	public const uint32 WMDM_FILE_ATTR_HIDDEN = 4194304;
	public const uint32 WMDM_FILE_ATTR_SYSTEM = 8388608;
	public const uint32 WMDM_FILE_ATTR_READONLY = 16777216;
	public const uint32 WMDM_STORAGE_ATTR_HAS_FOLDERS = 33554432;
	public const uint32 WMDM_STORAGE_ATTR_HAS_FILES = 67108864;
	public const uint32 WMDM_STORAGE_IS_DEFAULT = 134217728;
	public const uint32 WMDM_STORAGE_CONTAINS_DEFAULT = 268435456;
	public const uint32 WMDM_STORAGE_ATTR_VIRTUAL = 536870912;
	public const uint32 WMDM_STORAGECAP_FOLDERSINROOT = 1;
	public const uint32 WMDM_STORAGECAP_FILESINROOT = 2;
	public const uint32 WMDM_STORAGECAP_FOLDERSINFOLDERS = 4;
	public const uint32 WMDM_STORAGECAP_FILESINFOLDERS = 8;
	public const uint32 WMDM_STORAGECAP_FOLDERLIMITEXISTS = 16;
	public const uint32 WMDM_STORAGECAP_FILELIMITEXISTS = 32;
	public const uint32 WMDM_STORAGECAP_NOT_INITIALIZABLE = 64;
	public const uint32 WMDM_MODE_BLOCK = 1;
	public const uint32 WMDM_MODE_THREAD = 2;
	public const uint32 WMDM_CONTENT_FILE = 4;
	public const uint32 WMDM_CONTENT_FOLDER = 8;
	public const uint32 WMDM_CONTENT_OPERATIONINTERFACE = 16;
	public const uint32 WMDM_MODE_QUERY = 32;
	public const uint32 WMDM_MODE_PROGRESS = 64;
	public const uint32 WMDM_MODE_TRANSFER_PROTECTED = 128;
	public const uint32 WMDM_MODE_TRANSFER_UNPROTECTED = 256;
	public const uint32 WMDM_STORAGECONTROL_INSERTBEFORE = 512;
	public const uint32 WMDM_STORAGECONTROL_INSERTAFTER = 1024;
	public const uint32 WMDM_STORAGECONTROL_INSERTINTO = 2048;
	public const uint32 WMDM_MODE_RECURSIVE = 4096;
	public const uint32 WMDM_RIGHTS_PLAY_ON_PC = 1;
	public const uint32 WMDM_RIGHTS_COPY_TO_NON_SDMI_DEVICE = 2;
	public const uint32 WMDM_RIGHTS_COPY_TO_CD = 8;
	public const uint32 WMDM_RIGHTS_COPY_TO_SDMI_DEVICE = 16;
	public const uint32 WMDM_SEEK_BEGIN = 1;
	public const uint32 WMDM_SEEK_CURRENT = 2;
	public const uint32 WMDM_SEEK_END = 8;
	public const uint32 DO_NOT_VIRTUALIZE_STORAGES_AS_DEVICES = 1;
	public const uint32 ALLOW_OUTOFBAND_NOTIFICATION = 2;
	public const uint32 MDSP_READ = 1;
	public const uint32 MDSP_WRITE = 2;
	public const uint32 MDSP_SEEK_BOF = 1;
	public const uint32 MDSP_SEEK_CUR = 2;
	public const uint32 MDSP_SEEK_EOF = 4;
	public const int32 WMDM_SCP_EXAMINE_EXTENSION = 1;
	public const int32 WMDM_SCP_EXAMINE_DATA = 2;
	public const int32 WMDM_SCP_DECIDE_DATA = 8;
	public const int32 WMDM_SCP_PROTECTED_OUTPUT = 16;
	public const int32 WMDM_SCP_UNPROTECTED_OUTPUT = 32;
	public const int32 WMDM_SCP_RIGHTS_DATA = 64;
	public const int32 WMDM_SCP_TRANSFER_OBJECTDATA = 32;
	public const int32 WMDM_SCP_NO_MORE_CHANGES = 64;
	public const int32 WMDM_SCP_DRMINFO_NOT_DRMPROTECTED = 0;
	public const int32 WMDM_SCP_DRMINFO_V1HEADER = 1;
	public const int32 WMDM_SCP_DRMINFO_V2HEADER = 2;
	public const Guid SCP_EVENTID_ACQSECURECLOCK = .(0x86248cc9, 0x4a59, 0x43e2, 0x91, 0x46, 0x48, 0xa7, 0xf3, 0xf4, 0x14, 0x0c);
	public const Guid SCP_EVENTID_NEEDTOINDIV = .(0x87a507c7, 0xb469, 0x4386, 0xb9, 0x76, 0xd5, 0xd1, 0xce, 0x53, 0x8a, 0x6f);
	public const Guid SCP_EVENTID_DRMINFO = .(0x213dd287, 0x41d2, 0x432b, 0x9e, 0x3f, 0x3b, 0x4f, 0x7b, 0x35, 0x81, 0xdd);
	public const Guid SCP_PARAMID_DRMVERSION = .(0x41d0155d, 0x7cc7, 0x4217, 0xad, 0xa9, 0x00, 0x50, 0x74, 0x62, 0x4d, 0xa4);
	public const uint32 SAC_MAC_LEN = 8;
	public const uint32 WMDM_LOG_SEV_INFO = 1;
	public const uint32 WMDM_LOG_SEV_WARN = 2;
	public const uint32 WMDM_LOG_SEV_ERROR = 4;
	public const uint32 WMDM_LOG_NOTIMESTAMP = 16;
	public const String g_wszWMDMFileName = "WMDM/FileName";
	public const String g_wszWMDMFormatCode = "WMDM/FormatCode";
	public const String g_wszWMDMLastModifiedDate = "WMDM/LastModifiedDate";
	public const String g_wszWMDMFileCreationDate = "WMDM/FileCreationDate";
	public const String g_wszWMDMFileSize = "WMDM/FileSize";
	public const String g_wszWMDMFileAttributes = "WMDM/FileAttributes";
	public const String g_wszAudioWAVECodec = "WMDM/AudioWAVECodec";
	public const String g_wszVideoFourCCCodec = "WMDM/VideoFourCCCodec";
	public const String g_wszWMDMTitle = "WMDM/Title";
	public const String g_wszWMDMAuthor = "WMDM/Author";
	public const String g_wszWMDMDescription = "WMDM/Description";
	public const String g_wszWMDMIsProtected = "WMDM/IsProtected";
	public const String g_wszWMDMAlbumTitle = "WMDM/AlbumTitle";
	public const String g_wszWMDMAlbumArtist = "WMDM/AlbumArtist";
	public const String g_wszWMDMTrack = "WMDM/Track";
	public const String g_wszWMDMGenre = "WMDM/Genre";
	public const String g_wszWMDMTrackMood = "WMDM/TrackMood";
	public const String g_wszWMDMAlbumCoverFormat = "WMDM/AlbumCoverFormat";
	public const String g_wszWMDMAlbumCoverSize = "WMDM/AlbumCoverSize";
	public const String g_wszWMDMAlbumCoverHeight = "WMDM/AlbumCoverHeight";
	public const String g_wszWMDMAlbumCoverWidth = "WMDM/AlbumCoverWidth";
	public const String g_wszWMDMAlbumCoverDuration = "WMDM/AlbumCoverDuration";
	public const String g_wszWMDMAlbumCoverData = "WMDM/AlbumCoverData";
	public const String g_wszWMDMYear = "WMDM/Year";
	public const String g_wszWMDMComposer = "WMDM/Composer";
	public const String g_wszWMDMCodec = "WMDM/Codec";
	public const String g_wszWMDMDRMId = "WMDM/DRMId";
	public const String g_wszWMDMBitrate = "WMDM/Bitrate";
	public const String g_wszWMDMBitRateType = "WMDM/BitRateType";
	public const String g_wszWMDMSampleRate = "WMDM/SampleRate";
	public const String g_wszWMDMNumChannels = "WMDM/NumChannels";
	public const String g_wszWMDMBlockAlignment = "WMDM/BlockAlignment";
	public const String g_wszWMDMAudioBitDepth = "WMDM/AudioBitDepth";
	public const String g_wszWMDMTotalBitrate = "WMDM/TotalBitrate";
	public const String g_wszWMDMVideoBitrate = "WMDM/VideoBitrate";
	public const String g_wszWMDMFrameRate = "WMDM/FrameRate";
	public const String g_wszWMDMScanType = "WMDM/ScanType";
	public const String g_wszWMDMKeyFrameDistance = "WMDM/KeyFrameDistance";
	public const String g_wszWMDMBufferSize = "WMDM/BufferSize";
	public const String g_wszWMDMQualitySetting = "WMDM/QualitySetting";
	public const String g_wszWMDMEncodingProfile = "WMDM/EncodingProfile";
	public const String g_wszWMDMDuration = "WMDM/Duration";
	public const String g_wszWMDMAlbumArt = "WMDM/AlbumArt";
	public const String g_wszWMDMBuyNow = "WMDM/BuyNow";
	public const String g_wszWMDMNonConsumable = "WMDM/NonConsumable";
	public const String g_wszWMDMediaClassPrimaryID = "WMDM/MediaClassPrimaryID";
	public const String g_wszWMDMMediaClassSecondaryID = "WMDM/MediaClassSecondaryID";
	public const String g_wszWMDMUserEffectiveRating = "WMDM/UserEffectiveRating";
	public const String g_wszWMDMUserRating = "WMDM/UserRating";
	public const String g_wszWMDMUserRatingOnDevice = "WMDM/UserRatingOnDevice";
	public const String g_wszWMDMPlayCount = "WMDM/PlayCount";
	public const String g_wszWMDMDevicePlayCount = "WMDM/DevicePlayCount";
	public const String g_wszWMDMAuthorDate = "WMDM/AuthorDate";
	public const String g_wszWMDMUserLastPlayTime = "WMDM/UserLastPlayTime";
	public const String g_wszWMDMSubTitle = "WMDM/SubTitle";
	public const String g_wszWMDMSubTitleDescription = "WMDM/SubTitleDescription";
	public const String g_wszWMDMMediaCredits = "WMDM/MediaCredits";
	public const String g_wszWMDMMediaStationName = "WMDM/MediaStationName";
	public const String g_wszWMDMMediaOriginalChannel = "WMDM/MediaOriginalChannel";
	public const String g_wszWMDMMediaOriginalBroadcastDateTime = "WMDM/MediaOriginalBroadcastDateTime";
	public const String g_wszWMDMProviderCopyright = "WMDM/ProviderCopyright";
	public const String g_wszWMDMSyncID = "WMDM/SyncID";
	public const String g_wszWMDMPersistentUniqueID = "WMDM/PersistentUniqueID";
	public const String g_wszWMDMWidth = "WMDM/Width";
	public const String g_wszWMDMHeight = "WMDM/Height";
	public const String g_wszWMDMSyncTime = "WMDM/SyncTime";
	public const String g_wszWMDMParentalRating = "WMDM/ParentalRating";
	public const String g_wszWMDMMetaGenre = "WMDM/MetaGenre";
	public const String g_wszWMDMIsRepeat = "WMDM/IsRepeat";
	public const String g_wszWMDMSupportedDeviceProperties = "WMDM/SupportedDeviceProperties";
	public const String g_wszWMDMDeviceFriendlyName = "WMDM/DeviceFriendlyName";
	public const String g_wszWMDMFormatsSupported = "WMDM/FormatsSupported";
	public const String g_wszWMDMFormatsSupportedAreOrdered = "WMDM/FormatsSupportedAreOrdered";
	public const String g_wszWMDMSyncRelationshipID = "WMDM/SyncRelationshipID";
	public const String g_wszWMDMDeviceModelName = "WMDM/DeviceModelName";
	public const String g_wszWMDMDeviceFirmwareVersion = "WMDM/DeviceFirmwareVersion";
	public const String g_wszWMDMDeviceVendorExtension = "WMDM/DeviceVendorExtension";
	public const String g_wszWMDMDeviceProtocol = "WMDM/DeviceProtocol";
	public const String g_wszWMDMDeviceServiceProviderVendor = "WMDM/DeviceServiceProviderVendor";
	public const String g_wszWMDMDeviceRevocationInfo = "WMDM/DeviceRevocationInfo";
	public const String g_wszWMDMCollectionID = "WMDM/CollectionID";
	public const String g_wszWMDMOwner = "WMDM/Owner";
	public const String g_wszWMDMEditor = "WMDM/Editor";
	public const String g_wszWMDMWebmaster = "WMDM/Webmaster";
	public const String g_wszWMDMSourceURL = "WMDM/SourceURL";
	public const String g_wszWMDMDestinationURL = "WMDM/DestinationURL";
	public const String g_wszWMDMCategory = "WMDM/Category";
	public const String g_wszWMDMTimeBookmark = "WMDM/TimeBookmark";
	public const String g_wszWMDMObjectBookmark = "WMDM/ObjectBookmark";
	public const String g_wszWMDMByteBookmark = "WMDM/ByteBookmark";
	public const String g_wszWMDMDataOffset = "WMDM/DataOffset";
	public const String g_wszWMDMDataLength = "WMDM/DataLength";
	public const String g_wszWMDMDataUnits = "WMDM/DataUnits";
	public const String g_wszWMDMTimeToLive = "WMDM/TimeToLive";
	public const String g_wszWMDMMediaGuid = "WMDM/MediaGuid";
	public const String g_wszWPDPassthroughPropertyValues = "WPD/PassthroughPropertyValues";
	public const Guid EVENT_WMDM_CONTENT_TRANSFER = .(0x339c9bf4, 0xbcfe, 0x4ed8, 0x94, 0xdf, 0xea, 0xf8, 0xc2, 0x6a, 0xb6, 0x1b);
	public const uint32 MTP_COMMAND_MAX_PARAMS = 5;
	public const uint32 MTP_RESPONSE_MAX_PARAMS = 5;
	public const uint16 MTP_RESPONSE_OK = 8193;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WMDM_TAG_DATATYPE : int32
{
	WMDM_TYPE_DWORD = 0,
	WMDM_TYPE_STRING = 1,
	WMDM_TYPE_BINARY = 2,
	WMDM_TYPE_BOOL = 3,
	WMDM_TYPE_QWORD = 4,
	WMDM_TYPE_WORD = 5,
	WMDM_TYPE_GUID = 6,
	WMDM_TYPE_DATE = 7,
}


[AllowDuplicates]
public enum WMDM_SESSION_TYPE : int32
{
	WMDM_SESSION_NONE = 0,
	WMDM_SESSION_TRANSFER_TO_DEVICE = 1,
	WMDM_SESSION_TRANSFER_FROM_DEVICE = 16,
	WMDM_SESSION_DELETE = 256,
	WMDM_SESSION_CUSTOM = 4096,
}


[AllowDuplicates]
public enum WMDM_STORAGE_ENUM_MODE : int32
{
	ENUM_MODE_RAW = 0,
	ENUM_MODE_USE_DEVICE_PREF = 1,
	ENUM_MODE_METADATA_VIEWS = 2,
}


[AllowDuplicates]
public enum WMDM_FORMATCODE : int32
{
	WMDM_FORMATCODE_NOTUSED = 0,
	WMDM_FORMATCODE_ALLIMAGES = -1,
	WMDM_FORMATCODE_UNDEFINED = 12288,
	WMDM_FORMATCODE_ASSOCIATION = 12289,
	WMDM_FORMATCODE_SCRIPT = 12290,
	WMDM_FORMATCODE_EXECUTABLE = 12291,
	WMDM_FORMATCODE_TEXT = 12292,
	WMDM_FORMATCODE_HTML = 12293,
	WMDM_FORMATCODE_DPOF = 12294,
	WMDM_FORMATCODE_AIFF = 12295,
	WMDM_FORMATCODE_WAVE = 12296,
	WMDM_FORMATCODE_MP3 = 12297,
	WMDM_FORMATCODE_AVI = 12298,
	WMDM_FORMATCODE_MPEG = 12299,
	WMDM_FORMATCODE_ASF = 12300,
	WMDM_FORMATCODE_RESERVED_FIRST = 12301,
	WMDM_FORMATCODE_RESERVED_LAST = 14335,
	WMDM_FORMATCODE_IMAGE_UNDEFINED = 14336,
	WMDM_FORMATCODE_IMAGE_EXIF = 14337,
	WMDM_FORMATCODE_IMAGE_TIFFEP = 14338,
	WMDM_FORMATCODE_IMAGE_FLASHPIX = 14339,
	WMDM_FORMATCODE_IMAGE_BMP = 14340,
	WMDM_FORMATCODE_IMAGE_CIFF = 14341,
	WMDM_FORMATCODE_IMAGE_GIF = 14343,
	WMDM_FORMATCODE_IMAGE_JFIF = 14344,
	WMDM_FORMATCODE_IMAGE_PCD = 14345,
	WMDM_FORMATCODE_IMAGE_PICT = 14346,
	WMDM_FORMATCODE_IMAGE_PNG = 14347,
	WMDM_FORMATCODE_IMAGE_TIFF = 14349,
	WMDM_FORMATCODE_IMAGE_TIFFIT = 14350,
	WMDM_FORMATCODE_IMAGE_JP2 = 14351,
	WMDM_FORMATCODE_IMAGE_JPX = 14352,
	WMDM_FORMATCODE_IMAGE_RESERVED_FIRST = 14353,
	WMDM_FORMATCODE_IMAGE_RESERVED_LAST = 16383,
	WMDM_FORMATCODE_UNDEFINEDFIRMWARE = 47106,
	WMDM_FORMATCODE_WBMP = 47107,
	WMDM_FORMATCODE_JPEGXR = 47108,
	WMDM_FORMATCODE_WINDOWSIMAGEFORMAT = 47233,
	WMDM_FORMATCODE_UNDEFINEDAUDIO = 47360,
	WMDM_FORMATCODE_WMA = 47361,
	WMDM_FORMATCODE_OGG = 47362,
	WMDM_FORMATCODE_AAC = 47363,
	WMDM_FORMATCODE_AUDIBLE = 47364,
	WMDM_FORMATCODE_FLAC = 47366,
	WMDM_FORMATCODE_QCELP = 47367,
	WMDM_FORMATCODE_AMR = 47368,
	WMDM_FORMATCODE_UNDEFINEDVIDEO = 47488,
	WMDM_FORMATCODE_WMV = 47489,
	WMDM_FORMATCODE_MP4 = 47490,
	WMDM_FORMATCODE_MP2 = 47491,
	WMDM_FORMATCODE_3GP = 47492,
	WMDM_FORMATCODE_3G2 = 47493,
	WMDM_FORMATCODE_AVCHD = 47494,
	WMDM_FORMATCODE_ATSCTS = 47495,
	WMDM_FORMATCODE_DVBTS = 47496,
	WMDM_FORMATCODE_MKV = 47497,
	WMDM_FORMATCODE_MKA = 47498,
	WMDM_FORMATCODE_MK3D = 47499,
	WMDM_FORMATCODE_UNDEFINEDCOLLECTION = 47616,
	WMDM_FORMATCODE_ABSTRACTMULTIMEDIAALBUM = 47617,
	WMDM_FORMATCODE_ABSTRACTIMAGEALBUM = 47618,
	WMDM_FORMATCODE_ABSTRACTAUDIOALBUM = 47619,
	WMDM_FORMATCODE_ABSTRACTVIDEOALBUM = 47620,
	WMDM_FORMATCODE_ABSTRACTAUDIOVIDEOPLAYLIST = 47621,
	WMDM_FORMATCODE_ABSTRACTCONTACTGROUP = 47622,
	WMDM_FORMATCODE_ABSTRACTMESSAGEFOLDER = 47623,
	WMDM_FORMATCODE_ABSTRACTCHAPTEREDPRODUCTION = 47624,
	WMDM_FORMATCODE_MEDIA_CAST = 47627,
	WMDM_FORMATCODE_WPLPLAYLIST = 47632,
	WMDM_FORMATCODE_M3UPLAYLIST = 47633,
	WMDM_FORMATCODE_MPLPLAYLIST = 47634,
	WMDM_FORMATCODE_ASXPLAYLIST = 47635,
	WMDM_FORMATCODE_PLSPLAYLIST = 47636,
	WMDM_FORMATCODE_UNDEFINEDDOCUMENT = 47744,
	WMDM_FORMATCODE_ABSTRACTDOCUMENT = 47745,
	WMDM_FORMATCODE_XMLDOCUMENT = 47746,
	WMDM_FORMATCODE_MICROSOFTWORDDOCUMENT = 47747,
	WMDM_FORMATCODE_MHTCOMPILEDHTMLDOCUMENT = 47748,
	WMDM_FORMATCODE_MICROSOFTEXCELSPREADSHEET = 47749,
	WMDM_FORMATCODE_MICROSOFTPOWERPOINTDOCUMENT = 47750,
	WMDM_FORMATCODE_UNDEFINEDMESSAGE = 47872,
	WMDM_FORMATCODE_ABSTRACTMESSAGE = 47873,
	WMDM_FORMATCODE_UNDEFINEDCONTACT = 48000,
	WMDM_FORMATCODE_ABSTRACTCONTACT = 48001,
	WMDM_FORMATCODE_VCARD2 = 48002,
	WMDM_FORMATCODE_VCARD3 = 48003,
	WMDM_FORMATCODE_UNDEFINEDCALENDARITEM = 48640,
	WMDM_FORMATCODE_ABSTRACTCALENDARITEM = 48641,
	WMDM_FORMATCODE_VCALENDAR1 = 48642,
	WMDM_FORMATCODE_VCALENDAR2 = 48643,
	WMDM_FORMATCODE_UNDEFINEDWINDOWSEXECUTABLE = 48768,
	WMDM_FORMATCODE_M4A = 1297101889,
	WMDM_FORMATCODE_3GPA = 860311617,
	WMDM_FORMATCODE_3G2A = 860303937,
	WMDM_FORMATCODE_SECTION = 48770,
}


[AllowDuplicates]
public enum WMDM_ENUM_PROP_VALID_VALUES_FORM : int32
{
	WMDM_ENUM_PROP_VALID_VALUES_ANY = 0,
	WMDM_ENUM_PROP_VALID_VALUES_RANGE = 1,
	WMDM_ENUM_PROP_VALID_VALUES_ENUM = 2,
}


[AllowDuplicates]
public enum WMDM_FIND_SCOPE : int32
{
	WMDM_FIND_SCOPE_GLOBAL = 0,
	WMDM_FIND_SCOPE_IMMEDIATE_CHILDREN = 1,
}


[AllowDuplicates]
public enum WMDMMessage : int32
{
	WMDM_MSG_DEVICE_ARRIVAL = 0,
	WMDM_MSG_DEVICE_REMOVAL = 1,
	WMDM_MSG_MEDIA_ARRIVAL = 2,
	WMDM_MSG_MEDIA_REMOVAL = 3,
}

#endregion


#region Structs
[CRepr]
public struct MACINFO
{
	public BOOL fUsed;
	public uint8[36] abMacState;
}

[CRepr]
public struct WMFILECAPABILITIES
{
	public PWSTR pwszMimeType;
	public uint32 dwReserved;
}

[CRepr]
public struct OPAQUECOMMAND
{
	public Guid guidCommand;
	public uint32 dwDataLen;
	public uint8* pData;
	public uint8[20] abMAC;
}

[CRepr]
public struct WMDMID
{
	public uint32 cbSize;
	public uint32 dwVendorID;
	public uint8[128] pID;
	public uint32 SerialNumberLength;
}

[CRepr]
public struct WMDMDATETIME
{
	public uint16 wYear;
	public uint16 wMonth;
	public uint16 wDay;
	public uint16 wHour;
	public uint16 wMinute;
	public uint16 wSecond;
}

[CRepr]
public struct WMDMRIGHTS
{
	public uint32 cbSize;
	public uint32 dwContentType;
	public uint32 fuFlags;
	public uint32 fuRights;
	public uint32 dwAppSec;
	public uint32 dwPlaybackCount;
	public WMDMDATETIME ExpirationDate;
}

[CRepr]
public struct WMDMMetadataView
{
	public PWSTR pwszViewName;
	public uint32 nDepth;
	public uint16** ppwszTags;
}

[CRepr]
public struct WMDM_PROP_VALUES_RANGE
{
	public PROPVARIANT rangeMin;
	public PROPVARIANT rangeMax;
	public PROPVARIANT rangeStep;
}

[CRepr]
public struct WMDM_PROP_VALUES_ENUM
{
	public uint32 cEnumValues;
	public PROPVARIANT* pValues;
}

[CRepr]
public struct WMDM_PROP_DESC
{
	[CRepr, Union]
	public struct _ValidValues_e__Union
	{
		public WMDM_PROP_VALUES_RANGE ValidValuesRange;
		public WMDM_PROP_VALUES_ENUM EnumeratedValidValues;
	}
	public PWSTR pwszPropName;
	public WMDM_ENUM_PROP_VALID_VALUES_FORM ValidValuesForm;
	public _ValidValues_e__Union ValidValues;
}

[CRepr]
public struct WMDM_PROP_CONFIG
{
	public uint32 nPreference;
	public uint32 nPropDesc;
	public WMDM_PROP_DESC* pPropDesc;
}

[CRepr]
public struct WMDM_FORMAT_CAPABILITY
{
	public uint32 nPropConfig;
	public WMDM_PROP_CONFIG* pConfigs;
}

[CRepr, Union]
public struct WMDMDetermineMaxPropStringLen
{
	public char16[27] sz001;
	public char16[31] sz002;
	public char16[14] sz003;
	public char16[16] sz004;
	public char16[22] sz005;
	public char16[14] sz006;
	public char16[20] sz007;
	public char16[20] sz008;
	public char16[22] sz009;
	public char16[11] sz010;
	public char16[12] sz011;
	public char16[17] sz012;
	public char16[17] sz013;
	public char16[16] sz014;
	public char16[17] sz015;
	public char16[11] sz016;
	public char16[11] sz017;
	public char16[15] sz018;
	public char16[22] sz019;
	public char16[20] sz020;
	public char16[22] sz021;
	public char16[21] sz022;
	public char16[24] sz023;
	public char16[20] sz024;
	public char16[10] sz025;
	public char16[14] sz026;
	public char16[11] sz027;
	public char16[11] sz028;
	public char16[13] sz029;
	public char16[17] sz030;
	public char16[16] sz031;
	public char16[17] sz032;
	public char16[20] sz033;
	public char16[19] sz034;
	public char16[18] sz035;
	public char16[18] sz036;
	public char16[15] sz037;
	public char16[14] sz041;
	public char16[22] sz043;
	public char16[16] sz044;
	public char16[20] sz045;
	public char16[14] sz046;
	public char16[14] sz047;
	public char16[12] sz048;
	public char16[25] sz049;
	public char16[26] sz050;
	public char16[25] sz051;
	public char16[16] sz052;
	public char16[24] sz053;
	public char16[15] sz054;
	public char16[21] sz055;
	public char16[16] sz056;
	public char16[22] sz057;
	public char16[14] sz058;
	public char16[25] sz059;
	public char16[18] sz060;
	public char16[22] sz061;
	public char16[26] sz062;
	public char16[36] sz063;
	public char16[23] sz064;
	public char16[12] sz065;
	public char16[24] sz066;
	public char16[11] sz067;
	public char16[12] sz068;
	public char16[14] sz069;
	public char16[20] sz070;
	public char16[15] sz071;
	public char16[14] sz072;
	public char16[31] sz073;
	public char16[24] sz074;
	public char16[22] sz075;
	public char16[24] sz076;
	public char16[21] sz077;
	public char16[27] sz078;
	public char16[27] sz079;
	public char16[20] sz080;
	public char16[33] sz081;
	public char16[21] sz082;
	public char16[32] sz083;
	public char16[26] sz084;
	public char16[18] sz085;
	public char16[30] sz086;
}

[CRepr, Packed(1)]
public struct MTP_COMMAND_DATA_IN
{
	public uint16 OpCode;
	public uint32 NumParams;
	public uint32[5] Params;
	public uint32 NextPhase;
	public uint32 CommandWriteDataSize;
	public uint8* CommandWriteData mut => &CommandWriteData_impl;
	private uint8[ANYSIZE_ARRAY] CommandWriteData_impl;
}

[CRepr, Packed(1)]
public struct MTP_COMMAND_DATA_OUT
{
	public uint16 ResponseCode;
	public uint32 NumParams;
	public uint32[5] Params;
	public uint32 CommandReadDataSize;
	public uint8* CommandReadData mut => &CommandReadData_impl;
	private uint8[ANYSIZE_ARRAY] CommandReadData_impl;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_MediaDevMgrClassFactory = .(0x50040c1d, 0xbdbf, 0x4924, 0xb8, 0x73, 0xf1, 0x4d, 0x6c, 0x5b, 0xfd, 0x66);


	public const Guid CLSID_MediaDevMgr = .(0x25baad81, 0x3560, 0x11d3, 0x84, 0x71, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);


	public const Guid CLSID_WMDMDevice = .(0x807b3cdf, 0x357a, 0x11d3, 0x84, 0x71, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);


	public const Guid CLSID_WMDMStorage = .(0x807b3ce0, 0x357a, 0x11d3, 0x84, 0x71, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);


	public const Guid CLSID_WMDMStorageGlobal = .(0x807b3ce1, 0x357a, 0x11d3, 0x84, 0x71, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);


	public const Guid CLSID_WMDMDeviceEnum = .(0x430e35af, 0x3971, 0x11d3, 0x84, 0x74, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);


	public const Guid CLSID_WMDMStorageEnum = .(0xeb401a3b, 0x3af7, 0x11d3, 0x84, 0x74, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);


	public const Guid CLSID_WMDMLogger = .(0x110a3202, 0x5a79, 0x11d3, 0x8d, 0x78, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);


}
#endregion

#region COM Types
[CRepr]struct IWMDMMetaData : IUnknown
{
	public new const Guid IID = .(0xec3b0663, 0x0951, 0x460a, 0x9a, 0x80, 0x0d, 0xce, 0xed, 0x3c, 0x04, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDM_TAG_DATATYPE Type, PWSTR pwszTagName, uint8* pValue, uint32 iLength) AddItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszTagName, WMDM_TAG_DATATYPE* pType, uint8** pValue, uint32* pcbLength) QueryByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, uint16** ppwszName, WMDM_TAG_DATATYPE* pType, uint8** ppValue, uint32* pcbLength) QueryByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* iCount) GetItemCount;
	}


	public HRESULT AddItem(WMDM_TAG_DATATYPE Type, PWSTR pwszTagName, uint8* pValue, uint32 iLength) mut => VT.[Friend]AddItem(&this, Type, pwszTagName, pValue, iLength);

	public HRESULT QueryByName(PWSTR pwszTagName, WMDM_TAG_DATATYPE* pType, uint8** pValue, uint32* pcbLength) mut => VT.[Friend]QueryByName(&this, pwszTagName, pType, pValue, pcbLength);

	public HRESULT QueryByIndex(uint32 iIndex, uint16** ppwszName, WMDM_TAG_DATATYPE* pType, uint8** ppValue, uint32* pcbLength) mut => VT.[Friend]QueryByIndex(&this, iIndex, ppwszName, pType, ppValue, pcbLength);

	public HRESULT GetItemCount(uint32* iCount) mut => VT.[Friend]GetItemCount(&this, iCount);
}

[CRepr]struct IWMDeviceManager : IUnknown
{
	public new const Guid IID = .(0x1dcb3a00, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwRevision) GetRevision;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetDeviceCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMEnumDevice** ppEnumDevice) EnumDevices;
	}


	public HRESULT GetRevision(uint32* pdwRevision) mut => VT.[Friend]GetRevision(&this, pdwRevision);

	public HRESULT GetDeviceCount(uint32* pdwCount) mut => VT.[Friend]GetDeviceCount(&this, pdwCount);

	public HRESULT EnumDevices(IWMDMEnumDevice** ppEnumDevice) mut => VT.[Friend]EnumDevices(&this, ppEnumDevice);
}

[CRepr]struct IWMDeviceManager2 : IWMDeviceManager
{
	public new const Guid IID = .(0x923e5249, 0x8731, 0x4c5b, 0x9b, 0x1c, 0xb8, 0xb6, 0x0b, 0x6e, 0x46, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDeviceManager.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszCanonicalName, IWMDMDevice** ppDevice) GetDeviceFromCanonicalName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMEnumDevice** ppEnumDevice) EnumDevices2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reinitialize;
	}


	public HRESULT GetDeviceFromCanonicalName(PWSTR pwszCanonicalName, IWMDMDevice** ppDevice) mut => VT.[Friend]GetDeviceFromCanonicalName(&this, pwszCanonicalName, ppDevice);

	public HRESULT EnumDevices2(IWMDMEnumDevice** ppEnumDevice) mut => VT.[Friend]EnumDevices2(&this, ppEnumDevice);

	public HRESULT Reinitialize() mut => VT.[Friend]Reinitialize(&this);
}

[CRepr]struct IWMDeviceManager3 : IWMDeviceManager2
{
	public new const Guid IID = .(0xaf185c41, 0x100d, 0x46ed, 0xbe, 0x2e, 0x9c, 0xe8, 0xc4, 0x45, 0x94, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDeviceManager2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEnumPref) SetDeviceEnumPreference;
	}


	public HRESULT SetDeviceEnumPreference(uint32 dwEnumPref) mut => VT.[Friend]SetDeviceEnumPreference(&this, dwEnumPref);
}

[CRepr]struct IWMDMStorageGlobals : IUnknown
{
	public new const Guid IID = .(0x1dcb3a07, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCapabilities) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDMID* pSerialNum, uint8* abMac) GetSerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwTotalSizeLow, uint32* pdwTotalSizeHigh) GetTotalSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFreeLow, uint32* pdwFreeHigh) GetTotalFree;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwBadLow, uint32* pdwBadHigh) GetTotalBad;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, IWMDMProgress* pProgress) Initialize;
	}


	public HRESULT GetCapabilities(uint32* pdwCapabilities) mut => VT.[Friend]GetCapabilities(&this, pdwCapabilities);

	public HRESULT GetSerialNumber(WMDMID* pSerialNum, uint8* abMac) mut => VT.[Friend]GetSerialNumber(&this, pSerialNum, abMac);

	public HRESULT GetTotalSize(uint32* pdwTotalSizeLow, uint32* pdwTotalSizeHigh) mut => VT.[Friend]GetTotalSize(&this, pdwTotalSizeLow, pdwTotalSizeHigh);

	public HRESULT GetTotalFree(uint32* pdwFreeLow, uint32* pdwFreeHigh) mut => VT.[Friend]GetTotalFree(&this, pdwFreeLow, pdwFreeHigh);

	public HRESULT GetTotalBad(uint32* pdwBadLow, uint32* pdwBadHigh) mut => VT.[Friend]GetTotalBad(&this, pdwBadLow, pdwBadHigh);

	public HRESULT GetStatus(uint32* pdwStatus) mut => VT.[Friend]GetStatus(&this, pdwStatus);

	public HRESULT Initialize(uint32 fuMode, IWMDMProgress* pProgress) mut => VT.[Friend]Initialize(&this, fuMode, pProgress);
}

[CRepr]struct IWMDMStorage : IUnknown
{
	public new const Guid IID = .(0x1dcb3a06, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAttributes, WAVEFORMATEX* pFormat) SetAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMStorageGlobals** ppStorageGlobals) GetStorageGlobals;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwAttributes, WAVEFORMATEX* pFormat) GetAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint32 nMaxChars) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDMDATETIME* pDateTimeUTC) GetDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwSizeLow, uint32* pdwSizeHigh) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDMRIGHTS** ppRights, uint32* pnRightsCount, uint8* abMac) GetRights;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMEnumStorage** pEnumStorage) EnumStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPAQUECOMMAND* pCommand) SendOpaqueCommand;
	}


	public HRESULT SetAttributes(uint32 dwAttributes, WAVEFORMATEX* pFormat) mut => VT.[Friend]SetAttributes(&this, dwAttributes, pFormat);

	public HRESULT GetStorageGlobals(IWMDMStorageGlobals** ppStorageGlobals) mut => VT.[Friend]GetStorageGlobals(&this, ppStorageGlobals);

	public HRESULT GetAttributes(uint32* pdwAttributes, WAVEFORMATEX* pFormat) mut => VT.[Friend]GetAttributes(&this, pdwAttributes, pFormat);

	public HRESULT GetName(char16* pwszName, uint32 nMaxChars) mut => VT.[Friend]GetName(&this, pwszName, nMaxChars);

	public HRESULT GetDate(WMDMDATETIME* pDateTimeUTC) mut => VT.[Friend]GetDate(&this, pDateTimeUTC);

	public HRESULT GetSize(uint32* pdwSizeLow, uint32* pdwSizeHigh) mut => VT.[Friend]GetSize(&this, pdwSizeLow, pdwSizeHigh);

	public HRESULT GetRights(WMDMRIGHTS** ppRights, uint32* pnRightsCount, uint8* abMac) mut => VT.[Friend]GetRights(&this, ppRights, pnRightsCount, abMac);

	public HRESULT EnumStorage(IWMDMEnumStorage** pEnumStorage) mut => VT.[Friend]EnumStorage(&this, pEnumStorage);

	public HRESULT SendOpaqueCommand(OPAQUECOMMAND* pCommand) mut => VT.[Friend]SendOpaqueCommand(&this, pCommand);
}

[CRepr]struct IWMDMStorage2 : IWMDMStorage
{
	public new const Guid IID = .(0x1ed5a144, 0x5cd5, 0x4683, 0x9e, 0xff, 0x72, 0xcb, 0xdb, 0x2d, 0x95, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMStorage.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStorageName, IWMDMStorage** ppStorage) GetStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAttributes, uint32 dwAttributesEx, WAVEFORMATEX* pFormat, VIDEOINFOHEADER* pVideoFormat) SetAttributes2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwAttributes, uint32* pdwAttributesEx, WAVEFORMATEX* pAudioFormat, VIDEOINFOHEADER* pVideoFormat) GetAttributes2;
	}


	public HRESULT GetStorage(PWSTR pszStorageName, IWMDMStorage** ppStorage) mut => VT.[Friend]GetStorage(&this, pszStorageName, ppStorage);

	public HRESULT SetAttributes2(uint32 dwAttributes, uint32 dwAttributesEx, WAVEFORMATEX* pFormat, VIDEOINFOHEADER* pVideoFormat) mut => VT.[Friend]SetAttributes2(&this, dwAttributes, dwAttributesEx, pFormat, pVideoFormat);

	public HRESULT GetAttributes2(uint32* pdwAttributes, uint32* pdwAttributesEx, WAVEFORMATEX* pAudioFormat, VIDEOINFOHEADER* pVideoFormat) mut => VT.[Friend]GetAttributes2(&this, pdwAttributes, pdwAttributesEx, pAudioFormat, pVideoFormat);
}

[CRepr]struct IWMDMStorage3 : IWMDMStorage2
{
	public new const Guid IID = .(0x97717eea, 0x926a, 0x464e, 0x96, 0xa4, 0x24, 0x7b, 0x02, 0x16, 0x02, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMStorage2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMMetaData** ppMetadata) GetMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMMetaData* pMetadata) SetMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMMetaData** ppMetadata) CreateEmptyMetadataObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDM_STORAGE_ENUM_MODE* pMode, uint32 nViews, WMDMMetadataView* pViews) SetEnumPreference;
	}


	public HRESULT GetMetadata(IWMDMMetaData** ppMetadata) mut => VT.[Friend]GetMetadata(&this, ppMetadata);

	public HRESULT SetMetadata(IWMDMMetaData* pMetadata) mut => VT.[Friend]SetMetadata(&this, pMetadata);

	public HRESULT CreateEmptyMetadataObject(IWMDMMetaData** ppMetadata) mut => VT.[Friend]CreateEmptyMetadataObject(&this, ppMetadata);

	public HRESULT SetEnumPreference(WMDM_STORAGE_ENUM_MODE* pMode, uint32 nViews, WMDMMetadataView* pViews) mut => VT.[Friend]SetEnumPreference(&this, pMode, nViews, pViews);
}

[CRepr]struct IWMDMStorage4 : IWMDMStorage3
{
	public new const Guid IID = .(0xc225bac5, 0xa03a, 0x40b8, 0x9a, 0x23, 0x91, 0xcf, 0x47, 0x8c, 0x64, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMStorage3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRefs, IWMDMStorage** ppIWMDMStorage) SetReferences;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwRefs, IWMDMStorage*** pppIWMDMStorage) GetReferences;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMProgress3* pIProgressCallback, WMDMRIGHTS** ppRights, uint32* pnRightsCount) GetRightsWithProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cProperties, PWSTR* ppwszPropNames, IWMDMMetaData** ppMetadata) GetSpecifiedMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDM_FIND_SCOPE findScope, PWSTR pwszUniqueID, IWMDMStorage** ppStorage) FindStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMStorage** ppStorage) GetParent;
	}


	public HRESULT SetReferences(uint32 dwRefs, IWMDMStorage** ppIWMDMStorage) mut => VT.[Friend]SetReferences(&this, dwRefs, ppIWMDMStorage);

	public HRESULT GetReferences(uint32* pdwRefs, IWMDMStorage*** pppIWMDMStorage) mut => VT.[Friend]GetReferences(&this, pdwRefs, pppIWMDMStorage);

	public HRESULT GetRightsWithProgress(IWMDMProgress3* pIProgressCallback, WMDMRIGHTS** ppRights, uint32* pnRightsCount) mut => VT.[Friend]GetRightsWithProgress(&this, pIProgressCallback, ppRights, pnRightsCount);

	public HRESULT GetSpecifiedMetadata(uint32 cProperties, PWSTR* ppwszPropNames, IWMDMMetaData** ppMetadata) mut => VT.[Friend]GetSpecifiedMetadata(&this, cProperties, ppwszPropNames, ppMetadata);

	public HRESULT FindStorage(WMDM_FIND_SCOPE findScope, PWSTR pwszUniqueID, IWMDMStorage** ppStorage) mut => VT.[Friend]FindStorage(&this, findScope, pwszUniqueID, ppStorage);

	public HRESULT GetParent(IWMDMStorage** ppStorage) mut => VT.[Friend]GetParent(&this, ppStorage);
}

[CRepr]struct IWMDMOperation : IUnknown
{
	public new const Guid IID = .(0x1dcb3a0b, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BeginRead;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BeginWrite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint32 nMaxChars) GetObjectName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint32 nMaxChars) SetObjectName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwAttributes, WAVEFORMATEX* pFormat) GetObjectAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAttributes, WAVEFORMATEX* pFormat) SetObjectAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwSize, uint32* pdwSizeHigh) GetObjectTotalSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSize, uint32 dwSizeHigh) SetObjectTotalSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32* pdwSize, uint8* abMac) TransferObjectData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* phCompletionCode, IUnknown* pNewObject) End;
	}


	public HRESULT BeginRead() mut => VT.[Friend]BeginRead(&this);

	public HRESULT BeginWrite() mut => VT.[Friend]BeginWrite(&this);

	public HRESULT GetObjectName(char16* pwszName, uint32 nMaxChars) mut => VT.[Friend]GetObjectName(&this, pwszName, nMaxChars);

	public HRESULT SetObjectName(char16* pwszName, uint32 nMaxChars) mut => VT.[Friend]SetObjectName(&this, pwszName, nMaxChars);

	public HRESULT GetObjectAttributes(uint32* pdwAttributes, WAVEFORMATEX* pFormat) mut => VT.[Friend]GetObjectAttributes(&this, pdwAttributes, pFormat);

	public HRESULT SetObjectAttributes(uint32 dwAttributes, WAVEFORMATEX* pFormat) mut => VT.[Friend]SetObjectAttributes(&this, dwAttributes, pFormat);

	public HRESULT GetObjectTotalSize(uint32* pdwSize, uint32* pdwSizeHigh) mut => VT.[Friend]GetObjectTotalSize(&this, pdwSize, pdwSizeHigh);

	public HRESULT SetObjectTotalSize(uint32 dwSize, uint32 dwSizeHigh) mut => VT.[Friend]SetObjectTotalSize(&this, dwSize, dwSizeHigh);

	public HRESULT TransferObjectData(uint8* pData, uint32* pdwSize, uint8* abMac) mut => VT.[Friend]TransferObjectData(&this, pData, pdwSize, abMac);

	public HRESULT End(HRESULT* phCompletionCode, IUnknown* pNewObject) mut => VT.[Friend]End(&this, phCompletionCode, pNewObject);
}

[CRepr]struct IWMDMOperation2 : IWMDMOperation
{
	public new const Guid IID = .(0x33445b48, 0x7df7, 0x425c, 0xad, 0x8f, 0x0f, 0xc6, 0xd8, 0x2f, 0x9f, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMOperation.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAttributes, uint32 dwAttributesEx, WAVEFORMATEX* pFormat, VIDEOINFOHEADER* pVideoFormat) SetObjectAttributes2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwAttributes, uint32* pdwAttributesEx, WAVEFORMATEX* pAudioFormat, VIDEOINFOHEADER* pVideoFormat) GetObjectAttributes2;
	}


	public HRESULT SetObjectAttributes2(uint32 dwAttributes, uint32 dwAttributesEx, WAVEFORMATEX* pFormat, VIDEOINFOHEADER* pVideoFormat) mut => VT.[Friend]SetObjectAttributes2(&this, dwAttributes, dwAttributesEx, pFormat, pVideoFormat);

	public HRESULT GetObjectAttributes2(uint32* pdwAttributes, uint32* pdwAttributesEx, WAVEFORMATEX* pAudioFormat, VIDEOINFOHEADER* pVideoFormat) mut => VT.[Friend]GetObjectAttributes2(&this, pdwAttributes, pdwAttributesEx, pAudioFormat, pVideoFormat);
}

[CRepr]struct IWMDMOperation3 : IWMDMOperation
{
	public new const Guid IID = .(0xd1f9b46a, 0x9ca8, 0x46d8, 0x9d, 0x0f, 0x1e, 0xc9, 0xba, 0xe5, 0x49, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMOperation.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32* pdwSize) TransferObjectDataOnClearChannel;
	}


	public HRESULT TransferObjectDataOnClearChannel(uint8* pData, uint32* pdwSize) mut => VT.[Friend]TransferObjectDataOnClearChannel(&this, pData, pdwSize);
}

[CRepr]struct IWMDMProgress : IUnknown
{
	public new const Guid IID = .(0x1dcb3a0c, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEstimatedTicks) Begin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwTranspiredTicks) Progress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) End;
	}


	public HRESULT Begin(uint32 dwEstimatedTicks) mut => VT.[Friend]Begin(&this, dwEstimatedTicks);

	public HRESULT Progress(uint32 dwTranspiredTicks) mut => VT.[Friend]Progress(&this, dwTranspiredTicks);

	public HRESULT End() mut => VT.[Friend]End(&this);
}

[CRepr]struct IWMDMProgress2 : IWMDMProgress
{
	public new const Guid IID = .(0x3a43f550, 0xb383, 0x4e92, 0xb0, 0x4a, 0xe6, 0xbb, 0xc6, 0x60, 0xfe, 0xfc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMProgress.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrCompletionCode) End2;
	}


	public HRESULT End2(HRESULT hrCompletionCode) mut => VT.[Friend]End2(&this, hrCompletionCode);
}

[CRepr]struct IWMDMProgress3 : IWMDMProgress2
{
	public new const Guid IID = .(0x21de01cb, 0x3bb4, 0x4929, 0xb2, 0x1a, 0x17, 0xaf, 0x3f, 0x80, 0xf6, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMProgress2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid EventId, uint32 dwEstimatedTicks, OPAQUECOMMAND* pContext) Begin3;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid EventId, uint32 dwTranspiredTicks, OPAQUECOMMAND* pContext) Progress3;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid EventId, HRESULT hrCompletionCode, OPAQUECOMMAND* pContext) End3;
	}


	public HRESULT Begin3(Guid EventId, uint32 dwEstimatedTicks, OPAQUECOMMAND* pContext) mut => VT.[Friend]Begin3(&this, EventId, dwEstimatedTicks, pContext);

	public HRESULT Progress3(Guid EventId, uint32 dwTranspiredTicks, OPAQUECOMMAND* pContext) mut => VT.[Friend]Progress3(&this, EventId, dwTranspiredTicks, pContext);

	public HRESULT End3(Guid EventId, HRESULT hrCompletionCode, OPAQUECOMMAND* pContext) mut => VT.[Friend]End3(&this, EventId, hrCompletionCode, pContext);
}

[CRepr]struct IWMDMDevice : IUnknown
{
	public new const Guid IID = .(0x1dcb3a02, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint32 nMaxChars) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint32 nMaxChars) GetManufacturer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwVersion) GetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDMID* pSerialNumber, uint8* abMac) GetSerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPowerSource, uint32* pdwPercentRemaining) GetPowerSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* hIcon) GetDeviceIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMEnumStorage** ppEnumStorage) EnumStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WAVEFORMATEX** ppFormatEx, uint32* pnFormatCount, PWSTR** pppwszMimeType, uint32* pnMimeTypeCount) GetFormatSupport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPAQUECOMMAND* pCommand) SendOpaqueCommand;
	}


	public HRESULT GetName(char16* pwszName, uint32 nMaxChars) mut => VT.[Friend]GetName(&this, pwszName, nMaxChars);

	public HRESULT GetManufacturer(char16* pwszName, uint32 nMaxChars) mut => VT.[Friend]GetManufacturer(&this, pwszName, nMaxChars);

	public HRESULT GetVersion(uint32* pdwVersion) mut => VT.[Friend]GetVersion(&this, pdwVersion);

	public HRESULT GetType(uint32* pdwType) mut => VT.[Friend]COM_GetType(&this, pdwType);

	public HRESULT GetSerialNumber(WMDMID* pSerialNumber, uint8* abMac) mut => VT.[Friend]GetSerialNumber(&this, pSerialNumber, abMac);

	public HRESULT GetPowerSource(uint32* pdwPowerSource, uint32* pdwPercentRemaining) mut => VT.[Friend]GetPowerSource(&this, pdwPowerSource, pdwPercentRemaining);

	public HRESULT GetStatus(uint32* pdwStatus) mut => VT.[Friend]GetStatus(&this, pdwStatus);

	public HRESULT GetDeviceIcon(uint32* hIcon) mut => VT.[Friend]GetDeviceIcon(&this, hIcon);

	public HRESULT EnumStorage(IWMDMEnumStorage** ppEnumStorage) mut => VT.[Friend]EnumStorage(&this, ppEnumStorage);

	public HRESULT GetFormatSupport(WAVEFORMATEX** ppFormatEx, uint32* pnFormatCount, PWSTR** pppwszMimeType, uint32* pnMimeTypeCount) mut => VT.[Friend]GetFormatSupport(&this, ppFormatEx, pnFormatCount, pppwszMimeType, pnMimeTypeCount);

	public HRESULT SendOpaqueCommand(OPAQUECOMMAND* pCommand) mut => VT.[Friend]SendOpaqueCommand(&this, pCommand);
}

[CRepr]struct IWMDMDevice2 : IWMDMDevice
{
	public new const Guid IID = .(0xe34f3d37, 0x9d67, 0x4fc1, 0x92, 0x52, 0x62, 0xd2, 0x8b, 0x2f, 0x8b, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMDevice.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStorageName, IWMDMStorage** ppStorage) GetStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, WAVEFORMATEX** ppAudioFormatEx, uint32* pnAudioFormatCount, VIDEOINFOHEADER** ppVideoFormatEx, uint32* pnVideoFormatCount, WMFILECAPABILITIES** ppFileType, uint32* pnFileTypeCount) GetFormatSupport2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpecifyPropertyPages** ppSpecifyPropPages, IUnknown*** pppUnknowns, uint32* pcUnks) GetSpecifyPropertyPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszPnPName, uint32 nMaxChars) GetCanonicalName;
	}


	public HRESULT GetStorage(PWSTR pszStorageName, IWMDMStorage** ppStorage) mut => VT.[Friend]GetStorage(&this, pszStorageName, ppStorage);

	public HRESULT GetFormatSupport2(uint32 dwFlags, WAVEFORMATEX** ppAudioFormatEx, uint32* pnAudioFormatCount, VIDEOINFOHEADER** ppVideoFormatEx, uint32* pnVideoFormatCount, WMFILECAPABILITIES** ppFileType, uint32* pnFileTypeCount) mut => VT.[Friend]GetFormatSupport2(&this, dwFlags, ppAudioFormatEx, pnAudioFormatCount, ppVideoFormatEx, pnVideoFormatCount, ppFileType, pnFileTypeCount);

	public HRESULT GetSpecifyPropertyPages(ISpecifyPropertyPages** ppSpecifyPropPages, IUnknown*** pppUnknowns, uint32* pcUnks) mut => VT.[Friend]GetSpecifyPropertyPages(&this, ppSpecifyPropPages, pppUnknowns, pcUnks);

	public HRESULT GetCanonicalName(char16* pwszPnPName, uint32 nMaxChars) mut => VT.[Friend]GetCanonicalName(&this, pwszPnPName, nMaxChars);
}

[CRepr]struct IWMDMDevice3 : IWMDMDevice2
{
	public new const Guid IID = .(0x6c03e4fe, 0x05db, 0x4dda, 0x9e, 0x3c, 0x06, 0x23, 0x3a, 0x6d, 0x5d, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMDevice2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPropName, PROPVARIANT* pValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPropName, PROPVARIANT* pValue) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDM_FORMATCODE format, WMDM_FORMAT_CAPABILITY* pFormatSupport) GetFormatCapability;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIoControlCode, uint8* lpInBuffer, uint32 nInBufferSize, uint8* lpOutBuffer, uint32* pnOutBufferSize) DeviceIoControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDM_FIND_SCOPE findScope, PWSTR pwszUniqueID, IWMDMStorage** ppStorage) FindStorage;
	}


	public HRESULT GetProperty(PWSTR pwszPropName, PROPVARIANT* pValue) mut => VT.[Friend]GetProperty(&this, pwszPropName, pValue);

	public HRESULT SetProperty(PWSTR pwszPropName, PROPVARIANT* pValue) mut => VT.[Friend]SetProperty(&this, pwszPropName, pValue);

	public HRESULT GetFormatCapability(WMDM_FORMATCODE format, WMDM_FORMAT_CAPABILITY* pFormatSupport) mut => VT.[Friend]GetFormatCapability(&this, format, pFormatSupport);

	public HRESULT DeviceIoControl(uint32 dwIoControlCode, uint8* lpInBuffer, uint32 nInBufferSize, uint8* lpOutBuffer, uint32* pnOutBufferSize) mut => VT.[Friend]DeviceIoControl(&this, dwIoControlCode, lpInBuffer, nInBufferSize, lpOutBuffer, pnOutBufferSize);

	public HRESULT FindStorage(WMDM_FIND_SCOPE findScope, PWSTR pwszUniqueID, IWMDMStorage** ppStorage) mut => VT.[Friend]FindStorage(&this, findScope, pwszUniqueID, ppStorage);
}

[CRepr]struct IWMDMDeviceSession : IUnknown
{
	public new const Guid IID = .(0x82af0a65, 0x9d96, 0x412c, 0x83, 0xe5, 0x3c, 0x43, 0xe4, 0xb0, 0x6c, 0xc7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDM_SESSION_TYPE type, uint8* pCtx, uint32 dwSizeCtx) BeginSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDM_SESSION_TYPE type, uint8* pCtx, uint32 dwSizeCtx) EndSession;
	}


	public HRESULT BeginSession(WMDM_SESSION_TYPE type, uint8* pCtx, uint32 dwSizeCtx) mut => VT.[Friend]BeginSession(&this, type, pCtx, dwSizeCtx);

	public HRESULT EndSession(WMDM_SESSION_TYPE type, uint8* pCtx, uint32 dwSizeCtx) mut => VT.[Friend]EndSession(&this, type, pCtx, dwSizeCtx);
}

[CRepr]struct IWMDMEnumDevice : IUnknown
{
	public new const Guid IID = .(0x1dcb3a01, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IWMDMDevice** ppDevice, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, uint32* pceltFetched) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMEnumDevice** ppEnumDevice) Clone;
	}


	public HRESULT Next(uint32 celt, IWMDMDevice** ppDevice, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, ppDevice, pceltFetched);

	public HRESULT Skip(uint32 celt, uint32* pceltFetched) mut => VT.[Friend]Skip(&this, celt, pceltFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IWMDMEnumDevice** ppEnumDevice) mut => VT.[Friend]Clone(&this, ppEnumDevice);
}

[CRepr]struct IWMDMDeviceControl : IUnknown
{
	public new const Guid IID = .(0x1dcb3a04, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCapabilitiesMask) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Play;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WAVEFORMATEX* pFormat) Record;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, int32 nOffset) Seek;
	}


	public HRESULT GetStatus(uint32* pdwStatus) mut => VT.[Friend]GetStatus(&this, pdwStatus);

	public HRESULT GetCapabilities(uint32* pdwCapabilitiesMask) mut => VT.[Friend]GetCapabilities(&this, pdwCapabilitiesMask);

	public HRESULT Play() mut => VT.[Friend]Play(&this);

	public HRESULT Record(WAVEFORMATEX* pFormat) mut => VT.[Friend]Record(&this, pFormat);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT Seek(uint32 fuMode, int32 nOffset) mut => VT.[Friend]Seek(&this, fuMode, nOffset);
}

[CRepr]struct IWMDMEnumStorage : IUnknown
{
	public new const Guid IID = .(0x1dcb3a05, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IWMDMStorage** ppStorage, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, uint32* pceltFetched) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMEnumStorage** ppEnumStorage) Clone;
	}


	public HRESULT Next(uint32 celt, IWMDMStorage** ppStorage, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, ppStorage, pceltFetched);

	public HRESULT Skip(uint32 celt, uint32* pceltFetched) mut => VT.[Friend]Skip(&this, celt, pceltFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IWMDMEnumStorage** ppEnumStorage) mut => VT.[Friend]Clone(&this, ppEnumStorage);
}

[CRepr]struct IWMDMStorageControl : IUnknown
{
	public new const Guid IID = .(0x1dcb3a08, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, PWSTR pwszFile, IWMDMOperation* pOperation, IWMDMProgress* pProgress, IWMDMStorage** ppNewObject) Insert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, IWMDMProgress* pProgress) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, PWSTR pwszNewName, IWMDMProgress* pProgress) Rename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, PWSTR pwszFile, IWMDMProgress* pProgress, IWMDMOperation* pOperation) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, IWMDMStorage* pTargetObject, IWMDMProgress* pProgress) Move;
	}


	public HRESULT Insert(uint32 fuMode, PWSTR pwszFile, IWMDMOperation* pOperation, IWMDMProgress* pProgress, IWMDMStorage** ppNewObject) mut => VT.[Friend]Insert(&this, fuMode, pwszFile, pOperation, pProgress, ppNewObject);

	public HRESULT Delete(uint32 fuMode, IWMDMProgress* pProgress) mut => VT.[Friend]Delete(&this, fuMode, pProgress);

	public HRESULT Rename(uint32 fuMode, PWSTR pwszNewName, IWMDMProgress* pProgress) mut => VT.[Friend]Rename(&this, fuMode, pwszNewName, pProgress);

	public HRESULT Read(uint32 fuMode, PWSTR pwszFile, IWMDMProgress* pProgress, IWMDMOperation* pOperation) mut => VT.[Friend]Read(&this, fuMode, pwszFile, pProgress, pOperation);

	public HRESULT Move(uint32 fuMode, IWMDMStorage* pTargetObject, IWMDMProgress* pProgress) mut => VT.[Friend]Move(&this, fuMode, pTargetObject, pProgress);
}

[CRepr]struct IWMDMStorageControl2 : IWMDMStorageControl
{
	public new const Guid IID = .(0x972c2e88, 0xbd6c, 0x4125, 0x8e, 0x09, 0x84, 0xf8, 0x37, 0xe6, 0x37, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMStorageControl.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, PWSTR pwszFileSource, PWSTR pwszFileDest, IWMDMOperation* pOperation, IWMDMProgress* pProgress, IUnknown* pUnknown, IWMDMStorage** ppNewObject) Insert2;
	}


	public HRESULT Insert2(uint32 fuMode, PWSTR pwszFileSource, PWSTR pwszFileDest, IWMDMOperation* pOperation, IWMDMProgress* pProgress, IUnknown* pUnknown, IWMDMStorage** ppNewObject) mut => VT.[Friend]Insert2(&this, fuMode, pwszFileSource, pwszFileDest, pOperation, pProgress, pUnknown, ppNewObject);
}

[CRepr]struct IWMDMStorageControl3 : IWMDMStorageControl2
{
	public new const Guid IID = .(0xb3266365, 0xd4f3, 0x4696, 0x8d, 0x53, 0xbd, 0x27, 0xec, 0x60, 0x99, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMDMStorageControl2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, uint32 fuType, PWSTR pwszFileSource, PWSTR pwszFileDest, IWMDMOperation* pOperation, IWMDMProgress* pProgress, IWMDMMetaData* pMetaData, IUnknown* pUnknown, IWMDMStorage** ppNewObject) Insert3;
	}


	public HRESULT Insert3(uint32 fuMode, uint32 fuType, PWSTR pwszFileSource, PWSTR pwszFileDest, IWMDMOperation* pOperation, IWMDMProgress* pProgress, IWMDMMetaData* pMetaData, IUnknown* pUnknown, IWMDMStorage** ppNewObject) mut => VT.[Friend]Insert3(&this, fuMode, fuType, pwszFileSource, pwszFileDest, pOperation, pProgress, pMetaData, pUnknown, ppNewObject);
}

[CRepr]struct IWMDMObjectInfo : IUnknown
{
	public new const Guid IID = .(0x1dcb3a09, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLength) GetPlayLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLength) SetPlayLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwOffset) GetPlayOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOffset) SetPlayOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLength) GetTotalLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLastPos) GetLastPlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLongestPos) GetLongestPlayPosition;
	}


	public HRESULT GetPlayLength(uint32* pdwLength) mut => VT.[Friend]GetPlayLength(&this, pdwLength);

	public HRESULT SetPlayLength(uint32 dwLength) mut => VT.[Friend]SetPlayLength(&this, dwLength);

	public HRESULT GetPlayOffset(uint32* pdwOffset) mut => VT.[Friend]GetPlayOffset(&this, pdwOffset);

	public HRESULT SetPlayOffset(uint32 dwOffset) mut => VT.[Friend]SetPlayOffset(&this, dwOffset);

	public HRESULT GetTotalLength(uint32* pdwLength) mut => VT.[Friend]GetTotalLength(&this, pdwLength);

	public HRESULT GetLastPlayPosition(uint32* pdwLastPos) mut => VT.[Friend]GetLastPlayPosition(&this, pdwLastPos);

	public HRESULT GetLongestPlayPosition(uint32* pdwLongestPos) mut => VT.[Friend]GetLongestPlayPosition(&this, pdwLongestPos);
}

[CRepr]struct IWMDMRevoked : IUnknown
{
	public new const Guid IID = .(0xebeccedb, 0x88ee, 0x4e55, 0xb6, 0xa4, 0x8d, 0x9f, 0x07, 0xd6, 0x96, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszRevocationURL, uint32* pdwBufferLen, uint32* pdwRevokedBitFlag) GetRevocationURL;
	}


	public HRESULT GetRevocationURL(PWSTR* ppwszRevocationURL, uint32* pdwBufferLen, uint32* pdwRevokedBitFlag) mut => VT.[Friend]GetRevocationURL(&this, ppwszRevocationURL, pdwBufferLen, pdwRevokedBitFlag);
}

[CRepr]struct IWMDMNotification : IUnknown
{
	public new const Guid IID = .(0x3f5e95c0, 0x0f43, 0x4ed4, 0x93, 0xd2, 0xc8, 0x9a, 0x45, 0xd5, 0x9b, 0x81);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMessageType, PWSTR pwszCanonicalName) WMDMMessage;
	}


	public HRESULT WMDMMessage(uint32 dwMessageType, PWSTR pwszCanonicalName) mut => VT.[Friend]WMDMMessage(&this, dwMessageType, pwszCanonicalName);
}

[CRepr]struct IMDServiceProvider : IUnknown
{
	public new const Guid IID = .(0x1dcb3a10, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetDeviceCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPEnumDevice** ppEnumDevice) EnumDevices;
	}


	public HRESULT GetDeviceCount(uint32* pdwCount) mut => VT.[Friend]GetDeviceCount(&this, pdwCount);

	public HRESULT EnumDevices(IMDSPEnumDevice** ppEnumDevice) mut => VT.[Friend]EnumDevices(&this, ppEnumDevice);
}

[CRepr]struct IMDServiceProvider2 : IMDServiceProvider
{
	public new const Guid IID = .(0xb2fa24b7, 0xcda3, 0x4694, 0x98, 0x62, 0x41, 0x3a, 0xe1, 0xa3, 0x48, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMDServiceProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszDevicePath, uint32* pdwCount, IMDSPDevice*** pppDeviceArray) CreateDevice;
	}


	public HRESULT CreateDevice(PWSTR pwszDevicePath, uint32* pdwCount, IMDSPDevice*** pppDeviceArray) mut => VT.[Friend]CreateDevice(&this, pwszDevicePath, pdwCount, pppDeviceArray);
}

[CRepr]struct IMDServiceProvider3 : IMDServiceProvider2
{
	public new const Guid IID = .(0x4ed13ef3, 0xa971, 0x4d19, 0x9f, 0x51, 0x0e, 0x18, 0x26, 0xb2, 0xda, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMDServiceProvider2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEnumPref) SetDeviceEnumPreference;
	}


	public HRESULT SetDeviceEnumPreference(uint32 dwEnumPref) mut => VT.[Friend]SetDeviceEnumPreference(&this, dwEnumPref);
}

[CRepr]struct IMDSPEnumDevice : IUnknown
{
	public new const Guid IID = .(0x1dcb3a11, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IMDSPDevice** ppDevice, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, uint32* pceltFetched) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPEnumDevice** ppEnumDevice) Clone;
	}


	public HRESULT Next(uint32 celt, IMDSPDevice** ppDevice, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, ppDevice, pceltFetched);

	public HRESULT Skip(uint32 celt, uint32* pceltFetched) mut => VT.[Friend]Skip(&this, celt, pceltFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IMDSPEnumDevice** ppEnumDevice) mut => VT.[Friend]Clone(&this, ppEnumDevice);
}

[CRepr]struct IMDSPDevice : IUnknown
{
	public new const Guid IID = .(0x1dcb3a12, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint32 nMaxChars) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint32 nMaxChars) GetManufacturer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwVersion) GetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDMID* pSerialNumber, uint8* abMac) GetSerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPowerSource, uint32* pdwPercentRemaining) GetPowerSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* hIcon) GetDeviceIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPEnumStorage** ppEnumStorage) EnumStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WAVEFORMATEX** pFormatEx, uint32* pnFormatCount, PWSTR** pppwszMimeType, uint32* pnMimeTypeCount) GetFormatSupport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPAQUECOMMAND* pCommand) SendOpaqueCommand;
	}


	public HRESULT GetName(char16* pwszName, uint32 nMaxChars) mut => VT.[Friend]GetName(&this, pwszName, nMaxChars);

	public HRESULT GetManufacturer(char16* pwszName, uint32 nMaxChars) mut => VT.[Friend]GetManufacturer(&this, pwszName, nMaxChars);

	public HRESULT GetVersion(uint32* pdwVersion) mut => VT.[Friend]GetVersion(&this, pdwVersion);

	public HRESULT GetType(uint32* pdwType) mut => VT.[Friend]COM_GetType(&this, pdwType);

	public HRESULT GetSerialNumber(WMDMID* pSerialNumber, uint8* abMac) mut => VT.[Friend]GetSerialNumber(&this, pSerialNumber, abMac);

	public HRESULT GetPowerSource(uint32* pdwPowerSource, uint32* pdwPercentRemaining) mut => VT.[Friend]GetPowerSource(&this, pdwPowerSource, pdwPercentRemaining);

	public HRESULT GetStatus(uint32* pdwStatus) mut => VT.[Friend]GetStatus(&this, pdwStatus);

	public HRESULT GetDeviceIcon(uint32* hIcon) mut => VT.[Friend]GetDeviceIcon(&this, hIcon);

	public HRESULT EnumStorage(IMDSPEnumStorage** ppEnumStorage) mut => VT.[Friend]EnumStorage(&this, ppEnumStorage);

	public HRESULT GetFormatSupport(WAVEFORMATEX** pFormatEx, uint32* pnFormatCount, PWSTR** pppwszMimeType, uint32* pnMimeTypeCount) mut => VT.[Friend]GetFormatSupport(&this, pFormatEx, pnFormatCount, pppwszMimeType, pnMimeTypeCount);

	public HRESULT SendOpaqueCommand(OPAQUECOMMAND* pCommand) mut => VT.[Friend]SendOpaqueCommand(&this, pCommand);
}

[CRepr]struct IMDSPDevice2 : IMDSPDevice
{
	public new const Guid IID = .(0x420d16ad, 0xc97d, 0x4e00, 0x82, 0xaa, 0x00, 0xe9, 0xf4, 0x33, 0x5d, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMDSPDevice.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStorageName, IMDSPStorage** ppStorage) GetStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, WAVEFORMATEX** ppAudioFormatEx, uint32* pnAudioFormatCount, VIDEOINFOHEADER** ppVideoFormatEx, uint32* pnVideoFormatCount, WMFILECAPABILITIES** ppFileType, uint32* pnFileTypeCount) GetFormatSupport2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISpecifyPropertyPages** ppSpecifyPropPages, IUnknown*** pppUnknowns, uint32* pcUnks) GetSpecifyPropertyPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszPnPName, uint32 nMaxChars) GetCanonicalName;
	}


	public HRESULT GetStorage(PWSTR pszStorageName, IMDSPStorage** ppStorage) mut => VT.[Friend]GetStorage(&this, pszStorageName, ppStorage);

	public HRESULT GetFormatSupport2(uint32 dwFlags, WAVEFORMATEX** ppAudioFormatEx, uint32* pnAudioFormatCount, VIDEOINFOHEADER** ppVideoFormatEx, uint32* pnVideoFormatCount, WMFILECAPABILITIES** ppFileType, uint32* pnFileTypeCount) mut => VT.[Friend]GetFormatSupport2(&this, dwFlags, ppAudioFormatEx, pnAudioFormatCount, ppVideoFormatEx, pnVideoFormatCount, ppFileType, pnFileTypeCount);

	public HRESULT GetSpecifyPropertyPages(ISpecifyPropertyPages** ppSpecifyPropPages, IUnknown*** pppUnknowns, uint32* pcUnks) mut => VT.[Friend]GetSpecifyPropertyPages(&this, ppSpecifyPropPages, pppUnknowns, pcUnks);

	public HRESULT GetCanonicalName(char16* pwszPnPName, uint32 nMaxChars) mut => VT.[Friend]GetCanonicalName(&this, pwszPnPName, nMaxChars);
}

[CRepr]struct IMDSPDevice3 : IMDSPDevice2
{
	public new const Guid IID = .(0x1a839845, 0xfc55, 0x487c, 0x97, 0x6f, 0xee, 0x38, 0xac, 0x0e, 0x8c, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMDSPDevice2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPropName, PROPVARIANT* pValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPropName, PROPVARIANT* pValue) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDM_FORMATCODE format, WMDM_FORMAT_CAPABILITY* pFormatSupport) GetFormatCapability;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIoControlCode, uint8* lpInBuffer, uint32 nInBufferSize, uint8* lpOutBuffer, uint32* pnOutBufferSize) DeviceIoControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDM_FIND_SCOPE findScope, PWSTR pwszUniqueID, IMDSPStorage** ppStorage) FindStorage;
	}


	public HRESULT GetProperty(PWSTR pwszPropName, PROPVARIANT* pValue) mut => VT.[Friend]GetProperty(&this, pwszPropName, pValue);

	public HRESULT SetProperty(PWSTR pwszPropName, PROPVARIANT* pValue) mut => VT.[Friend]SetProperty(&this, pwszPropName, pValue);

	public HRESULT GetFormatCapability(WMDM_FORMATCODE format, WMDM_FORMAT_CAPABILITY* pFormatSupport) mut => VT.[Friend]GetFormatCapability(&this, format, pFormatSupport);

	public HRESULT DeviceIoControl(uint32 dwIoControlCode, uint8* lpInBuffer, uint32 nInBufferSize, uint8* lpOutBuffer, uint32* pnOutBufferSize) mut => VT.[Friend]DeviceIoControl(&this, dwIoControlCode, lpInBuffer, nInBufferSize, lpOutBuffer, pnOutBufferSize);

	public HRESULT FindStorage(WMDM_FIND_SCOPE findScope, PWSTR pwszUniqueID, IMDSPStorage** ppStorage) mut => VT.[Friend]FindStorage(&this, findScope, pwszUniqueID, ppStorage);
}

[CRepr]struct IMDSPDeviceControl : IUnknown
{
	public new const Guid IID = .(0x1dcb3a14, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetDCStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCapabilitiesMask) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Play;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WAVEFORMATEX* pFormat) Record;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, int32 nOffset) Seek;
	}


	public HRESULT GetDCStatus(uint32* pdwStatus) mut => VT.[Friend]GetDCStatus(&this, pdwStatus);

	public HRESULT GetCapabilities(uint32* pdwCapabilitiesMask) mut => VT.[Friend]GetCapabilities(&this, pdwCapabilitiesMask);

	public HRESULT Play() mut => VT.[Friend]Play(&this);

	public HRESULT Record(WAVEFORMATEX* pFormat) mut => VT.[Friend]Record(&this, pFormat);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT Seek(uint32 fuMode, int32 nOffset) mut => VT.[Friend]Seek(&this, fuMode, nOffset);
}

[CRepr]struct IMDSPEnumStorage : IUnknown
{
	public new const Guid IID = .(0x1dcb3a15, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IMDSPStorage** ppStorage, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, uint32* pceltFetched) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPEnumStorage** ppEnumStorage) Clone;
	}


	public HRESULT Next(uint32 celt, IMDSPStorage** ppStorage, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, ppStorage, pceltFetched);

	public HRESULT Skip(uint32 celt, uint32* pceltFetched) mut => VT.[Friend]Skip(&this, celt, pceltFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IMDSPEnumStorage** ppEnumStorage) mut => VT.[Friend]Clone(&this, ppEnumStorage);
}

[CRepr]struct IMDSPStorage : IUnknown
{
	public new const Guid IID = .(0x1dcb3a16, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAttributes, WAVEFORMATEX* pFormat) SetAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPStorageGlobals** ppStorageGlobals) GetStorageGlobals;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwAttributes, WAVEFORMATEX* pFormat) GetAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszName, uint32 nMaxChars) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDMDATETIME* pDateTimeUTC) GetDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwSizeLow, uint32* pdwSizeHigh) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDMRIGHTS** ppRights, uint32* pnRightsCount, uint8* abMac) GetRights;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAttributes, WAVEFORMATEX* pFormat, PWSTR pwszName, IMDSPStorage** ppNewStorage) CreateStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPEnumStorage** ppEnumStorage) EnumStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPAQUECOMMAND* pCommand) SendOpaqueCommand;
	}


	public HRESULT SetAttributes(uint32 dwAttributes, WAVEFORMATEX* pFormat) mut => VT.[Friend]SetAttributes(&this, dwAttributes, pFormat);

	public HRESULT GetStorageGlobals(IMDSPStorageGlobals** ppStorageGlobals) mut => VT.[Friend]GetStorageGlobals(&this, ppStorageGlobals);

	public HRESULT GetAttributes(uint32* pdwAttributes, WAVEFORMATEX* pFormat) mut => VT.[Friend]GetAttributes(&this, pdwAttributes, pFormat);

	public HRESULT GetName(char16* pwszName, uint32 nMaxChars) mut => VT.[Friend]GetName(&this, pwszName, nMaxChars);

	public HRESULT GetDate(WMDMDATETIME* pDateTimeUTC) mut => VT.[Friend]GetDate(&this, pDateTimeUTC);

	public HRESULT GetSize(uint32* pdwSizeLow, uint32* pdwSizeHigh) mut => VT.[Friend]GetSize(&this, pdwSizeLow, pdwSizeHigh);

	public HRESULT GetRights(WMDMRIGHTS** ppRights, uint32* pnRightsCount, uint8* abMac) mut => VT.[Friend]GetRights(&this, ppRights, pnRightsCount, abMac);

	public HRESULT CreateStorage(uint32 dwAttributes, WAVEFORMATEX* pFormat, PWSTR pwszName, IMDSPStorage** ppNewStorage) mut => VT.[Friend]CreateStorage(&this, dwAttributes, pFormat, pwszName, ppNewStorage);

	public HRESULT EnumStorage(IMDSPEnumStorage** ppEnumStorage) mut => VT.[Friend]EnumStorage(&this, ppEnumStorage);

	public HRESULT SendOpaqueCommand(OPAQUECOMMAND* pCommand) mut => VT.[Friend]SendOpaqueCommand(&this, pCommand);
}

[CRepr]struct IMDSPStorage2 : IMDSPStorage
{
	public new const Guid IID = .(0x0a5e07a5, 0x6454, 0x4451, 0x9c, 0x36, 0x1c, 0x6a, 0xe7, 0xe2, 0xb1, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMDSPStorage.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStorageName, IMDSPStorage** ppStorage) GetStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAttributes, uint32 dwAttributesEx, WAVEFORMATEX* pAudioFormat, VIDEOINFOHEADER* pVideoFormat, PWSTR pwszName, uint64 qwFileSize, IMDSPStorage** ppNewStorage) CreateStorage2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAttributes, uint32 dwAttributesEx, WAVEFORMATEX* pAudioFormat, VIDEOINFOHEADER* pVideoFormat) SetAttributes2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwAttributes, uint32* pdwAttributesEx, WAVEFORMATEX* pAudioFormat, VIDEOINFOHEADER* pVideoFormat) GetAttributes2;
	}


	public HRESULT GetStorage(PWSTR pszStorageName, IMDSPStorage** ppStorage) mut => VT.[Friend]GetStorage(&this, pszStorageName, ppStorage);

	public HRESULT CreateStorage2(uint32 dwAttributes, uint32 dwAttributesEx, WAVEFORMATEX* pAudioFormat, VIDEOINFOHEADER* pVideoFormat, PWSTR pwszName, uint64 qwFileSize, IMDSPStorage** ppNewStorage) mut => VT.[Friend]CreateStorage2(&this, dwAttributes, dwAttributesEx, pAudioFormat, pVideoFormat, pwszName, qwFileSize, ppNewStorage);

	public HRESULT SetAttributes2(uint32 dwAttributes, uint32 dwAttributesEx, WAVEFORMATEX* pAudioFormat, VIDEOINFOHEADER* pVideoFormat) mut => VT.[Friend]SetAttributes2(&this, dwAttributes, dwAttributesEx, pAudioFormat, pVideoFormat);

	public HRESULT GetAttributes2(uint32* pdwAttributes, uint32* pdwAttributesEx, WAVEFORMATEX* pAudioFormat, VIDEOINFOHEADER* pVideoFormat) mut => VT.[Friend]GetAttributes2(&this, pdwAttributes, pdwAttributesEx, pAudioFormat, pVideoFormat);
}

[CRepr]struct IMDSPStorage3 : IMDSPStorage2
{
	public new const Guid IID = .(0x6c669867, 0x97ed, 0x4a67, 0x97, 0x06, 0x1c, 0x55, 0x29, 0xd2, 0xa4, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMDSPStorage2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMMetaData* pMetadata) GetMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMDMMetaData* pMetadata) SetMetadata;
	}


	public HRESULT GetMetadata(IWMDMMetaData* pMetadata) mut => VT.[Friend]GetMetadata(&this, pMetadata);

	public HRESULT SetMetadata(IWMDMMetaData* pMetadata) mut => VT.[Friend]SetMetadata(&this, pMetadata);
}

[CRepr]struct IMDSPStorage4 : IMDSPStorage3
{
	public new const Guid IID = .(0x3133b2c4, 0x515c, 0x481b, 0xb1, 0xce, 0x39, 0x32, 0x7e, 0xcb, 0x4f, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMDSPStorage3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRefs, IMDSPStorage** ppISPStorage) SetReferences;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwRefs, IMDSPStorage*** pppISPStorage) GetReferences;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAttributes, PWSTR pwszName, IWMDMMetaData* pMetadata, uint64 qwFileSize, IMDSPStorage** ppNewStorage) CreateStorageWithMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cProperties, PWSTR* ppwszPropNames, IWMDMMetaData* pMetadata) GetSpecifiedMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDM_FIND_SCOPE findScope, PWSTR pwszUniqueID, IMDSPStorage** ppStorage) FindStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPStorage** ppStorage) GetParent;
	}


	public HRESULT SetReferences(uint32 dwRefs, IMDSPStorage** ppISPStorage) mut => VT.[Friend]SetReferences(&this, dwRefs, ppISPStorage);

	public HRESULT GetReferences(uint32* pdwRefs, IMDSPStorage*** pppISPStorage) mut => VT.[Friend]GetReferences(&this, pdwRefs, pppISPStorage);

	public HRESULT CreateStorageWithMetadata(uint32 dwAttributes, PWSTR pwszName, IWMDMMetaData* pMetadata, uint64 qwFileSize, IMDSPStorage** ppNewStorage) mut => VT.[Friend]CreateStorageWithMetadata(&this, dwAttributes, pwszName, pMetadata, qwFileSize, ppNewStorage);

	public HRESULT GetSpecifiedMetadata(uint32 cProperties, PWSTR* ppwszPropNames, IWMDMMetaData* pMetadata) mut => VT.[Friend]GetSpecifiedMetadata(&this, cProperties, ppwszPropNames, pMetadata);

	public HRESULT FindStorage(WMDM_FIND_SCOPE findScope, PWSTR pwszUniqueID, IMDSPStorage** ppStorage) mut => VT.[Friend]FindStorage(&this, findScope, pwszUniqueID, ppStorage);

	public HRESULT GetParent(IMDSPStorage** ppStorage) mut => VT.[Friend]GetParent(&this, ppStorage);
}

[CRepr]struct IMDSPStorageGlobals : IUnknown
{
	public new const Guid IID = .(0x1dcb3a17, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCapabilities) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMDMID* pSerialNum, uint8* abMac) GetSerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwTotalSizeLow, uint32* pdwTotalSizeHigh) GetTotalSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFreeLow, uint32* pdwFreeHigh) GetTotalFree;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwBadLow, uint32* pdwBadHigh) GetTotalBad;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, IWMDMProgress* pProgress) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPDevice** ppDevice) GetDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPStorage** ppRoot) GetRootStorage;
	}


	public HRESULT GetCapabilities(uint32* pdwCapabilities) mut => VT.[Friend]GetCapabilities(&this, pdwCapabilities);

	public HRESULT GetSerialNumber(WMDMID* pSerialNum, uint8* abMac) mut => VT.[Friend]GetSerialNumber(&this, pSerialNum, abMac);

	public HRESULT GetTotalSize(uint32* pdwTotalSizeLow, uint32* pdwTotalSizeHigh) mut => VT.[Friend]GetTotalSize(&this, pdwTotalSizeLow, pdwTotalSizeHigh);

	public HRESULT GetTotalFree(uint32* pdwFreeLow, uint32* pdwFreeHigh) mut => VT.[Friend]GetTotalFree(&this, pdwFreeLow, pdwFreeHigh);

	public HRESULT GetTotalBad(uint32* pdwBadLow, uint32* pdwBadHigh) mut => VT.[Friend]GetTotalBad(&this, pdwBadLow, pdwBadHigh);

	public HRESULT GetStatus(uint32* pdwStatus) mut => VT.[Friend]GetStatus(&this, pdwStatus);

	public HRESULT Initialize(uint32 fuMode, IWMDMProgress* pProgress) mut => VT.[Friend]Initialize(&this, fuMode, pProgress);

	public HRESULT GetDevice(IMDSPDevice** ppDevice) mut => VT.[Friend]GetDevice(&this, ppDevice);

	public HRESULT GetRootStorage(IMDSPStorage** ppRoot) mut => VT.[Friend]GetRootStorage(&this, ppRoot);
}

[CRepr]struct IMDSPObjectInfo : IUnknown
{
	public new const Guid IID = .(0x1dcb3a19, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLength) GetPlayLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLength) SetPlayLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwOffset) GetPlayOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOffset) SetPlayOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLength) GetTotalLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLastPos) GetLastPlayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwLongestPos) GetLongestPlayPosition;
	}


	public HRESULT GetPlayLength(uint32* pdwLength) mut => VT.[Friend]GetPlayLength(&this, pdwLength);

	public HRESULT SetPlayLength(uint32 dwLength) mut => VT.[Friend]SetPlayLength(&this, dwLength);

	public HRESULT GetPlayOffset(uint32* pdwOffset) mut => VT.[Friend]GetPlayOffset(&this, pdwOffset);

	public HRESULT SetPlayOffset(uint32 dwOffset) mut => VT.[Friend]SetPlayOffset(&this, dwOffset);

	public HRESULT GetTotalLength(uint32* pdwLength) mut => VT.[Friend]GetTotalLength(&this, pdwLength);

	public HRESULT GetLastPlayPosition(uint32* pdwLastPos) mut => VT.[Friend]GetLastPlayPosition(&this, pdwLastPos);

	public HRESULT GetLongestPlayPosition(uint32* pdwLongestPos) mut => VT.[Friend]GetLongestPlayPosition(&this, pdwLongestPos);
}

[CRepr]struct IMDSPObject : IUnknown
{
	public new const Guid IID = .(0x1dcb3a18, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32* pdwSize, uint8* abMac) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32* pdwSize, uint8* abMac) Write;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, IWMDMProgress* pProgress) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuFlags, uint32 dwOffset) Seek;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszNewName, IWMDMProgress* pProgress) Rename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuMode, IWMDMProgress* pProgress, IMDSPStorage* pTarget) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT Open(uint32 fuMode) mut => VT.[Friend]Open(&this, fuMode);

	public HRESULT Read(uint8* pData, uint32* pdwSize, uint8* abMac) mut => VT.[Friend]Read(&this, pData, pdwSize, abMac);

	public HRESULT Write(uint8* pData, uint32* pdwSize, uint8* abMac) mut => VT.[Friend]Write(&this, pData, pdwSize, abMac);

	public HRESULT Delete(uint32 fuMode, IWMDMProgress* pProgress) mut => VT.[Friend]Delete(&this, fuMode, pProgress);

	public HRESULT Seek(uint32 fuFlags, uint32 dwOffset) mut => VT.[Friend]Seek(&this, fuFlags, dwOffset);

	public HRESULT Rename(PWSTR pwszNewName, IWMDMProgress* pProgress) mut => VT.[Friend]Rename(&this, pwszNewName, pProgress);

	public HRESULT Move(uint32 fuMode, IWMDMProgress* pProgress, IMDSPStorage* pTarget) mut => VT.[Friend]Move(&this, fuMode, pProgress, pTarget);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IMDSPObject2 : IMDSPObject
{
	public new const Guid IID = .(0x3f34cd3e, 0x5907, 0x4341, 0x9a, 0xf9, 0x97, 0xf4, 0x18, 0x7c, 0x3a, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMDSPObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32* pdwSize) ReadOnClearChannel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32* pdwSize) WriteOnClearChannel;
	}


	public HRESULT ReadOnClearChannel(uint8* pData, uint32* pdwSize) mut => VT.[Friend]ReadOnClearChannel(&this, pData, pdwSize);

	public HRESULT WriteOnClearChannel(uint8* pData, uint32* pdwSize) mut => VT.[Friend]WriteOnClearChannel(&this, pData, pdwSize);
}

[CRepr]struct IMDSPDirectTransfer : IUnknown
{
	public new const Guid IID = .(0xc2fe57a8, 0x9304, 0x478c, 0x9e, 0xe4, 0x47, 0xe3, 0x97, 0xb9, 0x12, 0xd7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszSourceFilePath, IWMDMOperation* pSourceOperation, uint32 fuFlags, PWSTR pwszDestinationName, IWMDMMetaData* pSourceMetaData, IWMDMProgress* pTransferProgress, IMDSPStorage** ppNewObject) TransferToDevice;
	}


	public HRESULT TransferToDevice(PWSTR pwszSourceFilePath, IWMDMOperation* pSourceOperation, uint32 fuFlags, PWSTR pwszDestinationName, IWMDMMetaData* pSourceMetaData, IWMDMProgress* pTransferProgress, IMDSPStorage** ppNewObject) mut => VT.[Friend]TransferToDevice(&this, pwszSourceFilePath, pSourceOperation, fuFlags, pwszDestinationName, pSourceMetaData, pTransferProgress, ppNewObject);
}

[CRepr]struct IMDSPRevoked : IUnknown
{
	public new const Guid IID = .(0xa4e8f2d4, 0x3f31, 0x464d, 0xb5, 0x3d, 0x4f, 0xc3, 0x35, 0x99, 0x81, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszRevocationURL, uint32* pdwBufferLen) GetRevocationURL;
	}


	public HRESULT GetRevocationURL(PWSTR* ppwszRevocationURL, uint32* pdwBufferLen) mut => VT.[Friend]GetRevocationURL(&this, ppwszRevocationURL, pdwBufferLen);
}

[CRepr]struct ISCPSecureAuthenticate : IUnknown
{
	public new const Guid IID = .(0x1dcb3a0f, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISCPSecureQuery** ppSecureQuery) GetSecureQuery;
	}


	public HRESULT GetSecureQuery(ISCPSecureQuery** ppSecureQuery) mut => VT.[Friend]GetSecureQuery(&this, ppSecureQuery);
}

[CRepr]struct ISCPSecureAuthenticate2 : ISCPSecureAuthenticate
{
	public new const Guid IID = .(0xb580cfae, 0x1672, 0x47e2, 0xac, 0xaa, 0x44, 0xbb, 0xec, 0xbc, 0xae, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISCPSecureAuthenticate.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISCPSession** ppSCPSession) GetSCPSession;
	}


	public HRESULT GetSCPSession(ISCPSession** ppSCPSession) mut => VT.[Friend]GetSCPSession(&this, ppSCPSession);
}

[CRepr]struct ISCPSecureQuery : IUnknown
{
	public new const Guid IID = .(0x1dcb3a0d, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pfuFlags, uint32* pdwMinRightsData, uint32* pdwMinExamineData, uint32* pdwMinDecideData, uint8* abMac) GetDataDemands;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuFlags, PWSTR pwszExtension, uint8* pData, uint32 dwSize, uint8* abMac) ExamineData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuFlags, uint8* pData, uint32 dwSize, uint32 dwAppSec, uint8* pbSPSessionKey, uint32 dwSessionKeyLen, IMDSPStorageGlobals* pStorageGlobals, ISCPSecureExchange** ppExchange, uint8* abMac) MakeDecision;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32 dwSize, uint8* pbSPSessionKey, uint32 dwSessionKeyLen, IMDSPStorageGlobals* pStgGlobals, WMDMRIGHTS** ppRights, uint32* pnRightsCount, uint8* abMac) GetRights;
	}


	public HRESULT GetDataDemands(uint32* pfuFlags, uint32* pdwMinRightsData, uint32* pdwMinExamineData, uint32* pdwMinDecideData, uint8* abMac) mut => VT.[Friend]GetDataDemands(&this, pfuFlags, pdwMinRightsData, pdwMinExamineData, pdwMinDecideData, abMac);

	public HRESULT ExamineData(uint32 fuFlags, PWSTR pwszExtension, uint8* pData, uint32 dwSize, uint8* abMac) mut => VT.[Friend]ExamineData(&this, fuFlags, pwszExtension, pData, dwSize, abMac);

	public HRESULT MakeDecision(uint32 fuFlags, uint8* pData, uint32 dwSize, uint32 dwAppSec, uint8* pbSPSessionKey, uint32 dwSessionKeyLen, IMDSPStorageGlobals* pStorageGlobals, ISCPSecureExchange** ppExchange, uint8* abMac) mut => VT.[Friend]MakeDecision(&this, fuFlags, pData, dwSize, dwAppSec, pbSPSessionKey, dwSessionKeyLen, pStorageGlobals, ppExchange, abMac);

	public HRESULT GetRights(uint8* pData, uint32 dwSize, uint8* pbSPSessionKey, uint32 dwSessionKeyLen, IMDSPStorageGlobals* pStgGlobals, WMDMRIGHTS** ppRights, uint32* pnRightsCount, uint8* abMac) mut => VT.[Friend]GetRights(&this, pData, dwSize, pbSPSessionKey, dwSessionKeyLen, pStgGlobals, ppRights, pnRightsCount, abMac);
}

[CRepr]struct ISCPSecureQuery2 : ISCPSecureQuery
{
	public new const Guid IID = .(0xebe17e25, 0x4fd7, 0x4632, 0xaf, 0x46, 0x6d, 0x93, 0xd4, 0xfc, 0xc7, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISCPSecureQuery.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuFlags, uint8* pData, uint32 dwSize, uint32 dwAppSec, uint8* pbSPSessionKey, uint32 dwSessionKeyLen, IMDSPStorageGlobals* pStorageGlobals, uint8* pAppCertApp, uint32 dwAppCertAppLen, uint8* pAppCertSP, uint32 dwAppCertSPLen, PWSTR* pszRevocationURL, uint32* pdwRevocationURLLen, uint32* pdwRevocationBitFlag, uint64* pqwFileSize, IUnknown* pUnknown, ISCPSecureExchange** ppExchange, uint8* abMac) MakeDecision2;
	}


	public HRESULT MakeDecision2(uint32 fuFlags, uint8* pData, uint32 dwSize, uint32 dwAppSec, uint8* pbSPSessionKey, uint32 dwSessionKeyLen, IMDSPStorageGlobals* pStorageGlobals, uint8* pAppCertApp, uint32 dwAppCertAppLen, uint8* pAppCertSP, uint32 dwAppCertSPLen, PWSTR* pszRevocationURL, uint32* pdwRevocationURLLen, uint32* pdwRevocationBitFlag, uint64* pqwFileSize, IUnknown* pUnknown, ISCPSecureExchange** ppExchange, uint8* abMac) mut => VT.[Friend]MakeDecision2(&this, fuFlags, pData, dwSize, dwAppSec, pbSPSessionKey, dwSessionKeyLen, pStorageGlobals, pAppCertApp, dwAppCertAppLen, pAppCertSP, dwAppCertSPLen, pszRevocationURL, pdwRevocationURLLen, pdwRevocationBitFlag, pqwFileSize, pUnknown, ppExchange, abMac);
}

[CRepr]struct ISCPSecureExchange : IUnknown
{
	public new const Guid IID = .(0x1dcb3a0e, 0x33ed, 0x11d3, 0x84, 0x70, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32 dwSize, uint32* pfuReadyFlags, uint8* abMac) TransferContainerData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32* pdwSize, uint8* abMac) ObjectData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TransferComplete;
	}


	public HRESULT TransferContainerData(uint8* pData, uint32 dwSize, uint32* pfuReadyFlags, uint8* abMac) mut => VT.[Friend]TransferContainerData(&this, pData, dwSize, pfuReadyFlags, abMac);

	public HRESULT ObjectData(uint8* pData, uint32* pdwSize, uint8* abMac) mut => VT.[Friend]ObjectData(&this, pData, pdwSize, abMac);

	public HRESULT TransferComplete() mut => VT.[Friend]TransferComplete(&this);
}

[CRepr]struct ISCPSecureExchange2 : ISCPSecureExchange
{
	public new const Guid IID = .(0x6c62fc7b, 0x2690, 0x483f, 0x9d, 0x44, 0x0a, 0x20, 0xcb, 0x35, 0x57, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISCPSecureExchange.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32 dwSize, IWMDMProgress3* pProgressCallback, uint32* pfuReadyFlags, uint8* abMac) TransferContainerData2;
	}


	public HRESULT TransferContainerData2(uint8* pData, uint32 dwSize, IWMDMProgress3* pProgressCallback, uint32* pfuReadyFlags, uint8* abMac) mut => VT.[Friend]TransferContainerData2(&this, pData, dwSize, pProgressCallback, pfuReadyFlags, abMac);
}

[CRepr]struct ISCPSecureExchange3 : ISCPSecureExchange2
{
	public new const Guid IID = .(0xab4e77e4, 0x8908, 0x4b17, 0xbd, 0x2a, 0xb1, 0xdb, 0xe6, 0xdd, 0x69, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISCPSecureExchange2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPDevice* pDevice, uint8* pData, uint32 dwSize, IWMDMProgress3* pProgressCallback, uint32* pfuReadyFlags) TransferContainerDataOnClearChannel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPDevice* pDevice, uint8* pData, uint32* pdwSize) GetObjectDataOnClearChannel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPDevice* pDevice) TransferCompleteForDevice;
	}


	public HRESULT TransferContainerDataOnClearChannel(IMDSPDevice* pDevice, uint8* pData, uint32 dwSize, IWMDMProgress3* pProgressCallback, uint32* pfuReadyFlags) mut => VT.[Friend]TransferContainerDataOnClearChannel(&this, pDevice, pData, dwSize, pProgressCallback, pfuReadyFlags);

	public HRESULT GetObjectDataOnClearChannel(IMDSPDevice* pDevice, uint8* pData, uint32* pdwSize) mut => VT.[Friend]GetObjectDataOnClearChannel(&this, pDevice, pData, pdwSize);

	public HRESULT TransferCompleteForDevice(IMDSPDevice* pDevice) mut => VT.[Friend]TransferCompleteForDevice(&this, pDevice);
}

[CRepr]struct ISCPSession : IUnknown
{
	public new const Guid IID = .(0x88a3e6ed, 0xeee4, 0x4619, 0xbb, 0xb3, 0xfd, 0x4f, 0xb6, 0x27, 0x15, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMDSPDevice* pIDevice, uint8* pCtx, uint32 dwSizeCtx) BeginSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pCtx, uint32 dwSizeCtx) EndSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISCPSecureQuery** ppSecureQuery) GetSecureQuery;
	}


	public HRESULT BeginSession(IMDSPDevice* pIDevice, uint8* pCtx, uint32 dwSizeCtx) mut => VT.[Friend]BeginSession(&this, pIDevice, pCtx, dwSizeCtx);

	public HRESULT EndSession(uint8* pCtx, uint32 dwSizeCtx) mut => VT.[Friend]EndSession(&this, pCtx, dwSizeCtx);

	public HRESULT GetSecureQuery(ISCPSecureQuery** ppSecureQuery) mut => VT.[Friend]GetSecureQuery(&this, ppSecureQuery);
}

[CRepr]struct ISCPSecureQuery3 : ISCPSecureQuery2
{
	public new const Guid IID = .(0xb7edd1a2, 0x4dab, 0x484b, 0xb3, 0xc5, 0xad, 0x39, 0xb8, 0xb4, 0xc0, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISCPSecureQuery2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pData, uint32 dwSize, uint8* pbSPSessionKey, uint32 dwSessionKeyLen, IMDSPStorageGlobals* pStgGlobals, IWMDMProgress3* pProgressCallback, WMDMRIGHTS** ppRights, uint32* pnRightsCount) GetRightsOnClearChannel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fuFlags, uint8* pData, uint32 dwSize, uint32 dwAppSec, uint8* pbSPSessionKey, uint32 dwSessionKeyLen, IMDSPStorageGlobals* pStorageGlobals, IWMDMProgress3* pProgressCallback, uint8* pAppCertApp, uint32 dwAppCertAppLen, uint8* pAppCertSP, uint32 dwAppCertSPLen, PWSTR* pszRevocationURL, uint32* pdwRevocationURLLen, uint32* pdwRevocationBitFlag, uint64* pqwFileSize, IUnknown* pUnknown, ISCPSecureExchange** ppExchange) MakeDecisionOnClearChannel;
	}


	public HRESULT GetRightsOnClearChannel(uint8* pData, uint32 dwSize, uint8* pbSPSessionKey, uint32 dwSessionKeyLen, IMDSPStorageGlobals* pStgGlobals, IWMDMProgress3* pProgressCallback, WMDMRIGHTS** ppRights, uint32* pnRightsCount) mut => VT.[Friend]GetRightsOnClearChannel(&this, pData, dwSize, pbSPSessionKey, dwSessionKeyLen, pStgGlobals, pProgressCallback, ppRights, pnRightsCount);

	public HRESULT MakeDecisionOnClearChannel(uint32 fuFlags, uint8* pData, uint32 dwSize, uint32 dwAppSec, uint8* pbSPSessionKey, uint32 dwSessionKeyLen, IMDSPStorageGlobals* pStorageGlobals, IWMDMProgress3* pProgressCallback, uint8* pAppCertApp, uint32 dwAppCertAppLen, uint8* pAppCertSP, uint32 dwAppCertSPLen, PWSTR* pszRevocationURL, uint32* pdwRevocationURLLen, uint32* pdwRevocationBitFlag, uint64* pqwFileSize, IUnknown* pUnknown, ISCPSecureExchange** ppExchange) mut => VT.[Friend]MakeDecisionOnClearChannel(&this, fuFlags, pData, dwSize, dwAppSec, pbSPSessionKey, dwSessionKeyLen, pStorageGlobals, pProgressCallback, pAppCertApp, dwAppCertAppLen, pAppCertSP, dwAppCertSPLen, pszRevocationURL, pdwRevocationURLLen, pdwRevocationBitFlag, pqwFileSize, pUnknown, ppExchange);
}

[CRepr]struct IComponentAuthenticate : IUnknown
{
	public new const Guid IID = .(0xa9889c00, 0x6d2b, 0x11d3, 0x84, 0x96, 0x00, 0xc0, 0x4f, 0x79, 0xdb, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProtocolID, uint32 dwPass, uint8* pbDataIn, uint32 dwDataInLen, uint8** ppbDataOut, uint32* pdwDataOutLen) SACAuth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32** ppdwProtocols, uint32* pdwProtocolCount) SACGetProtocols;
	}


	public HRESULT SACAuth(uint32 dwProtocolID, uint32 dwPass, uint8* pbDataIn, uint32 dwDataInLen, uint8** ppbDataOut, uint32* pdwDataOutLen) mut => VT.[Friend]SACAuth(&this, dwProtocolID, dwPass, pbDataIn, dwDataInLen, ppbDataOut, pdwDataOutLen);

	public HRESULT SACGetProtocols(uint32** ppdwProtocols, uint32* pdwProtocolCount) mut => VT.[Friend]SACGetProtocols(&this, ppdwProtocols, pdwProtocolCount);
}

[CRepr]struct IWMDMLogger : IUnknown
{
	public new const Guid IID = .(0x110a3200, 0x5a79, 0x11d3, 0x8d, 0x78, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnabled) IsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszFilename, uint32 nMaxChars) GetLogFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszFilename) SetLogFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, PSTR pszSrcName, PSTR pszLog) LogString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, PSTR pszSrcName, PSTR pszLogFormat, uint32 dwLog) LogDword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwMaxSize, uint32* pdwShrinkToSize) GetSizeParams;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMaxSize, uint32 dwShrinkToSize) SetSizeParams;
	}


	public HRESULT IsEnabled(BOOL* pfEnabled) mut => VT.[Friend]IsEnabled(&this, pfEnabled);

	public HRESULT Enable(BOOL fEnable) mut => VT.[Friend]Enable(&this, fEnable);

	public HRESULT GetLogFileName(PSTR pszFilename, uint32 nMaxChars) mut => VT.[Friend]GetLogFileName(&this, pszFilename, nMaxChars);

	public HRESULT SetLogFileName(PSTR pszFilename) mut => VT.[Friend]SetLogFileName(&this, pszFilename);

	public HRESULT LogString(uint32 dwFlags, PSTR pszSrcName, PSTR pszLog) mut => VT.[Friend]LogString(&this, dwFlags, pszSrcName, pszLog);

	public HRESULT LogDword(uint32 dwFlags, PSTR pszSrcName, PSTR pszLogFormat, uint32 dwLog) mut => VT.[Friend]LogDword(&this, dwFlags, pszSrcName, pszLogFormat, dwLog);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT GetSizeParams(uint32* pdwMaxSize, uint32* pdwShrinkToSize) mut => VT.[Friend]GetSizeParams(&this, pdwMaxSize, pdwShrinkToSize);

	public HRESULT SetSizeParams(uint32 dwMaxSize, uint32 dwShrinkToSize) mut => VT.[Friend]SetSizeParams(&this, dwMaxSize, dwShrinkToSize);
}

#endregion
