using System;
using Sedulous.Core;
using Sedulous.Net;
using Sedulous.Net.Replication;
using Sedulous.Net.WebSocket;
using Sedulous.Profiler;
using Sedulous.Scene;

namespace Sedulous.Net.Manager;

/// A networked ENDPOINT: a live session and RPC table over a datagram socket, driven each
/// fixed step, with the replication of one scene attached.
///
/// Owned per running game rather than per application. There is no once per context
/// networking state, so an endpoint lives with the instance that runs it: N instances hold N
/// independent endpoints.
///
/// No script service here: a Net facade, its binding and a network controller interface
/// would only exist to reach this from a script, and that surface has not been asked for.
class NetworkManager
{
	/// Reserved for replication deltas, alongside NetSession.ControlChannel at 255 and
	/// RpcTable.RpcChannel at 254.
	public const uint8 ReplicationChannel = 253;

	/// Null when the socket is borrowed, which is the sim and test path.
	private IDatagramSocket mOwnedSocket;
	private NetSession mSession;
	private RpcTable mRpc = new .();
	private StateReplication mReplication = new .();
	/// Client side smoothing of received states.
	private InterpolationBuffer mInterpolation = new .();
	/// BORROWED. Null means no replication; the session and RPC still run.
	private Scene mScene;
	private uint16 mBoundPort = 0;
	private uint16 mWebSocketPort = 0;
	private double mInterpolationDelayMs = 100.0;

	/// Sim and test: BORROWS an external socket, which must outlive this. The session is live
	/// immediately.
	public this(IDatagramSocket socket, ReliableConfig config = .())
	{
		mSession = new .(socket, config);
	}

	/// OWNS the socket. Used by the factories; a bare game never calls this.
	private this(IDatagramSocket ownedSocket, uint16 boundPort, uint16 webSocketPort,
		ReliableConfig config)
	{
		mOwnedSocket = ownedSocket;
		mBoundPort = boundPort;
		mWebSocketPort = webSocketPort;
		mSession = new .(ownedSocket, config);
	}

	public ~this()
	{
		// Explicit, and in this order: the session BORROWS the socket, so freeing an owned
		// socket while the session still lives is a use after free. Field declaration order is
		// too quiet a thing to rest that on.
		delete mSession;
		delete mInterpolation;
		delete mReplication;
		delete mRpc;
		delete mOwnedSocket;
	}

	/// Whether THIS build can host a session at all. A browser cannot listen on any socket, so
	/// the web build's host paths refuse cleanly rather than hanging.
	public static bool CanHost
	{
		get
		{
#if BF_PLATFORM_WASM
			return false;
#else
			return true;
#endif
		}
	}

	/// Opens a real UDP socket and starts serving. Null when the socket cannot open, which the
	/// caller logs before running offline.
	///
	/// A non zero webSocketPort ALSO accepts browser clients, so native and browser peers share
	/// one session behind one datagram socket.
	public static NetworkManager HostServer(uint16 port, bool dedicated = false,
		ReliableConfig config = .(), uint16 webSocketPort = 0)
	{
		if (!CanHost)
			return null;

		if (webSocketPort != 0)
		{
			let hybrid = new WebSocketHybridSocket(port, webSocketPort);
			if (!hybrid.IsOpen)
			{
				delete hybrid;
				return null;
			}
			let manager = new NetworkManager(hybrid, hybrid.BoundPort, hybrid.WebSocketBoundPort,
				config);
			manager.StartServer(dedicated);
			return manager;
		}

		let socket = new UdpSocket(port);
		if (!socket.IsOpen)
		{
			delete socket;
			return null;
		}
		let manager = new NetworkManager(socket, socket.BoundPort, 0, config);
		manager.StartServer(dedicated);
		return manager;
	}

	/// Connects to host:port. Null when the socket cannot open.
	///
	/// A browser has no UDP, so the web build joins over a WEBSOCKET to the host's gateway,
	/// and `port` there is the gateway's port rather than the UDP one. NetworkController does
	/// that translation, so the same game script joins with the same number everywhere.
	///
	/// Nothing waits for the handshake. The browser socket queues sends until it opens, which
	/// is what keeps the session's immediate connect packet from being dropped into it.
	public static NetworkManager JoinServer(StringView host, uint16 port,
		ReliableConfig config = .())
	{
#if BF_PLATFORM_WASM
		let socket = new WebSocketClientSocket(host, port);
		if (!socket.IsOpen)
		{
			delete socket;
			return null;
		}
		let manager = new NetworkManager(socket, 0, port, config);
		manager.ConnectTo(WebSocketClientSocket.ServerEndpoint);
		return manager;
#else
		let socket = new UdpSocket(0);
		if (!socket.IsOpen)
		{
			delete socket;
			return null;
		}
		let manager = new NetworkManager(socket, socket.BoundPort, 0, config);
		manager.ConnectTo(NetAddress.ResolveEndpoint(host, port));
		return manager;
#endif
	}

	/// The port this endpoint's OWNED socket is bound to; nought when the socket is borrowed.
	/// A host opened on port nought reports its assigned port here, so a client can reach it.
	public uint16 BoundPort => mBoundPort;
	/// The web socket gateway's port. Nought means this endpoint accepts no browser clients.
	public uint16 WebSocketBoundPort => mWebSocketPort;

	public NetSession Session => mSession;
	public RpcTable Rpc => mRpc;
	public StateReplication Replication => mReplication;

	/// How far behind synced network time a client renders. About twice the server's send
	/// interval hides one lost or late update.
	public void SetInterpolationDelayMs(double milliseconds) =>
		mInterpolationDelayMs = milliseconds;

	public void StartServer(bool dedicated = false) => mSession.StartServer(dedicated);
	public PeerId ConnectTo(DatagramEndpoint server) => mSession.Connect(server);

	/// The scene this endpoint replicates. Null turns replication off.
	///
	/// On a SERVER the scene's authored networked entities are assigned NetworkIds here, so a
	/// designer marks an entity networked and it just replicates on host. On a client the same
	/// ids are DERIVED rather than received, so incoming state lands on the client's own
	/// authored entity instead of minting a duplicate beside it.
	public void SetReplicatedScene(Scene scene)
	{
		mScene = scene;
		if (scene == null)
			return;

		if (mSession.IsServer)
			mReplication.AssignSceneNetworkIds(scene);
		else
			mReplication.RegisterAuthoredEntities(scene);
	}

	/// The TRANSPORT half, driven per frame: pump the session and route what arrives by
	/// reserved channel. Nothing is captured or sent here; that is the replication half.
	///
	/// Pumped regardless of scene time, so connections stay alive while a scene is paused.
	public void UpdateTransport(float deltaMs, delegate void(NetEvent) onEvent = null)
	{
		using (ProfileScope("Net.Transport"))
		{
			mSession.Update(deltaMs);

			// One event, refilled: the same shape RpcTable.Pump uses.
			let event = scope NetEvent();
			while (mSession.PollEvent(event))
			{
				if ((event.Kind == .Received) && (event.Channel == RpcTable.RpcChannel))
				{
					mRpc.Dispatch(event.Peer, event.Payload);
					continue;
				}

				if ((event.Kind == .Received) && (event.Channel == ReplicationChannel))
				{
					if (mScene == null)
						continue;

					// The packet is the server's capture time, for interpolation, then the
					// delta. Allocated rather than scoped because this is a loop on a per
					// frame path.
					let reader = new BitReader(event.Payload);
					var bits = reader.ReadU64();
					let serverTimeMs = *(double*)&bits;
					mReplication.ApplyDelta(mScene, reader, mInterpolation, serverTimeMs);
					delete reader;
					continue;
				}

				if (event.Kind == .Disconnected)
					mReplication.ForgetPeer(event.Peer);
				if (onEvent != null)
					onEvent(event);
			}
		}
	}

	/// The REPLICATION half, driven on the scene's fixed lane: a server captures the scene's
	/// networked state and pushes a per peer delta; a client samples its buffered
	/// interpolation into the scene.
	///
	/// Gated on the fixed lane, so a paused or slowed scene replicates at its scaled rate and a
	/// paused simulation produces no deltas at all. Touches no socket: transport keeps that.
	public void UpdateReplication()
	{
		using (ProfileScope("Net.Replication"))
		{
			if (mSession.IsServer && (mScene != null))
			{
				// Pull each entity's authoritative LOCAL transform into its NetworkedTransform,
				// so the capture below sends the current pose.
				ReplicationScene.CaptureEntityTransforms(mScene);

				var now = mSession.NetworkTimeMs;
				let bits = *(uint64*)&now;
				for (let peer in mSession.Peers)
				{
					let writer = new BitWriter();
					// The server's capture time rides AHEAD of the delta.
					writer.WriteU64(bits);
					if (mReplication.CaptureDelta(mScene, peer.Id, writer) > 0)
						mSession.Send(peer.Id, ReplicationChannel, writer.Data, .ReliableOrdered);
					delete writer;
				}
			}

			if (mSession.IsClient && (mScene != null))
			{
				// Render each interpolatable component at synced network time minus the delay,
				// playing the buffered states back smoothly between low rate updates, then push
				// the result onto the entities' local transforms.
				mReplication.SampleInterpolation(mScene, mInterpolation,
					mSession.NetworkTimeMs - mInterpolationDelayMs);
				ReplicationScene.ApplyEntityTransforms(mScene);
			}
		}
	}

	/// Both halves together, transport then replication. For tests and any single lane
	/// consumer; production drives the two on their own lanes.
	public void Update(float deltaMs, delegate void(NetEvent) onEvent = null)
	{
		UpdateTransport(deltaMs, onEvent);
		UpdateReplication();
	}
}
