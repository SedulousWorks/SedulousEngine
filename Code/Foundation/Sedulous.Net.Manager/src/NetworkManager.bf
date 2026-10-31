using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Net;
using Sedulous.Net.Replication;
using Sedulous.Net.Tls;
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
/// Scripts reach it as `Net` (Engine.GameInstance's NetFacade), through the run's network
/// controller, which outlives every endpoint it opens.
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
		// Closing an endpoint (a game leaving, a host stopping) tells every peer, so a host frees
		// a leaver's seat at once and a client sees its host go, instead of each waiting out the
		// transport's timeout. The socket is still open here: an owned one goes after the
		// session, and a borrowed one outlives the manager.
		mSession.DisconnectAll();

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
	/// one session behind one datagram socket; with webSocketTls, over wss:// instead of ws://.
	public static NetworkManager HostServer(uint16 port, bool dedicated = false,
		ReliableConfig config = .(), uint16 webSocketPort = 0, WebSocketTls webSocketTls = null)
	{
		if (!CanHost)
			return null;

		if (webSocketPort != 0)
		{
			let hybrid = new WebSocketHybridSocket(port, webSocketPort, webSocketTls);
			if (!hybrid.IsOpen)
			{
				if (!hybrid.Gateway.Failure.IsEmpty)
					GlobalLog(.Error, "Net: the wss gateway did not open: {}", hybrid.Gateway.Failure);
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
	/// `host` may be an address with a scheme: "ws://host[:port][/path]" or "wss://..." joins
	/// the host's WebSocket gateway (`port` when the address names none), natively too, wss
	/// through `tls` (BORROWED, outliving the manager) checked against `trust` (Roots:
	/// `trustedPem` alone). A bare host joins over UDP natively. A browser has no UDP, so the
	/// web build joins a bare host over a WEBSOCKET to the host's gateway, wss when the page is
	/// https (a browser refuses ws:// from an https page), and `port` there is the gateway's
	/// port rather than the UDP one. NetworkController does that translation, so the same game
	/// script joins with the same number everywhere.
	///
	/// Nothing waits for the handshake. The websocket queues sends until it upgrades, which is
	/// what keeps the session's immediate connect packet from being dropped into it.
	public static NetworkManager JoinServer(StringView host, uint16 port,
		ReliableConfig config = .(), ITlsBackend tls = null, TlsTrust trust = .System, StringView trustedPem = default)
	{
		let webSocket = scope WebSocketClientConfig();
		let addressed = webSocket.ParseAddress(host, port);
#if BF_PLATFORM_WASM
		if (!addressed)
		{
			webSocket.Host.Set(host);
			webSocket.Port = port;
			webSocket.Secure = emscripten_run_script_int("location.protocol === 'https:' ? 1 : 0") != 0;
		}
		return JoinWebSocket(webSocket, config);
#else
		if (addressed)
		{
			webSocket.Tls = tls;
			webSocket.Trust = trust;
			webSocket.TrustedPem.Set(trustedPem);
			return JoinWebSocket(webSocket, config);
		}
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

	/// Joins a host's gateway over a websocket. A join that cannot start says why in the log.
	private static NetworkManager JoinWebSocket(WebSocketClientConfig webSocket, ReliableConfig config)
	{
		let socket = new WebSocketClientSocket(webSocket);
		if (!socket.IsOpen)
		{
			GlobalLog(.Error, "Net: could not join {}: {}", webSocket.Host, socket.Failure);
			delete socket;
			return null;
		}
		let manager = new NetworkManager(socket, 0, webSocket.Port, config);
		manager.ConnectTo(WebSocketClientSocket.ServerEndpoint);
		return manager;
	}

#if BF_PLATFORM_WASM
	[CLink, CallingConvention(.Cdecl)]
	private static extern int32 emscripten_run_script_int(char8* script);
#endif

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
	/// Players joining and leaving, by player id (nought the host, else a client's PeerId on
	/// the server).
	public typealias PlayerEvents = delegate void(bool joined, uint32 player);

	private PlayerEvents mPlayerEvents = null ~ delete _;
	/// Client: the welcome has been reported.
	private bool mWelcomed = false;
	/// Host: joiners wait for their ready before any state.
	private bool mWaitForReady = false;
	/// Host: joined, not yet ready.
	private HashSet<PeerId> mHeld = new .() ~ delete _;

	/// Who hears players join and leave. On the host: a client joined or left. On a client:
	/// it joined itself (its own id, once the server welcomed it), or the host left (nought).
	/// TAKES OWNERSHIP; null stops it.
	public void SetPlayerEvents(PlayerEvents handler)
	{
		delete mPlayerEvents;
		mPlayerEvents = handler;
	}

	/// The player a session event is about, to the player events (see SetPlayerEvents).
	private void ReportPlayer(NetEvent event)
	{
		if (mPlayerEvents == null)
			return;
		if (mSession.IsServer && (event.Kind == .Connected))
			mPlayerEvents(true, event.Peer);
		else if (mSession.IsServer && (event.Kind == .Disconnected))
			mPlayerEvents(false, event.Peer);
		else if (mSession.IsClient && (event.Kind == .Disconnected))
			mPlayerEvents(false, 0); // the host went
	}

	/// Host: whether a client that joins waits for its ready (SendReady) before it hears any
	/// state: a game whose joiner loads the host's map after connecting holds the state off until
	/// the map's networked entities are there to take it. Off by default (state flows at once).
	/// RPCs are never held: the host's welcome (naming its map, say) reaches a held joiner.
	public bool WaitsForReady => mWaitForReady;
	public void SetWaitForReady(bool wait) => mWaitForReady = wait;

	/// Host: whether a client is held (joined, not yet ready).
	public bool IsHeld(PeerId peer) => mHeld.Contains(peer);

	/// Client: tells the host this end is ready for state (its scene loaded). The host forgets
	/// what it last sent it, so the state starts from a full snapshot. Harmless to a host that
	/// does not wait (its baseline restarts: one full snapshot more).
	public void SendReady()
	{
		if (!mSession.IsClient)
			return;
		var ready = (uint8)1;
		for (let peer in mSession.Peers)
			mSession.Send(peer.Id, ReplicationChannel, .(&ready, 1), .ReliableOrdered);
	}

	/// A held client said it is ready: its baseline goes, so its first delta is everything.
	private void ReleasePeer(PeerId peer)
	{
		mHeld.Remove(peer);
		mReplication.ForgetPeer(peer);
	}

	/// The scene this endpoint replicates; null is none.
	public Scene ReplicatedScene => mScene;

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

				if ((event.Kind == .Received) && (event.Channel == ReplicationChannel) && mSession.IsServer)
				{
					// The one message a client sends on this channel: it is ready (its scene is
					// the host's, loaded). Its state starts now, from a full snapshot.
					ReleasePeer(event.Peer);
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
				{
					mReplication.ForgetPeer(event.Peer);
					mHeld.Remove(event.Peer);
				}
				else if ((event.Kind == .Connected) && mSession.IsServer && mWaitForReady)
					mHeld.Add(event.Peer); // no state until it says it is ready
				if ((event.Kind == .Connected) || (event.Kind == .Disconnected))
					ReportPlayer(event);
				if (onEvent != null)
					onEvent(event);
			}

			// A client has joined once the server has said who it is (the session's welcome).
			if (mSession.IsClient && !mWelcomed && (mSession.LocalPeer != InvalidPeer))
			{
				mWelcomed = true;
				if (mPlayerEvents != null)
					mPlayerEvents(true, mSession.LocalPeer);
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
					if (mHeld.Contains(peer.Id))
						continue; // joined, not ready: its scene is not the host's yet
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
