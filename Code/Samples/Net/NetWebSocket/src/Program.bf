namespace NetWebSocket;

using System;
using System.Threading;
using System.Collections;
using Sedulous.Net;
using Sedulous.Net.HTTP;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Core.Logging.Debug;

/// WebSocket echo demo.
/// Starts an HTTP server with WebSocket upgrade support, connects a client,
/// sends text/binary messages, and receives echoes.
class Program
{
	public static int Main(String[] args)
	{
		ILogger logger = scope DebugLogger(.Trace);
		logger.LogTrace("=== WebSocket Echo Demo ===\n");

		let server = scope HttpServer();
		let wsConnections = scope List<WebSocketConnection>();
		defer { ClearAndDeleteItems!(wsConnections); }

		// Configure WebSocket upgrade handler
		server.OnWebSocketUpgrade = new [&](client, request) => {
			let ws = new WebSocketConnection();
			if (ws.AcceptUpgrade(client, request, true) case .Ok)
			{
				logger.LogTrace("[Server] WebSocket connection accepted");
				wsConnections.Add(ws);
				return true;
			}
			delete ws;
			return false;
		};

		// Also add a regular HTTP endpoint
		server.Get("/", new (req, resp) => {
			resp.StatusCode = .OK;
			resp.ReasonPhrase.Set("OK");
			resp.SetBody("WebSocket Echo Server - connect with ws://127.0.0.1:9300/");
		});

		if (server.Start(.(IPAddress(127, 0, 0, 1), 9300)) case .Err(let err))
		{
			let desc = scope String();
			err.GetDescription(desc);
			logger.LogError("Server start failed: {}", desc);
			return 1;
		}

		logger.LogTrace("Server running on ws://127.0.0.1:9300\n");

		// Server processing thread
		var serverDone = false;
		let serverThread = scope Thread(new [&]() => {
			while (!serverDone)
			{
				server.Update();

				// Echo back received messages
				for (let ws in wsConnections)
				{
					if (ws.State != .Open) continue;
					let msg = ws.Receive();
					if (msg != null)
					{
						switch (msg.OpCode)
						{
						case .Text:
							let text = scope String();
							msg.GetText(text);
							logger.LogTrace("[Server] Received text: \"{}\"", text);
							ws.SendText(text);
							logger.LogTrace("[Server] Echoed text back");
						case .Binary:
							logger.LogTrace("[Server] Received {} bytes binary", msg.Data.Count);
							ws.SendBinary(Span<uint8>(msg.Data.Ptr, msg.Data.Count));
							logger.LogTrace("[Server] Echoed binary back");
						default:
						}
						delete msg;
					}
				}

				Thread.Sleep(10);
			}
		});
		serverThread.Start(false);

		Thread.Sleep(100);

		// Connect WebSocket client
		let wsClient = scope WebSocketClient();
		logger.LogTrace("[Client] Connecting...");

		if (wsClient.Connect("127.0.0.1", 9300) case .Err(let connectErr))
		{
			let desc = scope String();
			connectErr.GetDescription(desc);
			logger.LogError("[Client] Connect failed: {}", desc);
			serverDone = true;
			serverThread.Join();
			server.Stop();
			return 1;
		}

		logger.LogTrace("[Client] Connected! State: {}\n", wsClient.State);

		// Send text messages
		StringView[?] messages = .("Hello WebSocket!", "Testing 1 2 3", "Beef networking is cool!");

		for (let msg in messages)
		{
			logger.LogTrace("[Client] Sending: \"{}\"", msg);
			wsClient.SendText(msg);
			Thread.Sleep(200);

			let reply = wsClient.Receive();
			if (reply != null)
			{
				let text = scope String();
				reply.GetText(text);
				logger.LogTrace("[Client] Got echo: \"{}\"\n", text);
				delete reply;
			}
			else
			{
				logger.LogTrace("[Client] No reply yet\n");
			}
		}

		// Send binary data
		logger.LogTrace("[Client] Sending 16 bytes of binary data");
		uint8[16] binData = default;
		for (int i = 0; i < 16; i++)
			binData[i] = (uint8)(i * 17);
		wsClient.SendBinary(Span<uint8>(&binData, 16));
		Thread.Sleep(200);

		let binReply = wsClient.Receive();
		if (binReply != null)
		{
			logger.LogTrace("[Client] Got {} bytes binary echo", binReply.Data.Count);
			delete binReply;
		}

		// Close
		logger.LogTrace("\n[Client] Closing connection...");
		wsClient.Close();
		logger.LogTrace("[Client] State: {}", wsClient.State);

		// Cleanup
		serverDone = true;
		serverThread.Join();
		server.Stop();

		logger.LogTrace("\n=== Done ===");
		return 0;
	}
}
