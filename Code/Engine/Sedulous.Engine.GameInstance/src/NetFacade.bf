using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Net;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Net.Replication;
using Sedulous.Net.Manager;

namespace Sedulous.Engine.GameInstance;

/// A run's networking to game code, reached as `Net`: whether it is a host or a client, the
/// role controls a game's menu calls (host, join, leave), and messages to the other side.
///
/// It holds the run's CONTROLLER, which outlives every endpoint it opens, so the facade never
/// dangles; each call reaches the live endpoint through it and does nothing offline. Ports
/// are whole numbers (0 to 65535); a message is an RPC by name, from a client to the host or
/// from the host to every client, and On, OnNumber and OnText receive one. Players are named by
/// id: nought the host, a client the id the host's welcome gave it. The game instance installs
/// one on its run.
///
/// Its entities are the replicated scene's (EntityScene): a spawn answers one there, and IsMine
/// takes one from there.
///
/// Game code receives through the delegates of On, OnNumber, OnText, OnJoin and OnLeave: a name
/// has one handler, of any kind, the later registration replacing it. The facade OWNS the
/// delegates and deletes them on Off (by the same name; OffJoin and OffLeave for those), on a
/// replacement, and as the run's session ends (DropHandlers), when the game, its levels and its
/// behaviours they call into go.
/// Something that goes mid-session (a level's scene unloaded, a behaviour's entity destroyed)
/// calls Off for what it registered.
class NetFacade
{
	/// The handler of a bare message, and of a player joining or leaving: the player that sent
	/// it, or that came or went.
	public typealias PlayerHandler = delegate void(int32 player);
	/// The handler of a message carrying a number.
	public typealias NumberHandler = delegate void(int32 player, double value);
	/// The handler of a message carrying a text, valid for the call alone.
	public typealias TextHandler = delegate void(int32 player, StringView text);

	/// What a message carries after its id: the sending call writes the kind first, so
	/// the receiving handler knows what follows (nothing, a number, or a text).
	public enum MessageKind : uint8
	{
		None = 0,
		Number = 1,
		Text = 2
	}

	/// The longest text a message may carry; a longer length on the wire is a broken message.
	public const int MaxTextBytes = 1 << 20;

	/// The handler for a message name and the kind it takes. Its endpoints' RPCs hold it, so it
	/// lives as long as the facade: Off empties it.
	private class Handler
	{
		public String Name = new .() ~ delete _;
		public MessageKind Kind;
		/// OWNED: the one of its kind; the others null, or all of them for none.
		public PlayerHandler Plain ~ delete _;
		public NumberHandler Number ~ delete _;
		public TextHandler Text ~ delete _;

		public bool IsSet => (Plain != null) || (Number != null) || (Text != null);
	}

	/// BORROWED: the instance's controller, which outlives this.
	private NetworkController mController;
	/// The handlers by message name. They live here, beside the controller, so every endpoint
	/// the controller opens gets them (registered before hosting or joining too), and a
	/// handler survives a disconnect.
	private List<Handler> mHandlers = new .() ~ DeleteContainerAndItems!(_);
	/// OnJoin and OnLeave's handlers, OWNED, kept beside the message handlers for the same reason.
	private PlayerHandler mJoinHandler ~ delete _;
	private PlayerHandler mLeaveHandler ~ delete _;
	/// Handlers replaced or taken off while a message or a player event is being delivered,
	/// deleted once it is: the handler running may be one of them, or a caller's own. OWNED.
	private List<Object> mRetired = new .() ~ DeleteContainerAndItems!(_);
	private int32 mDelivering = 0;

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
	public bool IsServer => (Endpoint != null) && Endpoint.Session.IsServer;
	/// Joined: this run is a client of a host.
	public bool IsClient => (Endpoint != null) && Endpoint.Session.IsClient;
	/// The peers connected: a host's clients, or a client's host. Nought offline.
	public int32 PeerCount => (Endpoint != null) ? (int32)Endpoint.Session.PeerCount : 0;
	/// The network's fixed step count, shared by every peer once a client has synced.
	public double NetworkTick => (Endpoint != null) ? (double)Endpoint.Session.NetworkTick : 0.0;
	/// The network's clock in milliseconds, the host's on every peer once synced.
	public double NetworkTimeMs => (Endpoint != null) ? Endpoint.Session.NetworkTimeMs : 0.0;

	/// Whether this build can host at all (a browser cannot listen): a title offers Host only when
	/// it can, rather than failing once it is chosen.
	public bool CanHost => NetworkManager.CanHost;

	/// Hosts on `port`, a listen server (this run plays too). False when the socket does not
	/// open; the game shows an error.
	public bool StartServer(int32 port) => (mController != null) && mController.StartServer((uint16)port, false);
	/// Hosts on `port` without playing: a dedicated server.
	public bool StartDedicatedServer(int32 port) => (mController != null) && mController.StartServer((uint16)port, true);
	/// Joins the host at `host`:`port`. False when the socket does not open; the handshake
	/// itself completes later.
	public bool Connect(StringView host, int32 port) => (mController != null) && mController.Connect(host, (uint16)port);
	/// Host: joiners wait for Ready before they hear any state (NetworkManager.SetWaitForReady):
	/// a game whose joiner loads the host's map after connecting. Called once hosting.
	public void WaitForReady(bool wait)
	{
		if (Endpoint != null)
			Endpoint.SetWaitForReady(wait);
	}

	/// Client: its scene is the host's, loaded; the host's state starts, from a full snapshot.
	public void Ready()
	{
		if (Endpoint != null)
			Endpoint.SendReady();
	}

	/// Leaves: the session and its socket close.
	public void Disconnect()
	{
		if (mController != null)
			mController.StopNetworking();
	}

	/// Sends the message `name`: a client's goes to the host, a host's to every client.
	public void Rpc(StringView name) => CallRpc(name, scope (w) => w.WriteU8((uint8)MessageKind.None));

	/// Sends the message `name` carrying a number.
	public void RpcNumber(StringView name, double value) => CallRpc(name, scope (w) =>
		{
			w.WriteU8((uint8)MessageKind.Number);
			w.WriteDouble(value);
		});

	/// Sends the message `name` carrying a text.
	public void RpcText(StringView name, StringView text) => CallRpc(name, scope (w) =>
		{
			w.WriteU8((uint8)MessageKind.Text);
			WriteText(w, text);
		});

	/// Host only: sends the message `name` to one player (a client's id), as Rpc sends it to
	/// all. Nothing for the host itself (nought), an unknown player, or on a client.
	public void RpcTo(int32 player, StringView name) => CallRpcTo(player, name, scope (w) => w.WriteU8((uint8)MessageKind.None));

	/// Host only: sends the message `name` carrying a number to one player.
	public void RpcNumberTo(int32 player, StringView name, double value) => CallRpcTo(player, name, scope (w) =>
		{
			w.WriteU8((uint8)MessageKind.Number);
			w.WriteDouble(value);
		});

	/// Host only: sends the message `name` carrying a text to one player.
	public void RpcTextTo(int32 player, StringView name, StringView text) => CallRpcTo(player, name, scope (w) =>
		{
			w.WriteU8((uint8)MessageKind.Text);
			WriteText(w, text);
		});

	/// This game's own player id: nought on the host, on a client the id the host gave it (its
	/// welcome), -1 offline or before the welcome.
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
	public bool IsMine(EntityHandle entity)
	{
		let endpoint = Endpoint;
		let scene = (endpoint != null) ? endpoint.ReplicatedScene : null;
		let networked = (scene != null) ? scene.GetSystem<NetworkComponentManager>() : null;
		let component = (networked != null) ? networked.Get(entity) : null;
		let self = LocalPlayer;
		return (component != null) && (self >= 0) && (component.Owner == (uint32)self);
	}

	/// Host only: spawns `prefab` at `position` in the replicated scene, as
	/// `scene.Prefabs.Spawn` does, and gives it a network id with the prefab, so every client
	/// spawns its own copy and a player who joins later gets it in the snapshot. The prefab's
	/// root needs a networked transform for its movement to follow. Unassigned on a client,
	/// offline, or for a prefab the scene cannot spawn.
	public EntityHandle Spawn(Guid prefab, Float3 position) => SpawnFor(0, prefab, position);

	/// Host only: spawns as Spawn does, owned by `player` (nought the host), so that player's
	/// IsMine says yes for it and its owner shows on every peer.
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

	/// Receives the message `name` with `handler(player)`. The sender is the peer that sent it:
	/// player nought on a client (the host), the client that called on the host. Register any
	/// time, before hosting or joining too; a later registration of the name, of any kind,
	/// replaces it. TAKES OWNERSHIP of the handler; null does nothing.
	public void On(StringView name, PlayerHandler handler)
	{
		if (handler != null)
			Register(name, .None, handler, null, null);
	}

	/// Receives the message `name` with `handler(player, value)`, its number. As On.
	public void OnNumber(StringView name, NumberHandler handler)
	{
		if (handler != null)
			Register(name, .Number, null, handler, null);
	}

	/// Receives the message `name` with `handler(player, text)`, its text, a view valid for the
	/// call alone. As On.
	public void OnText(StringView name, TextHandler handler)
	{
		if (handler != null)
			Register(name, .Text, null, null, handler);
	}

	/// Calls `handler(player)` when a player joins: on the host a client, on a client itself
	/// once the host has welcomed it. It replaces the one set. TAKES OWNERSHIP; null does nothing.
	public void OnJoin(PlayerHandler handler)
	{
		if (handler != null)
			SetPlayerHandler(handler, true);
	}

	/// Calls `handler(player)` when a player leaves: on the host a client, on a client the host
	/// (nought). As OnJoin.
	public void OnLeave(PlayerHandler handler)
	{
		if (handler != null)
			SetPlayerHandler(handler, false);
	}

	/// Takes the handler of the message `name` off, of any kind, and deletes it (once the
	/// message being delivered, if any, is done). Nothing for a name without one.
	public void Off(StringView name)
	{
		for (let handler in mHandlers)
		{
			if (handler.Name == name)
				Empty(handler);
		}
	}

	/// Takes the join handler off and deletes it.
	public void OffJoin()
	{
		Retire(mJoinHandler);
		mJoinHandler = null;
	}

	/// Takes the leave handler off and deletes it.
	public void OffLeave()
	{
		Retire(mLeaveHandler);
		mLeaveHandler = null;
	}

	/// Every handler, taken off and deleted. The run calls it as its session ends, when what
	/// they call into goes.
	public void DropHandlers()
	{
		for (let handler in mHandlers)
			Empty(handler);
		OffJoin();
		OffLeave();
	}

	/// How many message names have a handler.
	public int HandlerCount
	{
		get
		{
			int count = 0;
			for (let handler in mHandlers)
			{
				if (handler.IsSet)
					count++;
			}
			return count;
		}
	}

	/// The handler of `name`, made (empty) when there is none yet.
	private Handler HandlerFor(StringView name)
	{
		for (let existing in mHandlers)
		{
			if (existing.Name == name)
				return existing;
		}
		let handler = new Handler();
		handler.Name.Set(name);
		mHandlers.Add(handler);
		return handler;
	}

	/// Takes every callback off `handler`, retired.
	private void Empty(Handler handler)
	{
		Retire(handler.Plain);
		handler.Plain = null;
		Retire(handler.Number);
		handler.Number = null;
		Retire(handler.Text);
		handler.Text = null;
	}

	/// Deletes `callback`, or, while something is being delivered, once it is.
	private void Retire(Object callback)
	{
		if (callback == null)
			return;
		if (mDelivering > 0)
			mRetired.Add(callback);
		else
			delete callback;
	}

	private void BeginDelivery() => mDelivering++;

	private void EndDelivery()
	{
		mDelivering--;
		if (mDelivering == 0)
			ClearAndDeleteItems!(mRetired);
	}

	/// The handler for `name`, installed now if an endpoint is open, and on each the controller
	/// opens later.
	private void Register(StringView name, MessageKind kind, PlayerHandler plain, NumberHandler number, TextHandler text)
	{
		let handler = HandlerFor(name);
		Empty(handler);
		handler.Plain = plain;
		handler.Number = number;
		handler.Text = text;
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
	private void Install(NetworkManager endpoint, Handler handler)
	{
		endpoint.Rpc.On(handler.Name, new [=this, =handler, =endpoint](sender, args) =>
			{
				// A client hears only from the host: player nought (its own id for the host
				// connection means nothing to the game).
				let from = endpoint.Session.IsClient ? 0 : sender;
				let kind = (MessageKind)args.ReadU8();
				if (!args.Ok || (kind != handler.Kind) || !handler.IsSet)
					return;
				double number = 0;
				let text = scope String();
				switch (kind)
				{
				case .Number:
					number = args.ReadDouble();
				case .Text:
					let size = args.ReadVarU32();
					if (!args.Ok || (size > (uint32)MaxTextBytes))
						return;
					let bytes = scope uint8[size];
					args.ReadBytes(bytes);
					text.Append((char8*)bytes.Ptr, (int)size);
				case .None:
				}
				if (!args.Ok)
					return; // truncated: nothing half read reaches the handler
				// Locals from here on: a handler that registers its own name again replaces this
				// closure on the endpoint, which deletes it under the call.
				let facade = this;
				let entry = handler;
				facade.BeginDelivery();
				if (entry.Plain != null)
					entry.Plain((int32)from);
				else if (entry.Number != null)
					entry.Number((int32)from, number);
				else if (entry.Text != null)
					entry.Text((int32)from, text);
				facade.EndDelivery();
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

	private void SetPlayerHandler(PlayerHandler handler, bool join)
	{
		if (join)
		{
			OffJoin();
			mJoinHandler = handler;
		}
		else
		{
			OffLeave();
			mLeaveHandler = handler;
		}
		if (let endpoint = Endpoint)
			InstallPlayerEvents(endpoint);
	}

	/// Points the endpoint's join and leave reporting at the handlers, read when an event comes,
	/// so a later OnJoin needs no reinstall.
	private void InstallPlayerEvents(NetworkManager endpoint)
	{
		endpoint.SetPlayerEvents(new [=this](joined, player) =>
			{
				let handler = joined ? mJoinHandler : mLeaveHandler;
				if (handler == null)
					return;
				// A local: a handler that sets another OnJoin replaces this closure on the
				// endpoint, which deletes it under the call.
				let facade = this;
				facade.BeginDelivery();
				handler((int32)player);
				facade.EndDelivery();
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
