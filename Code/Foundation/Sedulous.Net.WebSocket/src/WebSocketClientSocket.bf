using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.WebSocket;

#if BF_PLATFORM_WASM
/// The BROWSER half: one websocket to a native host's gateway, presented as an
/// IDatagramSocket.
///
/// This is the other end of [[WebSocketServerGateway]]. Each binary frame is one datagram and
/// there is only ever one remote, so the session, reliability and replication layers above
/// cannot tell it from a UDP socket and need no branch of their own.
///
/// The handshake is ASYNC. A send before the socket opens QUEUES rather than being dropped,
/// which is not a nicety: the session fires its connect packet the instant it is created,
/// well inside the handshake latency, and dropping that one packet costs a whole connect
/// timeout before anything retries.
///
/// Callback driven, and without pthreads the callbacks run on the browser's own event loop,
/// which is the thread the frame runner is on. That is why the queues below need no lock.
///
/// Anything linking this needs `-lwebsocket.js`; see [[EmscriptenWebSocket]].
class WebSocketClientSocket : IDatagramSocket
{
	/// The one remote. The server gateway numbers its clients from one, so the browser end
	/// takes two for its own local endpoint and never collides.
	public static DatagramEndpoint ServerEndpoint => WebSocketEndpoint.Make(1);

	private int32 mSocket = 0;
	private bool mOpen = false;
	private bool mFailed = false;

	/// Sends made before onopen, in order. Owned here until they go.
	private List<List<uint8>> mPendingSends = new .() ~ DeleteContainerAndItems!(_);
	private List<List<uint8>> mReceived = new .() ~ DeleteContainerAndItems!(_);
	/// How far Receive has walked mReceived. The list is only compacted once drained, so a
	/// burst of frames costs no shuffling per read.
	private int mReceivedHead = 0;

	/// Dials ws://host:port. The browser resolves the host, so a name works as well as a
	/// dotted quad. Check IsOpen.
	public this(StringView host, uint16 port)
	{
		if (!EmscriptenWebSocket.emscripten_websocket_is_supported())
		{
			mFailed = true;
			return;
		}

		let url = scope $"ws://{host}:{port}";
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
	public bool IsConnected => mOpen;

	public DatagramEndpoint LocalEndpoint => WebSocketEndpoint.Make(2);

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
}
#endif
