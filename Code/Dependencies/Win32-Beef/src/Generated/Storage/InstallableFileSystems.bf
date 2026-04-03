using Win32.Foundation;
using Win32.Security;
using Win32.System.IO;
using System;

namespace Win32.Storage.InstallableFileSystems;

#region Constants
public static
{
	public const uint32 FILTER_NAME_MAX_CHARS = 255;
	public const uint32 VOLUME_NAME_MAX_CHARS = 1024;
	public const uint32 INSTANCE_NAME_MAX_CHARS = 255;
	public const uint32 FLTFL_AGGREGATE_INFO_IS_MINIFILTER = 1;
	public const uint32 FLTFL_AGGREGATE_INFO_IS_LEGACYFILTER = 2;
	public const uint32 FLTFL_ASI_IS_MINIFILTER = 1;
	public const uint32 FLTFL_ASI_IS_LEGACYFILTER = 2;
	public const uint32 FLTFL_VSI_DETACHED_VOLUME = 1;
	public const uint32 FLTFL_IASI_IS_MINIFILTER = 1;
	public const uint32 FLTFL_IASI_IS_LEGACYFILTER = 2;
	public const uint32 FLTFL_IASIM_DETACHED_VOLUME = 1;
	public const uint32 FLTFL_IASIL_DETACHED_VOLUME = 1;
	public const uint32 FLT_PORT_FLAG_SYNC_HANDLE = 1;
	public const uint32 WNNC_NET_MSNET = 65536;
	public const uint32 WNNC_NET_SMB = 131072;
	public const uint32 WNNC_NET_NETWARE = 196608;
	public const uint32 WNNC_NET_VINES = 262144;
	public const uint32 WNNC_NET_10NET = 327680;
	public const uint32 WNNC_NET_LOCUS = 393216;
	public const uint32 WNNC_NET_SUN_PC_NFS = 458752;
	public const uint32 WNNC_NET_LANSTEP = 524288;
	public const uint32 WNNC_NET_9TILES = 589824;
	public const uint32 WNNC_NET_LANTASTIC = 655360;
	public const uint32 WNNC_NET_AS400 = 720896;
	public const uint32 WNNC_NET_FTP_NFS = 786432;
	public const uint32 WNNC_NET_PATHWORKS = 851968;
	public const uint32 WNNC_NET_LIFENET = 917504;
	public const uint32 WNNC_NET_POWERLAN = 983040;
	public const uint32 WNNC_NET_BWNFS = 1048576;
	public const uint32 WNNC_NET_COGENT = 1114112;
	public const uint32 WNNC_NET_FARALLON = 1179648;
	public const uint32 WNNC_NET_APPLETALK = 1245184;
	public const uint32 WNNC_NET_INTERGRAPH = 1310720;
	public const uint32 WNNC_NET_SYMFONET = 1376256;
	public const uint32 WNNC_NET_CLEARCASE = 1441792;
	public const uint32 WNNC_NET_FRONTIER = 1507328;
	public const uint32 WNNC_NET_BMC = 1572864;
	public const uint32 WNNC_NET_DCE = 1638400;
	public const uint32 WNNC_NET_AVID = 1703936;
	public const uint32 WNNC_NET_DOCUSPACE = 1769472;
	public const uint32 WNNC_NET_MANGOSOFT = 1835008;
	public const uint32 WNNC_NET_SERNET = 1900544;
	public const uint32 WNNC_NET_RIVERFRONT1 = 1966080;
	public const uint32 WNNC_NET_RIVERFRONT2 = 2031616;
	public const uint32 WNNC_NET_DECORB = 2097152;
	public const uint32 WNNC_NET_PROTSTOR = 2162688;
	public const uint32 WNNC_NET_FJ_REDIR = 2228224;
	public const uint32 WNNC_NET_DISTINCT = 2293760;
	public const uint32 WNNC_NET_TWINS = 2359296;
	public const uint32 WNNC_NET_RDR2SAMPLE = 2424832;
	public const uint32 WNNC_NET_CSC = 2490368;
	public const uint32 WNNC_NET_3IN1 = 2555904;
	public const uint32 WNNC_NET_EXTENDNET = 2686976;
	public const uint32 WNNC_NET_STAC = 2752512;
	public const uint32 WNNC_NET_FOXBAT = 2818048;
	public const uint32 WNNC_NET_YAHOO = 2883584;
	public const uint32 WNNC_NET_EXIFS = 2949120;
	public const uint32 WNNC_NET_DAV = 3014656;
	public const uint32 WNNC_NET_KNOWARE = 3080192;
	public const uint32 WNNC_NET_OBJECT_DIRE = 3145728;
	public const uint32 WNNC_NET_MASFAX = 3211264;
	public const uint32 WNNC_NET_HOB_NFS = 3276800;
	public const uint32 WNNC_NET_SHIVA = 3342336;
	public const uint32 WNNC_NET_IBMAL = 3407872;
	public const uint32 WNNC_NET_LOCK = 3473408;
	public const uint32 WNNC_NET_TERMSRV = 3538944;
	public const uint32 WNNC_NET_SRT = 3604480;
	public const uint32 WNNC_NET_QUINCY = 3670016;
	public const uint32 WNNC_NET_OPENAFS = 3735552;
	public const uint32 WNNC_NET_AVID1 = 3801088;
	public const uint32 WNNC_NET_DFS = 3866624;
	public const uint32 WNNC_NET_KWNP = 3932160;
	public const uint32 WNNC_NET_ZENWORKS = 3997696;
	public const uint32 WNNC_NET_DRIVEONWEB = 4063232;
	public const uint32 WNNC_NET_VMWARE = 4128768;
	public const uint32 WNNC_NET_RSFX = 4194304;
	public const uint32 WNNC_NET_MFILES = 4259840;
	public const uint32 WNNC_NET_MS_NFS = 4325376;
	public const uint32 WNNC_NET_GOOGLE = 4390912;
	public const uint32 WNNC_NET_NDFS = 4456448;
	public const uint32 WNNC_NET_DOCUSHARE = 4521984;
	public const uint32 WNNC_NET_AURISTOR_FS = 4587520;
	public const uint32 WNNC_NET_SECUREAGENT = 4653056;
	public const uint32 WNNC_NET_9P = 4718592;
	public const uint32 WNNC_CRED_MANAGER = 4294901760;
	public const uint32 WNNC_NET_LANMAN = 131072;
}
#endregion

#region TypeDefs
typealias HFILTER = int;

typealias HFILTER_INSTANCE = int;

typealias FilterFindHandle = int;

typealias FilterVolumeFindHandle = int;

typealias FilterInstanceFindHandle = int;

typealias FilterVolumeInstanceFindHandle = int;

#endregion


#region Enums

[AllowDuplicates]
public enum FLT_FILESYSTEM_TYPE : int32
{
	FLT_FSTYPE_UNKNOWN = 0,
	FLT_FSTYPE_RAW = 1,
	FLT_FSTYPE_NTFS = 2,
	FLT_FSTYPE_FAT = 3,
	FLT_FSTYPE_CDFS = 4,
	FLT_FSTYPE_UDFS = 5,
	FLT_FSTYPE_LANMAN = 6,
	FLT_FSTYPE_WEBDAV = 7,
	FLT_FSTYPE_RDPDR = 8,
	FLT_FSTYPE_NFS = 9,
	FLT_FSTYPE_MS_NETWARE = 10,
	FLT_FSTYPE_NETWARE = 11,
	FLT_FSTYPE_BSUDF = 12,
	FLT_FSTYPE_MUP = 13,
	FLT_FSTYPE_RSFX = 14,
	FLT_FSTYPE_ROXIO_UDF1 = 15,
	FLT_FSTYPE_ROXIO_UDF2 = 16,
	FLT_FSTYPE_ROXIO_UDF3 = 17,
	FLT_FSTYPE_TACIT = 18,
	FLT_FSTYPE_FS_REC = 19,
	FLT_FSTYPE_INCD = 20,
	FLT_FSTYPE_INCD_FAT = 21,
	FLT_FSTYPE_EXFAT = 22,
	FLT_FSTYPE_PSFS = 23,
	FLT_FSTYPE_GPFS = 24,
	FLT_FSTYPE_NPFS = 25,
	FLT_FSTYPE_MSFS = 26,
	FLT_FSTYPE_CSVFS = 27,
	FLT_FSTYPE_REFS = 28,
	FLT_FSTYPE_OPENAFS = 29,
	FLT_FSTYPE_CIMFS = 30,
}


[AllowDuplicates]
public enum FILTER_INFORMATION_CLASS : int32
{
	FilterFullInformation = 0,
	FilterAggregateBasicInformation = 1,
	FilterAggregateStandardInformation = 2,
}


[AllowDuplicates]
public enum FILTER_VOLUME_INFORMATION_CLASS : int32
{
	FilterVolumeBasicInformation = 0,
	FilterVolumeStandardInformation = 1,
}


[AllowDuplicates]
public enum INSTANCE_INFORMATION_CLASS : int32
{
	InstanceBasicInformation = 0,
	InstancePartialInformation = 1,
	InstanceFullInformation = 2,
	InstanceAggregateStandardInformation = 3,
}

#endregion


#region Structs
[CRepr]
public struct FILTER_FULL_INFORMATION
{
	public uint32 NextEntryOffset;
	public uint32 FrameID;
	public uint32 NumberOfInstances;
	public uint16 FilterNameLength;
	public char16* FilterNameBuffer mut => &FilterNameBuffer_impl;
	private char16[ANYSIZE_ARRAY] FilterNameBuffer_impl;
}

[CRepr]
public struct FILTER_AGGREGATE_BASIC_INFORMATION
{
	[CRepr, Union]
	public struct _Type_e__Union
	{
		[CRepr]
		public struct _MiniFilter_e__Struct
		{
			public uint32 FrameID;
			public uint32 NumberOfInstances;
			public uint16 FilterNameLength;
			public uint16 FilterNameBufferOffset;
			public uint16 FilterAltitudeLength;
			public uint16 FilterAltitudeBufferOffset;
		}
		[CRepr]
		public struct _LegacyFilter_e__Struct
		{
			public uint16 FilterNameLength;
			public uint16 FilterNameBufferOffset;
		}
		public _MiniFilter_e__Struct MiniFilter;
		public _LegacyFilter_e__Struct LegacyFilter;
	}
	public uint32 NextEntryOffset;
	public uint32 Flags;
	public _Type_e__Union Type;
}

[CRepr]
public struct FILTER_AGGREGATE_STANDARD_INFORMATION
{
	[CRepr, Union]
	public struct _Type_e__Union
	{
		[CRepr]
		public struct _MiniFilter_e__Struct
		{
			public uint32 Flags;
			public uint32 FrameID;
			public uint32 NumberOfInstances;
			public uint16 FilterNameLength;
			public uint16 FilterNameBufferOffset;
			public uint16 FilterAltitudeLength;
			public uint16 FilterAltitudeBufferOffset;
		}
		[CRepr]
		public struct _LegacyFilter_e__Struct
		{
			public uint32 Flags;
			public uint16 FilterNameLength;
			public uint16 FilterNameBufferOffset;
			public uint16 FilterAltitudeLength;
			public uint16 FilterAltitudeBufferOffset;
		}
		public _MiniFilter_e__Struct MiniFilter;
		public _LegacyFilter_e__Struct LegacyFilter;
	}
	public uint32 NextEntryOffset;
	public uint32 Flags;
	public _Type_e__Union Type;
}

[CRepr]
public struct FILTER_VOLUME_BASIC_INFORMATION
{
	public uint16 FilterVolumeNameLength;
	public char16* FilterVolumeName mut => &FilterVolumeName_impl;
	private char16[ANYSIZE_ARRAY] FilterVolumeName_impl;
}

[CRepr]
public struct FILTER_VOLUME_STANDARD_INFORMATION
{
	public uint32 NextEntryOffset;
	public uint32 Flags;
	public uint32 FrameID;
	public FLT_FILESYSTEM_TYPE FileSystemType;
	public uint16 FilterVolumeNameLength;
	public char16* FilterVolumeName mut => &FilterVolumeName_impl;
	private char16[ANYSIZE_ARRAY] FilterVolumeName_impl;
}

[CRepr]
public struct INSTANCE_BASIC_INFORMATION
{
	public uint32 NextEntryOffset;
	public uint16 InstanceNameLength;
	public uint16 InstanceNameBufferOffset;
}

[CRepr]
public struct INSTANCE_PARTIAL_INFORMATION
{
	public uint32 NextEntryOffset;
	public uint16 InstanceNameLength;
	public uint16 InstanceNameBufferOffset;
	public uint16 AltitudeLength;
	public uint16 AltitudeBufferOffset;
}

[CRepr]
public struct INSTANCE_FULL_INFORMATION
{
	public uint32 NextEntryOffset;
	public uint16 InstanceNameLength;
	public uint16 InstanceNameBufferOffset;
	public uint16 AltitudeLength;
	public uint16 AltitudeBufferOffset;
	public uint16 VolumeNameLength;
	public uint16 VolumeNameBufferOffset;
	public uint16 FilterNameLength;
	public uint16 FilterNameBufferOffset;
}

[CRepr]
public struct INSTANCE_AGGREGATE_STANDARD_INFORMATION
{
	[CRepr, Union]
	public struct _Type_e__Union
	{
		[CRepr]
		public struct _MiniFilter_e__Struct
		{
			public uint32 Flags;
			public uint32 FrameID;
			public FLT_FILESYSTEM_TYPE VolumeFileSystemType;
			public uint16 InstanceNameLength;
			public uint16 InstanceNameBufferOffset;
			public uint16 AltitudeLength;
			public uint16 AltitudeBufferOffset;
			public uint16 VolumeNameLength;
			public uint16 VolumeNameBufferOffset;
			public uint16 FilterNameLength;
			public uint16 FilterNameBufferOffset;
			public uint32 SupportedFeatures;
		}
		[CRepr]
		public struct _LegacyFilter_e__Struct
		{
			public uint32 Flags;
			public uint16 AltitudeLength;
			public uint16 AltitudeBufferOffset;
			public uint16 VolumeNameLength;
			public uint16 VolumeNameBufferOffset;
			public uint16 FilterNameLength;
			public uint16 FilterNameBufferOffset;
			public uint32 SupportedFeatures;
		}
		public _MiniFilter_e__Struct MiniFilter;
		public _LegacyFilter_e__Struct LegacyFilter;
	}
	public uint32 NextEntryOffset;
	public uint32 Flags;
	public _Type_e__Union Type;
}

[CRepr]
public struct FILTER_MESSAGE_HEADER
{
	public uint32 ReplyLength;
	public uint64 MessageId;
}

[CRepr]
public struct FILTER_REPLY_HEADER
{
	public NTSTATUS Status;
	public uint64 MessageId;
}

#endregion

#region Functions
public static
{
	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterLoad(PWSTR lpFilterName);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterUnload(PWSTR lpFilterName);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterCreate(PWSTR lpFilterName, HFILTER* hFilter);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterClose(HFILTER hFilter);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterInstanceCreate(PWSTR lpFilterName, PWSTR lpVolumeName, PWSTR lpInstanceName, HFILTER_INSTANCE* hInstance);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterInstanceClose(HFILTER_INSTANCE hInstance);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterAttach(PWSTR lpFilterName, PWSTR lpVolumeName, PWSTR lpInstanceName, uint32 dwCreatedInstanceNameLength, PWSTR lpCreatedInstanceName);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterAttachAtAltitude(PWSTR lpFilterName, PWSTR lpVolumeName, PWSTR lpAltitude, PWSTR lpInstanceName, uint32 dwCreatedInstanceNameLength, PWSTR lpCreatedInstanceName);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterDetach(PWSTR lpFilterName, PWSTR lpVolumeName, PWSTR lpInstanceName);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterFindFirst(FILTER_INFORMATION_CLASS dwInformationClass, void* lpBuffer, uint32 dwBufferSize, uint32* lpBytesReturned, FilterFindHandle* lpFilterFind);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterFindNext(HANDLE hFilterFind, FILTER_INFORMATION_CLASS dwInformationClass, void* lpBuffer, uint32 dwBufferSize, uint32* lpBytesReturned);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterFindClose(HANDLE hFilterFind);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterVolumeFindFirst(FILTER_VOLUME_INFORMATION_CLASS dwInformationClass, void* lpBuffer, uint32 dwBufferSize, uint32* lpBytesReturned, FilterVolumeFindHandle* lpVolumeFind);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterVolumeFindNext(HANDLE hVolumeFind, FILTER_VOLUME_INFORMATION_CLASS dwInformationClass, void* lpBuffer, uint32 dwBufferSize, uint32* lpBytesReturned);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterVolumeFindClose(HANDLE hVolumeFind);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterInstanceFindFirst(PWSTR lpFilterName, INSTANCE_INFORMATION_CLASS dwInformationClass, void* lpBuffer, uint32 dwBufferSize, uint32* lpBytesReturned, FilterInstanceFindHandle* lpFilterInstanceFind);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterInstanceFindNext(HANDLE hFilterInstanceFind, INSTANCE_INFORMATION_CLASS dwInformationClass, void* lpBuffer, uint32 dwBufferSize, uint32* lpBytesReturned);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterInstanceFindClose(HANDLE hFilterInstanceFind);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterVolumeInstanceFindFirst(PWSTR lpVolumeName, INSTANCE_INFORMATION_CLASS dwInformationClass, void* lpBuffer, uint32 dwBufferSize, uint32* lpBytesReturned, FilterVolumeInstanceFindHandle* lpVolumeInstanceFind);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterVolumeInstanceFindNext(HANDLE hVolumeInstanceFind, INSTANCE_INFORMATION_CLASS dwInformationClass, void* lpBuffer, uint32 dwBufferSize, uint32* lpBytesReturned);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterVolumeInstanceFindClose(HANDLE hVolumeInstanceFind);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterGetInformation(HFILTER hFilter, FILTER_INFORMATION_CLASS dwInformationClass, void* lpBuffer, uint32 dwBufferSize, uint32* lpBytesReturned);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterInstanceGetInformation(HFILTER_INSTANCE hInstance, INSTANCE_INFORMATION_CLASS dwInformationClass, void* lpBuffer, uint32 dwBufferSize, uint32* lpBytesReturned);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterConnectCommunicationPort(PWSTR lpPortName, uint32 dwOptions, void* lpContext, uint16 wSizeOfContext, SECURITY_ATTRIBUTES* lpSecurityAttributes, HANDLE* hPort);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterSendMessage(HANDLE hPort, void* lpInBuffer, uint32 dwInBufferSize, void* lpOutBuffer, uint32 dwOutBufferSize, uint32* lpBytesReturned);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterGetMessage(HANDLE hPort, FILTER_MESSAGE_HEADER* lpMessageBuffer, uint32 dwMessageBufferSize, OVERLAPPED* lpOverlapped);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterReplyMessage(HANDLE hPort, FILTER_REPLY_HEADER* lpReplyBuffer, uint32 dwReplyBufferSize);

	[Import("FLTLIB.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT FilterGetDosName(PWSTR lpVolumeName, char16* lpDosName, uint32 dwDosNameBufferSize);

}
#endregion
