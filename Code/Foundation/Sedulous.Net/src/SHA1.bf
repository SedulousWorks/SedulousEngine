namespace Sedulous.Net;

using System;

struct SHA1Hash
{
	public uint8[20] mHash;

	public override void ToString(String strBuffer)
	{
		for (int i = 0; i < 20; i++)
			strBuffer.AppendF("{:x2}", mHash[i]);
	}
}

/// SHA1 hash implementation (RFC 3174).
/// Used for WebSocket Sec-WebSocket-Accept header computation.
class SHA1
{
	private uint32[5] mState;
	private uint8[64] mBlock;
	private int mBlockLen;
	private uint64 mTotalLen;

	public this()
	{
		mState[0] = 0x67452301;
		mState[1] = 0xEFCDAB89;
		mState[2] = 0x98BADCFE;
		mState[3] = 0x10325476;
		mState[4] = 0xC3D2E1F0;
		mBlockLen = 0;
		mTotalLen = 0;
	}

	public void Update(Span<uint8> data)
	{
		for (int i = 0; i < data.Length; i++)
		{
			mBlock[mBlockLen++] = data[i];
			mTotalLen++;
			if (mBlockLen == 64)
			{
				ProcessBlock();
				mBlockLen = 0;
			}
		}
	}

	public SHA1Hash Finish()
	{
		let bitLen = mTotalLen * 8;

		// Append padding bit
		mBlock[mBlockLen++] = 0x80;
		if (mBlockLen > 56)
		{
			while (mBlockLen < 64)
				mBlock[mBlockLen++] = 0;
			ProcessBlock();
			mBlockLen = 0;
		}
		while (mBlockLen < 56)
			mBlock[mBlockLen++] = 0;

		// Append length in bits (big-endian)
		mBlock[56] = (uint8)(bitLen >> 56);
		mBlock[57] = (uint8)(bitLen >> 48);
		mBlock[58] = (uint8)(bitLen >> 40);
		mBlock[59] = (uint8)(bitLen >> 32);
		mBlock[60] = (uint8)(bitLen >> 24);
		mBlock[61] = (uint8)(bitLen >> 16);
		mBlock[62] = (uint8)(bitLen >> 8);
		mBlock[63] = (uint8)(bitLen);
		ProcessBlock();

		SHA1Hash hash = default;
		for (int i = 0; i < 5; i++)
		{
			hash.mHash[i * 4]     = (uint8)(mState[i] >> 24);
			hash.mHash[i * 4 + 1] = (uint8)(mState[i] >> 16);
			hash.mHash[i * 4 + 2] = (uint8)(mState[i] >> 8);
			hash.mHash[i * 4 + 3] = (uint8)(mState[i]);
		}
		return hash;
	}

	public static SHA1Hash Hash(Span<uint8> data)
	{
		let sha = scope SHA1();
		sha.Update(data);
		return sha.Finish();
	}

	public static SHA1Hash Hash(StringView str)
	{
		return Hash(Span<uint8>((uint8*)str.Ptr, str.Length));
	}

	private void ProcessBlock()
	{
		uint32[80] w = default;

		for (int i = 0; i < 16; i++)
		{
			w[i] = ((uint32)mBlock[i * 4] << 24) | ((uint32)mBlock[i * 4 + 1] << 16) |
				((uint32)mBlock[i * 4 + 2] << 8) | mBlock[i * 4 + 3];
		}

		for (int i = 16; i < 80; i++)
		{
			let val = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16];
			w[i] = RotLeft(val, 1);
		}

		var a = mState[0];
		var b = mState[1];
		var c = mState[2];
		var d = mState[3];
		var e = mState[4];

		for (int i = 0; i < 80; i++)
		{
			uint32 f, k;
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

			let temp = RotLeft(a, 5) &+ f &+ e &+ k &+ w[i];
			e = d;
			d = c;
			c = RotLeft(b, 30);
			b = a;
			a = temp;
		}

		mState[0] &+= a;
		mState[1] &+= b;
		mState[2] &+= c;
		mState[3] &+= d;
		mState[4] &+= e;
	}

	private static uint32 RotLeft(uint32 val, int bits)
	{
		return (val << bits) | (val >> (32 - bits));
	}
}
