using Win32.Foundation;
using Win32.System.IO;
using System;

namespace Win32.Devices.Communication;

#region Constants
public static
{
	public const uint32 MDM_COMPRESSION = 1;
	public const uint32 MDM_ERROR_CONTROL = 2;
	public const uint32 MDM_FORCED_EC = 4;
	public const uint32 MDM_CELLULAR = 8;
	public const uint32 MDM_FLOWCONTROL_HARD = 16;
	public const uint32 MDM_FLOWCONTROL_SOFT = 32;
	public const uint32 MDM_CCITT_OVERRIDE = 64;
	public const uint32 MDM_SPEED_ADJUST = 128;
	public const uint32 MDM_TONE_DIAL = 256;
	public const uint32 MDM_BLIND_DIAL = 512;
	public const uint32 MDM_V23_OVERRIDE = 1024;
	public const uint32 MDM_DIAGNOSTICS = 2048;
	public const uint32 MDM_MASK_BEARERMODE = 61440;
	public const uint32 MDM_SHIFT_BEARERMODE = 12;
	public const uint32 MDM_MASK_PROTOCOLID = 983040;
	public const uint32 MDM_SHIFT_PROTOCOLID = 16;
	public const uint32 MDM_MASK_PROTOCOLDATA = 267386880;
	public const uint32 MDM_SHIFT_PROTOCOLDATA = 20;
	public const uint32 MDM_SHIFT_PROTOCOLINFO = 16;
	public const uint32 MDM_SHIFT_EXTENDEDINFO = 12;
	public const uint32 MDM_BEARERMODE_ANALOG = 0;
	public const uint32 MDM_BEARERMODE_ISDN = 1;
	public const uint32 MDM_BEARERMODE_GSM = 2;
	public const uint32 MDM_PROTOCOLID_DEFAULT = 0;
	public const uint32 MDM_PROTOCOLID_HDLCPPP = 1;
	public const uint32 MDM_PROTOCOLID_V128 = 2;
	public const uint32 MDM_PROTOCOLID_X75 = 3;
	public const uint32 MDM_PROTOCOLID_V110 = 4;
	public const uint32 MDM_PROTOCOLID_V120 = 5;
	public const uint32 MDM_PROTOCOLID_AUTO = 6;
	public const uint32 MDM_PROTOCOLID_ANALOG = 7;
	public const uint32 MDM_PROTOCOLID_GPRS = 8;
	public const uint32 MDM_PROTOCOLID_PIAFS = 9;
	public const uint32 MDM_SHIFT_HDLCPPP_SPEED = 0;
	public const uint32 MDM_MASK_HDLCPPP_SPEED = 7;
	public const uint32 MDM_HDLCPPP_SPEED_DEFAULT = 0;
	public const uint32 MDM_HDLCPPP_SPEED_64K = 1;
	public const uint32 MDM_HDLCPPP_SPEED_56K = 2;
	public const uint32 MDM_SHIFT_HDLCPPP_AUTH = 3;
	public const uint32 MDM_HDLCPPP_AUTH_DEFAULT = 0;
	public const uint32 MDM_HDLCPPP_AUTH_NONE = 1;
	public const uint32 MDM_HDLCPPP_AUTH_PAP = 2;
	public const uint32 MDM_HDLCPPP_AUTH_CHAP = 3;
	public const uint32 MDM_HDLCPPP_AUTH_MSCHAP = 4;
	public const uint32 MDM_SHIFT_HDLCPPP_ML = 6;
	public const uint32 MDM_HDLCPPP_ML_DEFAULT = 0;
	public const uint32 MDM_HDLCPPP_ML_NONE = 1;
	public const uint32 MDM_HDLCPPP_ML_2 = 2;
	public const uint32 MDM_SHIFT_V120_SPEED = 0;
	public const uint32 MDM_MASK_V120_SPEED = 7;
	public const uint32 MDM_V120_SPEED_DEFAULT = 0;
	public const uint32 MDM_V120_SPEED_64K = 1;
	public const uint32 MDM_V120_SPEED_56K = 2;
	public const uint32 MDM_SHIFT_V120_ML = 6;
	public const uint32 MDM_V120_ML_DEFAULT = 0;
	public const uint32 MDM_V120_ML_NONE = 1;
	public const uint32 MDM_V120_ML_2 = 2;
	public const uint32 MDM_SHIFT_X75_DATA = 0;
	public const uint32 MDM_MASK_X75_DATA = 7;
	public const uint32 MDM_X75_DATA_DEFAULT = 0;
	public const uint32 MDM_X75_DATA_64K = 1;
	public const uint32 MDM_X75_DATA_128K = 2;
	public const uint32 MDM_X75_DATA_T_70 = 3;
	public const uint32 MDM_X75_DATA_BTX = 4;
	public const uint32 MDM_SHIFT_V110_SPEED = 0;
	public const uint32 MDM_MASK_V110_SPEED = 15;
	public const uint32 MDM_V110_SPEED_DEFAULT = 0;
	public const uint32 MDM_V110_SPEED_1DOT2K = 1;
	public const uint32 MDM_V110_SPEED_2DOT4K = 2;
	public const uint32 MDM_V110_SPEED_4DOT8K = 3;
	public const uint32 MDM_V110_SPEED_9DOT6K = 4;
	public const uint32 MDM_V110_SPEED_12DOT0K = 5;
	public const uint32 MDM_V110_SPEED_14DOT4K = 6;
	public const uint32 MDM_V110_SPEED_19DOT2K = 7;
	public const uint32 MDM_V110_SPEED_28DOT8K = 8;
	public const uint32 MDM_V110_SPEED_38DOT4K = 9;
	public const uint32 MDM_V110_SPEED_57DOT6K = 10;
	public const uint32 MDM_SHIFT_AUTO_SPEED = 0;
	public const uint32 MDM_MASK_AUTO_SPEED = 7;
	public const uint32 MDM_AUTO_SPEED_DEFAULT = 0;
	public const uint32 MDM_SHIFT_AUTO_ML = 6;
	public const uint32 MDM_AUTO_ML_DEFAULT = 0;
	public const uint32 MDM_AUTO_ML_NONE = 1;
	public const uint32 MDM_AUTO_ML_2 = 2;
	public const uint32 MDM_ANALOG_RLP_ON = 0;
	public const uint32 MDM_ANALOG_RLP_OFF = 1;
	public const uint32 MDM_ANALOG_V34 = 2;
	public const uint32 MDM_PIAFS_INCOMING = 0;
	public const uint32 MDM_PIAFS_OUTGOING = 1;
	public const Guid SID_3GPP_SUPSVCMODEL = .(0xd7d08e07, 0xd767, 0x4478, 0xb1, 0x4a, 0xee, 0xcc, 0x87, 0xea, 0x12, 0xf7);
	public const uint32 MAXLENGTH_NAI = 72;
	public const uint32 MAXLENGTH_UICCDATASTORE = 10;
}
#endregion

#region Enums

[AllowDuplicates]
public enum MODEM_STATUS_FLAGS : uint32
{
	MS_CTS_ON = 16,
	MS_DSR_ON = 32,
	MS_RING_ON = 64,
	MS_RLSD_ON = 128,
}


[AllowDuplicates]
public enum CLEAR_COMM_ERROR_FLAGS : uint32
{
	CE_BREAK = 16,
	CE_FRAME = 8,
	CE_OVERRUN = 2,
	CE_RXOVER = 1,
	CE_RXPARITY = 4,
}


[AllowDuplicates]
public enum PURGE_COMM_FLAGS : uint32
{
	PURGE_RXABORT = 2,
	PURGE_RXCLEAR = 8,
	PURGE_TXABORT = 1,
	PURGE_TXCLEAR = 4,
}


[AllowDuplicates]
public enum COMM_EVENT_MASK : uint32
{
	EV_BREAK = 64,
	EV_CTS = 8,
	EV_DSR = 16,
	EV_ERR = 128,
	EV_EVENT1 = 2048,
	EV_EVENT2 = 4096,
	EV_PERR = 512,
	EV_RING = 256,
	EV_RLSD = 32,
	EV_RX80FULL = 1024,
	EV_RXCHAR = 1,
	EV_RXFLAG = 2,
	EV_TXEMPTY = 4,
}


[AllowDuplicates]
public enum ESCAPE_COMM_FUNCTION : uint32
{
	CLRBREAK = 9,
	CLRDTR = 6,
	CLRRTS = 4,
	SETBREAK = 8,
	SETDTR = 5,
	SETRTS = 3,
	SETXOFF = 1,
	SETXON = 2,
}


[AllowDuplicates]
public enum MODEMDEVCAPS_DIAL_OPTIONS : uint32
{
	DIALOPTION_BILLING = 64,
	DIALOPTION_DIALTONE = 256,
	DIALOPTION_QUIET = 128,
}


[AllowDuplicates]
public enum MODEMSETTINGS_SPEAKER_MODE : uint32
{
	MDMSPKR_CALLSETUP = 8,
	MDMSPKR_DIAL = 2,
	MDMSPKR_OFF = 1,
	MDMSPKR_ON = 4,
}


[AllowDuplicates]
public enum COMMPROP_STOP_PARITY : uint16
{
	STOPBITS_10 = 1,
	STOPBITS_15 = 2,
	STOPBITS_20 = 4,
	PARITY_NONE = 256,
	PARITY_ODD = 512,
	PARITY_EVEN = 1024,
	PARITY_MARK = 2048,
	PARITY_SPACE = 4096,
}


[AllowDuplicates]
public enum MODEM_SPEAKER_VOLUME : uint32
{
	MDMVOL_HIGH = 2,
	MDMVOL_LOW = 0,
	MDMVOL_MEDIUM = 1,
}


[AllowDuplicates]
public enum MODEMDEVCAPS_SPEAKER_VOLUME : uint32
{
	MDMVOLFLAG_HIGH = 4,
	MDMVOLFLAG_LOW = 1,
	MDMVOLFLAG_MEDIUM = 2,
}


[AllowDuplicates]
public enum MODEMDEVCAPS_SPEAKER_MODE : uint32
{
	MDMSPKRFLAG_CALLSETUP = 8,
	MDMSPKRFLAG_DIAL = 2,
	MDMSPKRFLAG_OFF = 1,
	MDMSPKRFLAG_ON = 4,
}


[AllowDuplicates]
public enum DCB_STOP_BITS : uint8
{
	ONESTOPBIT = 0,
	ONE5STOPBITS = 1,
	TWOSTOPBITS = 2,
}


[AllowDuplicates]
public enum DCB_PARITY : uint8
{
	EVENPARITY = 2,
	MARKPARITY = 3,
	NOPARITY = 0,
	ODDPARITY = 1,
	SPACEPARITY = 4,
}

#endregion


#region Structs
[CRepr]
public struct MODEMDEVCAPS
{
	public uint32 dwActualSize;
	public uint32 dwRequiredSize;
	public uint32 dwDevSpecificOffset;
	public uint32 dwDevSpecificSize;
	public uint32 dwModemProviderVersion;
	public uint32 dwModemManufacturerOffset;
	public uint32 dwModemManufacturerSize;
	public uint32 dwModemModelOffset;
	public uint32 dwModemModelSize;
	public uint32 dwModemVersionOffset;
	public uint32 dwModemVersionSize;
	public MODEMDEVCAPS_DIAL_OPTIONS dwDialOptions;
	public uint32 dwCallSetupFailTimer;
	public uint32 dwInactivityTimeout;
	public MODEMDEVCAPS_SPEAKER_VOLUME dwSpeakerVolume;
	public MODEMDEVCAPS_SPEAKER_MODE dwSpeakerMode;
	public uint32 dwModemOptions;
	public uint32 dwMaxDTERate;
	public uint32 dwMaxDCERate;
	public uint8* abVariablePortion mut => &abVariablePortion_impl;
	private uint8[ANYSIZE_ARRAY] abVariablePortion_impl;
}

[CRepr]
public struct MODEMSETTINGS
{
	public uint32 dwActualSize;
	public uint32 dwRequiredSize;
	public uint32 dwDevSpecificOffset;
	public uint32 dwDevSpecificSize;
	public uint32 dwCallSetupFailTimer;
	public uint32 dwInactivityTimeout;
	public MODEM_SPEAKER_VOLUME dwSpeakerVolume;
	public MODEMSETTINGS_SPEAKER_MODE dwSpeakerMode;
	public uint32 dwPreferredModemOptions;
	public uint32 dwNegotiatedModemOptions;
	public uint32 dwNegotiatedDCERate;
	public uint8* abVariablePortion mut => &abVariablePortion_impl;
	private uint8[ANYSIZE_ARRAY] abVariablePortion_impl;
}

[CRepr]
public struct COMMPROP
{
	public uint16 wPacketLength;
	public uint16 wPacketVersion;
	public uint32 dwServiceMask;
	public uint32 dwReserved1;
	public uint32 dwMaxTxQueue;
	public uint32 dwMaxRxQueue;
	public uint32 dwMaxBaud;
	public uint32 dwProvSubType;
	public uint32 dwProvCapabilities;
	public uint32 dwSettableParams;
	public uint32 dwSettableBaud;
	public uint16 wSettableData;
	public COMMPROP_STOP_PARITY wSettableStopParity;
	public uint32 dwCurrentTxQueue;
	public uint32 dwCurrentRxQueue;
	public uint32 dwProvSpec1;
	public uint32 dwProvSpec2;
	public char16* wcProvChar mut => &wcProvChar_impl;
	private char16[ANYSIZE_ARRAY] wcProvChar_impl;
}

[CRepr]
public struct COMSTAT
{
	public uint32 _bitfield;
	public uint32 cbInQue;
	public uint32 cbOutQue;
}

[CRepr]
public struct DCB
{
	public uint32 DCBlength;
	public uint32 BaudRate;
	public uint32 _bitfield;
	public uint16 wReserved;
	public uint16 XonLim;
	public uint16 XoffLim;
	public uint8 ByteSize;
	public DCB_PARITY Parity;
	public DCB_STOP_BITS StopBits;
	public CHAR XonChar;
	public CHAR XoffChar;
	public CHAR ErrorChar;
	public CHAR EofChar;
	public CHAR EvtChar;
	public uint16 wReserved1;
}

[CRepr]
public struct COMMTIMEOUTS
{
	public uint32 ReadIntervalTimeout;
	public uint32 ReadTotalTimeoutMultiplier;
	public uint32 ReadTotalTimeoutConstant;
	public uint32 WriteTotalTimeoutMultiplier;
	public uint32 WriteTotalTimeoutConstant;
}

[CRepr]
public struct COMMCONFIG
{
	public uint32 dwSize;
	public uint16 wVersion;
	public uint16 wReserved;
	public DCB dcb;
	public uint32 dwProviderSubType;
	public uint32 dwProviderOffset;
	public uint32 dwProviderSize;
	public char16* wcProviderData mut => &wcProviderData_impl;
	private char16[ANYSIZE_ARRAY] wcProviderData_impl;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ClearCommBreak(HANDLE hFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ClearCommError(HANDLE hFile, CLEAR_COMM_ERROR_FLAGS* lpErrors, COMSTAT* lpStat);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupComm(HANDLE hFile, uint32 dwInQueue, uint32 dwOutQueue);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EscapeCommFunction(HANDLE hFile, ESCAPE_COMM_FUNCTION dwFunc);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCommConfig(HANDLE hCommDev, COMMCONFIG* lpCC, uint32* lpdwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCommMask(HANDLE hFile, COMM_EVENT_MASK* lpEvtMask);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCommProperties(HANDLE hFile, COMMPROP* lpCommProp);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCommModemStatus(HANDLE hFile, MODEM_STATUS_FLAGS* lpModemStat);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCommState(HANDLE hFile, DCB* lpDCB);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCommTimeouts(HANDLE hFile, COMMTIMEOUTS* lpCommTimeouts);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PurgeComm(HANDLE hFile, PURGE_COMM_FLAGS dwFlags);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCommBreak(HANDLE hFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCommConfig(HANDLE hCommDev, COMMCONFIG* lpCC, uint32 dwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCommMask(HANDLE hFile, COMM_EVENT_MASK dwEvtMask);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCommState(HANDLE hFile, DCB* lpDCB);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetCommTimeouts(HANDLE hFile, COMMTIMEOUTS* lpCommTimeouts);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TransmitCommChar(HANDLE hFile, CHAR cChar);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WaitCommEvent(HANDLE hFile, COMM_EVENT_MASK* lpEvtMask, OVERLAPPED* lpOverlapped);

	[Import("api-ms-win-core-comm-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE OpenCommPort(uint32 uPortNumber, uint32 dwDesiredAccess, uint32 dwFlagsAndAttributes);

	[Import("api-ms-win-core-comm-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCommPorts(uint32* lpPortNumbers, uint32 uPortNumbersCount, uint32* puPortNumbersFound);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BuildCommDCBA(PSTR lpDef, DCB* lpDCB);
	public static BOOL BuildCommDCB(PSTR lpDef, DCB* lpDCB) => BuildCommDCBA(lpDef, lpDCB);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BuildCommDCBW(PWSTR lpDef, DCB* lpDCB);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BuildCommDCBAndTimeoutsA(PSTR lpDef, DCB* lpDCB, COMMTIMEOUTS* lpCommTimeouts);
	public static BOOL BuildCommDCBAndTimeouts(PSTR lpDef, DCB* lpDCB, COMMTIMEOUTS* lpCommTimeouts) => BuildCommDCBAndTimeoutsA(lpDef, lpDCB, lpCommTimeouts);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BuildCommDCBAndTimeoutsW(PWSTR lpDef, DCB* lpDCB, COMMTIMEOUTS* lpCommTimeouts);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CommConfigDialogA(PSTR lpszName, HWND hWnd, COMMCONFIG* lpCC);
	public static BOOL CommConfigDialog(PSTR lpszName, HWND hWnd, COMMCONFIG* lpCC) => CommConfigDialogA(lpszName, hWnd, lpCC);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CommConfigDialogW(PWSTR lpszName, HWND hWnd, COMMCONFIG* lpCC);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDefaultCommConfigA(PSTR lpszName, COMMCONFIG* lpCC, uint32* lpdwSize);
	public static BOOL GetDefaultCommConfig(PSTR lpszName, COMMCONFIG* lpCC, uint32* lpdwSize) => GetDefaultCommConfigA(lpszName, lpCC, lpdwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDefaultCommConfigW(PWSTR lpszName, COMMCONFIG* lpCC, uint32* lpdwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDefaultCommConfigA(PSTR lpszName, COMMCONFIG* lpCC, uint32 dwSize);
	public static BOOL SetDefaultCommConfig(PSTR lpszName, COMMCONFIG* lpCC, uint32 dwSize) => SetDefaultCommConfigA(lpszName, lpCC, dwSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDefaultCommConfigW(PWSTR lpszName, COMMCONFIG* lpCC, uint32 dwSize);

}
#endregion
