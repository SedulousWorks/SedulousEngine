using System;
using Sedulous.Core;
using Sedulous.Net;
using Sedulous.Net.Manager;

namespace Sedulous.Engine.GameInstance;

/// A run's networking to a script, reached as `Net`: whether it is a host or a client, the
/// role controls a game's menu calls (host, join, leave), and messages to the other side.
///
/// It holds the run's CONTROLLER, which outlives every endpoint it opens, so the facade never
/// dangles; each call reaches the live endpoint through it and does nothing offline. Ports
/// are whole numbers (0 to 65535); a message is an RPC by name, from a client to the host or
/// from the host to every client. The game instance installs one on its run.
[Scriptable, ServiceFacade("Net")]
class NetFacade
{
	/// BORROWED: the instance's controller, which outlives this.
	private NetworkController mController;

	public this(NetworkController controller)
	{
		mController = controller;
	}

	private NetworkManager Endpoint => (mController != null) ? mController.NetEndpoint : null;

	/// Hosting: this run is the server (a listen or a dedicated one).
	[Scriptable]
	public bool IsServer => (Endpoint != null) && Endpoint.Session.IsServer;
	/// Joined: this run is a client of a host.
	[Scriptable]
	public bool IsClient => (Endpoint != null) && Endpoint.Session.IsClient;
	/// The peers connected: a host's clients, or a client's host. Nought offline.
	[Scriptable]
	public int32 PeerCount => (Endpoint != null) ? (int32)Endpoint.Session.PeerCount : 0;
	/// The network's fixed step count, shared by every peer once a client has synced.
	[Scriptable]
	public double NetworkTick => (Endpoint != null) ? (double)Endpoint.Session.NetworkTick : 0.0;
	/// The network's clock in milliseconds, the host's on every peer once synced.
	[Scriptable]
	public double NetworkTimeMs => (Endpoint != null) ? Endpoint.Session.NetworkTimeMs : 0.0;

	/// Hosts on `port`, a listen server (this run plays too). False when the socket does not
	/// open; the game shows an error.
	[Scriptable]
	public bool StartServer(int32 port) => (mController != null) && mController.StartServer((uint16)port, false);
	/// Hosts on `port` without playing: a dedicated server.
	[Scriptable]
	public bool StartDedicatedServer(int32 port) => (mController != null) && mController.StartServer((uint16)port, true);
	/// Joins the host at `host`:`port`. False when the socket does not open; the handshake
	/// itself completes later.
	[Scriptable]
	public bool Connect(StringView host, int32 port) => (mController != null) && mController.Connect(host, (uint16)port);
	/// Leaves: the session and its socket close.
	[Scriptable]
	public void Disconnect()
	{
		if (mController != null)
			mController.StopNetworking();
	}

	/// Sends the message `name`: a client's goes to the host, a host's to every client.
	[Scriptable]
	public void Rpc(StringView name) => CallRpc(name, null);

	/// Sends the message `name` carrying a number.
	[Scriptable]
	public void RpcNumber(StringView name, double value) => CallRpc(name, scope (w) => w.WriteDouble(value));

	/// Sends the message `name` carrying a text.
	[Scriptable]
	public void RpcText(StringView name, StringView text) => CallRpc(name, scope (w) => WriteText(w, text));

	private static void WriteText(BitWriter w, StringView text)
	{
		w.WriteVarU32((uint32)text.Length);
		w.WriteBytes(.((uint8*)text.Ptr, text.Length));
	}

	private void CallRpc(StringView name, RpcTable.ArgumentWriter writeArgs)
	{
		let endpoint = Endpoint;
		if (endpoint == null)
			return;
		let session = endpoint.Session;
		if (session.IsClient)
			endpoint.Rpc.Call(session, session.ServerPeer, name, writeArgs);
		else if (session.IsServer)
			endpoint.Rpc.CallAll(session, name, writeArgs);
	}
}
