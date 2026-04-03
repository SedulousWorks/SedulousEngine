namespace Sedulous.Net;

using System;
using System.Net;

/// Ensures Socket.Init() is called once (WSAStartup on Windows, no-op elsewhere).
/// Also provides getsockname for querying actual bound port.
static class SocketInit
{
	private static bool sInitialized = false;

#if BF_PLATFORM_WINDOWS
	[Import("Ws2_32.lib"), CLink, CallingConvention(.Stdcall)]
	private static extern int32 getsockname(Socket.HSocket s, Socket.SockAddr* name, int32* namelen);
#else
	[CLink, CallingConvention(.Stdcall)]
	private static extern int32 getsockname(Socket.HSocket s, Socket.SockAddr* name, int32* namelen);
#endif

	public static void EnsureInitialized()
	{
		if (!sInitialized)
		{
			Socket.Init();
			sInitialized = true;
		}
	}

	/// Query the actual local endpoint of a bound socket.
	/// Essential for port 0 (OS-assigned port) scenarios.
	public static Result<IPEndPoint> GetLocalEndPoint(Socket.HSocket handle)
	{
		Socket.SockAddr_in addr = default;
		int32 addrLen = sizeof(Socket.SockAddr_in);
		if (getsockname(handle, &addr, &addrLen) == Socket.SOCKET_ERROR)
			return .Err;

		return .Ok(IPEndPoint.FromSockAddr(addr));
	}
}
