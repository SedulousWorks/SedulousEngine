namespace Sedulous.Net.HTTP.Tests;

using System;
using System.Threading;
using System.Collections;
using Sedulous.Net;
using Sedulous.Net.HTTP;

class WebSocketTests
{
	[Test]
	public static void ComputeAcceptKey()
	{
		// RFC 6455 Section 4.2.2 example
		let acceptKey = scope String();
		WebSocketClient.ComputeAcceptKey("dGhlIHNhbXBsZSBub25jZQ==", acceptKey);
		Test.Assert(acceptKey.Equals("s3pPLMBiTxaQ9kYGzzhZRbK+xOo="));
	}

	[Test]
	public static void WebSocket_Echo()
	{
		// Set up HTTP server with WebSocket support
		let server = scope HttpServer();
		let wsConnections = scope List<WebSocketConnection>();
		defer { ClearAndDeleteItems!(wsConnections); }

		server.OnWebSocketUpgrade = new [&](client, request) => {
			let ws = new WebSocketConnection();
			if (ws.AcceptUpgrade(client, request, true) case .Ok)
			{
				wsConnections.Add(ws);
				return true;
			}
			delete ws;
			return false;
		};

		Test.Assert(server.Start(.(IPAddress(127, 0, 0, 1), 0)) case .Ok);
		let port = server.Port;

		// Server processing thread
		var serverDone = false;
		let serverThread = scope Thread(new [&]() => {
			while (!serverDone)
			{
				server.Update();

				// Echo back received messages
				for (let ws in wsConnections)
				{
					let msg = ws.Receive();
					if (msg != null)
					{
						if (msg.OpCode == .Text)
						{
							let text = scope String();
							msg.GetText(text);
							ws.SendText(text);
						}
						delete msg;
					}
				}

				Thread.Sleep(10);
			}
		});
		serverThread.SetJoinOnDelete(true);
		serverThread.Start(false);

		// Connect client
		let wsClient = scope WebSocketClient();
		if (wsClient.Connect("127.0.0.1", port) case .Ok)
		{
			Test.Assert(wsClient.State == .Open);

			// Send a text message
			Test.Assert(wsClient.SendText("Hello WebSocket!") case .Ok);

			// Wait for echo
			Thread.Sleep(200);

			let msg = wsClient.Receive();
			if (msg != null)
			{
				Test.Assert(msg.OpCode == .Text);
				let text = scope String();
				msg.GetText(text);
				Test.Assert(text.Equals("Hello WebSocket!"));
				delete msg;
			}

			wsClient.Close();
		}

		serverDone = true;
		serverThread.Join();
		server.Stop();
	}
}
