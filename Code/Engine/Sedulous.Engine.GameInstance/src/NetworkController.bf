using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Engine.Net;
using Sedulous.Net.Manager;
using Sedulous.Net.Replication;
using Sedulous.Scene;

namespace Sedulous.Engine.GameInstance;

/// A running game's networking, held OFF the instance rather than inherited by it.
///
/// It owns the endpoint, the role lifecycle, and which scene is replicated. The controller
/// outlives every endpoint it opens, so anything holding the controller never dangles; the
/// endpoint inside it comes and goes.
class NetworkController
{
	/// Makes a fresh spawn resolver for EVERY endpoint the controller opens, so a reconnect
	/// keeps it.
	///
	/// A factory rather than a resolver because the handler is owned by the endpoint it is
	/// installed on: the controller has to produce one per endpoint rather than hand the same
	/// one round.
	public typealias SpawnResolverFactory = delegate StateReplication.SpawnHandler();

	/// OWNED: this run's endpoint. Null is offline.
	private NetworkManager mNet = null ~ delete _;
	private SpawnResolverFactory mSpawnResolverFactory = null ~ delete _;
	/// BORROWED: the scene a fresh endpoint replicates.
	private Scene mScene = null;

	/// The scene this run replicates.
	///
	/// Cached, so opening an endpoint can set it straight away, and applied live when one
	/// already exists. EDGE DRIVEN: the old scene's network system is detached and the new
	/// one attached, so only the replicated scene's fixed lane ever drives this endpoint.
	public void SetReplicatedScene(Scene scene)
	{
		// Unchanged, so both the endpoint and the scene system are already wired correctly.
		if (scene === mScene)
			return;

		// Detach the OLD scene's system, which reads the current field.
		WireSceneSystem(null);
		mScene = scene;

		if (mNet != null)
			mNet.SetReplicatedScene(scene);

		// And attach the NEW one's, to the live endpoint or to nothing.
		WireSceneSystem(mNet);
	}

	/// Injects the prefab spawn resolver factory, which is the app's to supply: it needs the
	/// content database. TAKES OWNERSHIP of the delegate.
	public void SetSpawnResolverFactory(SpawnResolverFactory factory)
	{
		delete mSpawnResolverFactory;
		mSpawnResolverFactory = factory;
	}

	/// This run's endpoint, or null offline.
	public NetworkManager NetEndpoint => mNet;

	/// Opens a listening socket and takes the server role.
	///
	/// A fixed port host ALSO opens the browser gateway one port up by convention, so a web
	/// client joins without the game script knowing which platform it is on. A host on an
	/// operating system assigned port, which a test is, stays plain.
	public bool StartServer(uint16 port, bool dedicated)
	{
		let webSocketPort = ((port != 0) && (port != 0xFFFF)) ? (uint16)(port + 1) : (uint16)0;

		delete mNet;
		mNet = NetworkManager.HostServer(port, dedicated, .(), webSocketPort);
		if (mNet == null)
		{
			GlobalLog(.Error, "NetworkController: failed to open a server socket on port {}", port);
			return false;
		}

		mNet.SetReplicatedScene(mScene);
		// The replicated scene's fixed lane now drives this endpoint.
		WireSceneSystem(mNet);

		if (mSpawnResolverFactory != null)
			mNet.Replication.SetSpawnHandler(mSpawnResolverFactory());

		if (mNet.WebSocketBoundPort != 0)
			GlobalLog(.Information,
				"NetworkController: server listening on port {}, browser gateway ws://:{}",
				mNet.BoundPort, mNet.WebSocketBoundPort);
		else
			GlobalLog(.Information, "NetworkController: server listening on port {}", mNet.BoundPort);

		return true;
	}

	/// Opens a client socket and connects.
	public bool Connect(StringView host, uint16 port)
	{
		var port;
#if BF_PLATFORM_WASM
		// The SAME game script joins with the UDP port on every platform. A browser cannot
		// speak UDP, so the web build redirects to the host's websocket gateway, which
		// StartServer opens one above the UDP port by the convention above. Nought and
		// 0xFFFF are left alone: an operating system assigned host has no gateway to redirect
		// to, and 0xFFFF has nowhere above it to go.
		if ((port != 0) && (port != 0xFFFF))
			port = (uint16)(port + 1);
#endif

		delete mNet;
		mNet = NetworkManager.JoinServer(host, port);
		if (mNet == null)
		{
			GlobalLog(.Error, "NetworkController: failed to open a client socket");
			return false;
		}

		mNet.SetReplicatedScene(mScene);
		WireSceneSystem(mNet);

		if (mSpawnResolverFactory != null)
			mNet.Replication.SetSpawnHandler(mSpawnResolverFactory());

		GlobalLog(.Information, "NetworkController: connecting to {}:{}", host, port);
		return true;
	}

	/// Drops the endpoint, which closes the session and its socket.
	public void StopNetworking()
	{
		// The scene system is detached BEFORE the endpoint dies, so nothing is left driving a
		// freed one.
		WireSceneSystem(null);

		if (mNet != null)
			GlobalLog(.Information, "NetworkController: networking stopped");

		delete mNet;
		mNet = null;
	}

	/// Points the CURRENT replicated scene's network system at `endpoint`, which is the live
	/// one when attaching and null when detaching.
	///
	/// Nothing to do with no scene, or with a scene built without the net module. The system
	/// dies with its scene, and the controller clears the scene before one dies, so this only
	/// ever runs while the scene is alive.
	private void WireSceneSystem(NetworkManager endpoint)
	{
		if (mScene == null)
			return;

		if (let system = mScene.GetSystem<NetworkSceneSystem>())
			system.Endpoint = endpoint;
	}
}
