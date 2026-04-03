namespace Sedulous.Net.HTTP;

using System;
using System.Collections;
using Sedulous.Net;

/// WebSocket frame encoder/decoder (RFC 6455 Section 5).
public static class WebSocketFrame
{
	/// Encode a WebSocket frame into the buffer.
	/// If maskKey is provided (non-null), the payload is masked (required for client->server).
	public static void Encode(List<uint8> buffer, WebSocketOpCode opcode, Span<uint8> payload, uint8[4]* maskKey = null)
	{
		// First byte: FIN=1 + opcode
		buffer.Add(0x80 | (uint8)opcode);

		// Second byte: MASK bit + payload length
		let maskBit = (maskKey != null) ? (uint8)0x80 : (uint8)0x00;

		if (payload.Length < 126)
		{
			buffer.Add(maskBit | (uint8)payload.Length);
		}
		else if (payload.Length <= 65535)
		{
			buffer.Add(maskBit | 126);
			NetWriter.WriteUInt16(buffer, (uint16)payload.Length);
		}
		else
		{
			buffer.Add(maskBit | 127);
			NetWriter.WriteUInt64(buffer, (uint64)payload.Length);
		}

		// Mask key
		if (maskKey != null)
		{
			buffer.Add((*maskKey)[0]);
			buffer.Add((*maskKey)[1]);
			buffer.Add((*maskKey)[2]);
			buffer.Add((*maskKey)[3]);
		}

		// Payload (masked if needed)
		if (maskKey != null)
		{
			for (int i = 0; i < payload.Length; i++)
				buffer.Add(payload[i] ^ (*maskKey)[i % 4]);
		}
		else
		{
			buffer.AddRange(payload);
		}
	}

	/// Encode a text frame.
	public static void EncodeText(List<uint8> buffer, StringView text, uint8[4]* maskKey = null)
	{
		Encode(buffer, .Text, Span<uint8>((uint8*)text.Ptr, text.Length), maskKey);
	}

	/// Encode a binary frame.
	public static void EncodeBinary(List<uint8> buffer, Span<uint8> data, uint8[4]* maskKey = null)
	{
		Encode(buffer, .Binary, data, maskKey);
	}

	/// Encode a close frame.
	public static void EncodeClose(List<uint8> buffer, uint16 statusCode = 1000, uint8[4]* maskKey = null)
	{
		uint8[2] payload = default;
		payload[0] = (uint8)(statusCode >> 8);
		payload[1] = (uint8)(statusCode);
		Encode(buffer, .Close, Span<uint8>(&payload, 2), maskKey);
	}

	/// Encode a ping frame.
	public static void EncodePing(List<uint8> buffer, Span<uint8> payload = default, uint8[4]* maskKey = null)
	{
		Encode(buffer, .Ping, payload, maskKey);
	}

	/// Encode a pong frame.
	public static void EncodePong(List<uint8> buffer, Span<uint8> payload = default, uint8[4]* maskKey = null)
	{
		Encode(buffer, .Pong, payload, maskKey);
	}

	/// Result of decoding a frame.
	public struct DecodedFrame
	{
		public bool Fin;
		public WebSocketOpCode OpCode;
		public bool Masked;
		public List<uint8> Payload;
		public int BytesConsumed;
	}

	/// Try to decode a WebSocket frame from data.
	/// Returns .Ok with the decoded frame, or .Err if insufficient data.
	/// Caller owns the Payload list in the result.
	public static Result<DecodedFrame> Decode(Span<uint8> data)
	{
		if (data.Length < 2)
			return .Err;

		int offset = 0;
		let byte0 = data[offset++];
		let byte1 = data[offset++];

		let fin = (byte0 & 0x80) != 0;
		let opcode = (WebSocketOpCode)(byte0 & 0x0F);
		let masked = (byte1 & 0x80) != 0;
		var payloadLen = (uint64)(byte1 & 0x7F);

		if (payloadLen == 126)
		{
			if (data.Length < offset + 2) return .Err;
			if (NetReader.ReadUInt16(data, offset) case .Ok(let len))
				payloadLen = len;
			else
				return .Err;
			offset += 2;
		}
		else if (payloadLen == 127)
		{
			if (data.Length < offset + 8) return .Err;
			if (NetReader.ReadUInt64(data, offset) case .Ok(let len))
				payloadLen = len;
			else
				return .Err;
			offset += 8;
		}

		uint8[4] maskKey = default;
		if (masked)
		{
			if (data.Length < offset + 4) return .Err;
			maskKey[0] = data[offset++];
			maskKey[1] = data[offset++];
			maskKey[2] = data[offset++];
			maskKey[3] = data[offset++];
		}

		if (data.Length < offset + (int)payloadLen)
			return .Err;

		let payload = new List<uint8>((int)payloadLen);
		for (int i = 0; i < (int)payloadLen; i++)
		{
			var b = data[offset + i];
			if (masked)
				b ^= maskKey[i % 4];
			payload.Add(b);
		}

		offset += (int)payloadLen;

		DecodedFrame result;
		result.Fin = fin;
		result.OpCode = opcode;
		result.Masked = masked;
		result.Payload = payload;
		result.BytesConsumed = offset;
		return .Ok(result);
	}
}
