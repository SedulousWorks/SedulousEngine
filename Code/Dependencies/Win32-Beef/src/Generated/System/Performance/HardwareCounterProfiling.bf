using Win32.Foundation;
using System;

namespace Win32.System.Performance.HardwareCounterProfiling;

#region Enums

[AllowDuplicates]
public enum HARDWARE_COUNTER_TYPE : int32
{
	PMCCounter = 0,
	MaxHardwareCounterType = 1,
}

#endregion


#region Structs
[CRepr]
public struct HARDWARE_COUNTER_DATA
{
	public HARDWARE_COUNTER_TYPE Type;
	public uint32 Reserved;
	public uint64 Value;
}

[CRepr]
public struct PERFORMANCE_DATA
{
	public uint16 Size;
	public uint8 Version;
	public uint8 HwCountersCount;
	public uint32 ContextSwitchCount;
	public uint64 WaitReasonBitMap;
	public uint64 CycleTime;
	public uint32 RetryCount;
	public uint32 Reserved;
	public HARDWARE_COUNTER_DATA[16] HwCounters;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EnableThreadProfiling(HANDLE ThreadHandle, uint32 Flags, uint64 HardwareCounters, HANDLE* PerformanceDataHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DisableThreadProfiling(HANDLE PerformanceDataHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 QueryThreadProfiling(HANDLE ThreadHandle, BOOLEAN* Enabled);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ReadThreadProfilingData(HANDLE PerformanceDataHandle, uint32 Flags, PERFORMANCE_DATA* PerformanceData);

}
#endregion
