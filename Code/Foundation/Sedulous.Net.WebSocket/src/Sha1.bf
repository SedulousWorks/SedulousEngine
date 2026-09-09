using System;
using System.Collections;

namespace Sedulous.Net.WebSocket;

/// SHA-1, for the handshake accept key ONLY.
///
/// Hand rolled because it is tiny and fixed by the RFC, and because the accept value is an
/// ECHO rather than a secret: the client proves nothing by computing it, so SHA-1 being
/// broken for collision resistance does not matter here. Do not reach for this as a general
/// hashing service.
static class Sha1
{
	public const int DigestBytes = 20;

	/// The digest of `data` into outDigest, which must hold twenty bytes.
	public static void Compute(Span<uint8> data, Span<uint8> outDigest)
	{
		uint32[5] h = .(0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0);

		// The padded message: the data, a one bit, zeros, and the length in bits as a big
		// endian sixty four bit value.
		let padded = scope List<uint8>();
		padded.AddRange(data);
		padded.Add(0x80);
		while ((padded.Count % 64) != 56)
			padded.Add(0);

		let bitLength = (uint64)data.Length * 8;
		for (int shift = 56; shift >= 0; shift -= 8)
			padded.Add((uint8)((bitLength >> shift) & 0xFF));

		uint32[80] w = .();
		for (int block = 0; block < padded.Count; block += 64)
		{
			for (int i = 0; i < 16; i++)
			{
				let at = block + i * 4;
				w[i] = ((uint32)padded[at] << 24) | ((uint32)padded[at + 1] << 16)
					| ((uint32)padded[at + 2] << 8) | (uint32)padded[at + 3];
			}
			for (int i = 16; i < 80; i++)
				w[i] = RotateLeft(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);

			var a = h[0];
			var b = h[1];
			var c = h[2];
			var d = h[3];
			var e = h[4];

			for (int i = 0; i < 80; i++)
			{
				uint32 f = 0;
				uint32 k = 0;
				if (i < 20)
				{
					f = (b & c) | ((~b) & d);
					k = 0x5A827999;
				}
				else if (i < 40)
				{
					f = b ^ c ^ d;
					k = 0x6ED9EBA1;
				}
				else if (i < 60)
				{
					f = (b & c) | (b & d) | (c & d);
					k = 0x8F1BBCDC;
				}
				else
				{
					f = b ^ c ^ d;
					k = 0xCA62C1D6;
				}

				// Wrapping throughout: SHA-1 is defined modulo two to the thirty two, and the
				// plain operators trap wherever overflow checks are on.
				let temp = RotateLeft(a, 5) &+ f &+ e &+ k &+ w[i];
				e = d;
				d = c;
				c = RotateLeft(b, 30);
				b = a;
				a = temp;
			}

			h[0] = h[0] &+ a;
			h[1] = h[1] &+ b;
			h[2] = h[2] &+ c;
			h[3] = h[3] &+ d;
			h[4] = h[4] &+ e;
		}

		for (int i = 0; i < 5; i++)
		{
			outDigest[i * 4 + 0] = (uint8)((h[i] >> 24) & 0xFF);
			outDigest[i * 4 + 1] = (uint8)((h[i] >> 16) & 0xFF);
			outDigest[i * 4 + 2] = (uint8)((h[i] >> 8) & 0xFF);
			outDigest[i * 4 + 3] = (uint8)(h[i] & 0xFF);
		}
	}

	private static uint32 RotateLeft(uint32 value, uint32 bits) =>
		(value << bits) | (value >> (32 - bits));
}
