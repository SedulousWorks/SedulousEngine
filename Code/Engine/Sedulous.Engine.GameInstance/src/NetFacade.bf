using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Net;
using Sedulous.Net.Manager;

namespace Sedulous.Engine.GameInstance;

/// A run's networking to a script, reached as `Net`: whether it is a host or a client, the
/// role controls a game's menu calls (host, join, leave), and messages to the other side.
///
/// It holds the run's CONTROLLER, which outlives every endpoint it opens, so the facade never
/// dangles; each call reaches the live endpoint through it and does nothing offline. Ports
/// are whole numbers (0 to 65535); a message is an RPC by name, from a client to the host or
/// from the host to every client, and On, OnNumber and OnText receive one. The game instance
/// installs one on its run.
[Scriptable, ServiceFacade("Net")]
class NetFacade
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

	public this(NetworkController controller)
	{
		mController = controller;
		if (mController != null)
			mController.OnEndpointOpened.Add(new [=this](endpoint) => InstallHandlers(endpoint));
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
		endpoint.Rpc.On(handler.Name, new [=handler](sender, args) =>
			{
				let kind = (MessageKind)args.ReadU8();
				if (!args.Ok || (kind != handler.Kind) || (handler.Callback == null))
					return;
				var values = ScriptValue[2](.FromInt((int32)sender), .Nil);
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
