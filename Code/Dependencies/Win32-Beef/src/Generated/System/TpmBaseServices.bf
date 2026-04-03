using Win32.Foundation;
using System;

namespace Win32.System.TpmBaseServices;

#region Constants
public static
{
	public const uint32 TBS_CONTEXT_VERSION_ONE = 1;
	public const uint32 TBS_SUCCESS = 0;
	public const uint32 TBS_OWNERAUTH_TYPE_FULL = 1;
	public const uint32 TBS_OWNERAUTH_TYPE_ADMIN = 2;
	public const uint32 TBS_OWNERAUTH_TYPE_USER = 3;
	public const uint32 TBS_OWNERAUTH_TYPE_ENDORSEMENT = 4;
	public const uint32 TBS_OWNERAUTH_TYPE_ENDORSEMENT_20 = 12;
	public const uint32 TBS_OWNERAUTH_TYPE_STORAGE_20 = 13;
	public const uint32 TBS_CONTEXT_VERSION_TWO = 2;
	public const uint32 TPM_WNF_INFO_CLEAR_SUCCESSFUL = 1;
	public const uint32 TPM_WNF_INFO_OWNERSHIP_SUCCESSFUL = 2;
	public const uint32 TPM_WNF_INFO_NO_REBOOT_REQUIRED = 1;
	public const uint32 TPM_VERSION_UNKNOWN = 0;
	public const uint32 TPM_VERSION_12 = 1;
	public const uint32 TPM_VERSION_20 = 2;
	public const uint32 TPM_IFTYPE_UNKNOWN = 0;
	public const uint32 TPM_IFTYPE_1 = 1;
	public const uint32 TPM_IFTYPE_TRUSTZONE = 2;
	public const uint32 TPM_IFTYPE_HW = 3;
	public const uint32 TPM_IFTYPE_EMULATOR = 4;
	public const uint32 TPM_IFTYPE_SPB = 5;
	public const uint32 TBS_TCGLOG_SRTM_CURRENT = 0;
	public const uint32 TBS_TCGLOG_DRTM_CURRENT = 1;
	public const uint32 TBS_TCGLOG_SRTM_BOOT = 2;
	public const uint32 TBS_TCGLOG_SRTM_RESUME = 3;
	public const uint32 TBS_TCGLOG_DRTM_BOOT = 4;
	public const uint32 TBS_TCGLOG_DRTM_RESUME = 5;
}
#endregion

#region Enums

[AllowDuplicates]
public enum TBS_COMMAND_PRIORITY : uint32
{
	TBS_COMMAND_PRIORITY_LOW = 100,
	TBS_COMMAND_PRIORITY_NORMAL = 200,
	TBS_COMMAND_PRIORITY_SYSTEM = 400,
	TBS_COMMAND_PRIORITY_HIGH = 300,
	TBS_COMMAND_PRIORITY_MAX = 2147483648,
}


[AllowDuplicates]
public enum TBS_COMMAND_LOCALITY : uint32
{
	TBS_COMMAND_LOCALITY_ZERO = 0,
	TBS_COMMAND_LOCALITY_ONE = 1,
	TBS_COMMAND_LOCALITY_TWO = 2,
	TBS_COMMAND_LOCALITY_THREE = 3,
	TBS_COMMAND_LOCALITY_FOUR = 4,
}

#endregion


#region Structs
[CRepr]
public struct TBS_CONTEXT_PARAMS
{
	public uint32 version;
}

[CRepr]
public struct TBS_CONTEXT_PARAMS2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 _bitfield;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 asUINT32;
	}
	public uint32 version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct TPM_WNF_PROVISIONING
{
	public uint32 status;
	public uint8[28] message;
}

[CRepr]
public struct TPM_DEVICE_INFO
{
	public uint32 structVersion;
	public uint32 tpmVersion;
	public uint32 tpmInterfaceType;
	public uint32 tpmImpRevision;
}

#endregion

#region Functions
public static
{
	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsi_Context_Create(TBS_CONTEXT_PARAMS* pContextParams, void** phContext);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsip_Context_Close(void* hContext);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsip_Submit_Command(void* hContext, TBS_COMMAND_LOCALITY Locality, TBS_COMMAND_PRIORITY Priority, uint8* pabCommand, uint32 cbCommand, uint8* pabResult, uint32* pcbResult);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsip_Cancel_Commands(void* hContext);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsi_Physical_Presence_Command(void* hContext, uint8* pabInput, uint32 cbInput, uint8* pabOutput, uint32* pcbOutput);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsi_Get_TCG_Log(void* hContext, uint8* pOutputBuf, uint32* pOutputBufLen);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsi_GetDeviceInfo(uint32 Size, void* Info);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsi_Get_OwnerAuth(void* hContext, uint32 ownerauthType, uint8* pOutputBuf, uint32* pOutputBufLen);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsi_Revoke_Attestation();

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetDeviceID(uint8* pbWindowsAIK, uint32 cbWindowsAIK, uint32* pcbResult, BOOL* pfProtectedByTPM);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetDeviceIDString(char16* pszWindowsAIK, uint32 cchWindowsAIK, uint32* pcchResult, BOOL* pfProtectedByTPM);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsi_Create_Windows_Key(uint32 keyHandle);

	[Import("tbs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Tbsi_Get_TCG_Log_Ex(uint32 logType, uint8* pbOutput, uint32* pcbOutput);

}
#endregion
