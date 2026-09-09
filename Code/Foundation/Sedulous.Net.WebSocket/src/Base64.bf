using System;

namespace Sedulous.Net.WebSocket;

/// Base64 encoding, for the handshake accept value.
static class Base64
{
	private const String cTable =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	/// Appends the encoding of `data` to outText.
	public static void Encode(Span<uint8> data, String outText)
	{
		var i = 0;
		// Three bytes make four characters, with no padding needed.
		for (; (i + 3) <= data.Length; i += 3)
		{
			let value = ((uint32)data[i] << 16) | ((uint32)data[i + 1] << 8) | (uint32)data[i + 2];
			outText.Append(cTable[(int)((value >> 18) & 0x3F)]);
			outText.Append(cTable[(int)((value >> 12) & 0x3F)]);
			outText.Append(cTable[(int)((value >> 6) & 0x3F)]);
			outText.Append(cTable[(int)(value & 0x3F)]);
		}

		// The tail, padded with equals signs so the length stays a multiple of four.
		let rest = data.Length - i;
		if (rest == 1)
		{
			let value = (uint32)data[i] << 16;
			outText.Append(cTable[(int)((value >> 18) & 0x3F)]);
			outText.Append(cTable[(int)((value >> 12) & 0x3F)]);
			outText.Append("==");
		}
		else if (rest == 2)
		{
			let value = ((uint32)data[i] << 16) | ((uint32)data[i + 1] << 8);
			outText.Append(cTable[(int)((value >> 18) & 0x3F)]);
			outText.Append(cTable[(int)((value >> 12) & 0x3F)]);
			outText.Append(cTable[(int)((value >> 6) & 0x3F)]);
			outText.Append('=');
		}
	}
}
