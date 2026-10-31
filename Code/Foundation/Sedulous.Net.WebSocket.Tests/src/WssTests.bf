using System;
using System.Collections;
using System.Threading;
using Sedulous.Net;
using Sedulous.Net.Tls;
using Sedulous.Net.Tls.MbedTLS;
using Sedulous.Net.WebSocket;

namespace Sedulous.Net.WebSocket.Tests;

/// The gateway over TLS: with a backend and a certificate every connection is TLS first, then the
/// upgrade, then frames, all through the same code as ws://. A TLS client upgrades and exchanges
/// binary frames both ways; a plain client is refused; a key that does not load leaves the
/// gateway closed, saying why. Then the native client socket: it joins the gateway over ws and
/// over wss, datagrams both ways and those sent before the upgrade held; it refuses a certificate
/// it does not trust, wss with no backend, and a plain gateway; it gives up on a host that never
/// upgrades; and its frame parser takes a server's unmasked frames only.
class WssTests
{
	private const String cUpgrade = "GET /game HTTP/1.1\r\nHost: localhost\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n";

	private static Span<uint8> Bytes(StringView text) => .((uint8*)text.Ptr, text.Length);

	/// The gateway's TLS over a new self-signed certificate for localhost.
	private class Bed
	{
		public MbedTlsBackend Backend = new .() ~ delete _;
		public WebSocketTls Tls = new .() ~ delete _;

		public this()
		{
			let error = scope String();
			let made = TlsCertificates.CreateSelfSigned("localhost", TlsCertificates.Time(-1, .. scope .()), TlsCertificates.Time(30, .. scope .()),
				Tls.Config.CertificateChainPem, Tls.Config.PrivateKeyPem, error);
			Test.Assert(made, error);
			Tls.Backend = Backend;
		}
	}

	/// Pumps the gateway and the client stream until `done` or about three seconds.
	private static bool PumpUntil(WebSocketServerGateway gateway, INetByteStream client, List<uint8> received, delegate bool() done)
	{
		uint8[1024] chunk = ?;
		for (int i < 3000)
		{
			gateway.Pump();
			client.Pump();
			for (var n = client.Receive(.(&chunk[0], chunk.Count)); n > 0; n = client.Receive(.(&chunk[0], chunk.Count)))
				received.AddRange(Span<uint8>(&chunk[0], (int)n));
			if (done())
				return true;
			Thread.Sleep(1);
		}
		return false;
	}

	private static bool StartsWith(List<uint8> bytes, StringView prefix) =>
		(bytes.Count >= prefix.Length) && (StringView((char8*)bytes.Ptr, prefix.Length) == prefix);

	[Test]
	public static void ATlsClientUpgradesThroughTheGatewayAndExchangesBinaryFramesBothWays()
	{
		let bed = scope Bed();
		let gateway = scope WebSocketServerGateway(0, bed.Tls);
		Test.Assert(gateway.IsOpen, scope String(gateway.Failure));
		Test.Assert(gateway.IsSecure);

		let config = scope TlsClientConfig();
		config.ServerName.Set("localhost");
		config.TrustPem(bed.Tls.Config.CertificateChainPem);
		let client = scope TlsStream(TcpSocket.Connect("127.0.0.1", gateway.BoundPort), bed.Backend.CreateClient(config));
		Test.Assert(client.Send(Bytes(cUpgrade)) > 0);
		let received = scope List<uint8>();
		Test.Assert(PumpUntil(gateway, client, received, scope () => StartsWith(received, "HTTP/1.1 101")), scope String(client.Failure));

		let event = scope WsGatewayEvent();
		var connected = false;
		while (gateway.Poll(event))
			connected = connected || (event.Kind == .Connected);
		Test.Assert(connected);

		// Client to gateway: one masked binary frame.
		uint8[4] payload = .(1, 2, 3, 250);
		let frame = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, .(&payload[0], payload.Count), true, 0x12345678, frame);
		Test.Assert(client.Send(frame) > 0);
		var message = false;
		let got = scope List<uint8>();
		Test.Assert(PumpUntil(gateway, client, received, scope [&]() =>
			{
				while (gateway.Poll(event))
				{
					if (event.Kind == .Message)
					{
						message = true;
						got.Clear();
						got.AddRange(event.Payload);
					}
				}
				return message;
			}));
		Test.Assert(got.Count == 4);
		Test.Assert(got[3] == 250);

		// Gateway to client: an unmasked binary frame after the 101's head.
		received.Clear();
		gateway.SendBinary(1, .(&payload[0], 3)); // the gateway's first client
		Test.Assert(PumpUntil(gateway, client, received, scope () => received.Count >= 5));
		Test.Assert((received[0] & 0x0F) == 0x2);
		Test.Assert(received[1] == 3);
		Test.Assert(received[4] == 3);
	}

	[Test]
	public static void APlainClientGetsNoUpgradeFromATlsGateway()
	{
		let bed = scope Bed();
		let gateway = scope WebSocketServerGateway(0, bed.Tls);
		Test.Assert(gateway.IsOpen, scope String(gateway.Failure));
		let client = scope PlainStream(TcpSocket.Connect("127.0.0.1", gateway.BoundPort));
		Test.Assert(client.Send(Bytes(cUpgrade)) > 0);
		let received = scope List<uint8>();
		// The gateway reads the HTTP text as a broken handshake and drops the connection.
		uint8[16] b = ?;
		Test.Assert(PumpUntil(gateway, client, received, scope [&]() => client.Receive(.(&b[0], b.Count)) < 0));
		Test.Assert(!StartsWith(received, "HTTP/1.1 101"));
		let event = scope WsGatewayEvent();
		while (gateway.Poll(event))
			Test.Assert(event.Kind != .Connected);
	}

	[Test]
	public static void AKeyThatDoesNotLoadLeavesTheGatewayClosedSayingWhy()
	{
		let bed = scope Bed();
		bed.Tls.Config.PrivateKeyPem.Set("not a key");
		let gateway = scope WebSocketServerGateway(0, bed.Tls);
		Test.Assert(!gateway.IsOpen);
		Test.Assert(!gateway.Failure.IsEmpty);

		let none = scope WebSocketTls();
		let noBackend = scope WebSocketServerGateway(0, none);
		Test.Assert(!noBackend.IsOpen);
		Test.Assert(noBackend.Failure.Contains("TLS backend", true), scope String(noBackend.Failure));
	}

	// ---- the native client socket -------------------------------------------------------------

	private static bool SameBytes(List<uint8> a, List<uint8> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i < a.Count)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}

	/// Pumps the gateway and drains the client until `done` or about three seconds; what the
	/// client receives collects in `got`, the gateway's messages in `atGateway`.
	private static bool Exchange(WebSocketServerGateway gateway, WebSocketClientSocket client, List<List<uint8>> got,
		List<List<uint8>> atGateway, ref uint32 clientId, delegate bool() done)
	{
		let event = scope WsGatewayEvent();
		let datagram = scope List<uint8>();
		for (int i < 3000)
		{
			gateway.Pump();
			while (gateway.Poll(event))
			{
				if (event.Kind == .Connected)
					clientId = event.Client;
				else if (event.Kind == .Message)
					atGateway.Add(new List<uint8>()..AddRange(event.Payload));
			}
			DatagramEndpoint source;
			while (client.Receive(out source, datagram))
			{
				Test.Assert(source == WebSocketClientSocket.ServerEndpoint);
				got.Add(new List<uint8>()..AddRange(datagram));
			}
			if (done())
				return true;
			Thread.Sleep(1);
		}
		return false;
	}

	private static void JoinAndTalk(WebSocketServerGateway gateway, WebSocketClientConfig config)
	{
		let client = scope WebSocketClientSocket(config);
		Test.Assert(client.IsOpen, scope String(client.Failure));
		// Sent before the upgrade: held, then delivered in order.
		uint8[1] first = .(7);
		uint8[2] second = .(8, 9);
		client.Send(WebSocketClientSocket.ServerEndpoint, .(&first[0], 1));
		client.Send(WebSocketClientSocket.ServerEndpoint, .(&second[0], 2));
		let got = scope List<List<uint8>>();
		defer { ClearAndDeleteItems!(got); }
		let atGateway = scope List<List<uint8>>();
		defer { ClearAndDeleteItems!(atGateway); }
		uint32 id = 0;
		Test.Assert(Exchange(gateway, client, got, atGateway, ref id, scope () => atGateway.Count == 2), scope String(client.Failure));
		Test.Assert(client.IsConnected);
		Test.Assert(atGateway[0].Count == 1);
		Test.Assert(atGateway[1][1] == 9);

		// A big one each way (16-bit and 64-bit lengths), then a small one back.
		let big = scope List<uint8>();
		for (int i < 70000)
			big.Add((uint8)(i * 31));
		client.Send(WebSocketClientSocket.ServerEndpoint, big);
		gateway.SendBinary(id, big);
		gateway.SendBinary(id, .(&second[0], 2));
		Test.Assert(Exchange(gateway, client, got, atGateway, ref id, scope () => (atGateway.Count == 3) && (got.Count == 2)));
		Test.Assert(SameBytes(atGateway[2], big));
		Test.Assert(SameBytes(got[0], big));
		Test.Assert(got[1].Count == 2);

		// The gateway drops it: the client sees the close.
		gateway.DisconnectClient(id);
		Test.Assert(Exchange(gateway, client, got, atGateway, ref id, scope () => !client.IsOpen));
		Test.Assert(client.Failure.Contains("closed", true), scope String(client.Failure));
	}

	[Test]
	public static void AClientJoinsTheGatewayOverWsDatagramsBothWaysSendsBeforeTheUpgradeHeld()
	{
		let gateway = scope WebSocketServerGateway(0);
		Test.Assert(gateway.IsOpen);
		let config = scope WebSocketClientConfig();
		config.Host.Set("127.0.0.1");
		config.Port = gateway.BoundPort;
		JoinAndTalk(gateway, config);
	}

	[Test]
	public static void AClientJoinsTheGatewayOverWssWithTheHostsCertificateTrusted()
	{
		let bed = scope Bed();
		let gateway = scope WebSocketServerGateway(0, bed.Tls);
		Test.Assert(gateway.IsOpen, scope String(gateway.Failure));
		let config = scope WebSocketClientConfig();
		config.Host.Set("localhost");
		config.Port = gateway.BoundPort;
		config.Secure = true;
		config.Tls = bed.Backend;
		config.Trust = .Roots;
		config.TrustedPem.Set(bed.Tls.Config.CertificateChainPem);
		JoinAndTalk(gateway, config);
	}

	[Test]
	public static void ACertificateItDoesNotTrustWssWithNoBackendAndAPlainGatewayRefused()
	{
		let bed = scope Bed();
		let other = scope Bed();
		let gateway = scope WebSocketServerGateway(0, bed.Tls);
		Test.Assert(gateway.IsOpen, scope String(gateway.Failure));
		let got = scope List<List<uint8>>();
		defer { ClearAndDeleteItems!(got); }
		let atGateway = scope List<List<uint8>>();
		defer { ClearAndDeleteItems!(atGateway); }

		let config = scope WebSocketClientConfig();
		config.Host.Set("localhost");
		config.Port = gateway.BoundPort;
		config.Secure = true;
		config.Tls = bed.Backend;
		config.Trust = .Roots;
		config.TrustedPem.Set(other.Tls.Config.CertificateChainPem);
		{
			let client = scope WebSocketClientSocket(config);
			uint32 id = 0;
			Test.Assert(Exchange(gateway, client, got, atGateway, ref id, scope () => !client.IsOpen));
			Test.Assert(!client.IsConnected);
			Test.Assert(client.Failure.Contains("refused", true), scope String(client.Failure));
			Test.Assert(id == 0);
		}
		config.Tls = null;
		{
			let client = scope WebSocketClientSocket(config);
			Test.Assert(!client.IsOpen);
			Test.Assert(client.Failure.Contains("TLS backend", true), scope String(client.Failure));
		}
		// wss to a plain gateway: the TLS hello is not an upgrade request; refused.
		let plain = scope WebSocketServerGateway(0);
		config.Port = plain.BoundPort;
		config.Tls = bed.Backend;
		config.TrustedPem.Set(bed.Tls.Config.CertificateChainPem);
		{
			let client = scope WebSocketClientSocket(config);
			uint32 id = 0;
			Test.Assert(Exchange(plain, client, got, atGateway, ref id, scope () => !client.IsOpen));
			Test.Assert(!client.Failure.IsEmpty);
		}
	}

	[Test]
	public static void AHostThatNeverUpgradesIsGivenUpOnSayingSo()
	{
		let silent = scope TcpListener(0, true); // accepts (the operating system does), never answers
		let config = scope WebSocketClientConfig();
		config.Host.Set("127.0.0.1");
		config.Port = silent.BoundPort;
		config.UpgradeTimeoutSeconds = 0.3f;
		let client = scope WebSocketClientSocket(config);
		Test.Assert(client.IsOpen, scope String(client.Failure));
		let datagram = scope List<uint8>();
		for (int i < 3000)
		{
			if (!client.IsOpen)
				break;
			client.Receive(let source, datagram);
			Thread.Sleep(1);
		}
		Test.Assert(!client.IsOpen);
		Test.Assert(client.Failure.Contains("in time", true), scope String(client.Failure));
	}

	[Test]
	public static void TheClientSidesParserTakesUnmaskedFramesAndRefusesMaskedOnes()
	{
		uint8[2] payload = .(1, 2);
		let unmasked = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, .(&payload[0], 2), false, 0, unmasked);
		let client = scope WebSocketFrameParser(false);
		client.Push(unmasked);
		let frame = scope WsFrame();
		Test.Assert(client.Next(frame));
		Test.Assert(frame.Payload.Count == 2);
		let masked = scope List<uint8>();
		WebSocketFrame.Encode(.Binary, .(&payload[0], 2), true, 0x01020304, masked);
		let strict = scope WebSocketFrameParser(false);
		strict.Push(masked);
		Test.Assert(!strict.Next(frame));
		Test.Assert(strict.Failed);
	}

	[Test]
	public static void JoinAddressesWithASchemeAreReadABareHostIsNotOne()
	{
		let c = scope WebSocketClientConfig();
		Test.Assert(c.ParseAddress("wss://play.example.com/ball", 7000));
		Test.Assert(c.Secure);
		Test.Assert(c.Host == "play.example.com");
		Test.Assert(c.Port == 7000);
		Test.Assert(c.Path == "/ball");
		Test.Assert(c.ParseAddress("WS://10.0.0.2:7010", 7000));
		Test.Assert(!c.Secure);
		Test.Assert(c.Host == "10.0.0.2");
		Test.Assert(c.Port == 7010);
		Test.Assert(c.Path == "/");
		Test.Assert(c.ParseAddress("wss://host", 0));
		Test.Assert(c.Port == 443);
		Test.Assert(!c.ParseAddress("10.0.0.2", 7000));
		Test.Assert(!c.ParseAddress("https://host/", 7000));
		Test.Assert(!c.ParseAddress("wss://", 7000));
		Test.Assert(!c.ParseAddress("ws://host:99999", 7000));
	}
}
