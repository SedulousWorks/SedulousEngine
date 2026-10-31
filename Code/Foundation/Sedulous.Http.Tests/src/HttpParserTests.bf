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

	/// A request line missing its version, or ending on its second separator, is refused and
	/// never read past; a response may leave out its reason phrase, which is legal.
	[Test]
	public static void ARequestNeedsItsVersionAndAResponseMayOmitItsReason()
	{
		Test.Assert(scope HttpMessageParser(.Request).Push(Bytes("GET /path\r\n\r\n")) == .Failed);
		Test.Assert(scope HttpMessageParser(.Request).Push(Bytes("GET\r\n\r\n")) == .Failed);
		Test.Assert(scope HttpMessageParser(.Request).Push(Bytes("GET /path \r\n\r\n")) == .Failed, "an empty version");

		let response = scope HttpMessageParser(.Response);
		Test.Assert(response.Push(Bytes("HTTP/1.1 204\r\nContent-Length: 0\r\n\r\n")) != .Failed);
		Test.Assert(response.Status == 204);
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

	/// A chunked response body, split anywhere, extensions and trailers dropped; a bad size line
	/// and chunk data not ended by CRLF refused; past the cap refused as too large.
	[Test]
	public static void AChunkedResponseBodySplitAnywhereExtensionsAndTrailersDropped()
	{
		let wire = "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello\r\n7;ext=1\r\n, world\r\nA\r\n0123456789\r\n0\r\nX-Trailer: t\r\n\r\n";
		// Whole, then a byte at a time, then three: the same body.
		int[3] steps = .(wire.Length, 1, 3);
		for (let step in steps)
		{
			let parser = scope HttpMessageParser(.Response);
			var state = HttpParseState.NeedMore;
			for (int at = 0; at < wire.Length; at += step)
			{
				let n = Math.Min(step, wire.Length - at);
				state = parser.Push(Bytes(wire.Substring(at, n)));
				if (at + n < wire.Length)
					Test.Assert(state == .NeedMore);
			}
			Test.Assert(state == .Complete);
			Test.Assert(parser.Status == 200);
			Test.Assert(StringView((char8*)parser.Body.Ptr, parser.Body.Count) == "hello, world0123456789");
		}
		{
			let parser = scope HttpMessageParser(.Response);
			Test.Assert(parser.Push(Bytes("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nzz\r\n")) == .Failed);
			Test.Assert(!parser.TooLarge);
		}
		{
			let parser = scope HttpMessageParser(.Response);
			Test.Assert(parser.Push(Bytes("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2\r\nabcd\r\n")) == .Failed);
		}
		{
			let parser = scope HttpMessageParser(.Response, 8);
			Test.Assert(parser.Push(Bytes("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello\r\n5\r\n")) == .Failed);
			Test.Assert(parser.TooLarge);
		}
	}

	/// Responses with no body (204, 304, 1xx, a HEAD's) complete at their head; a Content-Length
	/// past the cap is too large, not malformed.
	[Test]
	public static void ResponsesWithNoBodyCompleteAtTheirHead()
	{
		StringView[2] heads = .("HTTP/1.1 204 No Content\r\n\r\n", "HTTP/1.1 304 Not Modified\r\nContent-Length: 50\r\n\r\n");
		for (let head in heads)
		{
			let parser = scope:: HttpMessageParser(.Response);
			Test.Assert(parser.Push(Bytes(head)) == .Complete);
			Test.Assert(parser.Body.IsEmpty);
		}
		let head = scope HttpMessageParser(.Response);
		head.SetNoBody();
		Test.Assert(head.Push(Bytes("HTTP/1.1 200 OK\r\nContent-Length: 1234\r\n\r\n")) == .Complete);
		Test.Assert(head.Status == 200);
		let capped = scope HttpMessageParser(.Response, 8);
		Test.Assert(capped.Push(Bytes("HTTP/1.1 200 OK\r\nContent-Length: 9\r\n\r\n")) == .Failed);
		Test.Assert(capped.TooLarge);
	}
}
