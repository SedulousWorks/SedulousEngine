namespace Sedulous.Net.HTTP.Tests;

using System;
using System.Threading;
using Sedulous.Net;
using Sedulous.Net.HTTP;

class HttpClientServerTests
{
	[Test]
	public static void Server_StartStop()
	{
		let server = scope HttpServer();
		Test.Assert(server.Start(.(IPAddress(127, 0, 0, 1), 0)) case .Ok);
		Test.Assert(server.IsRunning);
		Test.Assert(server.Port > 0);
		server.Stop();
		Test.Assert(!server.IsRunning);
	}

	[Test]
	public static void GET_Roundtrip()
	{
		let server = scope HttpServer();
		server.Get("/hello", new (req, resp) => {
			resp.StatusCode = .OK;
			resp.ReasonPhrase.Set("OK");
			resp.SetBody("Hello World");
			resp.Headers.SetContentType("text/plain");
		});
		Test.Assert(server.Start(.(IPAddress(127, 0, 0, 1), 0)) case .Ok);
		let port = server.Port;

		var serverDone = false;
		let serverThread = scope Thread(new [&]() => {
			while (!serverDone)
			{
				server.Update();
				Thread.Sleep(10);
			}
		});
		serverThread.SetJoinOnDelete(true);
		serverThread.Start(false);

		let client = scope HttpClient();
		client.TimeoutMs = 5000;

		switch (client.Get("127.0.0.1", port, "/hello"))
		{
		case .Ok(let resp):
			Test.Assert(resp.StatusCode == .OK);
			let body = scope String();
			resp.GetBodyString(body);
			Test.Assert(body.Equals("Hello World"));
			delete resp;
		case .Err:
			Test.Assert(false);
		}

		serverDone = true;
		serverThread.Join();
		server.Stop();
	}

	[Test]
	public static void POST_WithBody()
	{
		let server = scope HttpServer();
		server.Post("/echo", new (req, resp) => {
			resp.StatusCode = .OK;
			resp.ReasonPhrase.Set("OK");
			if (req.Body.Count > 0)
				resp.SetBody(Span<uint8>(req.Body.Ptr, req.Body.Count));
		});
		Test.Assert(server.Start(.(IPAddress(127, 0, 0, 1), 0)) case .Ok);
		let port = server.Port;

		var serverDone = false;
		let serverThread = scope Thread(new [&]() => {
			while (!serverDone)
			{
				server.Update();
				Thread.Sleep(10);
			}
		});
		serverThread.SetJoinOnDelete(true);
		serverThread.Start(false);

		let client = scope HttpClient();
		client.TimeoutMs = 5000;

		switch (client.Post("127.0.0.1", port, "/echo", "Echo me!", "text/plain"))
		{
		case .Ok(let resp):
			Test.Assert(resp.StatusCode == .OK);
			let body = scope String();
			resp.GetBodyString(body);
			Test.Assert(body.Equals("Echo me!"));
			delete resp;
		case .Err:
			Test.Assert(false);
		}

		serverDone = true;
		serverThread.Join();
		server.Stop();
	}

	[Test]
	public static void NotFound_Route()
	{
		let server = scope HttpServer();
		server.Get("/exists", new (req, resp) => {
			resp.StatusCode = .OK;
			resp.ReasonPhrase.Set("OK");
			resp.SetBody("Found");
		});
		Test.Assert(server.Start(.(IPAddress(127, 0, 0, 1), 0)) case .Ok);
		let port = server.Port;

		var serverDone = false;
		let serverThread = scope Thread(new [&]() => {
			while (!serverDone)
			{
				server.Update();
				Thread.Sleep(10);
			}
		});
		serverThread.SetJoinOnDelete(true);
		serverThread.Start(false);

		let client = scope HttpClient();
		client.TimeoutMs = 5000;

		switch (client.Get("127.0.0.1", port, "/nonexistent"))
		{
		case .Ok(let resp):
			Test.Assert(resp.StatusCode == .NotFound);
			delete resp;
		case .Err:
			Test.Assert(false);
		}

		serverDone = true;
		serverThread.Join();
		server.Stop();
	}

	[Test]
	public static void ParseUrl_Basic()
	{
		let host = scope String();
		var port = uint16(0);
		let path = scope String();

		Test.Assert(HttpClient.ParseUrl("http://example.com/api", host, out port, path) case .Ok);
		Test.Assert(host.Equals("example.com"));
		Test.Assert(port == 80);
		Test.Assert(path.Equals("/api"));
	}

	[Test]
	public static void ParseUrl_WithPort()
	{
		let host = scope String();
		var port = uint16(0);
		let path = scope String();

		Test.Assert(HttpClient.ParseUrl("http://localhost:8080/test", host, out port, path) case .Ok);
		Test.Assert(host.Equals("localhost"));
		Test.Assert(port == 8080);
		Test.Assert(path.Equals("/test"));
	}

	[Test]
	public static void ParseUrl_NoPath()
	{
		let host = scope String();
		var port = uint16(0);
		let path = scope String();

		Test.Assert(HttpClient.ParseUrl("http://example.com", host, out port, path) case .Ok);
		Test.Assert(host.Equals("example.com"));
		Test.Assert(path.Equals("/"));
	}
}
