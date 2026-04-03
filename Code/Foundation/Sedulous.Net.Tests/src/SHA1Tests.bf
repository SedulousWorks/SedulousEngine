namespace Sedulous.Net.Tests;

using System;
using Sedulous.Net;

class SHA1Tests
{
	[Test]
	public static void Hash_Empty()
	{
		// SHA1("") = da39a3ee5e6b4b0d3255bfef95601890afd80709
		let hash = SHA1.Hash("");
		let str = scope String();
		hash.ToString(str);
		Test.Assert(str.Equals("da39a3ee5e6b4b0d3255bfef95601890afd80709"));
	}

	[Test]
	public static void Hash_abc()
	{
		// SHA1("abc") = a9993e364706816aba3e25717850c26c9cd0d89d
		let hash = SHA1.Hash("abc");
		let str = scope String();
		hash.ToString(str);
		Test.Assert(str.Equals("a9993e364706816aba3e25717850c26c9cd0d89d"));
	}

	[Test]
	public static void Hash_LongerString()
	{
		// SHA1("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
		// = 84983e441c3bd26ebaae4aa1f95129e5e54670f1
		let hash = SHA1.Hash("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq");
		let str = scope String();
		hash.ToString(str);
		Test.Assert(str.Equals("84983e441c3bd26ebaae4aa1f95129e5e54670f1"));
	}

	[Test]
	public static void Hash_WebSocketKey()
	{
		// The canonical WebSocket example from RFC 6455:
		// SHA1("dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
		// = b3 7a 4f 2c c0 62 4f 16 90 f6 46 06 cf 38 59 45 b2 be c4 ea
		let hash = SHA1.Hash("dGhlIHNhbXBsZSBub25jZQ==258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
		let str = scope String();
		hash.ToString(str);
		Test.Assert(str.Equals("b37a4f2cc0624f1690f64606cf385945b2bec4ea"));
	}

	[Test]
	public static void Hash_IncrementalUpdate()
	{
		// Hash "abc" incrementally: "a" + "bc"
		let sha = scope SHA1();
		StringView a = "a";
		StringView bc = "bc";
		sha.Update(Span<uint8>((uint8*)a.Ptr, a.Length));
		sha.Update(Span<uint8>((uint8*)bc.Ptr, bc.Length));
		let hash = sha.Finish();
		let str = scope String();
		hash.ToString(str);
		Test.Assert(str.Equals("a9993e364706816aba3e25717850c26c9cd0d89d"));
	}

	[Test]
	public static void Hash_SingleByte()
	{
		// SHA1("a") = 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8
		let hash = SHA1.Hash("a");
		let str = scope String();
		hash.ToString(str);
		Test.Assert(str.Equals("86f7e437faa5a7fce15d1ddcb9eaeaea377667b8"));
	}

	[Test]
	public static void Hash_ExactBlockSize()
	{
		// 64 bytes = exactly one SHA1 block
		// SHA1("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa") (64 'a')
		// = 0098ba824b5c16427bd7a1122a5a442a25ec644d
		let input = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
		Test.Assert(input.Length == 64);
		let hash = SHA1.Hash(input);
		let str = scope String();
		hash.ToString(str);
		Test.Assert(str.Equals("0098ba824b5c16427bd7a1122a5a442a25ec644d"));
	}

	[Test]
	public static void SHA1Hash_ToString()
	{
		let hash = SHA1.Hash("test");
		let str = scope String();
		hash.ToString(str);
		// Must be 40 hex chars
		Test.Assert(str.Length == 40);
		for (let c in str.RawChars)
			Test.Assert((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'));
	}
}
