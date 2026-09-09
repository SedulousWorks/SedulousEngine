using System;
using System.Collections;
using Sedulous.Http;
using Sedulous.Net.WebSocket;

namespace Sedulous.Net.WebSocket.Tests;

/// Upgrade validation: what counts as a websocket handshake and what does not.
class WebSocketHandshakeTests
{
	private const String cGoodRequest = """
		GET /game HTTP/1.1\r
		Host: localhost\r
		Upgrade: websocket\r
		Connection: keep-alive, Upgrade\r
		Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r
		Sec-WebSocket-Version: 13\r
		\r

		""";

	/// Parses request text into a completed parser the caller owns.
	private static HttpMessageParser Parse(StringView text)
	{
		let parser = new HttpMessageParser(.Request);
		parser.Push(.((uint8*)text.Ptr, text.Length));
		return parser;
	}

	[Test]
	public static void AValidUpgradeIsAcceptedAndAnswered()
	{
		let parser = Parse(cGoodRequest);
		defer delete parser;
		Test.Assert(parser.State == .Complete);

		let key = scope String();
		Test.Assert(WebSocketHandshake.Validate(parser, key));
		Test.Assert(key == "dGhlIHNhbXBsZSBub25jZQ==");

		let response = scope List<uint8>();
		WebSocketHandshake.BuildUpgradeResponse(key, response);
		let text = scope String();
		text.Append(StringView((char8*)response.Ptr, response.Count));

		Test.Assert(text.StartsWith("HTTP/1.1 101"));
		// The accept value is what proves to the client that we understood the protocol
		// rather than merely returning 101.
		Test.Assert(text.Contains("s3pPLMBiTxaQ9kYGzzhZRbK+xOo="));
	}

	[Test]
	public static void TheConnectionTokenIsFoundInAList()
	{
		// A browser routinely sends "keep-alive, Upgrade", so the header is searched for a
		// token rather than compared whole.
		let parser = Parse(cGoodRequest);
		defer delete parser;
		Test.Assert(WebSocketHandshake.Validate(parser, scope String()));
	}

	[Test]
	public static void APostIsRefused()
	{
		let parser = Parse("""
			POST /game HTTP/1.1\r
			Upgrade: websocket\r
			Connection: Upgrade\r
			Sec-WebSocket-Key: aaaa\r
			Sec-WebSocket-Version: 13\r
			\r

			""");
		defer delete parser;
		Test.Assert(!WebSocketHandshake.Validate(parser, scope String()));
	}

	[Test]
	public static void AMissingKeyIsRefused()
	{
		let parser = Parse("""
			GET / HTTP/1.1\r
			Upgrade: websocket\r
			Connection: Upgrade\r
			Sec-WebSocket-Version: 13\r
			\r

			""");
		defer delete parser;
		Test.Assert(!WebSocketHandshake.Validate(parser, scope String()));
	}

	[Test]
	public static void TheWrongVersionIsRefused()
	{
		// Only thirteen is RFC 6455. An older draft speaks a different wire.
		let parser = Parse("""
			GET / HTTP/1.1\r
			Upgrade: websocket\r
			Connection: Upgrade\r
			Sec-WebSocket-Key: aaaa\r
			Sec-WebSocket-Version: 8\r
			\r

			""");
		defer delete parser;
		Test.Assert(!WebSocketHandshake.Validate(parser, scope String()));
	}

	[Test]
	public static void AMissingUpgradeHeaderIsRefused()
	{
		let parser = Parse("""
			GET / HTTP/1.1\r
			Connection: Upgrade\r
			Sec-WebSocket-Key: aaaa\r
			Sec-WebSocket-Version: 13\r
			\r

			""");
		defer delete parser;
		Test.Assert(!WebSocketHandshake.Validate(parser, scope String()));
	}

	[Test]
	public static void AConnectionWithoutTheUpgradeTokenIsRefused()
	{
		let parser = Parse("""
			GET / HTTP/1.1\r
			Upgrade: websocket\r
			Connection: close\r
			Sec-WebSocket-Key: aaaa\r
			Sec-WebSocket-Version: 13\r
			\r

			""");
		defer delete parser;
		Test.Assert(!WebSocketHandshake.Validate(parser, scope String()));
	}

	[Test]
	public static void AnIncompleteRequestIsRefused()
	{
		let parser = scope HttpMessageParser(.Request);
		// The head has not ended, so nothing about it is decided yet.
		let partial = scope String("GET / HTTP/1.1\r\nUpgrade: websocket\r\n");
		parser.Push(.((uint8*)partial.Ptr, partial.Length));
		Test.Assert(parser.State == .NeedMore);
		Test.Assert(!WebSocketHandshake.Validate(parser, scope String()));
	}

	[Test]
	public static void HeaderNamesAndTokensAreCaseInsensitive()
	{
		let parser = Parse("""
			GET / HTTP/1.1\r
			upgrade: WebSocket\r
			connection: UPGRADE\r
			sec-websocket-key: aaaa\r
			sec-websocket-version: 13\r
			\r

			""");
		defer delete parser;
		Test.Assert(WebSocketHandshake.Validate(parser, scope String()));
	}

	[Test]
	public static void TheRejectResponseIsAPlain400()
	{
		let response = scope List<uint8>();
		WebSocketHandshake.BuildRejectResponse(response);
		let text = scope String();
		text.Append(StringView((char8*)response.Ptr, response.Count));

		Test.Assert(text.StartsWith("HTTP/1.1 400"));
		// A length and a close, so a client is not left waiting on a body that never comes.
		Test.Assert(text.Contains("Content-Length: 0"));
		Test.Assert(text.Contains("Connection: close"));
	}
}
