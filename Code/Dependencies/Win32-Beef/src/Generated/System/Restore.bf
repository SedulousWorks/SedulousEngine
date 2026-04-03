using Win32.Foundation;
using System;

namespace Win32.System.Restore;

#region Constants
public static
{
	public const uint32 MIN_EVENT = 100;
	public const uint32 BEGIN_NESTED_SYSTEM_CHANGE_NORP = 104;
	public const uint32 MAX_EVENT = 104;
	public const uint32 MIN_RPT = 0;
	public const uint32 DESKTOP_SETTING = 2;
	public const uint32 ACCESSIBILITY_SETTING = 3;
	public const uint32 OE_SETTING = 4;
	public const uint32 APPLICATION_RUN = 5;
	public const uint32 RESTORE = 6;
	public const uint32 CHECKPOINT = 7;
	public const uint32 WINDOWS_SHUTDOWN = 8;
	public const uint32 WINDOWS_BOOT = 9;
	public const uint32 FIRSTRUN = 11;
	public const uint32 BACKUP_RECOVERY = 14;
	public const uint32 BACKUP = 15;
	public const uint32 MANUAL_CHECKPOINT = 16;
	public const uint32 WINDOWS_UPDATE = 17;
	public const uint32 CRITICAL_UPDATE = 18;
	public const uint32 MAX_RPT = 18;
	public const uint32 MAX_DESC = 64;
	public const uint32 MAX_DESC_W = 256;
}
#endregion

#region Enums

[AllowDuplicates]
public enum RESTOREPOINTINFO_TYPE : uint32
{
	APPLICATION_INSTALL = 0,
	APPLICATION_UNINSTALL = 1,
	DEVICE_DRIVER_INSTALL = 10,
	MODIFY_SETTINGS = 12,
	CANCELLED_OPERATION = 13,
}


[AllowDuplicates]
public enum RESTOREPOINTINFO_EVENT_TYPE : uint32
{
	BEGIN_NESTED_SYSTEM_CHANGE = 102,
	BEGIN_SYSTEM_CHANGE = 100,
	END_NESTED_SYSTEM_CHANGE = 103,
	END_SYSTEM_CHANGE = 101,
}

#endregion


#region Structs
[CRepr, Packed(1)]
public struct RESTOREPOINTINFOA
{
	public RESTOREPOINTINFO_EVENT_TYPE dwEventType;
	public RESTOREPOINTINFO_TYPE dwRestorePtType;
	public int64 llSequenceNumber;
	public CHAR[64] szDescription;
}

[CRepr, Packed(1)]
public struct RESTOREPOINTINFOW
{
	public RESTOREPOINTINFO_EVENT_TYPE dwEventType;
	public RESTOREPOINTINFO_TYPE dwRestorePtType;
	public int64 llSequenceNumber;
	public char16[256] szDescription;
}

[CRepr, Packed(1)]
public struct RESTOREPOINTINFOEX
{
	public FILETIME ftCreation;
	public uint32 dwEventType;
	public uint32 dwRestorePtType;
	public uint32 dwRPNum;
	public char16[256] szDescription;
}

[CRepr, Packed(1)]
public struct STATEMGRSTATUS
{
	public uint32 nStatus;
	public int64 llSequenceNumber;
}

#endregion

#region Functions
public static
{
	[Import("sfc.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SRSetRestorePointA(RESTOREPOINTINFOA* pRestorePtSpec, STATEMGRSTATUS* pSMgrStatus);
	public static BOOL SRSetRestorePoint(RESTOREPOINTINFOA* pRestorePtSpec, STATEMGRSTATUS* pSMgrStatus) => SRSetRestorePointA(pRestorePtSpec, pSMgrStatus);

	[Import("sfc.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SRSetRestorePointW(RESTOREPOINTINFOW* pRestorePtSpec, STATEMGRSTATUS* pSMgrStatus);

}
#endregion
