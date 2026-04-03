using Win32.Foundation;
using System;

namespace Win32.System.IO;
#region Function Pointers
public function void LPOVERLAPPED_COMPLETION_ROUTINE(uint32 dwErrorCode, uint32 dwNumberOfBytesTransfered, OVERLAPPED* lpOverlapped);

#endregion

#region Structs
[CRepr]
public struct OVERLAPPED
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 Offset;
			public uint32 OffsetHigh;
		}
		public using _Anonymous_e__Struct Anonymous;
		public void* Pointer;
	}
	public uint Internal;
	public uint InternalHigh;
	public using _Anonymous_e__Union Anonymous;
	public HANDLE hEvent;
}

[CRepr]
public struct OVERLAPPED_ENTRY
{
	public uint lpCompletionKey;
	public OVERLAPPED* lpOverlapped;
	public uint Internal;
	public uint32 dwNumberOfBytesTransferred;
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE CreateIoCompletionPort(HANDLE FileHandle, HANDLE ExistingCompletionPort, uint CompletionKey, uint32 NumberOfConcurrentThreads);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetQueuedCompletionStatus(HANDLE CompletionPort, uint32* lpNumberOfBytesTransferred, uint* lpCompletionKey, OVERLAPPED** lpOverlapped, uint32 dwMilliseconds);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetQueuedCompletionStatusEx(HANDLE CompletionPort, OVERLAPPED_ENTRY* lpCompletionPortEntries, uint32 ulCount, uint32* ulNumEntriesRemoved, uint32 dwMilliseconds, BOOL fAlertable);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PostQueuedCompletionStatus(HANDLE CompletionPort, uint32 dwNumberOfBytesTransferred, uint dwCompletionKey, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeviceIoControl(HANDLE hDevice, uint32 dwIoControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetOverlappedResult(HANDLE hFile, OVERLAPPED* lpOverlapped, uint32* lpNumberOfBytesTransferred, BOOL bWait);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CancelIoEx(HANDLE hFile, OVERLAPPED* lpOverlapped);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CancelIo(HANDLE hFile);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetOverlappedResultEx(HANDLE hFile, OVERLAPPED* lpOverlapped, uint32* lpNumberOfBytesTransferred, uint32 dwMilliseconds, BOOL bAlertable);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CancelSynchronousIo(HANDLE hThread);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BindIoCompletionCallback(HANDLE FileHandle, LPOVERLAPPED_COMPLETION_ROUTINE Function, uint32 Flags);

}
#endregion
