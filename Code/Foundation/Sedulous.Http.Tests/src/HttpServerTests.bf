using System;
using System.Collections;
using System.Threading;
using Sedulous.Http;
using Sedulous.Net;

namespace Sedulous.Http.Tests;

/// The server and client over real loopback sockets.
///
/// The shape is always the same: the CLIENT runs on a worker and the TEST THREAD pumps the
/// server, because the server is single threaded by contract and the client blocks.
class HttpServerTests
{
	/// How many pump iterations to give an exchange. At a millisecond a turn this is seconds
	/// of patience, which loopback never needs and a wedged machine might.
	private const int cPumpLimit = 5000;

	private static Span<uint8> Bytes(StringView text) => .((uint8*)text.Ptr, text.Length);

	/// Pumps until the flag flips or the patience runs out.
	private static void PumpUntil(HttpServer server, ref bool done)
	{
		for (int i = 0; (i < cPumpLimit) && !done; i++)
		{
			if (server.Pump() == 0)
				Thread.Sleep(1);
		}
	}

	/// Connects and waits for the non blocking connect to settle.
	private static TcpSocket ConnectRaw(uint16 port)
	{
		let socket = TcpSocket.Connect("127.0.0.1", port);
		for (int i = 0; (i < cPumpLimit) && (socket.ConnectStatus == 0); i++)
			Thread.Sleep(1);
		return socket;
	}

	[Test]
	public static void AOneShotExchangeAnswersAndAMissingRouteIs404()
	{
		let server = scope HttpServer();
		Test.Assert(server.Start(.()));
		let port = server.BoundPort;
		Test.Assert(port != 0);

		server.SetHandler(new (request) =>
			{
				if (request.Target == "/echo")
					return HttpResponse.Json(200,
						scope $"{{\"method\":\"{request.Method}\",\"size\":{request.Body.Count}}}");
				return HttpResponse.Text(404, "text/plain", "not here");
			});

		var done = false;
		HttpResponse echo = null;
		HttpResponse missing = null;

		let client = scope Thread(new [&done, &echo, &missing, &port]() =>
			{
				let post = scope HttpRequest("POST", "/echo");
				post.AddHeader("Content-Type", "application/json");
				post.SetBodyText("xxxxx");
				if (HttpClient.Fetch("127.0.0.1", port, post) case .Ok(let posted))
					echo = posted;

				let get = scope HttpRequest("GET", "/nope");
				if (HttpClient.Fetch("127.0.0.1", port, get) case .Ok(let fetched))
					missing = fetched;

				done = true;
			});
		client.Start(false);
		PumpUntil(server, ref done);
		client.Join();

		Test.Assert(echo != null);
		defer delete echo;
		Test.Assert(echo.Status == 200);
		// The header the handler set survives, and reads back case insensitively.
		Test.Assert(echo.Header("content-type") == "application/json");
		Test.Assert(echo.BodyText == "{\"method\":\"POST\",\"size\":5}");

		Test.Assert(missing != null);
		defer delete missing;
		Test.Assert(missing.Status == 404);
	}

	[Test]
	public static void NoHandlerAnswers404()
	{
		let server = scope HttpServer();
		Test.Assert(server.Start(.()));
		let port = server.BoundPort;

		var done = false;
		HttpResponse response = null;
		let client = scope Thread(new [&done, &port, &response]() =>
			{
				let get = scope HttpRequest("GET", "/anything");
				if (HttpClient.Fetch("127.0.0.1", port, get) case .Ok(let got))
					response = got;
				done = true;
			});
		client.Start(false);
		PumpUntil(server, ref done);
		client.Join();

		Test.Assert(response != null);
		defer delete response;
		Test.Assert(response.Status == 404);
	}

	[Test]
	public static void GarbageAnswers400AndTheServerSurvivesIt()
	{
		let server = scope HttpServer();
		Test.Assert(server.Start(.()));
		let port = server.BoundPort;
		server.SetHandler(new (request) => HttpResponse.Text(200, "text/plain", "fine"));

		var done = false;
		var status = 0;
		let rawClient = scope Thread(new [&done, &port, &status]() =>
			{
				let raw = ConnectRaw(port);
				defer delete raw;
				raw.Send(Bytes("complete garbage\r\n\r\n"));

				let parser = scope HttpMessageParser(.Response);
				let buffer = scope uint8[1024];
				for (int i = 0; i < cPumpLimit; i++)
				{
					let n = raw.Receive(buffer);
					if (n > 0)
					{
						if (parser.Push(.(&buffer[0], (int)n)) == .Complete)
							break;
						continue;
					}
					if (n == 0)
					{
						Thread.Sleep(1);
						continue;
					}
					parser.OnPeerClosed();
					break;
				}
				status = parser.Status;
				done = true;
			});
		rawClient.Start(false);
		PumpUntil(server, ref done);
		rawClient.Join();

		Test.Assert(status == 400);

		// And the server is still serving: a malformed peer closes its own connection and
		// takes nothing else with it.
		var secondDone = false;
		HttpResponse after = null;
		let client = scope Thread(new [&after, &port, &secondDone]() =>
			{
				let get = scope HttpRequest("GET", "/still-here");
				if (HttpClient.Fetch("127.0.0.1", port, get) case .Ok(let got))
					after = got;
				secondDone = true;
			});
		client.Start(false);
		PumpUntil(server, ref secondDone);
		client.Join();

		Test.Assert(after != null);
		defer delete after;
		Test.Assert(after.Status == 200);
	}

	[Test]
	public static void AnEventStreamStaysOpenAndDeliversWhatIsWritten()
	{
		let server = scope HttpServer();
		Test.Assert(server.Start(.()));
		let port = server.BoundPort;

		server.SetHandler(new (request) => HttpResponse.EventStreamResponse());

		SseStream held = null;
		server.SetStreamHandler(new [&held](request, stream) =>
			{
				// The consumer takes its OWN reference, which is what lets it outlive the
				// server's sweep.
				stream.AddRef();
				held = stream;
			});

		let received = scope String();
		let receivedLock = scope Monitor();
		var clientDone = false;

		let client = scope Thread(new [&clientDone, &port, &received, &receivedLock]() =>
			{
				let raw = ConnectRaw(port);
				defer delete raw;
				raw.Send(Bytes("GET /events HTTP/1.1\r\nHost: local\r\n\r\n"));

				let buffer = scope uint8[2048];
				for (int i = 0; i < cPumpLimit; i++)
				{
					let n = raw.Receive(buffer);
					if (n > 0)
					{
						using (receivedLock.Enter())
						{
							received.Append(StringView((char8*)&buffer[0], (int)n));
							// Two events means two blank line terminators.
							var terminators = 0;
							for (int c = 0; (c + 1) < received.Length; c++)
							{
								if ((received[c] == '\n') && (received[c + 1] == '\n'))
									terminators++;
							}
							if (terminators >= 2)
								break;
						}
						continue;
					}
					if (n == 0)
					{
						Thread.Sleep(1);
						continue;
					}
					break;
				}
				clientDone = true;
			});
		client.Start(false);

		// Pump until the handler has been handed the stream.
		for (int i = 0; (i < cPumpLimit) && (held == null); i++)
		{
			if (server.Pump() == 0)
				Thread.Sleep(1);
		}
		Test.Assert(held != null);
		Test.Assert(held.IsOpen);

		Test.Assert(held.WriteEvent("progress", "cooking 1/2"));
		Test.Assert(held.WriteEvent("progress", "cooking 2/2"));

		PumpUntil(server, ref clientDone);
		client.Join();

		using (receivedLock.Enter())
		{
			// The stream headers went first, then the events, on ONE connection that was
			// never closed between them.
			Test.Assert(received.Contains("text/event-stream"));
			Test.Assert(received.Contains("event: progress"));
			Test.Assert(received.Contains("data: cooking 1/2"));
			Test.Assert(received.Contains("data: cooking 2/2"));
		}

		held.Close();
		held.ReleaseRef();
	}

	[Test]
	public static void AMultiLineEventBecomesOneDataFieldPerLine()
	{
		let server = scope HttpServer();
		Test.Assert(server.Start(.()));
		let port = server.BoundPort;
		server.SetHandler(new (request) => HttpResponse.EventStreamResponse());

		SseStream held = null;
		server.SetStreamHandler(new [&held](request, stream) =>
			{
				stream.AddRef();
				held = stream;
			});

		let received = scope String();
		let receivedLock = scope Monitor();
		var clientDone = false;

		let client = scope Thread(new [&clientDone, &port, &received, &receivedLock]() =>
			{
				let raw = ConnectRaw(port);
				defer delete raw;
				raw.Send(Bytes("GET /events HTTP/1.1\r\nHost: local\r\n\r\n"));

				let buffer = scope uint8[2048];
				for (int i = 0; i < cPumpLimit; i++)
				{
					let n = raw.Receive(buffer);
					if (n > 0)
					{
						using (receivedLock.Enter())
						{
							received.Append(StringView((char8*)&buffer[0], (int)n));
							if (received.Contains("data: second"))
								break;
						}
						continue;
					}
					if (n == 0)
					{
						Thread.Sleep(1);
						continue;
					}
					break;
				}
				clientDone = true;
			});
		client.Start(false);

		for (int i = 0; (i < cPumpLimit) && (held == null); i++)
		{
			if (server.Pump() == 0)
				Thread.Sleep(1);
		}
		Test.Assert(held != null);

		// A raw newline inside a field would end the event early, so each line gets its own
		// data field.
		Test.Assert(held.WriteEvent("", "first\nsecond"));

		PumpUntil(server, ref clientDone);
		client.Join();

		using (receivedLock.Enter())
		{
			Test.Assert(received.Contains("data: first"));
			Test.Assert(received.Contains("data: second"));
			// No name was given, so no event line was written.
			Test.Assert(!received.Contains("event: "));
		}

		held.Close();
		held.ReleaseRef();
	}

	[Test]
	public static void FetchingAClosedPortReportsAReason()
	{
		let request = scope HttpRequest("GET", "/");
		// Port one is privileged and nothing is listening, so this cannot connect.
		let result = HttpClient.Fetch("127.0.0.1", 1, request, 200);
		if (result case .Err(let reason))
		{
			Test.Assert(!reason.IsEmpty);
			delete reason;
		}
		else
		{
			Test.FatalError("a fetch against a closed port must not succeed");
		}
	}

	/// A handler that answers NOT YET keeps the request pending on its connection and sees it
	/// again every pump until it answers; a peer that leaves while waiting is dropped without
	/// ever being answered.
	[Test]
	public static void ANotYetRequestIsAskedAgainEveryPumpAndADepartedPeerIsDropped()
	{
		let server = scope HttpServer();
		Test.Assert(server.Start(.()));
		let port = server.BoundPort;
		Test.Assert(port != 0);

		var calls = 0;
		var answerOnCall = 3;
		server.SetHandler(new [&calls, &answerOnCall] (request) =>
			{
				calls++;
				if (calls < answerOnCall)
					return null; // not yet
				return HttpResponse.Json(200, scope $"{{\"calls\":{calls},\"target\":\"{request.Target}\"}}");
			});

		// The client blocks on one GET; the handler says not yet twice and answers on the
		// third pump.
		var done = false;
		HttpResponse outcome = null;
		let client = scope Thread(new [&done, &outcome, &port]() =>
			{
				let get = scope HttpRequest("GET", "/wait");
				if (HttpClient.Fetch("127.0.0.1", port, get) case .Ok(let got))
					outcome = got;
				done = true;
			});
		client.Start(false);

		// Pumped by hand so the wait is observable: a pump whose handler says not yet answers
		// nothing and leaves exactly one request pending.
		var sawPending = false;
		var answered = 0;
		for (int i = 0; (i < cPumpLimit) && !done; i++)
		{
			answered += server.Pump();
			if (server.PendingRequestCount == 1)
				sawPending = true;
			Thread.Sleep(1);
		}
		client.Join();

		Test.Assert(outcome != null);
		defer delete outcome;
		Test.Assert(outcome.Status == 200);
		Test.Assert(outcome.BodyText == "{\"calls\":3,\"target\":\"/wait\"}");
		Test.Assert(calls == 3);
		Test.Assert(sawPending);
		Test.Assert(answered == 1, "a request counts once, when it is finally answered");
		Test.Assert(server.PendingRequestCount == 0);

		// A peer that sends a request and leaves while the handler keeps saying not yet is
		// dropped: the pending count returns to nought without the handler ever answering.
		calls = 0;
		answerOnCall = int.MaxValue; // never
		let departing = scope Thread(new [&port]() =>
			{
				let raw = ConnectRaw(port);
				raw.Send(Bytes("GET /gone HTTP/1.1\r\nHost: x\r\n\r\n"));
				delete raw; // closes it
			});
		departing.Start(false);
		departing.Join();

		var dropped = false;
		for (int i = 0; (i < cPumpLimit) && !dropped; i++)
		{
			server.Pump();
			dropped = (calls > 0) && (server.PendingRequestCount == 0);
			Thread.Sleep(1);
		}
		Test.Assert(dropped);
		Test.Assert(calls >= 1);
	}
}
