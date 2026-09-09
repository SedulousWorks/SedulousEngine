using System;
using System.Collections;

namespace Sedulous.Net.WebSocket;

/// The frame codec.
static class WebSocketFrame
{
	/// The largest frame this server will decode. A game packet is orders of magnitude
	/// smaller, so anything past this is a mistake or an attack, not a big message.
	public const int MaxFrameBytes = 1024 * 1024;

	/// Appends one whole frame.
	///
	/// The RFC is asymmetric on masking: a CLIENT must mask and a SERVER must not, so
	/// `mask` says which side is being written rather than being a choice.
	public static void Encode(WsOpcode opcode, Span<uint8> payload, bool mask, uint32 maskingKey,
		List<uint8> outBytes)
	{
		// The high bit is FIN: this codec never fragments, so every frame is final.
		outBytes.Add((uint8)(0x80 | (uint8)opcode));

		let maskBit = mask ? (uint8)0x80 : (uint8)0x00;
		if (payload.Length < 126)
		{
			outBytes.Add(maskBit | (uint8)payload.Length);
		}
		else if (payload.Length <= 0xFFFF)
		{
			// The 126 marker means a sixteen bit length follows, big endian.
			outBytes.Add(maskBit | 126);
			outBytes.Add((uint8)((payload.Length >> 8) & 0xFF));
			outBytes.Add((uint8)(payload.Length & 0xFF));
		}
		else
		{
			outBytes.Add(maskBit | 127);
			for (int shift = 56; shift >= 0; shift -= 8)
				outBytes.Add((uint8)(((uint64)payload.Length >> shift) & 0xFF));
		}

		if (!mask)
		{
			outBytes.AddRange(payload);
			return;
		}

		let key = scope uint8[4](
			(uint8)((maskingKey >> 24) & 0xFF),
			(uint8)((maskingKey >> 16) & 0xFF),
			(uint8)((maskingKey >> 8) & 0xFF),
			(uint8)(maskingKey & 0xFF));
		outBytes.AddRange(key);
		for (int i = 0; i < payload.Length; i++)
			outBytes.Add(payload[i] ^ key[i % 4]);
	}
}
