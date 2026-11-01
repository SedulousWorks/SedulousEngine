using System;

namespace Sedulous.Core;

/// A SHA-256 digest: 32 bytes.
struct Sha256Digest : IEquatable<Sha256Digest>
{
	public uint8[32] Bytes;

	/// Its 64 lowercase hex digits, as published digests are written, appended to `outHex`.
	public void ToHex(String outHex)
	{
		const String cDigits = "0123456789abcdef";
		for (let b in Bytes)
		{
			outHex.Append(cDigits[b >> 4]);
			outHex.Append(cDigits[b & 0x0F]);
		}
	}

	public bool Equals(Sha256Digest other)
	{
		for (int i < 32)
		{
			if (Bytes[i] != other.Bytes[i])
				return false;
		}
		return true;
	}

	public static bool operator==(Sha256Digest a, Sha256Digest b) => a.Equals(b);
}

/// SHA-256 (FIPS 180-4) over bytes given in any number of pieces: Update with each, then Finish
/// once. For checking a download against the digest its publisher gives (a release's
/// samples.json), hashing each piece as it arrives. Not for passwords or keys: the TLS backend has
/// the crypto for those.
///
/// Every addition wraps (&+), as the algorithm relies on, where plain arithmetic would trap with
/// overflow checks on.
class Sha256
{
	private static uint32[64] sRounds = .(
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
		0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
		0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
		0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
		0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
		0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2);

	private uint32[8] mState = .(0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19);
	private uint8[64] mBlock = .();
	private int mUsed = 0;
	private uint64 mLength = 0;

	public void Update(Span<uint8> bytes)
	{
		for (let b in bytes)
		{
			mBlock[mUsed++] = b;
			if (mUsed == 64)
			{
				Compress();
				mUsed = 0;
			}
		}
		mLength += (uint64)bytes.Length;
	}

	/// The digest of everything given. The hash is spent after this; make a new one to go on.
	public Sha256Digest Finish()
	{
		let bits = mLength &* 8;
		mBlock[mUsed++] = 0x80;
		if (mUsed > 56)
		{
			while (mUsed < 64)
				mBlock[mUsed++] = 0;
			Compress();
			mUsed = 0;
		}
		while (mUsed < 56)
			mBlock[mUsed++] = 0;
		for (int i = 7; i >= 0; i--)
			mBlock[mUsed++] = (uint8)(bits >> (i * 8));
		Compress();
		Sha256Digest digest = default;
		for (int i < 8)
		{
			for (int k < 4)
				digest.Bytes[i * 4 + k] = (uint8)(mState[i] >> (24 - 8 * k));
		}
		return digest;
	}

	/// The digest of `bytes` in one call.
	public static Sha256Digest Of(Span<uint8> bytes)
	{
		let hash = scope Sha256();
		hash.Update(bytes);
		return hash.Finish();
	}

	private static uint32 Rotate(uint32 v, int n) => (v >> n) | (v << (32 - n));

	private void Compress()
	{
		uint32[64] w = ?;
		for (int i < 16)
			w[i] = ((uint32)mBlock[i * 4] << 24) | ((uint32)mBlock[i * 4 + 1] << 16) | ((uint32)mBlock[i * 4 + 2] << 8) | (uint32)mBlock[i * 4 + 3];
		for (int i = 16; i < 64; i++)
		{
			let s0 = Rotate(w[i - 15], 7) ^ Rotate(w[i - 15], 18) ^ (w[i - 15] >> 3);
			let s1 = Rotate(w[i - 2], 17) ^ Rotate(w[i - 2], 19) ^ (w[i - 2] >> 10);
			w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1;
		}
		var a = mState[0];
		var b = mState[1];
		var c = mState[2];
		var d = mState[3];
		var e = mState[4];
		var f = mState[5];
		var g = mState[6];
		var h = mState[7];
		for (int i < 64)
		{
			let s1 = Rotate(e, 6) ^ Rotate(e, 11) ^ Rotate(e, 25);
			let choose = (e & f) ^ (~e & g);
			let t1 = h &+ s1 &+ choose &+ sRounds[i] &+ w[i];
			let s0 = Rotate(a, 2) ^ Rotate(a, 13) ^ Rotate(a, 22);
			let majority = (a & b) ^ (a & c) ^ (b & c);
			let t2 = s0 &+ majority;
			h = g;
			g = f;
			f = e;
			e = d &+ t1;
			d = c;
			c = b;
			b = a;
			a = t1 &+ t2;
		}
		mState[0] &+= a;
		mState[1] &+= b;
		mState[2] &+= c;
		mState[3] &+= d;
		mState[4] &+= e;
		mState[5] &+= f;
		mState[6] &+= g;
		mState[7] &+= h;
	}
}
