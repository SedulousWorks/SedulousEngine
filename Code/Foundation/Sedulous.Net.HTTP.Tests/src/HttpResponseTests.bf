namespace Sedulous.Net.HTTP.Tests;

using System;
using Sedulous.Net.HTTP;

class HttpResponseTests
{
	[Test]
	public static void Constructor_StatusCode()
	{
		let resp = scope HttpResponse(.OK);
		Test.Assert(resp.StatusCode == .OK);
		Test.Assert(resp.ReasonPhrase.Equals("OK"));
	}

	[Test]
	public static void SetBody()
	{
		let resp = scope HttpResponse(.OK);
		resp.SetBody("Hello World");
		Test.Assert(resp.Body.Count == 11);
		Test.Assert(resp.Headers.ContentLength == 11);
	}

	[Test]
	public static void GetBodyString()
	{
		let resp = scope HttpResponse(.OK);
		resp.SetBody("Test Body");
		let str = scope String();
		resp.GetBodyString(str);
		Test.Assert(str.Equals("Test Body"));
	}

	[Test]
	public static void WriteTo_Format()
	{
		let resp = scope HttpResponse(.NotFound);
		resp.SetBody("Not Found");
		resp.Headers.SetContentType("text/plain");
		let wire = scope String();
		resp.WriteTo(wire);
		Test.Assert(wire.StartsWith("HTTP/1.1 404 Not Found\r\n"));
		Test.Assert(wire.Contains("Content-Type: text/plain\r\n"));
		Test.Assert(wire.EndsWith("Not Found"));
	}

	[Test]
	public static void SetJsonBody()
	{
		let resp = scope HttpResponse(.OK);
		resp.SetJsonBody("{\"status\":\"ok\"}");
		let ct = scope String();
		resp.Headers.GetContentType(ct);
		Test.Assert(ct.Equals("application/json"));
	}
}
