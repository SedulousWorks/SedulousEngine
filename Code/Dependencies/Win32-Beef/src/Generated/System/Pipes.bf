using Win32.Foundation;
using Win32.Security;
using Win32.System.IO;
using Win32.Storage.FileSystem;
using System;

namespace Win32.System.Pipes;

#region Constants
public static
{
	public const uint32 PIPE_UNLIMITED_INSTANCES = 255;
	public const uint32 NMPWAIT_WAIT_FOREVER = 4294967295;
	public const uint32 NMPWAIT_NOWAIT = 1;
	public const uint32 NMPWAIT_USE_DEFAULT_WAIT = 0;
}
#endregion

#region Enums

[AllowDuplicates]
public enum NAMED_PIPE_MODE : uint32
{
	PIPE_WAIT = 0,
	PIPE_NOWAIT = 1,
	PIPE_READMODE_BYTE = 0,
	PIPE_READMODE_MESSAGE = 2,
	PIPE_CLIENT_END = 0,
	PIPE_SERVER_END = 1,
	PIPE_TYPE_BYTE = 0,
	PIPE_TYPE_MESSAGE = 4,
	PIPE_ACCEPT_REMOTE_CLIENTS = 0,
	PIPE_REJECT_REMOTE_CLIENTS = 8,
}

#endregion


#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreatePipe(HANDLE* hReadPipe, HANDLE* hWritePipe, SECURITY_ATTRIBUTES* lpPipeAttributes, uint32 nSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConnectNamedPipe(HANDLE hNamedPipe, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DisconnectNamedPipe(HANDLE hNamedPipe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetNamedPipeHandleState(HANDLE hNamedPipe, NAMED_PIPE_MODE* lpMode, uint32* lpMaxCollectionCount, uint32* lpCollectDataTimeout);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PeekNamedPipe(HANDLE hNamedPipe, void* lpBuffer, uint32 nBufferSize, uint32* lpBytesRead, uint32* lpTotalBytesAvail, uint32* lpBytesLeftThisMessage);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TransactNamedPipe(HANDLE hNamedPipe, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesRead, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateNamedPipeW(PWSTR lpName, FILE_FLAGS_AND_ATTRIBUTES dwOpenMode, NAMED_PIPE_MODE dwPipeMode, uint32 nMaxInstances, uint32 nOutBufferSize, uint32 nInBufferSize, uint32 nDefaultTimeOut, SECURITY_ATTRIBUTES* lpSecurityAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WaitNamedPipeW(PWSTR lpNamedPipeName, uint32 nTimeOut);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNamedPipeClientComputerNameW(HANDLE Pipe, PWSTR ClientComputerName, uint32 ClientComputerNameLength);

	[Import("ADVAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImpersonateNamedPipeClient(HANDLE hNamedPipe);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNamedPipeInfo(HANDLE hNamedPipe, NAMED_PIPE_MODE* lpFlags, uint32* lpOutBufferSize, uint32* lpInBufferSize, uint32* lpMaxInstances);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNamedPipeHandleStateW(HANDLE hNamedPipe, NAMED_PIPE_MODE* lpState, uint32* lpCurInstances, uint32* lpMaxCollectionCount, uint32* lpCollectDataTimeout, char16* lpUserName, uint32 nMaxUserNameSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CallNamedPipeW(PWSTR lpNamedPipeName, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesRead, uint32 nTimeOut);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateNamedPipeA(PSTR lpName, FILE_FLAGS_AND_ATTRIBUTES dwOpenMode, NAMED_PIPE_MODE dwPipeMode, uint32 nMaxInstances, uint32 nOutBufferSize, uint32 nInBufferSize, uint32 nDefaultTimeOut, SECURITY_ATTRIBUTES* lpSecurityAttributes);
	public static HANDLE CreateNamedPipe(PSTR lpName, FILE_FLAGS_AND_ATTRIBUTES dwOpenMode, NAMED_PIPE_MODE dwPipeMode, uint32 nMaxInstances, uint32 nOutBufferSize, uint32 nInBufferSize, uint32 nDefaultTimeOut, SECURITY_ATTRIBUTES* lpSecurityAttributes) => CreateNamedPipeA(lpName, dwOpenMode, dwPipeMode, nMaxInstances, nOutBufferSize, nInBufferSize, nDefaultTimeOut, lpSecurityAttributes);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNamedPipeHandleStateA(HANDLE hNamedPipe, NAMED_PIPE_MODE* lpState, uint32* lpCurInstances, uint32* lpMaxCollectionCount, uint32* lpCollectDataTimeout, uint8* lpUserName, uint32 nMaxUserNameSize);
	public static BOOL GetNamedPipeHandleState(HANDLE hNamedPipe, NAMED_PIPE_MODE* lpState, uint32* lpCurInstances, uint32* lpMaxCollectionCount, uint32* lpCollectDataTimeout, uint8* lpUserName, uint32 nMaxUserNameSize) => GetNamedPipeHandleStateA(hNamedPipe, lpState, lpCurInstances, lpMaxCollectionCount, lpCollectDataTimeout, lpUserName, nMaxUserNameSize);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CallNamedPipeA(PSTR lpNamedPipeName, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesRead, uint32 nTimeOut);
	public static BOOL CallNamedPipe(PSTR lpNamedPipeName, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesRead, uint32 nTimeOut) => CallNamedPipeA(lpNamedPipeName, lpInBuffer, nInBufferSize, lpOutBuffer, nOutBufferSize, lpBytesRead, nTimeOut);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WaitNamedPipeA(PSTR lpNamedPipeName, uint32 nTimeOut);
	public static BOOL WaitNamedPipe(PSTR lpNamedPipeName, uint32 nTimeOut) => WaitNamedPipeA(lpNamedPipeName, nTimeOut);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNamedPipeClientComputerNameA(HANDLE Pipe, PSTR ClientComputerName, uint32 ClientComputerNameLength);
	public static BOOL GetNamedPipeClientComputerName(HANDLE Pipe, PSTR ClientComputerName, uint32 ClientComputerNameLength) => GetNamedPipeClientComputerNameA(Pipe, ClientComputerName, ClientComputerNameLength);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNamedPipeClientProcessId(HANDLE Pipe, uint32* ClientProcessId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNamedPipeClientSessionId(HANDLE Pipe, uint32* ClientSessionId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNamedPipeServerProcessId(HANDLE Pipe, uint32* ServerProcessId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNamedPipeServerSessionId(HANDLE Pipe, uint32* ServerSessionId);

}
#endregion
