using System;
using System.Net;

namespace Sedulous.Net;

/// Keeps a socket out of the processes this one starts.
///
/// corlib opens sockets inheritable, so every child a process starts (a build, a tool, a
/// relaunched editor) gets a copy of each one. A child that inherits a listening socket holds
/// its port without ever accepting on it: an editor relaunching itself found its own port
/// taken by the copy it had been handed, and nothing answered there. Each socket this module
/// opens or accepts is marked close-on-exec (not inherited, on Windows) as soon as it exists.
static class SocketInheritance
{
	/// Marks `socket` so no child process inherits it. Nothing for a socket that is not open.
	public static void KeepFromChildren(Socket socket)
	{
		if (!socket.IsOpen)
			return;
#if BF_PLATFORM_WINDOWS
		SetHandleInformation((void*)(int)socket.NativeSocket, cHandleFlagInherit, 0);
#else
		fcntl((int32)socket.NativeSocket, cSetDescriptorFlags, cCloseOnExec);
#endif
	}

	/// Whether `socket` is kept from child processes (false for one that is not open).
	public static bool IsKeptFromChildren(Socket socket)
	{
		if (!socket.IsOpen)
			return false;
#if BF_PLATFORM_WINDOWS
		uint32 flags = 0;
		return (GetHandleInformation((void*)(int)socket.NativeSocket, &flags) != 0) && ((flags & cHandleFlagInherit) == 0);
#else
		let flags = fcntl((int32)socket.NativeSocket, cGetDescriptorFlags, 0);
		return (flags >= 0) && ((flags & cCloseOnExec) != 0);
#endif
	}

#if BF_PLATFORM_WINDOWS
	private const uint32 cHandleFlagInherit = 1;

	[CLink, CallingConvention(.Stdcall)]
	private static extern int32 GetHandleInformation(void* handle, uint32* outFlags);

	[CLink, CallingConvention(.Stdcall)]
	private static extern int32 SetHandleInformation(void* handle, uint32 mask, uint32 flags);
#else
	/// F_GETFD, F_SETFD and FD_CLOEXEC, the same on Linux and macOS.
	private const int32 cGetDescriptorFlags = 1;
	private const int32 cSetDescriptorFlags = 2;
	private const int32 cCloseOnExec = 1;

	[CLink]
	private static extern int32 fcntl(int32 descriptor, int32 command, int32 argument);
#endif
}
