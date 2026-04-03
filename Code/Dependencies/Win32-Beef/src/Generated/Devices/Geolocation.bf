using Win32.System.Com;
using Win32.Foundation;
using Win32.UI.Shell.PropertiesSystem;
using Win32.System.Com.StructuredStorage;
using Win32.Devices.Sensors;
using System;

namespace Win32.Devices.Geolocation;

#region Constants
public static
{
	public const uint32 GNSS_DRIVER_VERSION_1 = 1;
	public const uint32 GNSS_DRIVER_VERSION_2 = 2;
	public const uint32 GNSS_DRIVER_VERSION_3 = 3;
	public const uint32 GNSS_DRIVER_VERSION_4 = 4;
	public const uint32 GNSS_DRIVER_VERSION_5 = 5;
	public const uint32 GNSS_DRIVER_VERSION_6 = 6;
	public const uint32 IOCTL_GNSS_SEND_PLATFORM_CAPABILITY = 2228228;
	public const uint32 IOCTL_GNSS_GET_DEVICE_CAPABILITY = 2228232;
	public const uint32 IOCTL_GNSS_SEND_DRIVERCOMMAND = 2228236;
	public const uint32 IOCTL_GNSS_START_FIXSESSION = 2228288;
	public const uint32 IOCTL_GNSS_MODIFY_FIXSESSION = 2228292;
	public const uint32 IOCTL_GNSS_STOP_FIXSESSION = 2228296;
	public const uint32 IOCTL_GNSS_GET_FIXDATA = 2228300;
	public const uint32 IOCTL_GNSS_INJECT_AGNSS = 2228352;
	public const uint32 IOCTL_GNSS_LISTEN_AGNSS = 2228416;
	public const uint32 IOCTL_GNSS_LISTEN_ERROR = 2228420;
	public const uint32 IOCTL_GNSS_LISTEN_NI = 2228480;
	public const uint32 IOCTL_GNSS_SET_SUPL_HSLP = 2228484;
	public const uint32 IOCTL_GNSS_CONFIG_SUPL_CERT = 2228488;
	public const uint32 IOCTL_GNSS_RESPOND_NI = 2228492;
	public const uint32 IOCTL_GNSS_EXECUTE_CWTEST = 2228496;
	public const uint32 IOCTL_GNSS_EXECUTE_SELFTEST = 2228500;
	public const uint32 IOCTL_GNSS_GET_CHIPSETINFO = 2228504;
	public const uint32 IOCTL_GNSS_LISTEN_NMEA = 2228508;
	public const uint32 IOCTL_GNSS_SET_V2UPL_CONFIG = 2228512;
	public const uint32 IOCTL_GNSS_CREATE_GEOFENCE = 2228544;
	public const uint32 IOCTL_GNSS_DELETE_GEOFENCE = 2228548;
	public const uint32 IOCTL_GNSS_LISTEN_GEOFENCE_ALERT = 2228552;
	public const uint32 IOCTL_GNSS_LISTEN_GEOFENCES_TRACKINGSTATUS = 2228556;
	public const uint32 IOCTL_GNSS_LISTEN_DRIVER_REQUEST = 2228608;
	public const uint32 IOCTL_GNSS_START_BREADCRUMBING = 2228672;
	public const uint32 IOCTL_GNSS_STOP_BREADCRUMBING = 2228676;
	public const uint32 IOCTL_GNSS_LISTEN_BREADCRUMBING_ALERT = 2228680;
	public const uint32 IOCTL_GNSS_POP_BREADCRUMBS = 2228684;
	public const uint32 GNSS_AGNSSFORMAT_XTRA1 = 1;
	public const uint32 GNSS_AGNSSFORMAT_XTRA2 = 2;
	public const uint32 GNSS_AGNSSFORMAT_LTO = 4;
	public const uint32 GNSS_AGNSSFORMAT_XTRA3 = 8;
	public const uint32 GNSS_AGNSSFORMAT_XTRA3_1 = 16;
	public const uint32 GNSS_AGNSSFORMAT_XTRA3_2 = 32;
	public const uint32 GNSS_AGNSSFORMAT_XTRA_INT = 64;
	public const uint32 MAX_SERVER_URL_NAME = 260;
	public const uint32 MIN_GEOFENCES_REQUIRED = 100;
	public const uint32 BREADCRUMBING_UNSUPPORTED = 0;
	public const uint32 BREADCRUMBING_VERSION_1 = 1;
	public const uint32 MIN_BREADCRUMBS_SUPPORTED = 120;
	public const uint32 GNSS_SATELLITE_ANY = 0;
	public const uint32 GNSS_SATELLITE_GPS = 1;
	public const uint32 GNSS_SATELLITE_GLONASS = 2;
	public const uint32 GNSS_SATELLITE_BEIDOU = 4;
	public const uint32 GNSS_SATELLITE_GALILEO = 8;
	public const uint32 GNSS_OPERMODE_ANY = 0;
	public const uint32 GNSS_OPERMODE_MSA = 1;
	public const uint32 GNSS_OPERMODE_MSB = 2;
	public const uint32 GNSS_OPERMODE_MSS = 4;
	public const uint32 GNSS_OPERMODE_CELLID = 8;
	public const uint32 GNSS_OPERMODE_AFLT = 16;
	public const uint32 GNSS_OPERMODE_OTDOA = 32;
	public const uint32 GNSS_NMEALOGGING_NONE = 0;
	public const uint32 GNSS_NMEALOGGING_ALL = 255;
	public const uint32 GNSS_FIXDETAIL_BASIC = 1;
	public const uint32 GNSS_FIXDETAIL_ACCURACY = 2;
	public const uint32 GNSS_FIXDETAIL_SATELLITE = 4;
	public const uint32 GNSS_MAXSATELLITE = 64;
	public const uint32 GNSS_GEOFENCESUPPORT_SUPPORTED = 1;
	public const uint32 GNSS_GEOFENCESUPPORT_CIRCLE = 2;
	public const uint32 LOCATION_API_VERSION = 1;
	public const Guid GUID_DEVINTERFACE_GNSS = .(0x3336e5e4, 0x018a, 0x4669, 0x84, 0xc5, 0xbd, 0x05, 0xf3, 0xbd, 0x36, 0x8b);
}
#endregion

#region Enums

[AllowDuplicates]
public enum LOCATION_REPORT_STATUS : int32
{
	REPORT_NOT_SUPPORTED = 0,
	REPORT_ERROR = 1,
	REPORT_ACCESS_DENIED = 2,
	REPORT_INITIALIZING = 3,
	REPORT_RUNNING = 4,
}


[AllowDuplicates]
public enum GNSS_DRIVERCOMMAND_TYPE : int32
{
	GNSS_SetLocationServiceEnabled = 1,
	GNSS_SetLocationNIRequestAllowed = 2,
	GNSS_ForceSatelliteSystem = 3,
	GNSS_ForceOperationMode = 4,
	GNSS_ResetEngine = 9,
	GNSS_ClearAgnssData = 10,
	GNSS_SetSuplVersion = 12,
	GNSS_SetNMEALogging = 13,
	GNSS_SetUplServerAccessInterval = 14,
	GNSS_SetNiTimeoutInterval = 15,
	GNSS_ResetGeofencesTracking = 16,
	GNSS_SetSuplVersion2 = 17,
	GNSS_CustomCommand = 256,
}


[AllowDuplicates]
public enum GNSS_FIXSESSIONTYPE : int32
{
	GNSS_FixSession_SingleShot = 1,
	GNSS_FixSession_DistanceTracking = 2,
	GNSS_FixSession_ContinuousTracking = 3,
	GNSS_FixSession_LKG = 4,
}


[AllowDuplicates]
public enum GNSS_GEOREGIONTYPE : int32
{
	GNSS_GeoRegion_Circle = 1,
}


[AllowDuplicates]
public enum GNSS_GEOFENCE_STATE : int32
{
	GNSS_GeofenceState_Unknown = 0,
	GNSS_GeofenceState_Entered = 1,
	GNSS_GeofenceState_Exited = 2,
}


[AllowDuplicates]
public enum GNSS_EVENT_TYPE : int32
{
	GNSS_Event_FixAvailable = 1,
	GNSS_Event_RequireAgnss = 2,
	GNSS_Event_Error = 3,
	GNSS_Event_NiRequest = 12,
	GNSS_Event_NmeaData = 13,
	GNSS_Event_GeofenceAlertData = 14,
	GNSS_Event_GeofencesTrackingStatus = 15,
	GNSS_Event_DriverRequest = 16,
	GNSS_Event_BreadcrumbAlertEvent = 17,
	GNSS_Event_FixAvailable_2 = 18,
	GNSS_Event_Custom = 32768,
}


[AllowDuplicates]
public enum GNSS_AGNSS_REQUEST_TYPE : int32
{
	GNSS_AGNSS_TimeInjection = 1,
	GNSS_AGNSS_PositionInjection = 2,
	GNSS_AGNSS_BlobInjection = 3,
}


[AllowDuplicates]
public enum GNSS_NI_PLANE_TYPE : int32
{
	GNSS_NI_SUPL = 1,
	GNSS_NI_CP = 2,
	GNSS_NI_V2UPL = 3,
}


[AllowDuplicates]
public enum GNSS_NI_REQUEST_TYPE : int32
{
	GNSS_NI_Request_SingleShot = 1,
	GNSS_NI_Request_AreaTrigger = 2,
}


[AllowDuplicates]
public enum GNSS_NI_NOTIFICATION_TYPE : int32
{
	GNSS_NI_NoNotifyNoVerify = 1,
	GNSS_NI_NotifyOnly = 2,
	GNSS_NI_NotifyVerifyDefaultAllow = 3,
	GNSS_NI_NotifyVerifyDefaultNotAllow = 4,
	GNSS_NI_PrivacyOverride = 5,
}


[AllowDuplicates]
public enum GNSS_DRIVER_REQUEST : int32
{
	SUPL_CONFIG_DATA = 1,
}


[AllowDuplicates]
public enum GNSS_SUPL_CERT_ACTION : int32
{
	GNSS_Supl_Cert_Inject = 1,
	GNSS_Supl_Cert_Delete = 2,
	GNSS_Supl_Cert_Purge = 3,
}


[AllowDuplicates]
public enum GNSS_NI_USER_RESPONSE : int32
{
	GNSS_Ni_UserResponseAccept = 1,
	GNSS_Ni_UserResponseDeny = 2,
	GNSS_Ni_UserResponseTimeout = 3,
}

#endregion


#region Structs
[CRepr]
public struct GNSS_SUPL_VERSION
{
	public uint32 MajorVersion;
	public uint32 MinorVersion;
}

[CRepr]
public struct GNSS_SUPL_VERSION_2
{
	public uint32 MajorVersion;
	public uint32 MinorVersion;
	public uint32 ServiceIndicator;
}

[CRepr]
public struct GNSS_DEVICE_CAPABILITY
{
	public uint32 Size;
	public uint32 Version;
	public BOOL SupportMultipleFixSessions;
	public BOOL SupportMultipleAppSessions;
	public BOOL RequireAGnssInjection;
	public uint32 AgnssFormatSupported;
	public uint32 AgnssFormatPreferred;
	public BOOL SupportDistanceTracking;
	public BOOL SupportContinuousTracking;
	public uint32 Reserved1;
	public BOOL Reserved2;
	public BOOL Reserved3;
	public BOOL Reserved4;
	public BOOL Reserved5;
	public uint32 GeofencingSupport;
	public BOOL Reserved6;
	public BOOL Reserved7;
	public BOOL SupportCpLocation;
	public BOOL SupportUplV2;
	public BOOL SupportSuplV1;
	public BOOL SupportSuplV2;
	public GNSS_SUPL_VERSION SupportedSuplVersion;
	public uint32 MaxGeofencesSupported;
	public BOOL SupportMultipleSuplRootCert;
	public uint32 GnssBreadCrumbPayloadVersion;
	public uint32 MaxGnssBreadCrumbFixes;
	public uint8[496] Unused;
}

[CRepr]
public struct GNSS_PLATFORM_CAPABILITY
{
	public uint32 Size;
	public uint32 Version;
	public BOOL SupportAgnssInjection;
	public uint32 AgnssFormatSupported;
	public uint8[516] Unused;
}

[CRepr]
public struct GNSS_DRIVERCOMMAND_PARAM
{
	public uint32 Size;
	public uint32 Version;
	public GNSS_DRIVERCOMMAND_TYPE CommandType;
	public uint32 Reserved;
	public uint32 CommandDataSize;
	public uint8[512] Unused;
	public uint8* CommandData mut => &CommandData_impl;
	private uint8[ANYSIZE_ARRAY] CommandData_impl;
}

[CRepr]
public struct GNSS_SINGLESHOT_PARAM
{
	public uint32 Size;
	public uint32 Version;
	public uint32 ResponseTime;
}

[CRepr]
public struct GNSS_DISTANCETRACKING_PARAM
{
	public uint32 Size;
	public uint32 Version;
	public uint32 MovementThreshold;
}

[CRepr]
public struct GNSS_CONTINUOUSTRACKING_PARAM
{
	public uint32 Size;
	public uint32 Version;
	public uint32 PreferredInterval;
}

[CRepr]
public struct GNSS_LKGFIX_PARAM
{
	public uint32 Size;
	public uint32 Version;
}

[CRepr]
public struct GNSS_FIXSESSION_PARAM
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public GNSS_SINGLESHOT_PARAM SingleShotParam;
		public GNSS_DISTANCETRACKING_PARAM DistanceParam;
		public GNSS_CONTINUOUSTRACKING_PARAM ContinuousParam;
		public GNSS_LKGFIX_PARAM LkgFixParam;
		public uint8[268] UnusedParam;
	}
	public uint32 Size;
	public uint32 Version;
	public uint32 FixSessionID;
	public GNSS_FIXSESSIONTYPE SessionType;
	public uint32 HorizontalAccuracy;
	public uint32 HorizontalConfidence;
	public uint32[9] Reserved;
	public uint32 FixLevelOfDetails;
	public using _Anonymous_e__Union Anonymous;
	public uint8[256] Unused;
}

[CRepr]
public struct GNSS_STOPFIXSESSION_PARAM
{
	public uint32 Size;
	public uint32 Version;
	public uint32 FixSessionID;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_FIXDATA_BASIC
{
	public uint32 Size;
	public uint32 Version;
	public double Latitude;
	public double Longitude;
	public double Altitude;
	public double Speed;
	public double Heading;
}

[CRepr]
public struct GNSS_FIXDATA_BASIC_2
{
	public uint32 Size;
	public uint32 Version;
	public double Latitude;
	public double Longitude;
	public double Altitude;
	public double Speed;
	public double Heading;
	public double AltitudeEllipsoid;
}

[CRepr]
public struct GNSS_FIXDATA_ACCURACY
{
	public uint32 Size;
	public uint32 Version;
	public uint32 HorizontalAccuracy;
	public uint32 HorizontalErrorMajorAxis;
	public uint32 HorizontalErrorMinorAxis;
	public uint32 HorizontalErrorAngle;
	public uint32 HeadingAccuracy;
	public uint32 AltitudeAccuracy;
	public uint32 SpeedAccuracy;
	public uint32 HorizontalConfidence;
	public uint32 HeadingConfidence;
	public uint32 AltitudeConfidence;
	public uint32 SpeedConfidence;
	public float PositionDilutionOfPrecision;
	public float HorizontalDilutionOfPrecision;
	public float VerticalDilutionOfPrecision;
}

[CRepr]
public struct GNSS_FIXDATA_ACCURACY_2
{
	public uint32 Size;
	public uint32 Version;
	public double HorizontalAccuracy;
	public double HorizontalErrorMajorAxis;
	public double HorizontalErrorMinorAxis;
	public double HorizontalErrorAngle;
	public double HeadingAccuracy;
	public double AltitudeAccuracy;
	public double SpeedAccuracy;
	public uint32 HorizontalConfidence;
	public uint32 HeadingConfidence;
	public uint32 AltitudeConfidence;
	public uint32 SpeedConfidence;
	public double PositionDilutionOfPrecision;
	public double HorizontalDilutionOfPrecision;
	public double VerticalDilutionOfPrecision;
	public double GeometricDilutionOfPrecision;
	public double TimeDilutionOfPrecision;
}

[CRepr]
public struct GNSS_SATELLITEINFO
{
	public uint32 SatelliteId;
	public BOOL UsedInPositiong;
	public double Elevation;
	public double Azimuth;
	public double SignalToNoiseRatio;
}

[CRepr]
public struct GNSS_FIXDATA_SATELLITE
{
	public uint32 Size;
	public uint32 Version;
	public uint32 SatelliteCount;
	public GNSS_SATELLITEINFO[64] SatelliteArray;
}

[CRepr]
public struct GNSS_FIXDATA
{
	public uint32 Size;
	public uint32 Version;
	public uint32 FixSessionID;
	public FILETIME FixTimeStamp;
	public BOOL IsFinalFix;
	public NTSTATUS FixStatus;
	public uint32 FixLevelOfDetails;
	public GNSS_FIXDATA_BASIC BasicData;
	public GNSS_FIXDATA_ACCURACY AccuracyData;
	public GNSS_FIXDATA_SATELLITE SatelliteData;
}

[CRepr]
public struct GNSS_FIXDATA_2
{
	public uint32 Size;
	public uint32 Version;
	public uint32 FixSessionID;
	public FILETIME FixTimeStamp;
	public BOOL IsFinalFix;
	public NTSTATUS FixStatus;
	public uint32 FixLevelOfDetails;
	public GNSS_FIXDATA_BASIC_2 BasicData;
	public GNSS_FIXDATA_ACCURACY_2 AccuracyData;
	public GNSS_FIXDATA_SATELLITE SatelliteData;
}

[CRepr]
public struct GNSS_BREADCRUMBING_PARAM
{
	public uint32 Size;
	public uint32 Version;
	public uint32 MaximumHorizontalUncertainty;
	public uint32 MinDistanceBetweenFixes;
	public uint32 MaximumErrorTimeoutMs;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_BREADCRUMBING_ALERT_DATA
{
	public uint32 Size;
	public uint32 Version;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_BREADCRUMB_V1
{
	public FILETIME FixTimeStamp;
	public double Latitude;
	public double Longitude;
	public uint32 HorizontalAccuracy;
	public uint16 Speed;
	public uint16 SpeedAccuracy;
	public int16 Altitude;
	public uint16 AltitudeAccuracy;
	public int16 Heading;
	public uint8 HeadingAccuracy;
	public uint8 FixSuccess;
}

[CRepr]
public struct GNSS_BREADCRUMB_LIST
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public GNSS_BREADCRUMB_V1[50] v1;
	}
	public uint32 Size;
	public uint32 Version;
	public uint32 NumCrumbs;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct GNSS_GEOREGION_CIRCLE
{
	public double Latitude;
	public double Longitude;
	public double RadiusInMeters;
}

[CRepr]
public struct GNSS_GEOREGION
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public GNSS_GEOREGION_CIRCLE Circle;
		public uint8[512] Unused;
	}
	public uint32 Size;
	public uint32 Version;
	public GNSS_GEOREGIONTYPE GeoRegionType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct GNSS_GEOFENCE_CREATE_PARAM
{
	public uint32 Size;
	public uint32 Version;
	public uint32 AlertTypes;
	public GNSS_GEOFENCE_STATE InitialState;
	public GNSS_GEOREGION Boundary;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_GEOFENCE_CREATE_RESPONSE
{
	public uint32 Size;
	public uint32 Version;
	public NTSTATUS CreationStatus;
	public uint32 GeofenceID;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_GEOFENCE_DELETE_PARAM
{
	public uint32 Size;
	public uint32 Version;
	public uint32 GeofenceID;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_GEOFENCE_ALERT_DATA
{
	public uint32 Size;
	public uint32 Version;
	public uint32 GeofenceID;
	public GNSS_GEOFENCE_STATE GeofenceState;
	public GNSS_FIXDATA_BASIC FixBasicData;
	public GNSS_FIXDATA_ACCURACY FixAccuracyData;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_GEOFENCES_TRACKINGSTATUS_DATA
{
	public uint32 Size;
	public uint32 Version;
	public NTSTATUS Status;
	public FILETIME StatusTimeStamp;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_ERRORINFO
{
	public uint32 Size;
	public uint32 Version;
	public uint32 ErrorCode;
	public BOOL IsRecoverable;
	public char16[256] ErrorDescription;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_NMEA_DATA
{
	public uint32 Size;
	public uint32 Version;
	public CHAR[256] NmeaSentences;
}

[CRepr]
public struct GNSS_AGNSS_REQUEST_PARAM
{
	public uint32 Size;
	public uint32 Version;
	public GNSS_AGNSS_REQUEST_TYPE RequestType;
	public uint32 BlobFormat;
}

[CRepr]
public struct GNSS_SUPL_NI_INFO
{
	public uint32 Size;
	public uint32 Version;
	public char16[260] RequestorId;
	public char16[260] ClientName;
	public CHAR[260] SuplNiUrl;
}

[CRepr]
public struct GNSS_CP_NI_INFO
{
	public uint32 Size;
	public uint32 Version;
	public char16[260] RequestorId;
	public char16[260] NotificationText;
}

[CRepr]
public struct GNSS_V2UPL_NI_INFO
{
	public uint32 Size;
	public uint32 Version;
	public char16[260] RequestorId;
}

[CRepr]
public struct GNSS_NI_REQUEST_PARAM
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public GNSS_SUPL_NI_INFO SuplNiInfo;
		public GNSS_CP_NI_INFO CpNiInfo;
		public GNSS_V2UPL_NI_INFO V2UplNiInfo;
	}
	public uint32 Size;
	public uint32 Version;
	public uint32 RequestId;
	public GNSS_NI_REQUEST_TYPE RequestType;
	public GNSS_NI_NOTIFICATION_TYPE NotificationType;
	public GNSS_NI_PLANE_TYPE RequestPlaneType;
	public using _Anonymous_e__Union Anonymous;
	public uint32 ResponseTimeInSec;
	public BOOL EmergencyLocation;
}

[CRepr]
public struct GNSS_DRIVER_REQUEST_DATA
{
	public uint32 Size;
	public uint32 Version;
	public GNSS_DRIVER_REQUEST Request;
	public uint32 RequestFlag;
}

[CRepr]
public struct GNSS_EVENT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public GNSS_FIXDATA FixData;
		public GNSS_AGNSS_REQUEST_PARAM AgnssRequest;
		public GNSS_NI_REQUEST_PARAM NiRequest;
		public GNSS_ERRORINFO ErrorInformation;
		public GNSS_NMEA_DATA NmeaData;
		public GNSS_GEOFENCE_ALERT_DATA GeofenceAlertData;
		public GNSS_BREADCRUMBING_ALERT_DATA BreadcrumbAlertData;
		public GNSS_GEOFENCES_TRACKINGSTATUS_DATA GeofencesTrackingStatus;
		public GNSS_DRIVER_REQUEST_DATA DriverRequestData;
		public uint8* CustomData mut => &CustomData_impl;
		private uint8[ANYSIZE_ARRAY] CustomData_impl;
	}
	public uint32 Size;
	public uint32 Version;
	public GNSS_EVENT_TYPE EventType;
	public uint32 EventDataSize;
	public uint8[512] Unused;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct GNSS_EVENT_2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public GNSS_FIXDATA FixData;
		public GNSS_FIXDATA_2 FixData2;
		public GNSS_AGNSS_REQUEST_PARAM AgnssRequest;
		public GNSS_NI_REQUEST_PARAM NiRequest;
		public GNSS_ERRORINFO ErrorInformation;
		public GNSS_NMEA_DATA NmeaData;
		public GNSS_GEOFENCE_ALERT_DATA GeofenceAlertData;
		public GNSS_BREADCRUMBING_ALERT_DATA BreadcrumbAlertData;
		public GNSS_GEOFENCES_TRACKINGSTATUS_DATA GeofencesTrackingStatus;
		public GNSS_DRIVER_REQUEST_DATA DriverRequestData;
		public uint8* CustomData mut => &CustomData_impl;
		private uint8[ANYSIZE_ARRAY] CustomData_impl;
	}
	public uint32 Size;
	public uint32 Version;
	public GNSS_EVENT_TYPE EventType;
	public uint32 EventDataSize;
	public uint8[512] Unused;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct GNSS_AGNSS_INJECTTIME
{
	public uint32 Size;
	public uint32 Version;
	public FILETIME UtcTime;
	public uint32 TimeUncertainty;
}

[CRepr]
public struct GNSS_AGNSS_INJECTPOSITION
{
	public uint32 Size;
	public uint32 Version;
	public uint32 Age;
	public GNSS_FIXDATA_BASIC BasicData;
	public GNSS_FIXDATA_ACCURACY AccuracyData;
}

[CRepr]
public struct GNSS_AGNSS_INJECTBLOB
{
	public uint32 Size;
	public uint32 Version;
	public uint32 BlobOui;
	public uint32 BlobVersion;
	public uint32 AgnssFormat;
	public uint32 BlobSize;
	public uint8* BlobData mut => &BlobData_impl;
	private uint8[ANYSIZE_ARRAY] BlobData_impl;
}

[CRepr]
public struct GNSS_AGNSS_INJECT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public GNSS_AGNSS_INJECTTIME Time;
		public GNSS_AGNSS_INJECTPOSITION Position;
		public GNSS_AGNSS_INJECTBLOB BlobData;
	}
	public uint32 Size;
	public uint32 Version;
	public GNSS_AGNSS_REQUEST_TYPE InjectionType;
	public NTSTATUS InjectionStatus;
	public uint32 InjectionDataSize;
	public uint8[512] Unused;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct GNSS_SUPL_HSLP_CONFIG
{
	public uint32 Size;
	public uint32 Version;
	public CHAR[260] SuplHslp;
	public CHAR[260] SuplHslpFromImsi;
	public uint32 Reserved;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_SUPL_CERT_CONFIG
{
	public uint32 Size;
	public uint32 Version;
	public GNSS_SUPL_CERT_ACTION CertAction;
	public CHAR[260] SuplCertName;
	public uint32 CertSize;
	public uint8[512] Unused;
	public uint8* CertData mut => &CertData_impl;
	private uint8[ANYSIZE_ARRAY] CertData_impl;
}

[CRepr]
public struct GNSS_V2UPL_CONFIG
{
	public uint32 Size;
	public uint32 Version;
	public CHAR[260] MPC;
	public CHAR[260] PDE;
	public uint8 ApplicationTypeIndicator_MR;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_NI_RESPONSE
{
	public uint32 Size;
	public uint32 Version;
	public uint32 RequestId;
	public GNSS_NI_USER_RESPONSE UserResponse;
}

[CRepr]
public struct GNSS_CWTESTDATA
{
	public uint32 Size;
	public uint32 Version;
	public NTSTATUS TestResultStatus;
	public double SignalToNoiseRatio;
	public double Frequency;
	public uint8[512] Unused;
}

[CRepr]
public struct GNSS_SELFTESTCONFIG
{
	public uint32 Size;
	public uint32 Version;
	public uint32 TestType;
	public uint8[512] Unused;
	public uint32 InBufLen;
	public uint8* InBuffer mut => &InBuffer_impl;
	private uint8[ANYSIZE_ARRAY] InBuffer_impl;
}

[CRepr]
public struct GNSS_SELFTESTRESULT
{
	public uint32 Size;
	public uint32 Version;
	public NTSTATUS TestResultStatus;
	public uint32 Result;
	public uint32 PinFailedBitMask;
	public uint8[512] Unused;
	public uint32 OutBufLen;
	public uint8* OutBuffer mut => &OutBuffer_impl;
	private uint8[ANYSIZE_ARRAY] OutBuffer_impl;
}

[CRepr]
public struct GNSS_CHIPSETINFO
{
	public uint32 Size;
	public uint32 Version;
	public char16[25] ManufacturerID;
	public char16[25] HardwareID;
	public char16[20] FirmwareVersion;
	public uint8[512] Unused;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_Location = .(0xe5b8e079, 0xee6d, 0x4e33, 0xa4, 0x38, 0xc8, 0x7f, 0x2e, 0x95, 0x92, 0x54);


	public const Guid CLSID_DefaultLocation = .(0x8b7fbfe0, 0x5cd7, 0x494a, 0xaf, 0x8c, 0x28, 0x3a, 0x65, 0x70, 0x75, 0x06);


	public const Guid CLSID_LatLongReport = .(0xed81c073, 0x1f84, 0x4ca8, 0xa1, 0x61, 0x18, 0x3c, 0x77, 0x6b, 0xc6, 0x51);


	public const Guid CLSID_CivicAddressReport = .(0xd39e7bdd, 0x7d05, 0x46b8, 0x87, 0x21, 0x80, 0xcf, 0x03, 0x5f, 0x57, 0xd7);


	public const Guid CLSID_LatLongReportFactory = .(0x9dcc3cc8, 0x8609, 0x4863, 0xba, 0xd4, 0x03, 0x60, 0x1f, 0x4c, 0x65, 0xe8);


	public const Guid CLSID_CivicAddressReportFactory = .(0x2a11f42c, 0x3e81, 0x4ad4, 0x9c, 0xbe, 0x45, 0x57, 0x9d, 0x89, 0x67, 0x1a);


	public const Guid CLSID_DispLatLongReport = .(0x7a7c3277, 0x8f84, 0x4636, 0x95, 0xb2, 0xeb, 0xb5, 0x50, 0x7f, 0xf7, 0x7e);


	public const Guid CLSID_DispCivicAddressReport = .(0x4c596aec, 0x8544, 0x4082, 0xba, 0x9f, 0xeb, 0x0a, 0x7d, 0x8e, 0x65, 0xc6);


}
#endregion

#region COM Types
[CRepr]struct ILocationReport : IUnknown
{
	public new const Guid IID = .(0xc8b7f7ee, 0x75d0, 0x4db9, 0xb6, 0x2d, 0x7a, 0x0f, 0x36, 0x9c, 0xa4, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pSensorID) GetSensorID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pCreationTime) GetTimestamp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* pKey, PROPVARIANT* pValue) GetValue;
	}


	public HRESULT GetSensorID(Guid* pSensorID) mut => VT.[Friend]GetSensorID(&this, pSensorID);

	public HRESULT GetTimestamp(SYSTEMTIME* pCreationTime) mut => VT.[Friend]GetTimestamp(&this, pCreationTime);

	public HRESULT GetValue(PROPERTYKEY* pKey, PROPVARIANT* pValue) mut => VT.[Friend]GetValue(&this, pKey, pValue);
}

[CRepr]struct ILatLongReport : ILocationReport
{
	public new const Guid IID = .(0x7fed806d, 0x0ef8, 0x4f07, 0x80, 0xac, 0x36, 0xa0, 0xbe, 0xae, 0x31, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ILocationReport.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pLatitude) GetLatitude;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pLongitude) GetLongitude;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pErrorRadius) GetErrorRadius;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pAltitude) GetAltitude;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pAltitudeError) GetAltitudeError;
	}


	public HRESULT GetLatitude(double* pLatitude) mut => VT.[Friend]GetLatitude(&this, pLatitude);

	public HRESULT GetLongitude(double* pLongitude) mut => VT.[Friend]GetLongitude(&this, pLongitude);

	public HRESULT GetErrorRadius(double* pErrorRadius) mut => VT.[Friend]GetErrorRadius(&this, pErrorRadius);

	public HRESULT GetAltitude(double* pAltitude) mut => VT.[Friend]GetAltitude(&this, pAltitude);

	public HRESULT GetAltitudeError(double* pAltitudeError) mut => VT.[Friend]GetAltitudeError(&this, pAltitudeError);
}

[CRepr]struct ICivicAddressReport : ILocationReport
{
	public new const Guid IID = .(0xc0b19f70, 0x4adf, 0x445d, 0x87, 0xf2, 0xca, 0xd8, 0xfd, 0x71, 0x17, 0x92);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ILocationReport.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrAddress1) GetAddressLine1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrAddress2) GetAddressLine2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCity) GetCity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrStateProvince) GetStateProvince;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPostalCode) GetPostalCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCountryRegion) GetCountryRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pDetailLevel) GetDetailLevel;
	}


	public HRESULT GetAddressLine1(BSTR* pbstrAddress1) mut => VT.[Friend]GetAddressLine1(&this, pbstrAddress1);

	public HRESULT GetAddressLine2(BSTR* pbstrAddress2) mut => VT.[Friend]GetAddressLine2(&this, pbstrAddress2);

	public HRESULT GetCity(BSTR* pbstrCity) mut => VT.[Friend]GetCity(&this, pbstrCity);

	public HRESULT GetStateProvince(BSTR* pbstrStateProvince) mut => VT.[Friend]GetStateProvince(&this, pbstrStateProvince);

	public HRESULT GetPostalCode(BSTR* pbstrPostalCode) mut => VT.[Friend]GetPostalCode(&this, pbstrPostalCode);

	public HRESULT GetCountryRegion(BSTR* pbstrCountryRegion) mut => VT.[Friend]GetCountryRegion(&this, pbstrCountryRegion);

	public HRESULT GetDetailLevel(uint32* pDetailLevel) mut => VT.[Friend]GetDetailLevel(&this, pDetailLevel);
}

[CRepr]struct ILocation : IUnknown
{
	public new const Guid IID = .(0xab2ece69, 0x56d9, 0x4f28, 0xb5, 0x25, 0xde, 0x1b, 0x0e, 0xe4, 0x42, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ILocationEvents* pEvents, in Guid reportType, uint32 dwRequestedReportInterval) RegisterForReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType) UnregisterForReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType, ILocationReport** ppLocationReport) GetReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType, LOCATION_REPORT_STATUS* pStatus) GetReportStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType, uint32* pMilliseconds) GetReportInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType, uint32 millisecondsRequested) SetReportInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType, LOCATION_DESIRED_ACCURACY* pDesiredAccuracy) GetDesiredAccuracy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType, LOCATION_DESIRED_ACCURACY desiredAccuracy) SetDesiredAccuracy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hParent, Guid* pReportTypes, uint32 count, BOOL fModal) RequestPermissions;
	}


	public HRESULT RegisterForReport(ILocationEvents* pEvents, in Guid reportType, uint32 dwRequestedReportInterval) mut => VT.[Friend]RegisterForReport(&this, pEvents, reportType, dwRequestedReportInterval);

	public HRESULT UnregisterForReport(in Guid reportType) mut => VT.[Friend]UnregisterForReport(&this, reportType);

	public HRESULT GetReport(in Guid reportType, ILocationReport** ppLocationReport) mut => VT.[Friend]GetReport(&this, reportType, ppLocationReport);

	public HRESULT GetReportStatus(in Guid reportType, LOCATION_REPORT_STATUS* pStatus) mut => VT.[Friend]GetReportStatus(&this, reportType, pStatus);

	public HRESULT GetReportInterval(in Guid reportType, uint32* pMilliseconds) mut => VT.[Friend]GetReportInterval(&this, reportType, pMilliseconds);

	public HRESULT SetReportInterval(in Guid reportType, uint32 millisecondsRequested) mut => VT.[Friend]SetReportInterval(&this, reportType, millisecondsRequested);

	public HRESULT GetDesiredAccuracy(in Guid reportType, LOCATION_DESIRED_ACCURACY* pDesiredAccuracy) mut => VT.[Friend]GetDesiredAccuracy(&this, reportType, pDesiredAccuracy);

	public HRESULT SetDesiredAccuracy(in Guid reportType, LOCATION_DESIRED_ACCURACY desiredAccuracy) mut => VT.[Friend]SetDesiredAccuracy(&this, reportType, desiredAccuracy);

	public HRESULT RequestPermissions(HWND hParent, Guid* pReportTypes, uint32 count, BOOL fModal) mut => VT.[Friend]RequestPermissions(&this, hParent, pReportTypes, count, fModal);
}

[CRepr]struct ILocationPower : IUnknown
{
	public new const Guid IID = .(0x193e7729, 0xab6b, 0x4b12, 0x86, 0x17, 0x75, 0x96, 0xe1, 0xbb, 0x19, 0x1c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
	}


	public HRESULT Connect() mut => VT.[Friend]Connect(&this);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);
}

[CRepr]struct IDefaultLocation : IUnknown
{
	public new const Guid IID = .(0xa65af77e, 0x969a, 0x4a2e, 0x8a, 0xca, 0x33, 0xbb, 0x7c, 0xbb, 0x12, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType, ILocationReport* pLocationReport) SetReport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType, ILocationReport** ppLocationReport) GetReport;
	}


	public HRESULT SetReport(in Guid reportType, ILocationReport* pLocationReport) mut => VT.[Friend]SetReport(&this, reportType, pLocationReport);

	public HRESULT GetReport(in Guid reportType, ILocationReport** ppLocationReport) mut => VT.[Friend]GetReport(&this, reportType, ppLocationReport);
}

[CRepr]struct ILocationEvents : IUnknown
{
	public new const Guid IID = .(0xcae02bbf, 0x798b, 0x4508, 0xa2, 0x07, 0x35, 0xa7, 0x90, 0x6d, 0xc7, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType, ILocationReport* pLocationReport) OnLocationChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid reportType, LOCATION_REPORT_STATUS newStatus) OnStatusChanged;
	}


	public HRESULT OnLocationChanged(in Guid reportType, ILocationReport* pLocationReport) mut => VT.[Friend]OnLocationChanged(&this, reportType, pLocationReport);

	public HRESULT OnStatusChanged(in Guid reportType, LOCATION_REPORT_STATUS newStatus) mut => VT.[Friend]OnStatusChanged(&this, reportType, newStatus);
}

[CRepr]struct IDispLatLongReport : IDispatch
{
	public new const Guid IID = .(0x8ae32723, 0x389b, 0x4a11, 0x99, 0x57, 0x5b, 0xdd, 0x48, 0xfc, 0x96, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pVal) get_Latitude;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pVal) get_Longitude;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pVal) get_ErrorRadius;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pVal) get_Altitude;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pVal) get_AltitudeError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pVal) get_Timestamp;
	}


	public HRESULT get_Latitude(double* pVal) mut => VT.[Friend]get_Latitude(&this, pVal);

	public HRESULT get_Longitude(double* pVal) mut => VT.[Friend]get_Longitude(&this, pVal);

	public HRESULT get_ErrorRadius(double* pVal) mut => VT.[Friend]get_ErrorRadius(&this, pVal);

	public HRESULT get_Altitude(double* pVal) mut => VT.[Friend]get_Altitude(&this, pVal);

	public HRESULT get_AltitudeError(double* pVal) mut => VT.[Friend]get_AltitudeError(&this, pVal);

	public HRESULT get_Timestamp(double* pVal) mut => VT.[Friend]get_Timestamp(&this, pVal);
}

[CRepr]struct IDispCivicAddressReport : IDispatch
{
	public new const Guid IID = .(0x16ff1a34, 0x9e30, 0x42c3, 0xb4, 0x4d, 0xe2, 0x25, 0x13, 0xb5, 0x76, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pAddress1) get_AddressLine1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pAddress2) get_AddressLine2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pCity) get_City;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pStateProvince) get_StateProvince;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pPostalCode) get_PostalCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pCountryRegion) get_CountryRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pDetailLevel) get_DetailLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pVal) get_Timestamp;
	}


	public HRESULT get_AddressLine1(BSTR* pAddress1) mut => VT.[Friend]get_AddressLine1(&this, pAddress1);

	public HRESULT get_AddressLine2(BSTR* pAddress2) mut => VT.[Friend]get_AddressLine2(&this, pAddress2);

	public HRESULT get_City(BSTR* pCity) mut => VT.[Friend]get_City(&this, pCity);

	public HRESULT get_StateProvince(BSTR* pStateProvince) mut => VT.[Friend]get_StateProvince(&this, pStateProvince);

	public HRESULT get_PostalCode(BSTR* pPostalCode) mut => VT.[Friend]get_PostalCode(&this, pPostalCode);

	public HRESULT get_CountryRegion(BSTR* pCountryRegion) mut => VT.[Friend]get_CountryRegion(&this, pCountryRegion);

	public HRESULT get_DetailLevel(uint32* pDetailLevel) mut => VT.[Friend]get_DetailLevel(&this, pDetailLevel);

	public HRESULT get_Timestamp(double* pVal) mut => VT.[Friend]get_Timestamp(&this, pVal);
}

[CRepr]struct ILocationReportFactory : IDispatch
{
	public new const Guid IID = .(0x2daec322, 0x90b2, 0x47e4, 0xbb, 0x08, 0x0d, 0xa8, 0x41, 0x93, 0x5a, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 requestedReportInterval) ListenForReports;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopListeningForReports;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pVal) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pMilliseconds) get_ReportInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 millisecondsRequested) put_ReportInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pDesiredAccuracy) get_DesiredAccuracy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 desiredAccuracy) put_DesiredAccuracy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* hWnd) RequestPermissions;
	}


	public HRESULT ListenForReports(uint32 requestedReportInterval) mut => VT.[Friend]ListenForReports(&this, requestedReportInterval);

	public HRESULT StopListeningForReports() mut => VT.[Friend]StopListeningForReports(&this);

	public HRESULT get_Status(uint32* pVal) mut => VT.[Friend]get_Status(&this, pVal);

	public HRESULT get_ReportInterval(uint32* pMilliseconds) mut => VT.[Friend]get_ReportInterval(&this, pMilliseconds);

	public HRESULT put_ReportInterval(uint32 millisecondsRequested) mut => VT.[Friend]put_ReportInterval(&this, millisecondsRequested);

	public HRESULT get_DesiredAccuracy(uint32* pDesiredAccuracy) mut => VT.[Friend]get_DesiredAccuracy(&this, pDesiredAccuracy);

	public HRESULT put_DesiredAccuracy(uint32 desiredAccuracy) mut => VT.[Friend]put_DesiredAccuracy(&this, desiredAccuracy);

	public HRESULT RequestPermissions(uint32* hWnd) mut => VT.[Friend]RequestPermissions(&this, hWnd);
}

[CRepr]struct ILatLongReportFactory : ILocationReportFactory
{
	public new const Guid IID = .(0x3f0804cb, 0xb114, 0x447d, 0x83, 0xdd, 0x39, 0x01, 0x74, 0xeb, 0xb0, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ILocationReportFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispLatLongReport** pVal) get_LatLongReport;
	}


	public HRESULT get_LatLongReport(IDispLatLongReport** pVal) mut => VT.[Friend]get_LatLongReport(&this, pVal);
}

[CRepr]struct ICivicAddressReportFactory : ILocationReportFactory
{
	public new const Guid IID = .(0xbf773b93, 0xc64f, 0x4bee, 0xbe, 0xb2, 0x67, 0xc0, 0xb8, 0xdf, 0x66, 0xe0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ILocationReportFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispCivicAddressReport** pVal) get_CivicAddressReport;
	}


	public HRESULT get_CivicAddressReport(IDispCivicAddressReport** pVal) mut => VT.[Friend]get_CivicAddressReport(&this, pVal);
}

[CRepr]struct _ILatLongReportFactoryEvents : IDispatch
{
	public new const Guid IID = .(0x16ee6cb7, 0xab3c, 0x424b, 0x84, 0x9f, 0x26, 0x9b, 0xe5, 0x51, 0xfc, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct _ICivicAddressReportFactoryEvents : IDispatch
{
	public new const Guid IID = .(0xc96039ff, 0x72ec, 0x4617, 0x89, 0xbd, 0x84, 0xd8, 0x8b, 0xed, 0xc7, 0x22);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

#endregion
