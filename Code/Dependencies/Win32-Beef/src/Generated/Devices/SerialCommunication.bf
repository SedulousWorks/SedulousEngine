using Win32.Foundation;
using System;

namespace Win32.Devices.SerialCommunication;

#region Constants
public static
{
	public const uint32 COMDB_MIN_PORTS_ARBITRATED = 256;
	public const uint32 COMDB_MAX_PORTS_ARBITRATED = 4096;
	public const uint32 CDB_REPORT_BITS = 0;
	public const uint32 CDB_REPORT_BYTES = 1;
}
#endregion

#region TypeDefs
typealias HCOMDB = int;

#endregion


#region Functions
public static
{
	[Import("MSPORTS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ComDBOpen(int* PHComDB);

	[Import("MSPORTS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ComDBClose(HCOMDB HComDB);

	[Import("MSPORTS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ComDBGetCurrentPortUsage(HCOMDB HComDB, uint8* Buffer, uint32 BufferSize, uint32 ReportType, uint32* MaxPortsReported);

	[Import("MSPORTS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ComDBClaimNextFreePort(HCOMDB HComDB, uint32* ComNumber);

	[Import("MSPORTS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ComDBClaimPort(HCOMDB HComDB, uint32 ComNumber, BOOL ForceClaim, BOOL* Forced);

	[Import("MSPORTS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ComDBReleasePort(HCOMDB HComDB, uint32 ComNumber);

	[Import("MSPORTS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ComDBResizeDatabase(HCOMDB HComDB, uint32 NewSize);

}
#endregion
