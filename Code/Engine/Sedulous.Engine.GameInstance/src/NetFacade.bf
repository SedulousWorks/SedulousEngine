using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Net;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Net.Replication;
using Sedulous.Net.Manager;

namespace Sedulous.Engine.GameInstance;

/// A run's networking to a script, reached as `Net`: whether it is a host or a client, the
/// role controls a game's menu calls (host, join, leave), and messages to the other side.
///
/// It holds the run's CONTROLLER, which outlives every endpoint it opens, so the facade never
/// dangles; each call reaches the live endpoint through it and does nothing offline. Ports
/// are whole numbers (0 to 65535); a message is an RPC by name, from a client to the host or
/// from the host to every client, and On, OnNumber and OnText receive one. Players are named by
/// id: nought the host, a client the id the host's welcome gave it. The game instance installs
/// one on its run.
///
/// Its entities are the replicated scene's (IScriptEntityScene): a spawn answers one a script
/// can use, and IsMine takes one from there.
[Scriptable, ServiceFacade("Net")]
class NetFacade : IScriptEntityScene
{
	/// What a script message carries after its id: the sending call writes the kind first, so
	/// the receiving handler knows what follows (nothing, a number, or a text).
	public enum MessageKind : uint8
	{
		None = 0,
		Number = 1,
		Text = 2
	}

	/// The longest text a message may carry; a longer length on the wire is a broken message.
	public const int MaxTextBytes = 1 << 20;

	/// A script's handler for a message name, and the kind it takes.
	private class Handler
	{
		public String Name = new .() ~ delete _;
		public MessageKind Kind;
		public ScriptDelegate Callback ~ delete _;
	}

	/// BORROWED: the instance's controller, which outlives this.
	private NetworkController mController;
	/// The handlers by message name. They live here, beside the controller, so every endpoint
	/// the controller opens gets them (registered before hosting or joining too), and a
	/// handler survives a disconnect.
	private List<Handler> mHandlers = new .() ~ DeleteContainerAndItems!(_);
	/// OnJoin and OnLeave's handlers, OWNED, kept beside the message handlers for the same reason.
	private ScriptDelegate mJoinHandler ~ delete _;
	private ScriptDelegate mLeaveHandler ~ delete _;

	public this(NetworkController controller)
	{
		mController = controller;
		if (mController != null)
			mController.OnEndpointOpened.Add(new [=this](endpoint) =>
				{
					InstallHandlers(endpoint);
					InstallPlayerEvents(endpoint);
				});
	}

	private NetworkManager Endpoint => (mController != null) ? mController.NetEndpoint : null;

	/// The scene its entities live in: the endpoint's replicated scene, none offline.
	public Scene EntityScene => (Endpoint != null) ? Endpoint.ReplicatedScene : null;

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
	public void Rpc(StringView name) => CallRpc(name, scope (w) => w.WriteU8((uint8)MessageKind.None));

	/// Sends the message `name` carrying a number.
	[Scriptable]
	public void RpcNumber(StringView name, double value) => CallRpc(name, scope (w) =>
		{
			w.WriteU8((uint8)MessageKind.Number);
			w.WriteDouble(value);
		});

	/// Sends the message `name` carrying a text.
	[Scriptable]
	public void RpcText(StringView name, StringView text) => CallRpc(name, scope (w) =>
		{
			w.WriteU8((uint8)MessageKind.Text);
			WriteText(w, text);
		});

	/// Host only: sends the message `name` to one player (a client's id), as Rpc sends it to
	/// all. Nothing for the host itself (nought), an unknown player, or on a client.
	[Scriptable]
	public void RpcTo(int32 player, StringView name) => CallRpcTo(player, name, scope (w) => w.WriteU8((uint8)MessageKind.None));

	/// Host only: sends the message `name` carrying a number to one player.
	[Scriptable]
	public void RpcNumberTo(int32 player, StringView name, double value) => CallRpcTo(player, name, scope (w) =>
		{
			w.WriteU8((uint8)MessageKind.Number);
			w.WriteDouble(value);
		});

	/// Host only: sends the message `name` carrying a text to one player.
	[Scriptable]
	public void RpcTextTo(int32 player, StringView name, StringView text) => CallRpcTo(player, name, scope (w) =>
		{
			w.WriteU8((uint8)MessageKind.Text);
			WriteText(w, text);
		});

	/// This game's own player id: nought on the host, on a client the id the host gave it (its
	/// welcome), -1 offline or before the welcome.
	[Scriptable]
	public int32 LocalPlayer
	{
		get
		{
			let endpoint = Endpoint;
			if (endpoint == null)
				return -1;
			if (endpoint.Session.IsServer)
				return 0;
			let self = endpoint.Session.LocalPeer;
			return (self != InvalidPeer) ? (int32)self : -1;
		}
	}

	/// Whether `entity` is this player's: its owner is LocalPlayer. False for an entity that is
	/// not networked, and offline.
	[Scriptable]
	public bool IsMine(EntityHandle entity)
	{
		let endpoint = Endpoint;
		let scene = (endpoint != null) ? endpoint.ReplicatedScene : null;
		let networked = (scene != null) ? scene.GetSystem<NetworkComponentManager>() : null;
		let component = (networked != null) ? networked.Get(entity) : null;
		let self = LocalPlayer;
		return (component != null) && (self >= 0) && (component.Owner == (uint32)self);
	}

	/// Calls `handler(player)` when a player joins: on the host a client, on a client itself
	/// once the host has welcomed it. TAKES OWNERSHIP; a later one replaces it.
	[Scriptable, ScriptCallback("void NetHandler(int sender)")]
	public void OnJoin(ScriptDelegate handler) => SetPlayerHandler(handler, true);

	/// Calls `handler(player)` when a player leaves: on the host a client, on a client the
	/// host (nought). TAKES OWNERSHIP; a later one replaces it.
	[Scriptable, ScriptCallback("void NetHandler(int sender)")]
	public void OnLeave(ScriptDelegate handler) => SetPlayerHandler(handler, false);

	/// Receives the message `name` with `handler(sender)`. The sender is the peer that sent it:
	/// on the host the client that called, on a client the host. Register any time, before
	/// hosting or joining too; a later registration of the name replaces it. TAKES OWNERSHIP of
	/// the handler.
	[Scriptable, ScriptCallback("void NetHandler(int sender)")]
	public void On(StringView name, ScriptDelegate handler) => Register(name, .None, handler);

	/// Receives the message `name` with `handler(sender, value)`, its number.
	[Scriptable, ScriptCallback("void NetNumberHandler(int sender, double value)")]
	public void OnNumber(StringView name, ScriptDelegate handler) => Register(name, .Number, handler);

	/// Receives the message `name` with `handler(sender, text)`, its text.
	[Scriptable, ScriptCallback("void NetTextHandler(int sender, const string &in text)")]
	public void OnText(StringView name, ScriptDelegate handler) => Register(name, .Text, handler);

	/// Host only: spawns `prefab` at `position` in the replicated scene, as
	/// `scene.Prefabs.Spawn` does, and gives it a network id with the prefab, so every client
	/// spawns its own copy and a player who joins later gets it in the snapshot. The prefab's
	/// root needs a networked transform for its movement to follow. Unassigned on a client,
	/// offline, or for a prefab the scene cannot spawn.
	[Scriptable]
	public EntityHandle Spawn(Guid prefab, Float3 position) => SpawnFor(0, prefab, position);

	/// Host only: spawns as Spawn does, owned by `player` (nought the host), so that player's
	/// IsMine says yes for it and its owner shows on every peer.
	[Scriptable]
	public EntityHandle SpawnFor(int32 player, Guid prefab, Float3 position)
	{
		let endpoint = Endpoint;
		if ((endpoint == null) || !endpoint.Session.IsServer)
			return .Invalid;
		let scene = endpoint.ReplicatedScene;
		let spawner = (scene != null) ? scene.GetSystem<PrefabSpawnSystem>() : null;
		if (spawner == null)
			return .Invalid;
		let entity = spawner.Spawn(prefab, position);
		if (entity.IsAssigned)
			endpoint.Replication.AssignNetworkId(scene, entity, prefab, (player > 0) ? (uint32)player : 0);
		return entity;
	}

	/// How many message names have a handler.
	public int HandlerCount => mHandlers.Count;

	private void Register(StringView name, MessageKind kind, ScriptDelegate callback)
	{
		if (callback == null)
			return;
		Handler handler = null;
		for (let existing in mHandlers)
		{
			if (existing.Name == name)
				handler = existing;
		}
		if (handler == null)
		{
			handler = new Handler();
			handler.Name.Set(name);
			mHandlers.Add(handler);
		}
		delete handler.Callback;
		handler.Callback = callback;
		handler.Kind = kind;
		if (let endpoint = Endpoint)
			Install(endpoint, handler);
	}

	/// Every handler, on an endpoint the controller just opened.
	private void InstallHandlers(NetworkManager endpoint)
	{
		for (let handler in mHandlers)
			Install(endpoint, handler);
	}

	/// Points the message's RPC on `endpoint` at the handler: the kind read first, then what
	/// it says follows. A message of another kind than the handler takes, or one cut short,
	/// reaches nothing half read.
	private static void Install(NetworkManager endpoint, Handler handler)
	{
		endpoint.Rpc.On(handler.Name, new [=handler, =endpoint](sender, args) =>
			{
				// A client hears only from the host: player nought (its own id for the host
				// connection means nothing to a script).
				let from = endpoint.Session.IsClient ? 0 : sender;
				let kind = (MessageKind)args.ReadU8();
				if (!args.Ok || (kind != handler.Kind) || (handler.Callback == null))
					return;
				var values = ScriptValue[2](.FromInt((int32)from), .Nil);
				int count = 1;
				let text = scope String();
				switch (kind)
				{
				case .Number:
					values[count++] = .FromFloat(args.ReadDouble());
				case .Text:
					let size = args.ReadVarU32();
					if (!args.Ok || (size > (uint32)MaxTextBytes))
						return;
					let bytes = scope uint8[size];
					args.ReadBytes(bytes);
					text.Append((char8*)bytes.Ptr, (int)size);
					values[count++] = .FromString(text);
				case .None:
				}
				if (!args.Ok)
					return; // truncated: nothing half read reaches the script
				var result = ScriptValue.Nil;
				handler.Callback.Invoke(.(&values[0], count), ref result);
			});
	}

	private static void WriteText(BitWriter w, StringView text)
	{
		w.WriteVarU32((uint32)text.Length);
		w.WriteBytes(.((uint8*)text.Ptr, text.Length));
	}

	private void CallRpcTo(int32 player, StringView name, RpcTable.ArgumentWriter writeArgs)
	{
		let endpoint = Endpoint;
		if ((endpoint == null) || !endpoint.Session.IsServer || (player <= 0))
			return;
		for (let peer in endpoint.Session.Peers)
		{
			if (peer.Id == (PeerId)player)
			{
				endpoint.Rpc.Call(endpoint.Session, peer.Id, name, writeArgs);
				return;
			}
		}
	}

	private void SetPlayerHandler(ScriptDelegate handler, bool join)
	{
		if (join)
		{
			delete mJoinHandler;
			mJoinHandler = handler;
		}
		else
		{
			delete mLeaveHandler;
			mLeaveHandler = handler;
		}
		if (let endpoint = Endpoint)
			InstallPlayerEvents(endpoint);
	}

	/// Points the endpoint's join and leave reporting at the script's handlers, read when an
	/// event comes, so a later OnJoin needs no reinstall.
	private void InstallPlayerEvents(NetworkManager endpoint)
	{
		endpoint.SetPlayerEvents(new [=this](joined, player) =>
			{
				let handler = joined ? mJoinHandler : mLeaveHandler;
				if (handler == null)
					return;
				var args = ScriptValue[1](.FromInt((int32)player));
				var result = ScriptValue.Nil;
				handler.Invoke(args, ref result);
			});
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
