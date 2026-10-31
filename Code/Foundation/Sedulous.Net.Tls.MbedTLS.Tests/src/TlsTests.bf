using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Net.Tls;
using Sedulous.Net.Tls.MbedTLS;

namespace Sedulous.Net.Tls.MbedTLS.Tests;

/// The TLS seam over its Mbed TLS backend, headless: a client and a server session wired by an
/// in-memory pipe, the server's certificate made by the test. A handshake and data both ways (TLS
/// 1.3, and 1.2 when asked), ALPN agreed, plaintext written before the handshake held and
/// delivered; the client refusing a certificate for another name, one it does not trust, and an
/// expired one, each saying why; a close seen by the peer; a configuration that cannot work
/// failing with its reason; the system's roots read where the box has them.
class TlsTests
{
	private class Certificate
	{
		public String Pem = new .() ~ delete _;
		public String Key = new .() ~ delete _;

		public this(StringView name, int32 fromDays = -1, int32 toDays = 30)
		{
			let error = scope String();
			let made = TlsCertificates.CreateSelfSigned(name, TlsCertificates.Time(fromDays, .. scope .()),
				TlsCertificates.Time(toDays, .. scope .()), Pem, Key, error);
			Test.Assert(made, error);
		}
	}

	/// Moves each side's bytes to the other until neither has any left (or a bound is hit).
	private static void Pump(ITlsSession client, ITlsSession server)
	{
		let toServer = scope List<uint8>();
		let toClient = scope List<uint8>();
		for (int round < 64)
		{
			toServer.Clear();
			toClient.Clear();
			let a = client.TakeOutgoing(toServer);
			if (a > 0)
				server.Receive(toServer).IgnoreError();
			let b = server.TakeOutgoing(toClient);
			if (b > 0)
				client.Receive(toClient).IgnoreError();
			if ((a == 0) && (b == 0))
				return;
		}
	}

	private static void ReadAll(ITlsSession session, String outText)
	{
		uint8[256] buffer = default;
		while (true)
		{
			let n = session.Read(.(&buffer[0], buffer.Count));
			if (n == 0)
				return;
			outText.Append(StringView((char8*)&buffer[0], n));
		}
	}

	private static Span<uint8> Bytes(StringView text) => .((uint8*)text.Ptr, text.Length);

	/// A backend, a server serving `served` and a client, pumped until the handshake settles.
	private class Pair
	{
		public MbedTlsBackend Backend = new .() ~ delete _;
		public ITlsSession Client ~ delete _;
		public ITlsSession Server ~ delete _;

		public this(Certificate served, TlsClientConfig client, TlsServerConfig server = null)
		{
			let config = server ?? scope:: TlsServerConfig();
			config.CertificateChainPem.Set(served.Pem);
			config.PrivateKeyPem.Set(served.Key);
			Server = Backend.CreateServer(config);
			Client = Backend.CreateClient(client);
			Pump(Client, Server);
		}
	}

	private static TlsClientConfig Trusting(Certificate certificate, StringView name, TlsClientConfig config)
	{
		config.ServerName.Set(name);
		config.TrustPem(certificate.Pem);
		return config;
	}

	[Test]
	public static void AHandshakeOverTls13DataBothWaysAlpnAgreed()
	{
		let cert = scope Certificate("game.example");
		let client = Trusting(cert, "game.example", scope .());
		client.Alpn.Add(new .("h2"));
		client.Alpn.Add(new .("http/1.1"));
		let server = scope TlsServerConfig();
		server.Alpn.Add(new .("http/1.1"));
		let pair = scope Pair(cert, client, server);
		Test.Assert(pair.Client.State == .Open, scope String(pair.Client.Failure));
		Test.Assert(pair.Server.State == .Open, scope String(pair.Server.Failure));
		Test.Assert(pair.Client.Version == .Tls13);
		Test.Assert(pair.Client.AlpnChosen == "http/1.1");
		Test.Assert(pair.Server.AlpnChosen == "http/1.1");

		Test.Assert(pair.Client.Write(Bytes("GET / HTTP/1.1\r\n\r\n")) case .Ok);
		Pump(pair.Client, pair.Server);
		Test.Assert(ReadAll(pair.Server, .. scope .()) == "GET / HTTP/1.1\r\n\r\n");
		Test.Assert(pair.Server.Write(Bytes("HTTP/1.1 200 OK\r\n\r\nhello")) case .Ok);
		Pump(pair.Client, pair.Server);
		Test.Assert(ReadAll(pair.Client, .. scope .()) == "HTTP/1.1 200 OK\r\n\r\nhello");

		// A larger message, past one TLS record.
		let big = scope String();
		for (int i < 40000)
			big.Append(((i % 26) == 25) ? '\n' : 'x');
		Test.Assert(pair.Client.Write(Bytes(big)) case .Ok);
		Pump(pair.Client, pair.Server);
		Test.Assert(ReadAll(pair.Server, .. scope .()) == big);
	}

	[Test]
	public static void Tls12WhenTheClientAsksNoHigherPlaintextWrittenEarlyWaitsForTheHandshake()
	{
		let cert = scope Certificate("localhost");
		let client = Trusting(cert, "localhost", scope .());
		client.Maximum = .Tls12;
		let backend = scope MbedTlsBackend();
		let serverConfig = scope TlsServerConfig();
		serverConfig.CertificateChainPem.Set(cert.Pem);
		serverConfig.PrivateKeyPem.Set(cert.Key);
		let server = backend.CreateServer(serverConfig);
		defer delete server;
		let session = backend.CreateClient(client);
		defer delete session;
		Test.Assert(session.State == .Handshaking, scope String(session.Failure));
		Test.Assert(session.Write(Bytes("early")) case .Ok); // held until Open
		Pump(session, server);
		Test.Assert(session.State == .Open, scope String(session.Failure));
		Test.Assert(session.Version == .Tls12);
		Pump(session, server);
		Test.Assert(ReadAll(server, .. scope .()) == "early");
	}

	[Test]
	public static void TheClientRefusesACertificateForAnotherNameAnUntrustedOneAndAnExpiredOneSayingWhy()
	{
		let cert = scope Certificate("localhost");
		{
			let pair = scope Pair(cert, Trusting(cert, "example.com", scope .()));
			Test.Assert(pair.Client.State == .Failed);
			Test.Assert(pair.Client.Failure.Contains("refused", true), scope String(pair.Client.Failure));
			Test.Assert(pair.Client.Failure.Contains("CN", true), scope String(pair.Client.Failure));
			Test.Assert(pair.Server.State != .Open);
		}
		{
			let other = scope Certificate("localhost");
			let pair = scope Pair(cert, Trusting(other, "localhost", scope .()));
			Test.Assert(pair.Client.State == .Failed);
			Test.Assert(pair.Client.Failure.Contains("trusted", true), scope String(pair.Client.Failure));
		}
		{
			let expired = scope Certificate("localhost", -30, -1);
			let pair = scope Pair(expired, Trusting(expired, "localhost", scope .()));
			Test.Assert(pair.Client.State == .Failed);
			Test.Assert(pair.Client.Failure.Contains("expired", true), scope String(pair.Client.Failure));
		}
		// Trusting nothing in particular (a test's own), it goes through whatever the name.
		{
			let insecure = scope TlsClientConfig();
			insecure.Trust = .InsecureForTests;
			let pair = scope Pair(cert, insecure);
			Test.Assert(pair.Client.State == .Open, scope String(pair.Client.Failure));
		}
	}

	[Test]
	public static void ACloseIsSeenByThePeer()
	{
		let cert = scope Certificate("localhost");
		let pair = scope Pair(cert, Trusting(cert, "localhost", scope .()));
		Test.Assert(pair.Client.State == .Open, scope String(pair.Client.Failure));
		pair.Client.Close();
		Test.Assert(pair.Client.State == .Closed);
		Pump(pair.Client, pair.Server);
		Test.Assert(ReadAll(pair.Server, .. scope .()).IsEmpty);
		Test.Assert(pair.Server.State == .Closed);
		Test.Assert(pair.Client.Write(Bytes("after")) case .Err);
	}

	[Test]
	public static void AConfigurationThatCannotWorkFailsAtOnceSayingWhy()
	{
		let backend = scope MbedTlsBackend();
		Test.Assert(backend.Name == "Mbed TLS");
		let noKey = scope TlsServerConfig();
		noKey.CertificateChainPem.Set("not a certificate");
		let server = backend.CreateServer(noKey);
		defer delete server;
		Test.Assert(server.State == .Failed);
		Test.Assert(server.Failure.Contains("certificate chain", true), scope String(server.Failure));

		let cert = scope Certificate("localhost");
		let nameless = scope TlsClientConfig();
		nameless.TrustPem(cert.Pem);
		let client = backend.CreateClient(nameless);
		defer delete client;
		Test.Assert(client.State == .Failed);
		Test.Assert(client.Failure.Contains("name", true), scope String(client.Failure));

		let noRoots = scope TlsClientConfig();
		noRoots.ServerName.Set("localhost");
		noRoots.TrustPem("nothing to trust");
		let rootless = backend.CreateClient(noRoots);
		defer delete rootless;
		Test.Assert(rootless.State == .Failed);
		Test.Assert(rootless.Failure.Contains("no trusted roots", true), scope String(rootless.Failure));
	}

	[Test]
	public static void TheSystemsRootsWhereTheBoxHasThem()
	{
		let rootsFrom = scope String();
		let roots = scope TlsRoots();
		TlsSystemRoots.Load(roots, rootsFrom);
		Console.WriteLine(scope $"TLS system roots: {rootsFrom}");
		if (roots.IsEmpty)
			return; // a box without a bundle: said above
		// A client trusting them starts its handshake (it has roots to check a server against).
		let backend = scope MbedTlsBackend();
		let config = scope TlsClientConfig();
		config.ServerName.Set("example.com");
		let client = backend.CreateClient(config);
		defer delete client;
		Test.Assert(client.State == .Handshaking, scope String(client.Failure));
		let hello = scope List<uint8>();
		Test.Assert(client.TakeOutgoing(hello) > 0, "its ClientHello");
	}
}
