using System;
using System.Collections;
using System.Threading;
using Sedulous.Net;

namespace Sedulous.Net.Tests;

/// The real socket backends, over loopback. These are the only tests here that touch the
/// operating system: everything above them runs on the sim.
class SocketTests
{
	/// Retries a non blocking operation for up to this long. Generous, because the loopback
	/// is fast but a loaded build machine is not.
	private const int cPollAttempts = 300;

	[Test]
	public static void EndpointPackingRoundTrips()
	{
		let endpoint = NetAddress.ResolveEndpoint("192.168.1.42", 7777);
		Test.Assert(endpoint.IsValid);
		Test.Assert(NetAddress.EndpointPort(endpoint) == 7777);
		// Host order, so the octets read left to right as they are written.
		Test.Assert(NetAddress.EndpointIp(endpoint) == 0xC0A8012A);

		Test.Assert(!NetAddress.ResolveEndpoint("not.an.ip", 80).IsValid);
	}

	[Test]
	public static void AHostNameResolvesThroughThePlatformResolver()
	{
		// Localhost is in every hosts file, so this exercises the resolver path without
		// needing a network.
		let endpoint = NetAddress.ResolveEndpoint("localhost", 4242);
		Test.Assert(endpoint.IsValid);
		Test.Assert(NetAddress.EndpointPort(endpoint) == 4242);
		Test.Assert(NetAddress.EndpointIp(endpoint) == 0x7F000001);

		// A literal resolves too, and must not depend on the resolver being reachable.
		Test.Assert(NetAddress.ResolveHostIPv4("127.0.0.1", let literal));
		Test.Assert(literal == 0x7F000001);

		Test.Assert(!NetAddress.ResolveHostIPv4("", let empty));
		// The .invalid domain is reserved by RFC 2606 and can never resolve.
		Test.Assert(!NetAddress.ResolveHostIPv4("no-such-host.invalid", let missing));
	}

	[Test]
	public static void TwoUdpSocketsBindDistinctPortsAndExchangeADatagram()
	{
		let a = scope UdpSocket(0);
		let b = scope UdpSocket(0);
		Test.Assert(a.IsOpen);
		Test.Assert(b.IsOpen);

		// A zero bind asks the operating system to choose, and BoundPort is how we learn what
		// it chose. Beef's corlib socket never reports this, so Net asks for it directly.
		Test.Assert(a.BoundPort != 0);
		Test.Assert(b.BoundPort != 0);
		Test.Assert(a.BoundPort != b.BoundPort);

		let message = scope uint8[](0xDE, 0xAD);
		a.Send(b.LocalEndpoint, message);

		let got = scope List<uint8>();
		var received = false;
		DatagramEndpoint from = .();
		for (int i = 0; (i < cPollAttempts) && !received; i++)
		{
			if (b.Receive(out from, got))
			{
				received = true;
				break;
			}
			Thread.Sleep(1);
		}

		Test.Assert(received);
		Test.Assert(got.Count == 2);
		Test.Assert(got[0] == 0xDE);
		// The sender is identified by the port it bound, which is what lets the reliable
		// transport key a connection off a datagram.
		Test.Assert(NetAddress.EndpointPort(from) == a.BoundPort);
	}

	[Test]
	public static void ATcpStreamConnectsAcceptsAndCarriesBytesBothWays()
	{
		let listener = scope TcpListener(0);
		Test.Assert(listener.IsOpen);
		Test.Assert(listener.BoundPort != 0);

		let client = TcpSocket.Connect("127.0.0.1", listener.BoundPort);
		defer delete client;
		Test.Assert(client.IsOpen);

		// Drive the non blocking connect and accept to completion.
		TcpSocket server = null;
		defer { if (server != null) delete server; }
		for (int i = 0; i < cPollAttempts; i++)
		{
			if (server == null)
				server = listener.Accept();
			if ((server != null) && (client.ConnectStatus == 1))
				break;
			Thread.Sleep(1);
		}
		Test.Assert(server != null);
		Test.Assert(client.ConnectStatus == 1);

		let outgoing = scope uint8[](0x01, 0x02, 0x03, 0x04);
		Test.Assert(client.Send(outgoing) == 4);

		let buffer = scope uint8[64];
		int64 got = 0;
		for (int i = 0; (i < cPollAttempts) && (got <= 0); i++)
		{
			got = server.Receive(buffer);
			if (got <= 0)
				Thread.Sleep(1);
		}
		Test.Assert(got == 4);
		Test.Assert(buffer[0] == 0x01);
		Test.Assert(buffer[3] == 0x04);

		Test.Assert(server.Send(Span<uint8>(&buffer[0], 4)) == 4);

		let back = scope uint8[64];
		int64 returned = 0;
		for (int i = 0; (i < cPollAttempts) && (returned <= 0); i++)
		{
			returned = client.Receive(back);
			if (returned <= 0)
				Thread.Sleep(1);
		}
		Test.Assert(returned == 4);
		Test.Assert(back[0] == 0x01);
	}

	[Test]
	public static void ClosingOneEndIsSeenAsAClosedStreamByTheOther()
	{
		let listener = scope TcpListener(0);
		Test.Assert(listener.IsOpen);

		let client = TcpSocket.Connect("127.0.0.1", listener.BoundPort);
		defer delete client;

		TcpSocket server = null;
		defer { if (server != null) delete server; }
		for (int i = 0; i < cPollAttempts; i++)
		{
			if (server == null)
				server = listener.Accept();
			if ((server != null) && (client.ConnectStatus == 1))
				break;
			Thread.Sleep(1);
		}
		Test.Assert(server != null);

		client.Close();

		// Minus one rather than nought: nought means nothing yet, and the difference is what
		// lets a caller tell a quiet peer from a gone one.
		let buffer = scope uint8[64];
		int64 afterClose = 0;
		for (int i = 0; i < cPollAttempts; i++)
		{
			afterClose = server.Receive(buffer);
			if (afterClose != 0)
				break;
			Thread.Sleep(1);
		}
		Test.Assert(afterClose == -1);
	}

	[Test]
	public static void ConnectingToAnUnresolvableHostFails()
	{
		let socket = TcpSocket.Connect("no-such-host.invalid", 80);
		defer delete socket;
		Test.Assert(socket.ConnectStatus == -1);
	}
}
