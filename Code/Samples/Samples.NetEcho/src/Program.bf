using System;
using System.Collections;
using Sedulous.Net;

namespace Samples.NetEcho;

/// The network stack end to end, with no graphics anywhere: a reliable server and client over
/// REAL localhost sockets exchange a few lines, the server echoing each one back.
///
/// Real sockets rather than the loopback link on purpose. The loopback exercises the protocol;
/// this exercises the protocol ON the operating system's datagrams, which is where fragmenting,
/// reordering and the bind itself actually live.
class Program
{
	private const int cLineCount = 3;

	public static int Main(String[] args)
	{
		let serverSocket = scope UdpSocket(0); // port nought, so the system picks one
		let clientSocket = scope UdpSocket(0);
		if (!serverSocket.IsOpen || !clientSocket.IsOpen)
		{
			Console.Error.WriteLine("NetEcho: the UDP sockets could not be opened");
			return 1;
		}
		Console.WriteLine($"NetEcho: server on :{serverSocket.BoundPort}, client on :{clientSocket.BoundPort}");

		let server = scope ReliableTransport(serverSocket);
		let client = scope ReliableTransport(clientSocket);
		server.SetAccepting(true);
		let serverAsSeenByClient = client.Connect(serverSocket.LocalEndpoint);

		let lines = scope String[](  "hello", "from the client", "over reliable UDP");

		var clientConnected = false;
		var sent = 0;
		var echoed = 0;

		let event = scope NetEvent();
		// BOUNDED rather than open ended: a sample that cannot finish has to fail rather than
		// hang, since this is the shape a smoke test runs in.
		for (int tick = 0; (tick < 1000) && (echoed < cLineCount); tick++)
		{
			client.Update(10.0f);
			server.Update(10.0f);

			// The server echoes whatever arrives straight back to whoever sent it.
			while (server.Poll(event))
			{
				if (event.Kind == .Connected)
				{
					Console.WriteLine($"NetEcho: server: peer {event.Peer} connected");
				}
				else if (event.Kind == .Received)
				{
					let text = scope String((char8*)event.Payload.Ptr, event.Payload.Count);
					Console.WriteLine($"NetEcho: server: recv '{text}' -> echo");
					server.Send(event.Peer, 0, event.Payload, .ReliableOrdered);
				}
			}

			while (client.Poll(event))
			{
				if (event.Kind == .Connected)
				{
					clientConnected = true;
					Console.WriteLine("NetEcho: client: connected to the server");
				}
				else if (event.Kind == .Received)
				{
					let text = scope String((char8*)event.Payload.Ptr, event.Payload.Count);
					Console.WriteLine($"NetEcho: client: echo <- '{text}'");
					echoed++;
				}
			}

			// PACED rather than sent at once, so the lines arrive as a conversation does and
			// the ordering guarantee is what puts them back in order.
			if (clientConnected && (sent < cLineCount) && ((tick % 5) == 0))
			{
				let line = lines[sent++];
				client.Send(serverAsSeenByClient, 0, .((uint8*)line.Ptr, line.Length),
					.ReliableOrdered);
			}
		}

		if (echoed == cLineCount)
		{
			Console.WriteLine($"NetEcho: all {cLineCount} lines round tripped - OK");
			return 0;
		}
		Console.Error.WriteLine($"NetEcho: only {echoed} of {cLineCount} lines echoed");
		return 1;
	}
}
