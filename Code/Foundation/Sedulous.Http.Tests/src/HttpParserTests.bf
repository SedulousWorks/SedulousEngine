using System;
using System.Collections;
using Sedulous.Http;

namespace Sedulous.Http.Tests;

/// The incremental parser, which is the piece that has to survive whatever a peer sends.
class HttpParserTests
{
	private static Span<uint8> Bytes(StringView text) => .((uint8*)text.Ptr, text.Length);

	[Test]
	public static void ARequestParsesFromArbitrarilySplitPushes()
	{
		let wire = """
			POST /mcp?x=1 HTTP/1.1\r
			Host: local\r
			content-type: application/json\r
			Content-Length: 11\r
			\r
			{"ok":true}
			""";

		// ONE BYTE AT A TIME, which is the harshest framing a peer can produce and the case
		// an accumulate-then-scan parser gets wrong.
		let parser = scope HttpMessageParser(.Request);
		var state = HttpParseState.NeedMore;
		for (int i = 0; i < wire.Length; i++)
			state = parser.Push(Bytes(wire.Substring(i, 1)));

		Test.Assert(state == .Complete);
		Test.Assert(parser.Method == "POST");
		Test.Assert(parser.Target == "/mcp?x=1");
		// The lookup finds a lower case spelling, because field names are case insensitive.
		Test.Assert(HttpHeader.Find(parser.Headers, "Content-Type") == "application/json");
		Test.Assert(parser.Body.Count == 11);
	}

	[Test]
	public static void GarbageIsRefused()
	{
		let parser = scope HttpMessageParser(.Request);
		Test.Assert(parser.Push(Bytes("this is not http\r\n\r\n")) == .Failed);
	}

	[Test]
	public static void ChunkedTransferIsRefusedRatherThanHalfSupported()
	{
		let parser = scope HttpMessageParser(.Request);
		// Guessing at a chunked body means guessing where the message ends, so this refuses.
		Test.Assert(parser.Push(Bytes("POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n"))
			== .Failed);
	}

	[Test]
	public static void AnOversizedHeadIsRefused()
	{
		let parser = scope HttpMessageParser(.Request);
		let huge = scope String("GET / HTTP/1.1\r\nX: ");
		for (int i = 0; i < 20000; i++)
			huge.Append('a');

		// The cap is what stops an unauthenticated peer from making the server buffer without
		// bound.
		Test.Assert(parser.Push(Bytes(huge)) == .Failed);
	}

	[Test]
	public static void ABodyPastTheCapIsRefusedFromTheHeaderAlone()
	{
		let parser = scope HttpMessageParser(.Request, 8);
		// Refused on the declared length, before a single body byte is buffered.
		Test.Assert(parser.Push(Bytes("POST / HTTP/1.1\r\nContent-Length: 9\r\n\r\n"))
			== .Failed);
	}

	[Test]
	public static void ANonNumericContentLengthIsRefused()
	{
		let parser = scope HttpMessageParser(.Request);
		Test.Assert(parser.Push(Bytes("POST / HTTP/1.1\r\nContent-Length: 12x\r\n\r\n"))
			== .Failed);
	}

	[Test]
	public static void ACloseDelimitedResponseBodyCompletesOnClose()
	{
		let parser = scope HttpMessageParser(.Response);
		// No Content-Length: the only framing left is the peer hanging up.
		Test.Assert(parser.Push(Bytes("HTTP/1.1 200 OK\r\nX-Kind: raw\r\n\r\nhello"))
			== .NeedMore);
		Test.Assert(parser.Push(Bytes(" world")) == .NeedMore);
		Test.Assert(parser.OnPeerClosed() == .Complete);
		Test.Assert(parser.Status == 200);
		Test.Assert(parser.Body.Count == 11);
	}

	[Test]
	public static void ACloseMidMessageFails()
	{
		let parser = scope HttpMessageParser(.Request);
		Test.Assert(parser.Push(Bytes("POST / HTTP/1.1\r\nContent-Length: 10\r\n\r\nabc"))
			== .NeedMore);
		// Cut off before the declared body arrived: that is a truncated request, not a short
		// one.
		Test.Assert(parser.OnPeerClosed() == .Failed);
	}

	[Test]
	public static void ARequestWithNoBodyCompletesAtTheBlankLine()
	{
		let parser = scope HttpMessageParser(.Request);
		Test.Assert(parser.Push(Bytes("GET /health HTTP/1.1\r\nHost: local\r\n\r\n"))
			== .Complete);
		Test.Assert(parser.Method == "GET");
		Test.Assert(parser.Target == "/health");
		Test.Assert(parser.Body.IsEmpty);
	}

	[Test]
	public static void OverReadPastTheDeclaredLengthIsDropped()
	{
		let parser = scope HttpMessageParser(.Request);
		// One connection carries one request, so bytes past the length are not ours to keep.
		Test.Assert(parser.Push(Bytes("POST / HTTP/1.1\r\nContent-Length: 2\r\n\r\nabcdef"))
			== .Complete);
		Test.Assert(parser.Body.Count == 2);
	}

	[Test]
	public static void HeaderLookupIsCaseInsensitiveAndValuesAreTrimmed()
	{
		let parser = scope HttpMessageParser(.Request);
		parser.Push(Bytes("GET / HTTP/1.1\r\nX-Odd-Case:   spaced   \r\n\r\n"));
		Test.Assert(HttpHeader.Find(parser.Headers, "x-ODD-case") == "spaced");
		Test.Assert(HttpHeader.Find(parser.Headers, "absent").IsEmpty);
	}
}
