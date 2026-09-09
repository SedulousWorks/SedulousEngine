using System;
using Sedulous.Net;

namespace Sedulous.Net.Manager;

/// A started net home: the socket the manager borrows, and the manager itself.
///
/// Both are OWNED here and torn down in the right order, which is what the bundle is for. Both
/// are null for a run that never went online.
class NetworkRuntime
{
	/// The manager BORROWS this, so ordering matters; the destructor states it.
	private UdpSocket mSocket;
	private NetworkManager mManager;

	public ~this()
	{
		delete mManager;
		delete mSocket;
	}

	public UdpSocket Socket => mSocket;
	public NetworkManager Manager => mManager;
	public bool IsActive => mManager != null;

	/// Opens the socket, builds the manager, and enters the role.
	///
	/// Always returns a runtime; one started with role None is simply inactive, which is what
	/// single player is. A socket that fails to open leaves the runtime inactive too, and the
	/// caller logs it and runs offline.
	public static NetworkRuntime Start(NetworkStartup config)
	{
		let runtime = new NetworkRuntime();
		if (config.Role == .None)
			return runtime;

		// A server binds its listen port; a client binds ephemeral unless one is forced.
		runtime.mSocket = new UdpSocket(config.ListenPort);
		if (!runtime.mSocket.IsOpen)
		{
			delete runtime.mSocket;
			runtime.mSocket = null;
			return runtime;
		}

		runtime.mManager = new NetworkManager(runtime.mSocket, config.Reliable);
		if (config.Role == .Server)
			runtime.mManager.StartServer(config.Dedicated);
		else
			runtime.mManager.ConnectTo(NetAddress.ResolveEndpoint(config.ServerHost, config.ServerPort));
		return runtime;
	}
}
