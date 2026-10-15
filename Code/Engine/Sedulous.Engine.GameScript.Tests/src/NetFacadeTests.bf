using System;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameScript.Tests;

/// `Net` to a game script: the run's networking role and its messages, over the instance's
/// controller. Offline every call is harmless; a host and a client are real endpoints on
/// loopback, pumped by hand.
class NetFacadeTests
{
	/// Offline nothing is hosted or joined and a message goes nowhere; a script hosts on an
	/// operating system assigned port and leaves again.
	[Test]
	public static void AScriptHostsAndLeavesAndOfflineCallsAreHarmless()
	{
		let run = scope GameRun("scratch_net_host");
		let game = run.Class("Game", """
			class Game
			{
				bool offlineServer = true;
				int offlinePeers = -1;
				bool hosted = false;
				bool server = false;
				bool client = true;
				void launch()
				{
					offlineServer = Net.IsServer;
					offlinePeers = Net.PeerCount;
					Net.Rpc("nobody");
					Net.RpcNumber("nobody", 1.5);
					Net.RpcText("nobody", "hello");
					hosted = Net.StartServer(0);
					server = Net.IsServer;
					client = Net.IsClient;
				}
				void exit() { Net.Disconnect(); }
			}
			""");
		Test.Assert(run.Instance.StartScript(game));
		Test.Assert(!run.PropBool("offlineServer"));
		Test.Assert(run.PropInt("offlinePeers") == 0);
		Test.Assert(run.PropBool("hosted"), "a host on an assigned port opens");
		Test.Assert(run.PropBool("server") && !run.PropBool("client"));
		Test.Assert(run.Instance.NetEndpoint != null);
		run.Instance.StopScript(); // exit() leaves
		Test.Assert(run.Instance.NetEndpoint == null, "left: offline again");
	}

	/// Both endpoints a step at a time, as the application drives their transport.
	public static void Pump(GameRun host, GameRun client, int steps)
	{
		for (int i < steps)
		{
			if (host.Instance.NetEndpoint != null)
				host.Instance.NetEndpoint.UpdateTransport(10.0f);
			if (client.Instance.NetEndpoint != null)
				client.Instance.NetEndpoint.UpdateTransport(10.0f);
			System.Threading.Thread.Sleep(1);
		}
	}

	/// A host registers its handlers before it hosts; a client sends a number, a text and a
	/// bare message; the host's number handler answers the sender from inside the handler.
	[Test]
	public static void OnReceivesANumberATextAndABareMessageAndReplies()
	{
		let host = scope GameRun("scratch_net_on_host");
		let hostGame = host.Class("Game", """
			class Game
			{
				double score = 0;
				int scoreFrom = -1;
				string greeting;
				int pings = 0;
				int port = 0;
				void onScore(int sender, double value) { score = value; scoreFrom = sender; Net.RpcNumber("ack", value * 2); }
				void onHello(int sender, const string &in text) { greeting = text; }
				void onPing(int sender) { pings++; }
				void launch()
				{
					Net.OnNumber("score", NetNumberHandler(this.onScore));
					Net.OnText("hello", NetTextHandler(this.onHello));
					Net.On("ping", NetHandler(this.onPing));
					Net.StartServer(0);
				}
				bool greeted() { return greeting == "masked"; }
			}
			""");
		Test.Assert(host.Instance.StartScript(hostGame));
		Test.Assert(host.Instance.NetEndpoint != null);
		let port = host.Instance.NetEndpoint.BoundPort;

		let client = scope GameRun("scratch_net_on_client");
		let clientGame = client.Class("Game", scope $$"""
			class Game
			{
				double ack = 0;
				void onAck(int sender, double value) { ack = value; }
				void launch()
				{
					Net.OnNumber("ack", NetNumberHandler(this.onAck));
					Net.Connect("127.0.0.1", {{port}});
				}
				void send()
				{
					Net.RpcNumber("score", 42.5);
					Net.RpcText("hello", "masked");
					Net.Rpc("ping");
					Net.Rpc("ping");
					Net.RpcText("score", "the wrong kind for its handler");
				}
				void update(float dt) { if (Net.PeerCount > 0 && !sent) { sent = true; send(); } }
				bool sent = false;
			}
			""");
		Test.Assert(client.Instance.StartScript(clientGame));
		for (int i < 200)
		{
			Pump(host, client, 1);
			client.Step();
			if (client.PropFloat("ack") != 0)
				break;
		}
		Test.Assert(host.Instance.NetEndpoint.Session.PeerCount == 1, "joined");
		Test.Assert(Math.Abs(host.PropFloat("score") - 42.5f) < 0.001f, scope $"{host.PropFloat("score")}");
		Test.Assert(host.PropInt("scoreFrom") == (int)host.Instance.NetEndpoint.Session.Peers[0].Id, "the sender is the client");
		Test.Assert(host.PropInt("pings") == 2);
		Test.Assert(Math.Abs(client.PropFloat("ack") - 85.0f) < 0.001f, "the reply, from inside a handler");
		// A text sent to a number handler reached nothing: the score stands.
		Test.Assert(Math.Abs(host.PropFloat("score") - 42.5f) < 0.001f);
	}
}
