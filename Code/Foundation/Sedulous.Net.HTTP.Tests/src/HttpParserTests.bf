namespace Sedulous.Net.HTTP.Tests;

using System;
using Sedulous.Net.HTTP;

class HttpParserTests
{
	[Test]
	public static void ParseResponse_Complete()
	{
		let parser = scope HttpParser();
		parser.Feed("HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nHello");

		switch (parser.TryParseResponse())
		{
		case .Ok(let resp):
			Test.Assert(resp.StatusCode == .OK);
			Test.Assert(resp.ReasonPhrase.Equals("OK"));
			Test.Assert(resp.Body.Count == 5);
			let body = scope String();
			resp.GetBodyString(body);
			Test.Assert(body.Equals("Hello"));
			delete resp;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void ParseResponse_NoBody()
	{
		let parser = scope HttpParser();
		parser.Feed("HTTP/1.1 204 No Content\r\n\r\n");

		switch (parser.TryParseResponse())
		{
		case .Ok(let resp):
			Test.Assert(resp.StatusCode == .NoContent);
			Test.Assert(resp.Body.Count == 0);
			delete resp;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void ParseResponse_Partial()
	{
		let parser = scope HttpParser();
		parser.Feed("HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\nHello");
		// Only 5 of 10 body bytes - should need more data
		Test.Assert(parser.TryParseResponse() case .Err);
	}

	[Test]
	public static void ParseResponse_Headers()
	{
		let parser = scope HttpParser();
		parser.Feed("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nX-Custom: value\r\nContent-Length: 0\r\n\r\n");

		switch (parser.TryParseResponse())
		{
		case .Ok(let resp):
			let ct = scope String();
			resp.Headers.GetContentType(ct);
			Test.Assert(ct.Equals("text/html"));
			let custom = scope String();
			Test.Assert(resp.Headers.Get("X-Custom", custom));
			Test.Assert(custom.Equals("value"));
			delete resp;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void ParseResponse_Chunked()
	{
		let parser = scope HttpParser();
		parser.Feed("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nHello\r\n6\r\n World\r\n0\r\n");

		switch (parser.TryParseResponse())
		{
		case .Ok(let resp):
			let body = scope String();
			resp.GetBodyString(body);
			Test.Assert(body.Equals("Hello World"));
			delete resp;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void ParseRequest_Complete()
	{
		let parser = scope HttpParser();
		parser.Feed("GET /api/users HTTP/1.1\r\nHost: localhost\r\n\r\n");

		switch (parser.TryParseRequest())
		{
		case .Ok(let req):
			Test.Assert(req.Method == .GET);
			Test.Assert(req.Path.Equals("/api/users"));
			Test.Assert(req.Version.Equals("HTTP/1.1"));
			let host = scope String();
			Test.Assert(req.Headers.Get("Host", host));
			Test.Assert(host.Equals("localhost"));
			delete req;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void ParseRequest_WithBody()
	{
		let parser = scope HttpParser();
		parser.Feed("POST /data HTTP/1.1\r\nContent-Length: 4\r\n\r\ntest");

		switch (parser.TryParseRequest())
		{
		case .Ok(let req):
			Test.Assert(req.Method == .POST);
			Test.Assert(req.Body.Count == 4);
			delete req;
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void ParseRequest_Partial()
	{
		let parser = scope HttpParser();
		parser.Feed("GET /path HTTP/1.1\r\n");
		// No \r\n\r\n yet - incomplete headers
		Test.Assert(parser.TryParseRequest() case .Err);
	}
}
