using System;
using System.Collections;
using System.Threading;
using Sedulous.Http;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Mcp.Http;
using Sedulous.Net;

namespace Sedulous.Mcp.Http.Tests;

/// The streamable HTTP binding over REAL loopback sockets.
///
/// The shape is the one Sedulous.Http's own tests use: the CLIENT runs on a worker and the
/// test thread pumps the host, because the host is single threaded by contract and the client
/// blocks.
class McpHttpHostTests
{
	/// How many pump iterations an exchange gets. At a millisecond a turn this is seconds of
	/// patience, which loopback never needs and a loaded machine might.
	private const int cPumpLimit = 5000;
	private const String cToken = "sekrit";

	private static void PumpUntil(McpHttpHost host, ref bool done)
	{
		for (int i = 0; (i < cPumpLimit) && !done; i++)
		{
			if (host.Pump() == 0)
				Thread.Sleep(1);
		}
	}

	/// A request carrying the bearer token, or none when the token is empty. The caller owns it.
	private static HttpRequest Post(StringView token, StringView body)
	{
		let request = new HttpRequest("POST", "/mcp");
		if (!token.IsEmpty)
			request.AddHeader("Authorization", scope $"Bearer {token}");
		request.AddHeader("Content-Type", "application/json");
		request.SetBodyText(body);
		return request;
	}

	private static int32 Fetch(uint16 port, HttpRequest request, String outBody)
	{
		defer delete request;
		if (HttpClient.Fetch("127.0.0.1", port, request) case .Ok(let response))
		{
			defer delete response;
			outBody.Set(response.BodyText);
			return response.Status;
		}
		return -1;
	}

	[Test]
	public static void AnEmptyTokenIsRefusedBeforeTheSocketOpens()
	{
		let server = scope McpServer();
		let host = scope McpHttpHost(server);

		McpHttpConfig config = .();
		config.Token = "";
		// A host that serves without a lock is worse than one that does not start, so this
		// fails rather than binding.
		Test.Assert(!host.Start(config));
		Test.Assert(!host.IsRunning);
		Test.Assert(host.BoundPort == 0);
	}

	[Test]
	public static void AnAuthorizedExchangeAnswersAndEveryRefusalHasItsOwnStatus()
	{
		let server = scope McpServer();
		server.SetServerInfo("http-host", "1.0.0");
		server.RegisterTool("ping_tool", "answers pong", scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				outResult.Set("pong", JsonValue.MakeBool(true));
				return true;
			});

		let host = scope McpHttpHost(server);
		McpHttpConfig config = .();
		config.Token = cToken;
		Test.Assert(host.Start(config));
		let port = host.BoundPort;
		Test.Assert(port != 0);

		var done = false;
		int32 initStatus = -1, callStatus = -1, noTokenStatus = -1, badTokenStatus = -1;
		int32 badMethodStatus = -1, badPathStatus = -1, notificationStatus = -1;
		let initBody = scope String();
		let callBody = scope String();
		let ignored = scope String();

		let client = scope Thread(new [&badMethodStatus, &badPathStatus, &badTokenStatus, &callBody, &callStatus, &done, &ignored, &initBody, &initStatus, &noTokenStatus, &notificationStatus, &port]() =>
			{
				initStatus = Fetch(port, Post(cToken,
					"""
					{"jsonrpc":"2.0","id":1,"method":"initialize"}
					"""), initBody);

				callStatus = Fetch(port, Post(cToken,
					"""
					{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"ping_tool","arguments":{}}}
					"""), callBody);

				noTokenStatus = Fetch(port, Post("", "{}"), ignored);
				badTokenStatus = Fetch(port, Post("wrong", "{}"), ignored);

				let wrongMethod = Post(cToken, "");
				wrongMethod.Method.Set("GET");
				badMethodStatus = Fetch(port, wrongMethod, ignored);

				let elsewhere = Post(cToken, "{}");
				elsewhere.Target.Set("/nope");
				badPathStatus = Fetch(port, elsewhere, ignored);

				// A notification has no JSON-RPC response, so the transport answers for it.
				notificationStatus = Fetch(port, Post(cToken,
					"""
					{"jsonrpc":"2.0","method":"notifications/initialized"}
					"""), ignored);

				done = true;
			});
		client.Start(false);
		PumpUntil(host, ref done);
		client.Join();

		Test.Assert(initStatus == 200);
		let initialize = JsonValue.Parse(initBody);
		defer delete initialize;
		Test.Assert(initialize.Get("result").Get("serverInfo").Get("name").AsString()
			== "http-host");

		Test.Assert(callStatus == 200);
		let called = JsonValue.Parse(callBody);
		defer delete called;
		Test.Assert(!called.Get("result").Get("isError").AsBool());

		// Each refusal is DISTINCT, because the four mean four different things to a client.
		Test.Assert(noTokenStatus == 401);
		Test.Assert(badTokenStatus == 401);
		Test.Assert(badMethodStatus == 405);
		Test.Assert(badPathStatus == 404);
		Test.Assert(notificationStatus == 202);
	}

	[Test]
	public static void AnUnauthorizedCallerIsRefusedOnTheEventRouteToo()
	{
		let server = scope McpServer();
		let host = scope McpHttpHost(server);
		McpHttpConfig config = .();
		config.Token = cToken;
		Test.Assert(host.Start(config));
		let port = host.BoundPort;

		var done = false;
		int32 status = -1;
		let ignored = scope String();

		let client = scope Thread(new [&done, &ignored, &port, &status]() =>
			{
				let events = Post("", "");
				events.Method.Set("GET");
				events.Target.Set("/events");
				status = Fetch(port, events, ignored);
				done = true;
			});
		client.Start(false);
		PumpUntil(host, ref done);
		client.Join();

		// The token guards BOTH routes: an event stream leaks as much as a tool call.
		Test.Assert(status == 401);
		Test.Assert(host.ListenerCount == 0);
	}

	[Test]
	public static void TheEventChannelConnectsBroadcastsAndIsSweptWhenThePeerGoes()
	{
		let server = scope McpServer();
		let host = scope McpHttpHost(server);
		McpHttpConfig config = .();
		config.Token = cToken;
		Test.Assert(host.Start(config));
		let port = host.BoundPort;

		let received = scope String();
		let receivedMonitor = scope Monitor();
		var clientDone = false;

		let listener = scope Thread(new [&clientDone, &port, &received, &receivedMonitor]() =>
			{
				let socket = TcpSocket.Connect("127.0.0.1", port);
				defer delete socket;
				for (int i = 0; (i < cPumpLimit) && (socket.ConnectStatus == 0); i++)
					Thread.Sleep(1);

				let get = "GET /events HTTP/1.1\r\nHost: local\r\nAuthorization: Bearer sekrit\r\n\r\n";
				socket.Send(.((uint8*)get.Ptr, get.Length));

				let buffer = scope uint8[2048];
				for (int i = 0; i < cPumpLimit; i++)
				{
					let n = socket.Receive(buffer);
					if (n > 0)
					{
						using (receivedMonitor.Enter())
						{
							received.Append(StringView((char8*)&buffer[0], (int)n));
							if (received.Contains("data: cook done"))
								break;
						}
						continue;
					}
					// Nothing yet: the stream is quiet, not gone.
					if (n == 0)
					{
						Thread.Sleep(1);
						continue;
					}
					break;
				}
				clientDone = true;
			});
		listener.Start(false);

		for (int i = 0; (i < cPumpLimit) && (host.ListenerCount == 0); i++)
		{
			if (host.Pump() == 0)
				Thread.Sleep(1);
		}
		Test.Assert(host.ListenerCount == 1);
		Test.Assert(host.Broadcast("progress", "cook done") == 1);

		for (int i = 0; (i < cPumpLimit) && !clientDone; i++)
		{
			host.Pump();
			Thread.Sleep(1);
		}
		listener.Join();

		using (receivedMonitor.Enter())
		{
			Test.Assert(received.StartsWith("HTTP/1.1 200 OK"));
			// The comment proves the stream is live before any event exists to prove it.
			Test.Assert(received.Contains(": connected"));
			Test.Assert(received.Contains("event: progress"));
			Test.Assert(received.Contains("data: cook done"));
		}

		// The peer has gone. The sweep drops the listener within a few pumps: a WRITE alone
		// cannot notice a fresh close, because the kernel buffers it until the reset arrives.
		for (int i = 0; (i < cPumpLimit) && (host.ListenerCount != 0); i++)
		{
			host.Pump();
			Thread.Sleep(1);
		}
		Test.Assert(host.ListenerCount == 0);
		Test.Assert(host.Broadcast("progress", "anyone?") == 0);
	}

	/// A tool that is not finished keeps the caller waiting across pumps, reported as a
	/// pending request in between so an idling host knows to keep pumping, and a later pump
	/// answers it.
	[Test]
	public static void ANotFinishedToolKeepsTheCallerWaitingAcrossPumps()
	{
		let server = scope McpServer();
		var calls = 0;
		server.RegisterTool("slow", "answers on its third entry", scope SchemaBuilder().Build(), .ReadOnly,
			new [&calls] (arguments, outResult, outError) =>
			{
				calls++;
				if (calls < 3)
					return .NotFinished;
				outResult.Set("calls", JsonValue.MakeNumber(calls));
				return .Answered;
			});

		let host = scope McpHttpHost(server);
		McpHttpConfig config = .();
		config.Token = cToken;
		Test.Assert(host.Start(config));
		let port = host.BoundPort;
		Test.Assert(port != 0);
		Test.Assert(!host.HasPendingRequest);

		var done = false;
		var status = (int32)0;
		let body = scope String();
		let client = scope Thread(new [&done, &status, &port, &body]() =>
			{
				status = Fetch(port, Post(cToken,
					"{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"tools/call\",\"params\":{\"name\":\"slow\",\"arguments\":{}}}"), body);
				done = true;
			});
		client.Start(false);

		// Pumped by hand so the wait is observable.
		var sawPending = false;
		var answered = 0;
		for (int i = 0; (i < cPumpLimit) && !done; i++)
		{
			answered += host.Pump();
			if (host.HasPendingRequest)
				sawPending = true;
			Thread.Sleep(1);
		}
		client.Join();

		Test.Assert(status == 200);
		let response = JsonValue.Parse(body);
		Test.Assert(response != null);
		defer delete response;
		Test.Assert(response.Get("id").AsInt() == 5);
		Test.Assert(!response.Get("result").Get("isError").AsBool());
		let payload = JsonValue.Parse(response.Get("result").Get("content").At(0).Get("text").AsString());
		defer delete payload;
		Test.Assert(payload.Get("calls").AsInt() == 3);
		Test.Assert(calls == 3);
		Test.Assert(sawPending);
		Test.Assert(answered == 1);
		Test.Assert(!host.HasPendingRequest);
	}
}
