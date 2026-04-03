namespace Sedulous.Net.HTTP.Tests;

using System;
using Sedulous.Net.HTTP;

class HttpRequestTests
{
	[Test]
	public static void Constructor()
	{
		let req = scope HttpRequest(.GET, "/api/test");
		Test.Assert(req.Method == .GET);
		Test.Assert(req.Path.Equals("/api/test"));
		Test.Assert(req.Version.Equals("HTTP/1.1"));
	}

	[Test]
	public static void SetHeader()
	{
		let req = scope HttpRequest(.POST, "/");
		req.SetHeader("Content-Type", "application/json");
		Test.Assert(req.Headers.Contains("Content-Type"));
	}

	[Test]
	public static void SetBody()
	{
		let req = scope HttpRequest(.POST, "/");
		req.SetBody("Hello");
		Test.Assert(req.Body.Count == 5);
		Test.Assert(req.Headers.ContentLength == 5);
	}

	[Test]
	public static void SetJsonBody()
	{
		let req = scope HttpRequest(.POST, "/");
		req.SetJsonBody("{\"key\":\"value\"}");
		let ct = scope String();
		req.Headers.GetContentType(ct);
		Test.Assert(ct.Equals("application/json"));
	}

	[Test]
	public static void WriteTo_Format()
	{
		let req = scope HttpRequest(.GET, "/index.html");
		req.SetHeader("Host", "example.com");
		let wire = scope String();
		req.WriteTo(wire);
		Test.Assert(wire.StartsWith("GET /index.html HTTP/1.1\r\n"));
		Test.Assert(wire.Contains("Host: example.com\r\n"));
		Test.Assert(wire.Contains("\r\n\r\n"));
	}

	[Test]
	public static void WriteTo_WithBody()
	{
		let req = scope HttpRequest(.POST, "/data");
		req.SetBody("body content");
		let wire = scope String();
		req.WriteTo(wire);
		Test.Assert(wire.EndsWith("body content"));
	}
}
