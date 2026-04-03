namespace Sedulous.Net.HTTP;

using System;
using System.Collections;
using Sedulous.Net;

/// Server-side WebSocket connection.
/// Created when a client upgrades an HTTP connection to WebSocket.
public class WebSocketConnection
{
	private TcpClient mTcp;
	private bool mOwnsTcp;
	private WebSocketState mState = .Closed;
	private List<uint8> mRecvBuffer = new .() ~ delete _;

	public WebSocketState State => mState;

	/// Accept a WebSocket upgrade from a client HTTP request.
	/// Takes ownership of the TcpClient if ownsTcp is true.
	public Result<void, NetError> AcceptUpgrade(TcpClient tcp, HttpRequest request, bool ownsTcp = false)
	{
		mTcp = tcp;
		mOwnsTcp = ownsTcp;

		// Get the client key
		let clientKey = scope String();
		if (!request.Headers.Get("Sec-WebSocket-Key", clientKey))
			return .Err(.ProtocolError);

		// Compute accept key
		let acceptKey = scope String();
		WebSocketClient.ComputeAcceptKey(clientKey, acceptKey);

		// Send upgrade response
		let response = scope String();
		response.Append("HTTP/1.1 101 Switching Protocols\r\n");
		response.Append("Upgrade: websocket\r\n");
		response.Append("Connection: Upgrade\r\n");
		response.AppendF("Sec-WebSocket-Accept: {}\r\n", acceptKey);
		response.Append("\r\n");

		if (mTcp.SendAll(Span<uint8>((uint8*)response.Ptr, response.Length)) case .Err(let err))
			return .Err(err);

		mState = .Open;
		return .Ok;
	}

	public ~this()
	{
		if (mOwnsTcp)
			delete mTcp;
	}

	/// Send a text message (server-side: no masking).
	public Result<void, NetError> SendText(StringView text)
	{
		if (mState != .Open)
			return .Err(.InvalidState);

		let frame = scope List<uint8>();
		WebSocketFrame.EncodeText(frame, text);
		return SendFrame(frame);
	}

	/// Send a binary message.
	public Result<void, NetError> SendBinary(Span<uint8> data)
	{
		if (mState != .Open)
			return .Err(.InvalidState);

		let frame = scope List<uint8>();
		WebSocketFrame.EncodeBinary(frame, data);
		return SendFrame(frame);
	}

	/// Send a ping.
	public Result<void, NetError> SendPing(Span<uint8> payload = default)
	{
		if (mState != .Open)
			return .Err(.InvalidState);

		let frame = scope List<uint8>();
		WebSocketFrame.EncodePing(frame, payload);
		return SendFrame(frame);
	}

	/// Initiate close.
	public Result<void, NetError> Close(uint16 statusCode = 1000)
	{
		if (mState != .Open)
			return .Err(.InvalidState);

		mState = .Closing;
		let frame = scope List<uint8>();
		WebSocketFrame.EncodeClose(frame, statusCode);
		let result = SendFrame(frame);
		mState = .Closed;
		return result;
	}

	/// Non-blocking receive.
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

		if (mRecvBuffer.Count == 0)
			return null;

		switch (WebSocketFrame.Decode(Span<uint8>(mRecvBuffer.Ptr, mRecvBuffer.Count)))
		{
		case .Ok(let frame):
			mRecvBuffer.RemoveRange(0, frame.BytesConsumed);

			switch (frame.OpCode)
			{
			case .Ping:
				let pongFrame = scope List<uint8>();
				WebSocketFrame.EncodePong(pongFrame, Span<uint8>(frame.Payload.Ptr, frame.Payload.Count));
				SendFrame(pongFrame);
				delete frame.Payload;
				return null;
			case .Pong:
				delete frame.Payload;
				return null;
			case .Close:
				if (mState == .Open)
				{
					mState = .Closing;
					let closeFrame = scope List<uint8>();
					WebSocketFrame.EncodeClose(closeFrame, 1000);
					SendFrame(closeFrame);
				}
				mState = .Closed;
				delete frame.Payload;
				return null;
			default:
				return new WebSocketMessage(frame.OpCode, frame.Payload);
			}
		case .Err:
			return null;
		}
	}

	private Result<void, NetError> SendFrame(List<uint8> frame)
	{
		return mTcp.SendAll(Span<uint8>(frame.Ptr, frame.Count));
	}
}
