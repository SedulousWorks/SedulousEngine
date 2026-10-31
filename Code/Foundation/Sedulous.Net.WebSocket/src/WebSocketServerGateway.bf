using System;
using System.Collections;
using Sedulous.Http;
using Sedulous.Net;
using Sedulous.Net.Tls;

namespace Sedulous.Net.WebSocket;

/// The pump model websocket server: accept, upgrade, decode frames, queue events.
///
/// A websocket connection BEGINS as an HTTP request, so the handshake is parsed with the HTTP
/// message parser rather than a second hand rolled one. After the 101 the connection speaks
/// binary frames, which are message oriented and so map one to one onto the datagram seam the
/// whole net stack rides.
///
/// TLS (wss://) is the gateway's when the host hands it a backend and a certificate
/// (WebSocketTls): each connection then runs a TLS session before the upgrade, through
/// Sedulous.Net.Tls's streams. A proxy in front of a plain gateway stays the way for a host with
/// no certificate.
///
/// SINGLE THREADED, like the HTTP server.
class WebSocketServerGateway
{
	/// The connection cap. Past it a pending connection is dropped, which closes it.
	private const int cMaxClients = 64;
	/// The handshake head cap. Far past a real upgrade request, and small enough that an
	/// unauthenticated peer cannot make the gateway buffer.
	private const int cHandshakeCap = 4096;
	private const int cReadChunk = 4096;

	/// One accepted connection, before or after its upgrade.
	private class Client
	{
		public uint32 Id = 0;
		/// Plain, or TLS (wss://); it buffers what the socket would not take. OWNED.
		public INetByteStream Stream ~ delete _;
		public bool Upgraded = false;
		/// Live until the upgrade completes, then deleted.
		public HttpMessageParser Handshake ~ delete _;
		public WebSocketFrameParser Frames = new .() ~ delete _;
		public bool Dead = false;
	}

	private TcpListener mListener ~ delete _;
	/// BORROWED: the application's, outliving the gateway. Null for ws:// alone.
	private ITlsBackend mTls = null;
	private TlsServerConfig mTlsConfig ~ delete _;
	private String mFailure = new .() ~ delete _;
	private List<Client> mClients = new .() ~ DeleteContainerAndItems!(_);
	private List<WsGatewayEvent> mEvents = new .() ~ DeleteContainerAndItems!(_);
	private int mEventHead = 0;
	private uint32 mNextClientId = 1;

	/// Scratch reused across a pump, so a busy tick does not allocate per read.
	private List<uint8> mScratch = new .() ~ delete _;
	private WsFrame mScratchFrame = new .() ~ delete _;

	/// Binds the listener. Nought lets the operating system choose; read BoundPort after. With
	/// `tls` every connection is TLS first (wss://); a certificate or key that does not load
	/// leaves the gateway closed, Failure saying why.
	public this(uint16 port, WebSocketTls tls = null)
	{
		mListener = new .(port);
		if (tls == null)
			return;
		mTls = tls.Backend;
		mTlsConfig = new .();
		mTlsConfig.CertificateChainPem.Set(tls.Config.CertificateChainPem);
		mTlsConfig.PrivateKeyPem.Set(tls.Config.PrivateKeyPem);
		for (let protocol in tls.Config.Alpn)
			mTlsConfig.Alpn.Add(new .(protocol));
		mTlsConfig.Minimum = tls.Config.Minimum;
		mTlsConfig.Maximum = tls.Config.Maximum;
		if (mTls == null)
		{
			mFailure.Set("wss needs a TLS backend, and none was given");
			return;
		}
		// A certificate or key that does not load fails every connection: say so now, once.
		let probe = mTls.CreateServer(mTlsConfig);
		defer delete probe;
		if (probe.State == .Failed)
			mFailure.Set(probe.Failure);
	}

	public ~this()
	{
		for (let client in mClients)
			client.Stream.Close();
	}

	public bool IsOpen => mListener.IsOpen && mFailure.IsEmpty;
	public bool IsSecure => mTlsConfig != null;
	/// Why the gateway is not open, when its TLS configuration is the reason.
	public StringView Failure => mFailure;
	public uint16 BoundPort => mListener.BoundPort;
	public int ClientCount => mClients.Count;

	/// One pump: accept, move each stream on, read, decode, and drop what died.
	public void Pump()
	{
		if (!mFailure.IsEmpty)
			return;
		AcceptPending();

		for (let client in mClients)
		{
			if (!client.Dead)
				PumpClient(client);
		}

		for (int i = mClients.Count - 1; i >= 0; i--)
		{
			if (mClients[i].Dead)
			{
				// What is still held goes (a close frame, close_notify).
				mClients[i].Stream.Close();
				delete mClients[i];
				mClients.RemoveAt(i);
			}
		}
	}

	/// Fills outEvent with one queued event. False when none remain.
	public bool Poll(WsGatewayEvent outEvent)
	{
		if (mEventHead >= mEvents.Count)
			return false;

		let entry = mEvents[mEventHead];
		mEventHead++;
		outEvent.Set(entry.Kind, entry.Client, entry.Payload);

		if (mEventHead >= mEvents.Count)
		{
			ClearAndDeleteItems!(mEvents);
			mEventHead = 0;
		}
		return true;
	}

	/// One binary frame to an upgraded client. An unknown or closed id is a no-op, because a
	/// caller holding a stale id is ordinary rather than exceptional.
	public void SendBinary(uint32 client, Span<uint8> data)
	{
		for (let entry in mClients)
		{
			if ((entry.Id != client) || !entry.Upgraded || entry.Dead)
				continue;

			let frame = scope List<uint8>();
			// A SERVER frame is never masked, which is the RFC's asymmetry.
			WebSocketFrame.Encode(.Binary, data, false, 0, frame);
			SendRaw(entry, frame);
			return;
		}
	}

	public void DisconnectClient(uint32 client)
	{
		for (let entry in mClients)
		{
			if (entry.Id != client)
				continue;

			let frame = scope List<uint8>();
			WebSocketFrame.Encode(.Close, .(), false, 0, frame);
			SendRaw(entry, frame);
			entry.Dead = true;
			return;
		}
	}

	// ---- Internals ------------------------------------------------------------------------

	private void AcceptPending()
	{
		for (;;)
		{
			let accepted = mListener.Accept();
			if (accepted == null)
				break;

			if (mClients.Count >= cMaxClients)
			{
				delete accepted;
				continue;
			}

			let client = new Client();
			client.Id = mNextClientId;
			mNextClientId++;
			if (mTlsConfig != null)
				client.Stream = new TlsStream(accepted, mTls.CreateServer(mTlsConfig));
			else
				client.Stream = new PlainStream(accepted);
			client.Handshake = new .(.Request, cHandshakeCap);
			mClients.Add(client);
		}
	}

	private void PushEvent(WsGatewayEventKind kind, uint32 client, Span<uint8> payload)
	{
		let entry = new WsGatewayEvent();
		entry.Set(kind, client, payload);
		mEvents.Add(entry);
	}

	/// The stream takes all of it, holding what the socket would not take yet.
	private void SendRaw(Client client, List<uint8> bytes)
	{
		if (client.Stream.Send(bytes) < 0)
			client.Dead = true;
	}

	/// Moves the stream's bytes (and a TLS handshake) on; what it already holds is still read
	/// before a closed stream counts.
	private void PumpClient(Client client)
	{
		let alive = client.Stream.Pump();
		ReadClient(client);
		if (!alive && !client.Dead)
		{
			client.Dead = true;
			if (client.Upgraded)
				PushEvent(.Disconnected, client.Id, .());
		}
	}

	private void ReadClient(Client client)
	{
		let chunk = scope uint8[cReadChunk];
		for (;;)
		{
			let got = client.Stream.Receive(chunk);
			if (got < 0)
			{
				client.Dead = true;
				// Only an UPGRADED client was ever announced, so only that one is mourned.
				if (client.Upgraded)
					PushEvent(.Disconnected, client.Id, .());
				return;
			}
			// Would block: nothing more this pump.
			if (got == 0)
				return;

			var offset = 0;
			if (!client.Upgraded)
			{
				if (!AdvanceHandshake(client, chunk, (int)got, ref offset))
					return;
				// Still mid handshake: read more rather than feeding the frame parser.
				if (!client.Upgraded)
					continue;
			}

			client.Frames.Push(.(&chunk[offset], (int)got - offset));
			if (client.Frames.Failed)
			{
				client.Dead = true;
				PushEvent(.Disconnected, client.Id, .());
				return;
			}

			if (!DrainFrames(client))
				return;
		}
	}

	/// Feeds handshake bytes and, on completion, answers. False when the client is finished
	/// with, either way.
	///
	/// Fed ONE BYTE AT A TIME because the parser reports no consumed count: an eager client
	/// can put its first frame in the same segment as the request, and those bytes belong to
	/// the frame parser rather than the HTTP one.
	private bool AdvanceHandshake(Client client, uint8[] chunk, int got, ref int offset)
	{
		while (offset < got)
		{
			let state = client.Handshake.Push(.(&chunk[offset], 1));
			offset++;

			if (state == .Failed)
			{
				Reject(client);
				return false;
			}
			if (state != .Complete)
				continue;

			let key = scope String();
			if (!WebSocketHandshake.Validate(client.Handshake, key))
			{
				Reject(client);
				return false;
			}

			let response = scope List<uint8>();
			WebSocketHandshake.BuildUpgradeResponse(key, response);
			SendRaw(client, response);

			client.Upgraded = true;
			delete client.Handshake;
			client.Handshake = null;
			PushEvent(.Connected, client.Id, .());
			return true;
		}
		return true;
	}

	private void Reject(Client client)
	{
		let response = scope List<uint8>();
		WebSocketHandshake.BuildRejectResponse(response);
		SendRaw(client, response);
		client.Dead = true;
	}

	/// Handles every decoded frame. False when the client is finished with.
	private bool DrainFrames(Client client)
	{
		while (client.Frames.Next(mScratchFrame))
		{
			switch (mScratchFrame.Opcode)
			{
			case .Binary:
				PushEvent(.Message, client.Id, mScratchFrame.Payload);

			case .Ping:
				// Answered here rather than surfaced: keep-alive is the transport's business.
				mScratch.Clear();
				WebSocketFrame.Encode(.Pong, mScratchFrame.Payload, false, 0, mScratch);
				SendRaw(client, mScratch);

			case .Pong:
				// The answer to our own keep-alive. Nothing to do.

			case .Close:
				mScratch.Clear();
				WebSocketFrame.Encode(.Close, .(), false, 0, mScratch);
				SendRaw(client, mScratch);
				client.Dead = true;
				PushEvent(.Disconnected, client.Id, .());
				return false;

			default:
				// Text and Continuation are not this wire's protocol: it is binary, and it
				// does not fragment.
				client.Dead = true;
				PushEvent(.Disconnected, client.Id, .());
				return false;
			}
		}
		return true;
	}
}
