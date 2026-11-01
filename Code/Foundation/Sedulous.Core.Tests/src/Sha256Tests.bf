using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// SHA-256 against the published test vectors (FIPS 180-4's examples, and the million 'a's), in
/// one piece and fed in pieces that straddle its 64-byte blocks.
class Sha256Tests
{
	private static Span<uint8> Bytes(StringView text) => .((uint8*)text.Ptr, text.Length);

	private static bool Hashes(StringView text, StringView hex) => Sha256.Of(Bytes(text)).ToHex(.. scope .()) == hex;

	[Test]
	public static void ThePublishedVectors()
	{
		Test.Assert(Hashes("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"));
		Test.Assert(Hashes("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"));
		Test.Assert(Hashes("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
			"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"));
		// 56 bytes and 64 bytes: the length's padding spills into a second block, or fills one.
		Test.Assert(Hashes("The quick brown fox jumps over the lazy dog",
			"d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"));
	}

	[Test]
	public static void FedInPiecesTheSameDigestAsAtOnce()
	{
		let million = scope Sha256();
		let thousand = scope String()..Append('a', 1000);
		for (int i < 1000)
			million.Update(Bytes(thousand));
		Test.Assert(million.Finish().ToHex(.. scope .()) == "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0");

		// Pieces of 1, 63, 65 and 171 bytes across block edges.
		let text = scope String();
		for (int i < 300)
			text.Append((char8)('a' + i % 26));
		let whole = Sha256.Of(Bytes(text));
		let pieces = scope Sha256();
		int at = 0;
		for (let size in scope int[](1, 63, 65, 171))
		{
			pieces.Update(Bytes(StringView(text, at, size)));
			at += size;
		}
		Test.Assert(at == text.Length);
		Test.Assert(pieces.Finish() == whole);
	}
}
