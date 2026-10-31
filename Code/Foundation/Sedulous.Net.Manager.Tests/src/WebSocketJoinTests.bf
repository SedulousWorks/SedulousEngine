using System;
using System.Collections;
using System.Threading;
using Sedulous.Net;
using Sedulous.Net.Manager;
using Sedulous.Net.Tls;
using Sedulous.Net.Tls.MbedTLS;
using Sedulous.Net.WebSocket;

namespace Sedulous.Net.Manager.Tests;

/// Joining a host's WebSocket gateway by address: a native client given "ws://..." or "wss://..."
/// joins over a WebSocket instead of UDP, the session and its RPCs unchanged; wss with the host's
/// certificate trusted.
class WebSocketJoinTests
{
	/// A port nothing listens on: the probe's, closed on return (as other tests do).
	private static uint16 FreePort()
	{
		let probe = scope TcpListener(0, true);
		return probe.BoundPort;
	}

	/// The client joins, then calls an RPC the host hears.
	private static void JoinAndCall(NetworkManager server, NetworkManager client)
	{
		for (int i < 2000)
		{
			if (server.Session.PeerCount != 0)
				break;
			server.Update(16.0f);
			client.Update(16.0f);
			Thread.Sleep(1);
		}
		Test.Assert(server.Session.PeerCount == 1);
		var got = false;
		server.Rpc.On("wave", new [&got](sender, args) => { got = true; });
		client.Rpc.Call(client.Session, client.Session.ServerPeer, "wave");
		for (int i < 2000)
		{
			if (got)
				break;
			server.Update(16.0f);
			client.Update(16.0f);
			Thread.Sleep(1);
		}
		Test.Assert(got);
	}

	[Test]
	public static void AWsAddressJoinsTheHostsGatewayNatively()
	{
		let webSocketPort = FreePort();
		let server = NetworkManager.HostServer(0, true, .(), webSocketPort);
		Test.Assert(server != null);
		defer delete server;
		let client = NetworkManager.JoinServer(scope $"ws://127.0.0.1:{webSocketPort}", 0);
		Test.Assert(client != null);
		defer delete client;
		Test.Assert(client.BoundPort == 0, "no UDP socket of its own");
		JoinAndCall(server, client);
	}

	[Test]
	public static void AWssAddressJoinsAHostWithACertificateTrusted()
	{
		let backend = scope MbedTlsBackend();
		let tls = scope WebSocketTls();
		tls.Backend = backend;
		let error = scope String();
		Test.Assert(TlsCertificates.CreateSelfSigned("localhost", TlsCertificates.Time(-1, .. scope .()), TlsCertificates.Time(30, .. scope .()),
			tls.Config.CertificateChainPem, tls.Config.PrivateKeyPem, error), error);
		let webSocketPort = FreePort();
		let server = NetworkManager.HostServer(0, true, .(), webSocketPort, tls);
		Test.Assert(server != null);
		defer delete server;
		let client = NetworkManager.JoinServer("wss://localhost", webSocketPort, .(), backend, .Roots, tls.Config.CertificateChainPem);
		Test.Assert(client != null);
		defer delete client;
		JoinAndCall(server, client);

		// wss with no backend: no join; and HostServer with a key that does not load: no host.
		Test.Assert(NetworkManager.JoinServer("wss://localhost", webSocketPort) == null);
		tls.Config.PrivateKeyPem.Set("not a key");
		Test.Assert(NetworkManager.HostServer(0, true, .(), FreePort(), tls) == null);
	}
}
