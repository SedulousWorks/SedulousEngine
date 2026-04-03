using System;

namespace Win32.System.Memory.NonVolatile;

#region Structs
[CRepr]
public struct NV_MEMORY_RANGE
{
	public void* BaseAddress;
	public uint Length;
}

#endregion

#region Functions
public static
{
#if BF_64_BIT || BF_ARM_64
	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlGetNonVolatileToken(void* NvBuffer, uint Size, void** NvToken);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlFreeNonVolatileToken(void* NvToken);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlFlushNonVolatileMemory(void* NvToken, void* NvBuffer, uint Size, uint32 Flags);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlDrainNonVolatileFlush(void* NvToken);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlWriteNonVolatileMemory(void* NvToken, void* NvDestination, void* Source, uint Size, uint32 Flags);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlFillNonVolatileMemory(void* NvToken, void* NvDestination, uint Size, uint8 Value, uint32 Flags);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlFlushNonVolatileMemoryRanges(void* NvToken, NV_MEMORY_RANGE* NvRanges, uint NumRanges, uint32 Flags);

#endif
}
#endregion
