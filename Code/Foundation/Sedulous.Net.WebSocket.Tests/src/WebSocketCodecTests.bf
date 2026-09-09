using System;
using System.Collections;
using Sedulous.Net.WebSocket;

namespace Sedulous.Net.WebSocket.Tests;

/// The handshake maths and the frame codec, checked against the RFC's own vectors.
class WebSocketCodecTests
{
	private static Span<uint8> Bytes(StringView text) => .((uint8*)text.Ptr, text.Length);

	private static void Hex(Span<uint8> data, String outText)
	{
		for (let b in data)
			outText.AppendF("{:x2}", b);
	}

	[Test]
	public static void Sha1MatchesTheRfc3174Vectors()
	{
		let digest = scope uint8[Sha1.DigestBytes];

		Sha1.Compute(Bytes("abc"), digest);
		Test.Assert(Hex(digest, .. scope String())
			== "a9993e364706816aba3e25717850c26c9cd0d89d");

		// Fifty six bytes, which is exactly the length that forces a second padded block.
		Sha1.Compute(Bytes("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"), digest);
		Test.Assert(Hex(digest, .. scope String())
			== "84983e441c3bd26ebaae4aa1f95129e5e54670f1");

		Sha1.Compute(.(), digest);
		Test.Assert(Hex(digest, .. scope String())
			== "da39a3ee5e6b4b0d3255bfef95601890afd80709");
	}

	[Test]
	public static void Base64MatchesTheRfc4648Vectors()
	{
		// The vectors exist to pin the PADDING, which is where an encoder usually goes wrong.
		Test.Assert(Base64.Encode(.(), .. scope String()) == "");
		Test.Assert(Base64.Encode(Bytes("f"), .. scope String()) == "Zg==");
		Test.Assert(Base64.Encode(Bytes("fo"), .. scope String()) == "Zm8=");
		Test.Assert(Base64.Encode(Bytes("foo"), .. scope String()) == "Zm9v");
		Test.Assert(Base64.Encode(Bytes("foobar"), .. scope String()) == "Zm9vYmFy");
	}

	[Test]
	public static void TheAcceptKeyMatchesTheRfc6455Example()
	{
		let accept = scope String();
		WebSocketHandshake.ComputeAccept("dGhlIHNhbXBsZSBub25jZQ==", accept);
		Test.Assert(accept == "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=");
	}

	[Test]
	public static void AMaskedClientFrameRoundTripsAcrossArbitrarySplits()
	{
		let payload = Bytes("hello frame");
		let wire = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, payload, true, 0xA1B2C3D4, wire);

		let parser = scope WebSocketFrameParser();
		// Split mid header, because the decoder has to be incremental.
		parser.Push(.(wire.Ptr, 3));
		parser.Push(.(wire.Ptr + 3, wire.Count - 3));
		Test.Assert(!parser.Failed);

		let frame = scope WsFrame();
		Test.Assert(parser.Next(frame));
		Test.Assert(frame.Opcode == .Binary);
		Test.Assert(frame.Payload.Count == payload.Length);
		for (int i = 0; i < payload.Length; i++)
			Test.Assert(frame.Payload[i] == payload[i]);

		// Exactly one frame came out of one frame's bytes.
		Test.Assert(!parser.Next(frame));
	}

	[Test]
	public static void SixteenBitExtendedLengthsRoundTrip()
	{
		let payload = scope List<uint8>();
		// Past 125, which is where the length moves into its own two byte field.
		for (int i = 0; i < 300; i++)
			payload.Add((uint8)(i & 0xFF));

		let wire = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, payload, true, 7, wire);

		let parser = scope WebSocketFrameParser();
		parser.Push(wire);

		let frame = scope WsFrame();
		Test.Assert(parser.Next(frame));
		Test.Assert(frame.Payload.Count == 300);
		Test.Assert(frame.Payload[299] == (uint8)(299 & 0xFF));
	}

	[Test]
	public static void SixtyFourBitExtendedLengthsRoundTrip()
	{
		let payload = scope List<uint8>();
		// Past sixty five thousand, which moves the length into its eight byte field.
		for (int i = 0; i < 70000; i++)
			payload.Add((uint8)(i & 0xFF));

		let wire = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, payload, true, 0x11223344, wire);

		let parser = scope WebSocketFrameParser();
		parser.Push(wire);

		let frame = scope WsFrame();
		Test.Assert(parser.Next(frame));
		Test.Assert(frame.Payload.Count == 70000);
		Test.Assert(frame.Payload[69999] == (uint8)(69999 & 0xFF));
	}

	[Test]
	public static void AnUnmaskedClientFrameIsRefused()
	{
		let wire = scope List<uint8>();
		// A server frame arriving from a client: the RFC requires client frames to be masked.
		WebSocketFrame.Encode(.Binary, Bytes("x"), false, 0, wire);

		let parser = scope WebSocketFrameParser();
		parser.Push(wire);
		Test.Assert(parser.Failed);
	}

	[Test]
	public static void AFragmentedFrameIsRefused()
	{
		let wire = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, Bytes("x"), true, 1, wire);
		// Clear FIN. This server does not reassemble, because a game packet never needs it.
		wire[0] = wire[0] & 0x7F;

		let parser = scope WebSocketFrameParser();
		parser.Push(wire);
		Test.Assert(parser.Failed);
	}

	[Test]
	public static void AReservedBitIsRefused()
	{
		let wire = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, Bytes("x"), true, 1, wire);
		// No extension was negotiated, so a reserved bit means the peer assumed one.
		wire[0] = wire[0] | 0x40;

		let parser = scope WebSocketFrameParser();
		parser.Push(wire);
		Test.Assert(parser.Failed);
	}

	[Test]
	public static void AnOversizedFrameIsRefusedFromItsHeaderAlone()
	{
		// A sixty four bit length claiming far past the cap, with no payload behind it: the
		// refusal must come from the header, before anything is buffered.
		let wire = scope List<uint8>();
		wire.Add(0x82);
		wire.Add(0xFF);
		for (int shift = 56; shift >= 0; shift -= 8)
			wire.Add((uint8)((((uint64)WebSocketFrame.MaxFrameBytes + 1) >> shift) & 0xFF));

		let parser = scope WebSocketFrameParser();
		parser.Push(wire);
		Test.Assert(parser.Failed);
	}

	[Test]
	public static void FailureLatches()
	{
		let bad = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, Bytes("x"), false, 0, bad);

		let parser = scope WebSocketFrameParser();
		parser.Push(bad);
		Test.Assert(parser.Failed);

		// Once framing is lost there is no way back into sync, so a well formed frame after
		// it changes nothing.
		let good = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, Bytes("y"), true, 5, good);
		parser.Push(good);
		Test.Assert(parser.Failed);

		let frame = scope WsFrame();
		Test.Assert(!parser.Next(frame));
	}

	[Test]
	public static void TwoFramesInOnePushBothDecode()
	{
		let wire = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, Bytes("one"), true, 3, wire);
		WebSocketFrame.Encode(.Binary, Bytes("two"), true, 4, wire);

		let parser = scope WebSocketFrameParser();
		parser.Push(wire);

		let frame = scope WsFrame();
		Test.Assert(parser.Next(frame));
		Test.Assert(StringView((char8*)frame.Payload.Ptr, frame.Payload.Count) == "one");
		Test.Assert(parser.Next(frame));
		Test.Assert(StringView((char8*)frame.Payload.Ptr, frame.Payload.Count) == "two");
		Test.Assert(!parser.Next(frame));
	}
}
