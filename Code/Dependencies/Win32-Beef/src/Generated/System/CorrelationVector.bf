using Win32.Foundation;
using System;

namespace Win32.System.CorrelationVector;

#region Constants
public static
{
	public const uint32 RTL_CORRELATION_VECTOR_STRING_LENGTH = 129;
	public const uint32 RTL_CORRELATION_VECTOR_V1_PREFIX_LENGTH = 16;
	public const uint32 RTL_CORRELATION_VECTOR_V1_LENGTH = 64;
	public const uint32 RTL_CORRELATION_VECTOR_V2_PREFIX_LENGTH = 22;
	public const uint32 RTL_CORRELATION_VECTOR_V2_LENGTH = 128;
}
#endregion

#region Structs
[CRepr]
public struct CORRELATION_VECTOR
{
	public CHAR Version;
	public CHAR[129] Vector;
}

#endregion

#region Functions
public static
{
	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlInitializeCorrelationVector(CORRELATION_VECTOR* CorrelationVector, int32 Version, Guid* Guid);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlIncrementCorrelationVector(CORRELATION_VECTOR* CorrelationVector);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlExtendCorrelationVector(CORRELATION_VECTOR* CorrelationVector);

	[Import("ntdll.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtlValidateCorrelationVector(CORRELATION_VECTOR* Vector);

}
#endregion
