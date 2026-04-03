namespace Sedulous.Net.HTTP.Tests;

using System;
using System.Collections;
using Sedulous.Net.HTTP;

class WebSocketFrameTests
{
	[Test]
	public static void EncodeText_Small()
	{
		let buf = scope List<uint8>();
		WebSocketFrame.EncodeText(buf, "Hi");
		// FIN=1, Text=0x1 -> 0x81, len=2
		Test.Assert(buf[0] == 0x81);
		Test.Assert(buf[1] == 2);
		Test.Assert(buf[2] == (uint8)'H');
		Test.Assert(buf[3] == (uint8)'i');
	}

	[Test]
	public static void Decode_Small()
	{
		let buf = scope List<uint8>();
		WebSocketFrame.EncodeText(buf, "Hi");

		switch (WebSocketFrame.Decode(Span<uint8>(buf.Ptr, buf.Count)))
		{
		case .Ok(let frame):
			Test.Assert(frame.Fin);
			Test.Assert(frame.OpCode == .Text);
			Test.Assert(!frame.Masked);
			Test.Assert(frame.Payload.Count == 2);
			Test.Assert(frame.Payload[0] == (uint8)'H');
			Test.Assert(frame.BytesConsumed == 4);
			delete frame.Payload;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void EncodeDecode_Binary()
	{
		uint8[8] data = .(1, 2, 3, 4, 5, 6, 7, 8);
		let buf = scope List<uint8>();
		WebSocketFrame.EncodeBinary(buf, Span<uint8>(&data, 8));

		switch (WebSocketFrame.Decode(Span<uint8>(buf.Ptr, buf.Count)))
		{
		case .Ok(let frame):
			Test.Assert(frame.OpCode == .Binary);
			Test.Assert(frame.Payload.Count == 8);
			for (int i = 0; i < 8; i++)
				Test.Assert(frame.Payload[i] == (uint8)(i + 1));
			delete frame.Payload;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void EncodeDecode_Masked()
	{
		let buf = scope List<uint8>();
		uint8[4] mask = .(0xAA, 0xBB, 0xCC, 0xDD);
		WebSocketFrame.EncodeText(buf, "Test", &mask);

		// Should have mask bit set
		Test.Assert((buf[1] & 0x80) != 0);

		switch (WebSocketFrame.Decode(Span<uint8>(buf.Ptr, buf.Count)))
		{
		case .Ok(let frame):
			Test.Assert(frame.Masked);
			Test.Assert(frame.Payload.Count == 4);
			// Decode should unmask
			Test.Assert(frame.Payload[0] == (uint8)'T');
			Test.Assert(frame.Payload[1] == (uint8)'e');
			Test.Assert(frame.Payload[2] == (uint8)'s');
			Test.Assert(frame.Payload[3] == (uint8)'t');
			delete frame.Payload;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void EncodeDecode_Close()
	{
		let buf = scope List<uint8>();
		WebSocketFrame.EncodeClose(buf, 1000);

		switch (WebSocketFrame.Decode(Span<uint8>(buf.Ptr, buf.Count)))
		{
		case .Ok(let frame):
			Test.Assert(frame.OpCode == .Close);
			Test.Assert(frame.Payload.Count == 2);
			// Status code 1000 = 0x03E8
			Test.Assert(frame.Payload[0] == 0x03);
			Test.Assert(frame.Payload[1] == 0xE8);
			delete frame.Payload;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void EncodeDecode_Ping()
	{
		let buf = scope List<uint8>();
		WebSocketFrame.EncodePing(buf);

		switch (WebSocketFrame.Decode(Span<uint8>(buf.Ptr, buf.Count)))
		{
		case .Ok(let frame):
			Test.Assert(frame.OpCode == .Ping);
			Test.Assert(frame.Payload.Count == 0);
			delete frame.Payload;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void Decode_InsufficientData()
	{
		uint8[1] data = .(0x81); // Only first byte
		Test.Assert(WebSocketFrame.Decode(Span<uint8>(&data, 1)) case .Err);
	}

	[Test]
	public static void EncodeDecode_MediumPayload()
	{
		// 200 bytes - uses 16-bit length encoding
		let payload = scope List<uint8>();
		for (int i = 0; i < 200; i++)
			payload.Add((uint8)(i % 256));

		let buf = scope List<uint8>();
		WebSocketFrame.Encode(buf, .Binary, Span<uint8>(payload.Ptr, payload.Count));

		// Length byte should be 126 (indicating 16-bit length follows)
		Test.Assert((buf[1] & 0x7F) == 126);

		switch (WebSocketFrame.Decode(Span<uint8>(buf.Ptr, buf.Count)))
		{
		case .Ok(let frame):
			Test.Assert(frame.Payload.Count == 200);
			for (int i = 0; i < 200; i++)
				Test.Assert(frame.Payload[i] == (uint8)(i % 256));
			delete frame.Payload;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void OpCode_IsControl()
	{
		Test.Assert(!WebSocketOpCode.Text.IsControl);
		Test.Assert(!WebSocketOpCode.Binary.IsControl);
		Test.Assert(!WebSocketOpCode.Continuation.IsControl);
		Test.Assert(WebSocketOpCode.Close.IsControl);
		Test.Assert(WebSocketOpCode.Ping.IsControl);
		Test.Assert(WebSocketOpCode.Pong.IsControl);
	}
}
