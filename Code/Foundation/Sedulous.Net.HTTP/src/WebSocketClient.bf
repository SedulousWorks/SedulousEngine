namespace Sedulous.Net.HTTP;

using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Net;

/// WebSocket connection state.
public enum WebSocketState
{
	case Connecting;
	case Open;
	case Closing;
	case Closed;
}

/// WebSocket message received from a connection.
public class WebSocketMessage
{
	public WebSocketOpCode OpCode;
	public List<uint8> Data ~ delete _;

	public this(WebSocketOpCode opCode, List<uint8> data)
	{
		OpCode = opCode;
		Data = data;
	}

	public void GetText(String outStr)
	{
		if (Data != null && Data.Count > 0)
			outStr.Append((char8*)Data.Ptr, Data.Count);
	}
}

/// WebSocket client. Connects to a WebSocket server via HTTP upgrade handshake.
public class WebSocketClient
{
	private TcpClient mTcp = new .() ~ delete _;
	private WebSocketState mState = .Closed;
	private List<uint8> mRecvBuffer = new .() ~ delete _;
	private String mExpectedAcceptKey = new .() ~ delete _;

	public WebSocketState State => mState;

	/// Connect to a WebSocket server.
	/// url should be like "ws://host:port/path" or just "host:port/path".
	public Result<void, NetError> Connect(StringView host, uint16 port, StringView path = "/")
	{
		if (mState != .Closed)
			return .Err(.InvalidState);

		mState = .Connecting;

		if (mTcp.Connect(host, port) case .Err(let err))
		{
			mState = .Closed;
			return .Err(err);
		}

		// Generate WebSocket key (16 random bytes, base64-encoded)
		let key = GenerateKey();
		defer delete key;

		// Compute expected accept key
		ComputeAcceptKey(key, mExpectedAcceptKey);

		// Build upgrade request
		let request = scope String();
		request.AppendF("GET {} HTTP/1.1\r\n", path);
		request.AppendF("Host: {}:{}\r\n", host, port);
		request.Append("Upgrade: websocket\r\n");
		request.Append("Connection: Upgrade\r\n");
		request.AppendF("Sec-WebSocket-Key: {}\r\n", key);
		request.Append("Sec-WebSocket-Version: 13\r\n");
		request.Append("\r\n");

		if (mTcp.SendAll(Span<uint8>((uint8*)request.Ptr, request.Length)) case .Err(let sendErr))
		{
			mState = .Closed;
			return .Err(sendErr);
		}

		// Read upgrade response
		uint8[1024] recvBuf = default;
		let responseStr = scope String();
		int elapsed = 0;

		while (elapsed < 5000)
		{
			switch (mTcp.Recv(Span<uint8>(&recvBuf, 1024)))
			{
			case .Ok(let received):
				if (received == 0)
				{
					mState = .Closed;
					return .Err(.ConnectionClosed);
				}
				responseStr.Append((char8*)&recvBuf, received);
				if (responseStr.Contains("\r\n\r\n"))
				{
					// Verify 101 Switching Protocols
					if (!responseStr.StartsWith("HTTP/1.1 101"))
					{
						mState = .Closed;
						return .Err(.ProtocolError);
					}
					mState = .Open;
					return .Ok;
				}
			case .Err(.WouldBlock):
				System.Threading.Thread.Sleep(10);
				elapsed += 10;
			case .Err(let recvErr):
				mState = .Closed;
				return .Err(recvErr);
			}
		}

		mState = .Closed;
		return .Err(.TimedOut);
	}

	/// Send a text message.
	public Result<void, NetError> SendText(StringView text)
	{
		if (mState != .Open)
			return .Err(.InvalidState);

		let frame = scope List<uint8>();
		var maskKey = GenerateMaskKey();
		WebSocketFrame.EncodeText(frame, text, &maskKey);
		return SendFrame(frame);
	}

	/// Send a binary message.
	public Result<void, NetError> SendBinary(Span<uint8> data)
	{
		if (mState != .Open)
			return .Err(.InvalidState);

		let frame = scope List<uint8>();
		var maskKey = GenerateMaskKey();
		WebSocketFrame.EncodeBinary(frame, data, &maskKey);
		return SendFrame(frame);
	}

	/// Send a ping.
	public Result<void, NetError> SendPing(Span<uint8> payload = default)
	{
		if (mState != .Open)
			return .Err(.InvalidState);

		let frame = scope List<uint8>();
		var maskKey = GenerateMaskKey();
		WebSocketFrame.EncodePing(frame, payload, &maskKey);
		return SendFrame(frame);
	}

	/// Initiate close handshake.
	public Result<void, NetError> Close(uint16 statusCode = 1000)
	{
		if (mState != .Open)
			return .Err(.InvalidState);

		mState = .Closing;
		let frame = scope List<uint8>();
		var maskKey = GenerateMaskKey();
		WebSocketFrame.EncodeClose(frame, statusCode, &maskKey);
		let result = SendFrame(frame);
		mState = .Closed;
		mTcp.Close();
		return result;
	}

	/// Non-blocking receive. Returns null if no complete message is available.
	public WebSocketMessage Receive()
	{
		if (mState != .Open && mState != .Closing)
			return null;

		// Try to read from TCP
		uint8[4096] recvBuf = default;
		switch (mTcp.Recv(Span<uint8>(&recvBuf, 4096)))
		{
		case .Ok(let received):
			if (received > 0)
				mRecvBuffer.AddRange(Span<uint8>(&recvBuf, received));
		case .Err:
		}

		// Try to decode a frame
		if (mRecvBuffer.Count == 0)
			return null;

		switch (WebSocketFrame.Decode(Span<uint8>(mRecvBuffer.Ptr, mRecvBuffer.Count)))
		{
		case .Ok(let frame):
			// Remove consumed bytes
			mRecvBuffer.RemoveRange(0, frame.BytesConsumed);

			// Handle control frames internally
			switch (frame.OpCode)
			{
			case .Ping:
				// Auto-respond with pong
				let pongFrame = scope List<uint8>();
				var maskKey = GenerateMaskKey();
				WebSocketFrame.EncodePong(pongFrame, Span<uint8>(frame.Payload.Ptr, frame.Payload.Count), &maskKey);
				SendFrame(pongFrame);
				delete frame.Payload;
				return null;
			case .Pong:
				delete frame.Payload;
				return null;
			case .Close:
				if (mState == .Open)
				{
					// Respond with close
					mState = .Closing;
					let closeFrame = scope List<uint8>();
					var maskKey = GenerateMaskKey();
					WebSocketFrame.EncodeClose(closeFrame, 1000, &maskKey);
					SendFrame(closeFrame);
				}
				mState = .Closed;
				mTcp.Close();
				delete frame.Payload;
				return null;
			default:
				return new WebSocketMessage(frame.OpCode, frame.Payload);
			}
		case .Err:
			return null; // Need more data
		}
	}

	/// Compute the Sec-WebSocket-Accept value from a client key.
	public static void ComputeAcceptKey(StringView clientKey, String outAcceptKey)
	{
		let combined = scope String();
		combined.Append(clientKey);
		combined.Append("258EAFA5-E914-47DA-95CA-C5AB0DC85B11");

		var hash = SHA1.Hash(combined);
		Base64.Encode(Span<uint8>(&hash.mHash, 20), outAcceptKey);
	}

	private Result<void, NetError> SendFrame(List<uint8> frame)
	{
		return mTcp.SendAll(Span<uint8>(frame.Ptr, frame.Count));
	}

	private static String GenerateKey()
	{
		// Generate 16 random bytes and base64 encode
		uint8[16] keyBytes = default;
		let rand = scope Random();
		for (int i = 0; i < 16; i++)
			keyBytes[i] = (uint8)rand.Next(256);

		let encoded = new String();
		Base64.Encode(Span<uint8>(&keyBytes, 16), encoded);
		return encoded;
	}

	private static uint8[4] GenerateMaskKey()
	{
		uint8[4] key = default;
		let rand = scope Random();
		for (int i = 0; i < 4; i++)
			key[i] = (uint8)rand.Next(256);
		return key;
	}
}
