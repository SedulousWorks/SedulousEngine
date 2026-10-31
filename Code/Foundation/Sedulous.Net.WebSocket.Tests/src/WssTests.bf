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
/// gateway closed, saying why.
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
}
