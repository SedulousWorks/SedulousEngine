using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.Http;
using Sedulous.Net;
using Sedulous.Net.Tls;

namespace Sedulous.Net.WebSocket;

/// One websocket to a host's gateway, presented as an IDatagramSocket.
///
/// This is the other end of [[WebSocketServerGateway]]. Each binary frame is one datagram and
/// there is only ever one remote, so the session, reliability and replication layers above
/// cannot tell it from a UDP socket and need no branch of their own. In a browser it is the
/// browser's WebSocket; natively it is this module's own client over a plain or TLS stream, so
/// a desktop or Deck player can join a host that only speaks wss.
///
/// The handshake is ASYNC either way. A send before the upgrade QUEUES rather than being
/// dropped, which is not a nicety: the session fires its connect packet the instant it is
/// created, well inside the handshake latency, and dropping that one packet costs a whole
/// connect timeout before anything retries. Natively the name lookup in the constructor blocks,
/// as a UDP join's does.
class WebSocketClientSocket : IDatagramSocket
{
	/// The one remote. The server gateway numbers its clients from one, so the client end takes
	/// two for its own local endpoint and never collides.
	public static DatagramEndpoint ServerEndpoint => WebSocketEndpoint.Make(1);

	public DatagramEndpoint LocalEndpoint => WebSocketEndpoint.Make(2);

#if BF_PLATFORM_WASM
	// The browser half. Callback driven, and without pthreads the callbacks run on the browser's
	// own event loop, which is the thread the frame runner is on: that is why the queues below
	// need no lock. Anything linking this needs `-lwebsocket.js`; see [[EmscriptenWebSocket]].

	private int32 mSocket = 0;
	private bool mOpen = false;
	private bool mFailed = false;

	/// Sends made before onopen, in order. Owned here until they go.
	private List<List<uint8>> mPendingSends = new .() ~ DeleteContainerAndItems!(_);
	private List<List<uint8>> mReceived = new .() ~ DeleteContainerAndItems!(_);
	/// How far Receive has walked mReceived. The list is only compacted once drained, so a
	/// burst of frames costs no shuffling per read.
	private int mReceivedHead = 0;

	/// Dials ws:// or wss://host:port/path. The browser resolves the host, so a name works as
	/// well as a dotted quad, and does its own TLS. Check IsOpen.
	public this(WebSocketClientConfig config)
	{
		if (!EmscriptenWebSocket.emscripten_websocket_is_supported())
		{
			mFailed = true;
			return;
		}

		let url = scope String(config.Secure ? "wss://" : "ws://");
		url.AppendF("{}:{}", config.Host, config.Port);
		url.Append(config.Path.IsEmpty ? "/" : config.Path);
		EmscriptenWebSocket.CreateAttributes attributes = .()
			{
				Url = url.CStr(),
				Protocols = null,
				CreateOnMainThread = true
			};

		mSocket = EmscriptenWebSocket.emscripten_websocket_new(&attributes);
		if (mSocket <= 0)
		{
			mFailed = true;
			return;
		}

		let self = Internal.UnsafeCastToPtr(this);
		EmscriptenWebSocket.emscripten_websocket_set_onopen_callback_on_thread(mSocket, self,
			=> OnOpen, EmscriptenWebSocket.CallingThread);
		EmscriptenWebSocket.emscripten_websocket_set_onmessage_callback_on_thread(mSocket, self,
			=> OnMessage, EmscriptenWebSocket.CallingThread);
		EmscriptenWebSocket.emscripten_websocket_set_onerror_callback_on_thread(mSocket, self,
			=> OnError, EmscriptenWebSocket.CallingThread);
		EmscriptenWebSocket.emscripten_websocket_set_onclose_callback_on_thread(mSocket, self,
			=> OnClose, EmscriptenWebSocket.CallingThread);
	}

	public ~this()
	{
		if (mSocket > 0)
		{
			EmscriptenWebSocket.emscripten_websocket_close(mSocket, 1000, "bye");
			EmscriptenWebSocket.emscripten_websocket_delete(mSocket);
		}
	}

	/// Created and not yet failed. TRUE BEFORE THE HANDSHAKE COMPLETES, which is the point:
	/// the caller may send immediately and the queue holds it.
	public bool IsOpen => mSocket > 0 && !mFailed;

	/// Whether the handshake has actually completed, for a caller that wants to wait.
	public bool IsConnected => mOpen && !mFailed;

	/// Why it failed or closed; empty while it lives. A browser keeps the reason from the page,
	/// so this says only that the connection failed.
	public StringView Failure => mFailed ? "the WebSocket connection failed or closed" : "";

	public void Send(DatagramEndpoint to, Span<uint8> data)
	{
		if (mFailed || mSocket <= 0)
			return;

		if (!mOpen)
		{
			let copy = new List<uint8>();
			copy.AddRange(data);
			mPendingSends.Add(copy);
			return;
		}

		EmscriptenWebSocket.emscripten_websocket_send_binary(mSocket, data.Ptr,
			(uint32)data.Length);
	}

	public bool Receive(out DatagramEndpoint outFrom, List<uint8> outData)
	{
		outFrom = default;
		if (mReceivedHead >= mReceived.Count)
			return false;

		outFrom = ServerEndpoint;
		// Null the slot BEFORE handing the payload on. The list is not compacted until it
		// drains, so a destruct part way through would otherwise free an entry twice.
		let payload = mReceived[mReceivedHead];
		mReceived[mReceivedHead] = null;
		mReceivedHead++;

		outData.Clear();
		// Span, not the list: AddRange(List) appends one element at a time.
		outData.AddRange(Span<uint8>(payload.Ptr, payload.Count));
		delete payload;

		if (mReceivedHead >= mReceived.Count)
		{
			mReceived.Clear();
			mReceivedHead = 0;
		}

		return true;
	}

	private static bool OnOpen(int32 eventType, EmscriptenWebSocket.OpenEvent* event,
		void* userData)
	{
		let self = (WebSocketClientSocket)Internal.UnsafeCastToObject(userData);
		self.mOpen = true;

		// Everything held back during the handshake, in the order it was written.
		for (let payload in self.mPendingSends)
		{
			EmscriptenWebSocket.emscripten_websocket_send_binary(self.mSocket, payload.Ptr,
				(uint32)payload.Count);
			delete payload;
		}
		self.mPendingSends.Clear();
		return true;
	}

	private static bool OnMessage(int32 eventType, EmscriptenWebSocket.MessageEvent* event,
		void* userData)
	{
		let self = (WebSocketClientSocket)Internal.UnsafeCastToObject(userData);
		if (event.IsText)
			return true; // the wire is binary; ignore stray text

		let payload = new List<uint8>();
		payload.AddRange(Span<uint8>(event.Data, (int)event.NumBytes));
		self.mReceived.Add(payload);
		return true;
	}

	private static bool OnError(int32 eventType, EmscriptenWebSocket.ErrorEvent* event,
		void* userData)
	{
		let self = (WebSocketClientSocket)Internal.UnsafeCastToObject(userData);
		self.mFailed = true;
		return true;
	}

	private static bool OnClose(int32 eventType, EmscriptenWebSocket.CloseEvent* event,
		void* userData)
	{
		let self = (WebSocketClientSocket)Internal.UnsafeCastToObject(userData);
		self.mOpen = false;
		self.mFailed = true;
		return true;
	}
#else
	// The native half: the client side of RFC 6455 over a plain or TLS stream. The upgrade
	// request goes at once (a TLS stream holds it until its handshake ends), the 101 is checked
	// against the key, then masked frames out and unmasked frames in. Pumped from Receive, which
	// the session drains every frame, as the hybrid socket pumps its gateway.

	private INetByteStream mStream ~ delete _;
	/// The Sec-WebSocket-Key sent.
	private String mKey = new .() ~ delete _;
	/// Live until the upgrade completes.
	private HttpMessageParser mHandshake ~ delete _;
	private WebSocketFrameParser mFrames = new .(false) ~ delete _;
	private WsFrame mScratchFrame = new .() ~ delete _;
	private bool mUpgraded = false;
	private bool mFailed = false;
	private String mFailure = new .() ~ delete _;
	/// Datagrams sent before the upgrade, in order.
	private List<List<uint8>> mPending = new .() ~ DeleteContainerAndItems!(_);
	private List<List<uint8>> mReceived = new .() ~ DeleteContainerAndItems!(_);
	private int mReceivedHead = 0;
	private Stopwatch mSinceStart = new .() ~ delete _;
	private double mUpgradeSeconds = 10.0;
	/// Masking keys and the handshake key: unpredictable to a page script is what the RFC asks
	/// (they defeat cache poisoning through proxies); a seeded PCG is not cryptographic, and
	/// over wss the TLS layer makes the mask moot.
	private Sedulous.Core.Random mRandom;

	/// Dials ws:// or wss://host:port/path; the name lookup blocks. Check IsOpen.
	public this(WebSocketClientConfig config)
	{
		mRandom = .((uint64)DateTime.UtcNow.Ticks ^ (uint64)(int)Internal.UnsafeCastToPtr(this));
		mSinceStart.Start();
		mUpgradeSeconds = config.UpgradeTimeoutSeconds;
		if (config.Secure && (config.Tls == null))
		{
			Fail("wss needs a TLS backend, and none was given");
			return;
		}
		let socket = TcpSocket.Connect(config.Host, config.Port);
		if (!socket.IsOpen)
		{
			delete socket;
			Fail(scope $"'{config.Host}' could not be found");
			return;
		}
		if (config.Secure)
		{
			let tls = scope TlsClientConfig();
			tls.ServerName.Set(config.Host);
			tls.Trust = config.Trust;
			tls.Roots.Pem.Set(config.TrustedPem);
			tls.Alpn.Add(new .("http/1.1"));
			mStream = new TlsStream(socket, config.Tls.CreateClient(tls));
		}
		else
			mStream = new PlainStream(socket);

		uint8[16] nonce = ?;
		for (int i = 0; i < nonce.Count; i += 4)
		{
			let r = mRandom.NextU32();
			nonce[i] = (uint8)r;
			nonce[i + 1] = (uint8)(r >> 8);
			nonce[i + 2] = (uint8)(r >> 16);
			nonce[i + 3] = (uint8)(r >> 24);
		}
		Base64.Encode(.(&nonce[0], nonce.Count), mKey);
		mHandshake = new .(.Response, 4096);
		let request = scope String("GET ");
		request.Append(config.Path.IsEmpty ? "/" : config.Path);
		request.AppendF(" HTTP/1.1\r\nHost: {}:{}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n", config.Host, config.Port);
		request.AppendF("Sec-WebSocket-Key: {}\r\nSec-WebSocket-Version: 13\r\n\r\n", mKey);
		if (mStream.Send(.((uint8*)request.Ptr, request.Length)) < 0)
			Fail("the connection closed before the upgrade went");
	}

	public ~this()
	{
		if (mStream != null)
		{
			if (mUpgraded && !mFailed)
				SendFrame(.Close, .());
			mStream.Close();
		}
	}

	/// Made and not failed. TRUE BEFORE THE UPGRADE COMPLETES: the caller may send at once and
	/// the queue holds it.
	public bool IsOpen => (mStream != null) && !mFailed;
	/// The upgrade done: sends go at once.
	public bool IsConnected => mUpgraded && !mFailed;
	/// Why it failed or closed, said for a person; empty while it lives.
	public StringView Failure => mFailure;

	public void Send(DatagramEndpoint to, Span<uint8> data)
	{
		if (mFailed || (mStream == null))
			return;
		if (!mUpgraded)
		{
			let copy = new List<uint8>();
			copy.AddRange(data);
			mPending.Add(copy);
			return;
		}
		SendFrame(.Binary, data);
	}

	public bool Receive(out DatagramEndpoint outFrom, List<uint8> outData)
	{
		outFrom = default;
		if ((mReceivedHead >= mReceived.Count) && (mStream != null))
		{
			ClearAndDeleteItems!(mReceived);
			mReceivedHead = 0;
			Pump();
		}
		if (mReceivedHead >= mReceived.Count)
			return false;
		outFrom = ServerEndpoint;
		let payload = mReceived[mReceivedHead];
		mReceived[mReceivedHead] = null;
		mReceivedHead++;
		outData.Clear();
		outData.AddRange(Span<uint8>(payload.Ptr, payload.Count));
		delete payload;
		return true;
	}

	private void Fail(StringView why)
	{
		if (mFailed)
			return;
		mFailed = true;
		mFailure.Set(why);
	}

	private void SendFrame(WsOpcode opcode, Span<uint8> payload)
	{
		let frame = scope List<uint8>();
		WebSocketFrame.Encode(opcode, payload, true, mRandom.NextU32(), frame);
		if (mStream.Send(frame) < 0)
			Fail("the connection closed");
	}

	/// The 101, checked: the status, the upgrade, and the accept key for ours.
	private void Upgrade()
	{
		if (mHandshake.Status != 101)
		{
			Fail(scope $"the server answered {mHandshake.Status} instead of upgrading to a WebSocket");
			return;
		}
		let accept = HttpHeader.Find(mHandshake.Headers, "Sec-WebSocket-Accept");
		if (accept != WebSocketHandshake.ComputeAccept(mKey, .. scope .()))
		{
			Fail("the server's upgrade does not answer this client's key");
			return;
		}
		mUpgraded = true;
		DeleteAndNullify!(mHandshake);
		for (let datagram in mPending)
			SendFrame(.Binary, datagram);
		ClearAndDeleteItems!(mPending);
	}

	private void Pump()
	{
		if (mFailed)
			return;
		let alive = mStream.Pump();
		uint8[4096] chunk = ?;
		while (!mFailed)
		{
			let got = mStream.Receive(.(&chunk[0], chunk.Count));
			if (got < 0)
			{
				Closed();
				return;
			}
			if (got == 0)
				break;
			var offset = 0;
			if (!mUpgraded)
			{
				// Byte-wise, so frames arriving with the 101 land in the frame parser.
				while ((offset < got) && !mUpgraded && !mFailed)
				{
					let state = mHandshake.Push(.(&chunk[offset], 1));
					offset++;
					if (state == .Failed)
						Fail("the server's answer is not HTTP");
					else if (state == .Complete)
						Upgrade();
				}
				if (!mUpgraded)
					continue;
			}
			mFrames.Push(.(&chunk[offset], (int)got - offset));
			if (mFrames.Failed)
			{
				Fail("the server sent a frame this client does not take");
				return;
			}
			while (!mFailed && mFrames.Next(mScratchFrame))
			{
				switch (mScratchFrame.Opcode)
				{
				case .Binary:
					let payload = new List<uint8>();
					payload.AddRange(mScratchFrame.Payload);
					mReceived.Add(payload);
				case .Ping:
					SendFrame(.Pong, mScratchFrame.Payload);
				case .Pong:
				case .Close:
					SendFrame(.Close, .());
					Fail("the server closed the connection");
				default:
					Fail("the server sent a frame this client does not take");
				}
			}
		}
		if (!alive && !mFailed)
			Closed();
		if (!mUpgraded && !mFailed && (mSinceStart.Elapsed.TotalSeconds > mUpgradeSeconds))
			Fail("the server did not upgrade the connection in time (is it a WebSocket host, and ws or wss as asked?)");
	}

	/// The stream ended: its own reason, or the server closing.
	private void Closed()
	{
		let why = mStream.Failure;
		if (why.IsEmpty)
			Fail("the server closed the connection");
		else
			Fail(why);
	}
#endif
}
