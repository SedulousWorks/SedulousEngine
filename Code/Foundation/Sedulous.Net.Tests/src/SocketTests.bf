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

		// Windows resolves an empty name to the local host, so the refusal is ours to make.
		Test.Assert(!NetAddress.ResolveHostIPv4("", let empty));
		// The .invalid domain is reserved by RFC 2606 and can never resolve.
		Test.Assert(!NetAddress.ResolveHostIPv4("no-such-host.invalid", let missing));
	}

	/// A literal is read HERE rather than by the platform, so what counts as one cannot drift
	/// between an inet_pton that takes shortened forms and one that does not.
	[Test]
	public static void ADottedQuadIsReadWithoutTheResolver()
	{
		Test.Assert(NetAddress.ParseIPv4("0.0.0.0", let zero));
		Test.Assert(zero == 0);
		Test.Assert(NetAddress.ParseIPv4("127.0.0.1", let loopback));
		Test.Assert(loopback == 0x7F000001);
		Test.Assert(NetAddress.ParseIPv4("255.255.255.255", let broadcast));
		Test.Assert(broadcast == 0xFFFFFFFF);
		Test.Assert(NetAddress.ParseIPv4("192.168.0.42", let lan));
		Test.Assert(lan == 0xC0A8002A);

		Test.Assert(!NetAddress.ParseIPv4("", let empty));
		Test.Assert(!NetAddress.ParseIPv4("127.0.0", let short));
		Test.Assert(!NetAddress.ParseIPv4("127.0.0.1.5", let long));
		Test.Assert(!NetAddress.ParseIPv4("127.0.0.256", let overflow));
		Test.Assert(!NetAddress.ParseIPv4("127.0.0.0001", let padded));
		Test.Assert(!NetAddress.ParseIPv4("127.0..1", let hole));
		Test.Assert(!NetAddress.ParseIPv4("127.0.0.1 ", let trailing));
		Test.Assert(!NetAddress.ParseIPv4(" 127.0.0.1", let leading));
		Test.Assert(!NetAddress.ParseIPv4("127.0.0.1:80", let ported));
		Test.Assert(!NetAddress.ParseIPv4("localhost", let name));
		Test.Assert(!NetAddress.ParseIPv4("-1.0.0.1", let negative));
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
	public static void AQuietPeerReadsAsZeroAndAGonePeerAsMinusOne()
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

		// Connected and silent. NOUGHT, not minus one: the difference is the whole non
		// blocking contract, and conflating them makes a server drop every live connection on
		// its first quiet read.
		let buffer = scope uint8[64];
		Test.Assert(server.Receive(buffer) == 0);
		Test.Assert(client.Receive(buffer) == 0);

		client.Close();

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
	[Test]
	public static void ConnectByNameReachesAListenerOnLoopback()
	{
		// The dotted quad path is covered above. This one goes through the resolver, which is
		// a different branch of Connect and the one an ordinary caller takes.
		let listener = scope TcpListener(0);
		Test.Assert(listener.IsOpen);

		let client = TcpSocket.Connect("localhost", listener.BoundPort);
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
		Test.Assert(client.ConnectStatus == 1);
	}

	[Test]
	public static void TheReliableTransportHandshakesAndDeliversOverRealSockets()
	{
		// Everything else about the transport runs on the sim, which delivers synchronously.
		// This one puts it on the OS stack, where a packet arrives when it arrives, so a
		// handshake that only works against the sim's timing would show up here.
		let serverSocket = scope UdpSocket(0);
		let clientSocket = scope UdpSocket(0);
		Test.Assert(serverSocket.IsOpen);
		Test.Assert(clientSocket.IsOpen);

		let server = scope ReliableTransport(serverSocket);
		let client = scope ReliableTransport(clientSocket);
		server.SetAccepting(true);
		let peer = client.Connect(serverSocket.LocalEndpoint);

		delegate void(int) pump = scope [&] (count) =>
			{
				for (int i = 0; i < count; i++)
				{
					client.Update(10.0f);
					server.Update(10.0f);
					Thread.Sleep(1);
				}
			};

		pump(30);

		let event = scope NetEvent();
		var connected = false;
		while (server.Poll(event))
		{
			if (event.Kind == .Connected)
				connected = true;
		}
		Test.Assert(connected);

		let payload = scope uint8[](0xCA, 0xFE, 0xBA, 0xBE);
		client.Send(peer, 0, payload, .ReliableOrdered);

		var delivered = false;
		for (int i = 0; (i < 100) && !delivered; i++)
		{
			pump(2);
			while (server.Poll(event))
			{
				if ((event.Kind == .Received) && (event.Payload.Count == 4)
					&& (event.Payload[0] == 0xCA) && (event.Payload[3] == 0xBE))
					delivered = true;
			}
		}
		Test.Assert(delivered);
	}

	/// A connected pair: the listener's accepted side, and the client. Both OWNED by the caller.
	private static void Connect(TcpListener listener, out TcpSocket outServer, out TcpSocket outClient)
	{
		outClient = TcpSocket.Connect("127.0.0.1", listener.BoundPort);
		outServer = null;
		for (int i = 0; i < cPollAttempts; i++)
		{
			if (outServer == null)
				outServer = listener.Accept();
			if ((outServer != null) && (outClient.ConnectStatus == 1))
				break;
			Thread.Sleep(1);
		}
	}

	[Test]
	public static void ALoopbackListenerBindsOnlyTheLocalAddress()
	{
		let local = scope TcpListener(0, true);
		Test.Assert(local.IsOpen);
		Test.Assert(local.BoundIp == NetAddress.PackIPv4(.(127, 0, 0, 1)));
		Connect(local, let server, let client);
		defer { delete server; delete client; }
		Test.Assert(server != null, "a local client still connects");

		let everywhere = scope TcpListener(0);
		Test.Assert(everywhere.IsOpen);
		Test.Assert(everywhere.BoundIp == 0, "the default is every interface");
	}

	/// A server that closes its side first leaves the connection in TIME_WAIT on its port for
	/// about a minute; a restarted server must still be able to listen there at once.
	[Test]
	public static void ARestartedListenerRebindsItsPortAtOnce()
	{
		uint16 port = 0;
		{
			let first = scope TcpListener(0, true);
			Test.Assert(first.IsOpen);
			port = first.BoundPort;
			Connect(first, let server, let client);
			Test.Assert(server != null);
			delete server; // the server closes first: its side of the port is in TIME_WAIT
			Thread.Sleep(20);
			delete client;
		}
		let again = scope TcpListener(port, true);
		Test.Assert(again.IsOpen, "the port rebinds while its old connection is in TIME_WAIT");
		Test.Assert(again.BoundPort == port);
	}
}
