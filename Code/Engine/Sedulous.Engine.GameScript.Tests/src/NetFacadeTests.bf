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
}
