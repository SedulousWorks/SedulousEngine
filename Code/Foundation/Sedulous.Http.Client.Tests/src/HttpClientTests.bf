using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Http;
using Sedulous.Http.Client;
using Sedulous.Net;
using Sedulous.Net.Tls;
using Sedulous.Net.Tls.MbedTLS;

namespace Sedulous.Http.Client.Tests;

/// The native HTTP client against real loopback servers: the engine's HttpServer for GET, POST,
/// redirects (followed, a POST turned GET by 303, a loop stopped), a timeout, a cancel and the
/// size cap; a raw server for a chunked response, a streamed body (its head, then its pieces; a
/// redirect's own not streamed; the cap; a cancel), and for https through the Mbed TLS backend with
/// a self-signed certificate (trusted, and an https request redirected to http refused). Also URL
/// parsing and redirect resolution alone.
class HttpClientTests
{
	private static Span<uint8> Bytes(StringView text) => .((uint8*)text.Ptr, text.Length);

	/// A server that answers each connection once, with what `answer` makes of the request's head,
	/// then closes; plain or TLS. Pumped on the test thread.
	private class RawServer
	{
		private class Connection
		{
			public INetByteStream Stream ~ delete _;
			public String Request = new .() ~ delete _;
			public bool Answered = false;
		}

		private TcpListener mListener = new .(0, true) ~ delete _;
		private delegate void(StringView head, String outReply) mAnswer ~ delete _;
		/// BORROWED.
		private ITlsBackend mTls;
		private String mPem = new .() ~ delete _;
		private String mKey = new .() ~ delete _;
		private List<Connection> mConnections = new .() ~ DeleteContainerAndItems!(_);

		/// Takes OWNERSHIP of `answer`.
		public this(delegate void(StringView head, String outReply) answer, ITlsBackend tls = null, StringView pem = default,
			StringView key = default)
		{
			mAnswer = answer;
			mTls = tls;
			mPem.Set(pem);
			mKey.Set(key);
		}

		public uint16 Port => mListener.BoundPort;

		public void Pump()
		{
			for (var socket = mListener.Accept(); socket != null; socket = mListener.Accept())
			{
				let c = new Connection();
				if (mTls != null)
				{
					let config = scope TlsServerConfig();
					config.CertificateChainPem.Set(mPem);
					config.PrivateKeyPem.Set(mKey);
					c.Stream = new TlsStream(socket, mTls.CreateServer(config));
				}
				else
					c.Stream = new PlainStream(socket);
				mConnections.Add(c);
			}
			uint8[4096] buffer = ?;
			for (let c in mConnections)
			{
				if (c.Answered)
					continue;
				c.Stream.Pump();
				for (var n = c.Stream.Receive(.(&buffer[0], buffer.Count)); n > 0; n = c.Stream.Receive(.(&buffer[0], buffer.Count)))
					c.Request.Append(StringView((char8*)&buffer[0], (int)n));
				if (c.Request.Contains("\r\n\r\n"))
				{
					let reply = scope String();
					mAnswer(c.Request, reply);
					c.Stream.Send(Bytes(reply));
					c.Stream.Pump();
					c.Stream.Close();
					c.Answered = true;
				}
			}
		}
	}

	/// Sends `request` (the client takes it) and pumps the client and `serve` until its answer
	/// arrives, about ten seconds at most, filling `outGot`.
	private static void Fetch(IHttpClient client, HttpClientRequest request, delegate void() serve, HttpClientResponse outGot)
	{
		var done = false;
		client.Send(request, new [&](r) =>
			{
				outGot.Status = r.Status;
				for (let h in r.Headers)
					outGot.Headers.Add(new .(h.Name, h.Value));
				outGot.Body.AddRange(r.Body);
				outGot.Error.Set(r.Error);
				outGot.Url.Set(r.Url);
				done = true;
			});
		for (int i < 10000)
		{
			serve();
			client.Pump();
			if (done)
				break;
			Thread.Sleep(1);
		}
		Test.Assert(done, "an answer arrived");
	}

	private static void Url(uint16 port, StringView path, bool secure, String outUrl)
	{
		outUrl.AppendF("{}://{}:{}{}", secure ? "https" : "http", secure ? "localhost" : "127.0.0.1", port, path);
	}

	[Test]
	public static void UrlsSplitForARequestOtherSchemesNoHostIpv6AndBadPortsRefused()
	{
		let u = scope HttpUrl();
		let error = scope String();
		Test.Assert(u.Parse("https://Example.com/a/b?x=1#frag", error), error);
		Test.Assert(u.Secure);
		Test.Assert(u.Host == "Example.com");
		Test.Assert(u.Port == 443);
		Test.Assert(u.Target == "/a/b?x=1");
		Test.Assert(u.Parse("http://user:pw@host:8080", error), error);
		Test.Assert(!u.Secure);
		Test.Assert(u.Host == "host");
		Test.Assert(u.Port == 8080);
		Test.Assert(u.Target == "/");
		Test.Assert(u.Parse("http://host?q", error), error);
		Test.Assert(u.Target == "/?q");
		Test.Assert(!u.Parse("ftp://host/", error));
		Test.Assert(!u.Parse("http:///path", error));
		Test.Assert(!u.Parse("http://[::1]/", error));
		Test.Assert(!u.Parse("http://host:99999/", error));
		Test.Assert(!u.Parse("http://host:/", error));
		Test.Assert(!error.IsEmpty);
	}

	[Test]
	public static void ARedirectsLocationMadeAbsolute()
	{
		let base_ = scope HttpUrl();
		let error = scope String();
		Test.Assert(base_.Parse("http://host:8080/dir/page?q=1", error));
		Test.Assert(base_.Resolve("https://other/x", .. scope .()) == "https://other/x");
		Test.Assert(base_.Resolve("//other/x", .. scope .()) == "http://other/x");
		Test.Assert(base_.Resolve("/root", .. scope .()) == "http://host:8080/root");
		Test.Assert(base_.Resolve("next", .. scope .()) == "http://host:8080/dir/next");
		Test.Assert(base_.Parse("https://host/", error));
		Test.Assert(base_.Resolve("/a", .. scope .()) == "https://host/a");
	}

	/// The engine's server answering by path, and a client without TLS.
	private class Bed
	{
		public HttpServer Server = new .() ~ delete _;
		public NativeHttpClient Client = new .(null) ~ delete _;
		public String LastMethod = new .() ~ delete _;
		public uint16 Port;

		public this()
		{
			Test.Assert(Server.Start(.()));
			Port = Server.BoundPort;
			Server.SetHandler(new (request) =>
				{
					LastMethod.Set(request.Method);
					let target = StringView(request.Target);
					if (target == "/hello")
					{
						let r = HttpResponse.Text(200, "text/plain", "hello there");
						r.AddHeader("X-Kind", "greeting");
						return r;
					}
					if (target == "/echo")
						return HttpResponse.Text(200, "text/plain", scope $"{request.Method} {request.Header("Content-Type")} {request.BodyText}");
					if (target == "/old")
					{
						let r = HttpResponse.Text(302, "text/plain", "");
						r.AddHeader("Location", "/hello");
						return r;
					}
					if (target == "/after-post")
					{
						let r = HttpResponse.Text(303, "text/plain", "");
						r.AddHeader("Location", "hello");
						return r;
					}
					if (target == "/loop")
					{
						let r = HttpResponse.Text(301, "text/plain", "");
						r.AddHeader("Location", "/loop");
						return r;
					}
					if (target == "/big")
						return HttpResponse.Text(200, "text/plain", scope String('x', 100));
					if (target == "/never")
						return null; // not yet, for as long as it is asked
					return HttpResponse.Text(404, "text/plain", "not here");
				});
		}

		public void Serve()
		{
			Server.Pump();
		}

		public HttpClientResponse Get(StringView path, HttpClientResponse outGot, int32 maxRedirects = 5, int maxBytes = 16 * 1024 * 1024,
			float timeout = 30.0f)
		{
			let request = HttpClientRequest.Get(Url(Port, path, false, .. scope .()));
			request.MaxRedirects = maxRedirects;
			request.MaxResponseBytes = maxBytes;
			request.TimeoutSeconds = timeout;
			Fetch(Client, request, scope => Serve, outGot);
			return outGot;
		}
	}

	[Test]
	public static void AGet()
	{
		let bed = scope Bed();
		let r = bed.Get("/hello", scope .());
		Test.Assert(r.Ok, r.Error);
		Test.Assert(r.Status == 200);
		Test.Assert(r.BodyText == "hello there");
		Test.Assert(r.Header("x-kind") == "greeting");
	}

	[Test]
	public static void APostItsBodyAndTypeSent()
	{
		let bed = scope Bed();
		let r = scope HttpClientResponse();
		Fetch(bed.Client, HttpClientRequest.Post(Url(bed.Port, "/echo", false, .. scope .()), "text/plain", "payload"), scope => bed.Serve, r);
		Test.Assert(r.Status == 200, r.Error);
		Test.Assert(r.BodyText == "POST text/plain payload");
	}

	[Test]
	public static void AStatusThatIsNot2xxIsStillAResponse()
	{
		let bed = scope Bed();
		let r = bed.Get("/nothing", scope .());
		Test.Assert(r.Ok, r.Error);
		Test.Assert(r.Status == 404);
	}

	[Test]
	public static void ARedirectFollowedTheAnsweringUrlReported()
	{
		let bed = scope Bed();
		let r = bed.Get("/old", scope .());
		Test.Assert(r.Status == 200, r.Error);
		Test.Assert(r.BodyText == "hello there");
		Test.Assert(r.Url == Url(bed.Port, "/hello", false, .. scope .()));
	}

	[Test]
	public static void A303AfterAPostBecomesAGet()
	{
		let bed = scope Bed();
		let r = scope HttpClientResponse();
		Fetch(bed.Client, HttpClientRequest.Post(Url(bed.Port, "/after-post", false, .. scope .()), "text/plain", "x"), scope => bed.Serve, r);
		Test.Assert(r.Status == 200, r.Error);
		Test.Assert(bed.LastMethod == "GET");
	}

	[Test]
	public static void WithRedirectsOffTheRedirectComesBackAsItIs()
	{
		let bed = scope Bed();
		let r = bed.Get("/old", scope .(), 0);
		Test.Assert(r.Status == 302, r.Error);
		Test.Assert(r.Header("Location") == "/hello");
	}

	[Test]
	public static void ARedirectLoopStoppedSayingWhy()
	{
		let bed = scope Bed();
		let r = bed.Get("/loop", scope .());
		Test.Assert(!r.Ok);
		Test.Assert(r.Status == 0);
		Test.Assert(r.Error.Contains("too many redirects", true), r.Error);
	}

	[Test]
	public static void ABodyPastTheCapFailsTheRequest()
	{
		let bed = scope Bed();
		let r = bed.Get("/big", scope .(), 5, 8);
		Test.Assert(!r.Ok);
		Test.Assert(r.Error.Contains("larger than 8 bytes", true), r.Error);
	}

	[Test]
	public static void AServerThatNeverAnswersTimesOut()
	{
		let bed = scope Bed();
		let r = bed.Get("/never", scope .(), 5, 16 * 1024 * 1024, 0.3f);
		Test.Assert(!r.Ok);
		Test.Assert(r.Error.Contains("timed out", true), r.Error);
	}

	[Test]
	public static void ACancelledRequestIsNeverAnsweredQueuedOrUnderWay()
	{
		let bed = scope Bed();
		var heard = false;
		let running = bed.Client.Send(HttpClientRequest.Get(Url(bed.Port, "/never", false, .. scope .())), new [&](r) => { heard = true; });
		let queued = bed.Client.Send(HttpClientRequest.Get(Url(bed.Port, "/hello", false, .. scope .())), new [&](r) => { heard = true; });
		Test.Assert(bed.Client.Pending == 2);
		for (int i < 50)
		{
			bed.Serve();
			Thread.Sleep(1);
		}
		bed.Client.Cancel(queued);
		bed.Client.Cancel(running);
		for (int i < 5000)
		{
			if (bed.Client.Pending == 0)
				break;
			bed.Serve();
			bed.Client.Pump();
			Thread.Sleep(1);
		}
		Test.Assert(bed.Client.Pending == 0);
		Test.Assert(!heard);
		// The client still works after.
		let r = bed.Get("/hello", scope .());
		Test.Assert(r.Status == 200, r.Error);
	}

	[Test]
	public static void HttpsWithNoTlsBackendFailsSayingSo()
	{
		let bed = scope Bed();
		let r = scope HttpClientResponse();
		Fetch(bed.Client, HttpClientRequest.Get("https://localhost:1/"), scope => bed.Serve, r);
		Test.Assert(!r.Ok);
		Test.Assert(r.Error.Contains("TLS backend", true), r.Error);
	}

	[Test]
	public static void ARefusedConnectionAndABadUrlComeBackAsErrors()
	{
		uint16 port = 0;
		{
			let gone = scope TcpListener(0, true);
			port = gone.BoundPort;
		}
		let client = scope NativeHttpClient(null);
		let refused = scope HttpClientResponse();
		Fetch(client, HttpClientRequest.Get(Url(port, "/", false, .. scope .())), scope () => {}, refused);
		Test.Assert(!refused.Ok);
		Test.Assert(refused.Status == 0);
		let bad = scope HttpClientResponse();
		Fetch(client, HttpClientRequest.Get("gopher://x/"), scope () => {}, bad);
		Test.Assert(bad.Error.Contains("not an http", true), bad.Error);
	}

	/// Off the web, the platform's client is the native one.
	[Test]
	public static void ThePlatformsClientIsTheNativeOneOffTheWeb()
	{
		let client = HttpClients.Create(null);
		defer delete client;
		Test.Assert(client is NativeHttpClient);
		let r = scope HttpClientResponse();
		Fetch(client, HttpClientRequest.Get("gopher://x/"), scope () => {}, r);
		Test.Assert(r.Error.Contains("not an http", true), r.Error);
	}

	[Test]
	public static void AChunkedResponse()
	{
		let server = scope RawServer(new (head, reply) =>
			{
				reply.Append("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n4\r\nWiki\r\n5\r\npedia\r\n0\r\n\r\n");
			});
		let client = scope NativeHttpClient(null);
		let r = scope HttpClientResponse();
		Fetch(client, HttpClientRequest.Get(Url(server.Port, "/", false, .. scope .())), scope => server.Pump, r);
		Test.Assert(r.Status == 200, r.Error);
		Test.Assert(r.BodyText == "Wikipedia");
	}

	/// What a streamed request heard: its head, its pieces joined, how many pieces, its end.
	private class Heard
	{
		public int Heads = 0;
		public int32 Status = 0;
		public int64 Length = -2;
		public List<uint8> Body = new .() ~ delete _;
		public int Pieces = 0;
		public bool Done = false;
		public HttpClientResponse Response = new .() ~ delete _;

		public StringView BodyText => .((char8*)Body.Ptr, Body.Count);
	}

	/// A GET of `url` streaming into `heard`.
	private static HttpClientRequest Streamed(StringView url, Heard heard)
	{
		let request = HttpClientRequest.Get(url);
		request.OnHead = new (status, headers, length) =>
			{
				heard.Heads++;
				heard.Status = status;
				heard.Length = length;
			};
		request.OnBody = new (piece) =>
			{
				Test.Assert(heard.Heads == 1, "the head first");
				heard.Pieces++;
				heard.Body.AddRange(piece);
			};
		return request;
	}

	/// The end of a request, kept in `heard`.
	private static delegate void(HttpClientResponse response) Ended(Heard heard)
	{
		return new (r) =>
			{
				heard.Done = true;
				heard.Response.Status = r.Status;
				heard.Response.Body.AddRange(r.Body);
				heard.Response.Error.Set(r.Error);
			};
	}

	/// Pumps the client and `server` until nothing is pending, about ten seconds at most.
	private static void Drain(IHttpClient client, RawServer server)
	{
		for (int i < 10000)
		{
			if (client.Pending == 0)
				break;
			server.Pump();
			client.Pump();
			if (client.Pending > 0)
				Thread.Sleep(1);
		}
		Test.Assert(client.Pending == 0);
	}

	[Test]
	public static void AStreamedBodyArrivesInPiecesAfterItsHeadAndTheResponseKeepsNoneOfIt()
	{
		// 200 KB with a length: more than one read's worth, so more than one piece.
		let big = scope String();
		for (int i < 200 * 1024)
			big.Append((char8)('a' + (i * 7) % 26));
		let server = scope RawServer(new [&](head, reply) =>
			{
				reply.AppendF("HTTP/1.1 200 OK\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}", big.Length, big);
			});
		let client = scope NativeHttpClient(null);
		let heard = scope Heard();
		client.Send(Streamed(Url(server.Port, "/big", false, .. scope .()), heard), Ended(heard));
		Drain(client, server);
		Test.Assert(heard.Done);
		Test.Assert(heard.Response.Ok, heard.Response.Error);
		Test.Assert(heard.Response.Status == 200);
		Test.Assert(heard.Response.Body.IsEmpty); // it went to OnBody
		Test.Assert(heard.Heads == 1);
		Test.Assert(heard.Status == 200);
		Test.Assert(heard.Length == big.Length);
		Test.Assert(heard.Pieces > 1);
		Test.Assert(heard.BodyText == big);

		// The cap counts a streamed body too.
		let capped = scope Heard();
		let small = Streamed(Url(server.Port, "/big", false, .. scope .()), capped);
		small.MaxResponseBytes = 64 * 1024;
		client.Send(small, Ended(capped));
		Drain(client, server);
		Test.Assert(capped.Done);
		Test.Assert(!capped.Response.Ok);
		Test.Assert(capped.Body.Count <= 64 * 1024);
	}

	[Test]
	public static void AStreamedChunkedBodyHasNoLengthAndOnlyTheFinalResponseOfARedirectStreams()
	{
		let server = scope RawServer(new (head, reply) =>
			{
				if (head.Contains("GET /moved ", true))
					reply.Append("HTTP/1.1 302 Found\r\nLocation: /here\r\nContent-Length: 5\r\nConnection: close\r\n\r\nmoved");
				else
					reply.Append("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n4\r\nWiki\r\n5\r\npedia\r\n0\r\n\r\n");
			});
		let client = scope NativeHttpClient(null);
		let heard = scope Heard();
		client.Send(Streamed(Url(server.Port, "/moved", false, .. scope .()), heard), Ended(heard));
		Drain(client, server);
		Test.Assert(heard.Done);
		Test.Assert(heard.Response.Ok, heard.Response.Error);
		Test.Assert(heard.Heads == 1); // the 302 is not heard
		Test.Assert(heard.Status == 200);
		Test.Assert(heard.Length == -1); // chunked: no length given
		Test.Assert(heard.BodyText == "Wikipedia");
	}

	[Test]
	public static void AStreamedRequestCancelledAtItsHeadHearsNothingMore()
	{
		let big = scope String();
		big.Append('x', 256 * 1024);
		let server = scope RawServer(new [&](head, reply) =>
			{
				reply.AppendF("HTTP/1.1 200 OK\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}", big.Length, big);
			});
		let client = scope NativeHttpClient(null);
		let heard = scope Heard();
		uint64 id = 0;
		let request = Streamed(Url(server.Port, "/", false, .. scope .()), heard);
		delete request.OnHead;
		request.OnHead = new [&](status, headers, length) =>
			{
				heard.Heads++;
				heard.Status = status;
				client.Cancel(id);
			};
		id = client.Send(request, new [&](r) => { heard.Done = true; });
		Drain(client, server);
		for (int i < 50) // anything still under way is dropped, not delivered
		{
			server.Pump();
			client.Pump();
			Thread.Sleep(1);
		}
		Test.Assert(heard.Heads == 1);
		Test.Assert(heard.Pieces == 0);
		Test.Assert(!heard.Done);
	}

	[Test]
	public static void HttpsThroughTheTlsBackendAndAnHttpsRequestRedirectedToHttpRefused()
	{
		let pem = scope String();
		let key = scope String();
		let error = scope String();
		Test.Assert(TlsCertificates.CreateSelfSigned("localhost", TlsCertificates.Time(-1, .. scope .()), TlsCertificates.Time(30, .. scope .()),
			pem, key, error), error);
		let tls = scope MbedTlsBackend();
		let seen = scope String();
		let server = scope RawServer(new [&](head, reply) =>
			{
				seen.Set(head);
				if (head.StartsWith("GET /down"))
					reply.Append("HTTP/1.1 302 Found\r\nLocation: http://127.0.0.1:1/\r\nContent-Length: 0\r\n\r\n");
				else
					reply.Append("HTTP/1.1 200 OK\r\nContent-Length: 6\r\n\r\nsecure");
			}, tls, pem, key);
		let client = scope NativeHttpClient(tls, .Roots, pem);

		let r = scope HttpClientResponse();
		Fetch(client, HttpClientRequest.Get(Url(server.Port, "/x", true, .. scope .())), scope => server.Pump, r);
		Test.Assert(r.Status == 200, r.Error);
		Test.Assert(r.BodyText == "secure");
		Test.Assert(seen.Contains(scope $"Host: localhost:{server.Port}", true), seen);

		let down = scope HttpClientResponse();
		Fetch(client, HttpClientRequest.Get(Url(server.Port, "/down", true, .. scope .())), scope => server.Pump, down);
		Test.Assert(!down.Ok);
		Test.Assert(down.Error.Contains("refused", true), down.Error);

		// A client that does not trust the certificate fails, saying why.
		let wary = scope NativeHttpClient(tls, .Roots, "");
		let untrusted = scope HttpClientResponse();
		Fetch(wary, HttpClientRequest.Get(Url(server.Port, "/x", true, .. scope .())), scope => server.Pump, untrusted);
		Test.Assert(!untrusted.Ok);
		Test.Assert(!untrusted.Error.IsEmpty);
	}

	/// A real site over the internet with the system's roots: only when ENGINE_HTTP_LIVE is set (a
	/// test run must not need the network). The check of the TLS 1.3 ticket read-on, which no
	/// loopback server reaches.
	[Test]
	public static void ARealHttpsSiteWithTheSystemsRoots()
	{
		if (Environment.GetEnvironmentVariable("ENGINE_HTTP_LIVE", scope .()) case .Err)
			return;
		let tls = scope MbedTlsBackend();
		let client = scope NativeHttpClient(tls);
		let r = scope HttpClientResponse();
		Fetch(client, HttpClientRequest.Get("https://example.com/"), scope () => {}, r);
		Test.Assert(r.Status == 200, r.Error);
		Test.Assert(r.BodyText.Contains("<html", true));
	}
}
