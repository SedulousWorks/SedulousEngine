using System;
using System.Collections;
using System.Threading;
using Sedulous.Net;

namespace Sedulous.Net.WebSocket.Tests;

/// The gateway and the hybrid socket over REAL loopback sockets.
///
/// The rest of this suite feeds buffers to the codec and the handshake, which is where the
/// protocol's edges live. These three cases cover what a buffer cannot reach: that an accept
/// actually completes, that a frame survives the wire in both directions, and that a browser
/// peer and a native UDP peer land as distinct endpoints on one socket. WebSocketServerGateway
/// and WebSocketHybridSocket are what NetworkManager runs a browser client on, so this is
/// coverage of shipped code rather than of a test fixture.
///
/// Every loop PUMPS. Both ends of each conversation live on the test's own thread.
static class WebSocketGatewayTests
{
	/// Port 0, so the OS picks a free one and two suites running at once cannot collide.
	private const uint16 cEphemeral = 0;

	[Test]
	public static void AClientUpgradesExchangesBinaryFramesAndIsPonged()
	{
		let gateway = scope WebSocketServerGateway(cEphemeral);
		Test.Assert(gateway.IsOpen, "the gateway bound a listener");
		Test.Assert(gateway.BoundPort != 0, "the OS handed back a real port");

		let client = scope WsLoopbackClient();
		Test.Assert(client.ConnectAndUpgrade(gateway, gateway.BoundPort),
			"the handshake answered 101");

		// The upgrade produces a Connected event, which is what names the client.
		let event = scope WsGatewayEvent();
		var connected = false;
		var clientId = (uint32)0;
		for (int i = 0; (i < 300) && !connected; i++)
		{
			gateway.Pump();
			while (gateway.Poll(event))
			{
				if (event.Kind == .Connected)
				{
					connected = true;
					clientId = event.Client;
				}
			}
			if (!connected)
				Thread.Sleep(1);
		}
		Test.Assert(connected, "the upgrade raised Connected");
		Test.Assert(gateway.ClientCount == 1, scope $"got {gateway.ClientCount} clients");

		// client -> gateway.
		let hello = scope List<uint8>();
		Bytes("hi server", hello);
		client.SendBinary(.(hello.Ptr, hello.Count));

		var received = false;
		for (int i = 0; (i < 500) && !received; i++)
		{
			gateway.Pump();
			while (gateway.Poll(event))
			{
				if (event.Kind == .Message)
				{
					received = true;
					Test.Assert(event.Client == clientId, "the message named the same client");
					Test.Assert(event.Payload.Count == hello.Count,
						scope $"got {event.Payload.Count} bytes, sent {hello.Count}");
					for (int j < hello.Count)
						Test.Assert(event.Payload[j] == hello[j], "the payload arrived intact");
				}
			}
			if (!received)
				Thread.Sleep(1);
		}
		Test.Assert(received, "the gateway raised Message for the client's frame");

		// gateway -> client.
		let reply = scope List<uint8>();
		Bytes("hi browser", reply);
		gateway.SendBinary(clientId, .(reply.Ptr, reply.Count));

		let got = scope List<uint8>();
		Test.Assert(client.ReceiveBinary(gateway, got), "the client read a binary frame back");
		Test.Assert(got.Count == reply.Count, scope $"got {got.Count} bytes, sent {reply.Count}");
		for (int j < reply.Count)
			Test.Assert(got[j] == reply[j], "the reply arrived intact");

		// A ping is answered with a pong carrying the same payload back.
		let pingBody = scope List<uint8>();
		Bytes("ka", pingBody);
		let wire = scope List<uint8>();
		WebSocketFrame.Encode(.Ping, .(pingBody.Ptr, pingBody.Count), true, 0x1234, wire);
		client.SendRaw(.(wire.Ptr, wire.Count));

		let pongLength = client.WaitForOpcode(gateway, 0xA);
		Test.Assert(pongLength == pingBody.Count,
			scope $"pong carried {pongLength} bytes, ping carried {pingBody.Count}");
	}

	[Test]
	public static void GarbageOnTheAcceptSocketIsRejectedNotCrashedOn()
	{
		let gateway = scope WebSocketServerGateway(cEphemeral);
		Test.Assert(gateway.IsOpen, "the gateway bound a listener");

		// A raw socket that never speaks HTTP. The accept path reads UNTRUSTED bytes, so the
		// question is whether it drops them rather than what it makes of them.
		let rogue = TcpSocket.Connect("127.0.0.1", gateway.BoundPort);
		defer delete rogue;
		Test.Assert(rogue.IsOpen, "the rogue socket opened");

		for (int i = 0; (i < 300) && (rogue.ConnectStatus == 0); i++)
		{
			gateway.Pump();
			Thread.Sleep(1);
		}
		Test.Assert(rogue.ConnectStatus == 1, "the rogue socket connected");

		let junk = scope List<uint8>();
		Bytes("NOT-HTTP \x01\x02 garbage\r\nmore trash\r\n\r\n", junk);
		rogue.Send(.(junk.Ptr, junk.Count));

		for (int i < 200)
		{
			gateway.Pump();
			Thread.Sleep(1);
		}

		// Dropped, with no upgrade and nothing to show for it.
		Test.Assert(gateway.ClientCount == 0,
			scope $"the garbage produced {gateway.ClientCount} clients");
	}

	[Test]
	public static void UdpAndWebSocketPeersArriveAsDistinctEndpoints()
	{
		let hybrid = scope WebSocketHybridSocket(cEphemeral, cEphemeral);
		Test.Assert(hybrid.IsOpen, "both halves bound");
		Test.Assert(hybrid.BoundPort != 0, "the UDP half took a real port");
		Test.Assert(hybrid.WebSocketBoundPort != 0, "the WebSocket half took a real port");

		// A browser peer: its binary frame becomes a datagram carrying the WebSocket bit.
		let browser = scope WsLoopbackClient();
		Test.Assert(browser.ConnectAndUpgrade(hybrid.Gateway, hybrid.WebSocketBoundPort),
			"the browser upgraded against the hybrid's gateway");

		let fromBrowser = scope List<uint8>();
		Bytes("from-browser", fromBrowser);
		browser.SendBinary(.(fromBrowser.Ptr, fromBrowser.Count));

		var wsFrom = DatagramEndpoint();
		let wsPayload = scope List<uint8>();
		var wsGot = false;
		for (int i = 0; (i < 500) && !wsGot; i++)
		{
			DatagramEndpoint from = ?;
			let payload = scope:: List<uint8>();
			while (hybrid.Receive(out from, payload))
			{
				if (WebSocketEndpoint.IsWebSocket(from))
				{
					wsFrom = from;
					wsPayload.Clear();
					wsPayload.AddRange(Span<uint8>(payload.Ptr, payload.Count));
					wsGot = true;
				}
				payload.Clear();
			}
			if (!wsGot)
				Thread.Sleep(1);
		}
		Test.Assert(wsGot, "the browser's frame arrived as a datagram");
		Test.Assert(wsPayload.Count == fromBrowser.Count,
			scope $"got {wsPayload.Count} bytes, sent {fromBrowser.Count}");
		Test.Assert(WebSocketEndpoint.IsWebSocket(wsFrom), "and carried the WebSocket bit");

		// Replying to that endpoint routes back out through the gateway as a frame.
		let toBrowser = scope List<uint8>();
		Bytes("to-browser", toBrowser);
		hybrid.Send(wsFrom, .(toBrowser.Ptr, toBrowser.Count));

		let browserGot = scope List<uint8>();
		Test.Assert(browser.ReceiveBinary(hybrid.Gateway, browserGot),
			"the reply reached the browser as a binary frame");
		Test.Assert(browserGot.Count == toBrowser.Count,
			scope $"got {browserGot.Count} bytes, sent {toBrowser.Count}");

		// A native peer on the SAME socket keeps an ordinary endpoint, with no WebSocket bit.
		let udpPeer = scope UdpSocket(cEphemeral);
		Test.Assert(udpPeer.IsOpen, "the native peer bound");

		let fromNative = scope List<uint8>();
		Bytes("from-native", fromNative);
		udpPeer.Send(NetAddress.MakeEndpoint(0x7F000001, hybrid.BoundPort),
			.(fromNative.Ptr, fromNative.Count));

		var udpGot = false;
		for (int i = 0; (i < 500) && !udpGot; i++)
		{
			DatagramEndpoint from = ?;
			let payload = scope:: List<uint8>();
			while (hybrid.Receive(out from, payload))
			{
				if (!WebSocketEndpoint.IsWebSocket(from) && (payload.Count == fromNative.Count))
					udpGot = true;
				payload.Clear();
			}
			if (!udpGot)
				Thread.Sleep(1);
		}
		Test.Assert(udpGot, "the native peer's datagram arrived without the WebSocket bit");
	}

	private static void Bytes(StringView text, List<uint8> outBytes)
	{
		outBytes.Clear();
		for (let c in text.RawChars)
			outBytes.Add((uint8)c);
	}
}
