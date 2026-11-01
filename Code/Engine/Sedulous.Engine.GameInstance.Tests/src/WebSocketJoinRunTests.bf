using System;
using System.Threading;
using Sedulous.Engine.GameInstance;
using Sedulous.Net;

namespace Sedulous.Engine.GameInstance.Tests;

/// A ws:// join address: a native client joins the host's browser gateway, at the game port + 1
/// (the StartServer convention) since the address names none.
class WebSocketJoinRunTests
{
	[Test]
	public static void AWsAddressJoinsTheHostsGatewayAtPortPlusOneNatively()
	{
		// Two free ports in a row (the game's and its gateway's).
		uint16 port = 0;
		for (int attempt < 20)
		{
			let probe = scope TcpListener(0, true);
			let candidate = probe.BoundPort;
			let next = scope TcpListener((uint16)(candidate + 1), true);
			if ((candidate < 65000) && next.IsOpen)
			{
				port = candidate;
				break;
			}
		}
		Test.Assert(port != 0);

		let server = scope GameInstance();
		let client = scope GameInstance();
		Test.Assert(server.StartServer(port, true));
		Test.Assert(server.NetEndpoint != null);
		Test.Assert(server.NetEndpoint.WebSocketBoundPort == port + 1);

		Test.Assert(client.Connect("ws://127.0.0.1", port));
		Test.Assert(client.NetEndpoint != null);
		Test.Assert(client.NetEndpoint.BoundPort == 0, "a websocket, not a UDP socket");
		for (int i < 2000)
		{
			if (server.NetEndpoint.Session.PeerCount != 0)
				break;
			server.NetEndpoint.UpdateTransport(16.0f);
			client.NetEndpoint.UpdateTransport(16.0f);
			Thread.Sleep(1);
		}
		Test.Assert(server.NetEndpoint.Session.PeerCount == 1);
	}
}
