using System;
using System.Threading;
using Sedulous.Script;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameInstance.Tests;

/// `Net` to native code: the delegate overloads of On, OnNumber, OnText, OnJoin and OnLeave on
/// the run's NetFacade, a host and a client as real endpoints on loopback, pumped by hand. The
/// facade owns the delegates: Off takes one off (deleted after the delivery that called it, if
/// any), and the run's session stop deletes every native one, a script's staying.
class NetFacadeNativeTests
{
	/// Both endpoints a step at a time, as the application drives their transport.
	private static void Pump(GameInstance host, GameInstance client)
	{
		if (host.NetEndpoint != null)
			host.NetEndpoint.UpdateTransport(10.0f);
		if (client.NetEndpoint != null)
			client.NetEndpoint.UpdateTransport(10.0f);
		Thread.Sleep(1);
	}

	/// Counts a handler's calls, held by reference in the closures, a nested one included.
	private class Tally
	{
		public int Calls = 0;
	}

	/// A script handler that counts its calls.
	private class Counted : ScriptDelegate
	{
		public int Calls = 0;
		public override bool IsAlive => true;
		public override bool Invoke(Span<ScriptValue> args, ref ScriptValue result)
		{
			Calls++;
			return true;
		}
	}

	/// The host registers before it hosts; the client sends a number, a text and two bare
	/// messages; the host's number handler answers the sender from inside the handler, and a
	/// text sent to the number handler reaches nothing.
	[Test]
	public static void OnReceivesANumberATextAndABareMessageAndReplies()
	{
		double score = 0;
		int32 scoreFrom = -1;
		let greeting = scope String();
		int pings = 0;
		double ack = 0;
		int32 ackFrom = -1;

		let host = scope GameInstance();
		let hostNet = host.Get<NetFacade>();
		hostNet.OnNumber("score", new [&] (player, value) =>
			{
				score = value;
				scoreFrom = player;
				hostNet.RpcNumber("ack", value * 2);
			});
		hostNet.OnText("hello", new [&] (player, text) => { greeting.Set(text); });
		hostNet.On("ping", new [&] (player) => { pings++; });
		Test.Assert(hostNet.HandlerCount == 3);
		Test.Assert(hostNet.StartServer(0));
		let port = host.NetEndpoint.BoundPort;

		let client = scope GameInstance();
		let clientNet = client.Get<NetFacade>();
		clientNet.OnNumber("ack", new [&] (player, value) =>
			{
				ack = value;
				ackFrom = player;
			});
		Test.Assert(clientNet.Connect("127.0.0.1", port));
		bool sent = false;
		for (int i < 300)
		{
			Pump(host, client);
			if (!sent && (clientNet.PeerCount > 0))
			{
				sent = true;
				clientNet.RpcNumber("score", 42.5);
				clientNet.RpcText("hello", "masked");
				clientNet.Rpc("ping");
				clientNet.Rpc("ping");
				clientNet.RpcText("score", "the wrong kind for its handler");
			}
			if (ack != 0)
				break;
		}
		// What was sent after the score is delivered by now too.
		for (int i < 20)
			Pump(host, client);
		Test.Assert(host.NetEndpoint.Session.PeerCount == 1, "joined");
		Test.Assert(score == 42.5, scope $"{score}");
		Test.Assert(scoreFrom == (int32)host.NetEndpoint.Session.Peers[0].Id, "the sender is the client");
		Test.Assert(greeting == "masked", greeting);
		Test.Assert(pings == 2);
		Test.Assert(ack == 85.0, "the reply, from inside a handler");
		Test.Assert(ackFrom == 0, "from the host, player nought");
		Test.Assert(score == 42.5, "a text sent to a number handler reached nothing");
		clientNet.Disconnect();
		hostNet.Disconnect();
	}

	/// Players by id through native handlers: the host hears the client join and sends it a
	/// message alone; the client hears its own join and the message. Off takes a message's
	/// handler off, a handler may take itself off or register its own name again from inside
	/// its call, and the client's session stop deletes its native handlers, the host's leaving
	/// then reaching none, while a script's handler stays.
	[Test]
	public static void JoinLeaveOffAndTheSessionsStop()
	{
		int32 joined = -1;
		int32 joinedAs = -1;
		double welcome = 0;
		int32 left = -1;
		int markers = 0;
		int onceCalls = 0;
		let again = scope Tally();

		let host = scope GameInstance();
		let hostNet = host.Get<NetFacade>();
		hostNet.OnJoin(new [&] (player) =>
			{
				joined = player;
				hostNet.RpcNumberTo(player, "welcome", player * 10);
			});
		Test.Assert(hostNet.StartServer(0));
		let port = host.NetEndpoint.BoundPort;

		let client = scope GameInstance();
		let clientNet = client.Get<NetFacade>();
		clientNet.OnJoin(new [&] (player) => { joinedAs = player; });
		clientNet.OnLeave(new [&] (player) => { left = player; });
		clientNet.OnNumber("welcome", new [&] (player, value) => { welcome = value; });
		clientNet.On("marker", new [&] (player) => { markers++; });
		// Off from inside its own call: the delegate running is deleted once it returns.
		clientNet.On("once", new [&] (player) =>
			{
				clientNet.Off("once");
				onceCalls++;
			});
		// Its own name registered again from inside its call: the endpoint's closure that called
		// it is replaced under the call.
		clientNet.On("again", new [=again, =clientNet] (player) =>
			{
				again.Calls++;
				clientNet.On("again", new [=again] (p) => { again.Calls += 10; });
			});
		let script = new Counted();
		clientNet.On("bye", script); // owned by the facade from here
		Test.Assert(clientNet.Connect("127.0.0.1", port));
		for (int i < 300)
		{
			Pump(host, client);
			if (welcome != 0)
				break;
		}
		let clientId = (int32)host.NetEndpoint.Session.Peers[0].Id;
		Test.Assert(joined == clientId, "the host heard the client join, by its id");
		Test.Assert(joinedAs == clientId, "the client heard itself join, by the same id");
		Test.Assert(welcome == (double)(clientId * 10), "a message to it alone");

		// Off: the next welcome reaches nothing; the marker after it says it has been delivered.
		clientNet.Off("welcome");
		hostNet.RpcNumberTo(clientId, "welcome", 1);
		hostNet.RpcTo(clientId, "once");
		hostNet.RpcTo(clientId, "once");
		hostNet.RpcTo(clientId, "again");
		hostNet.RpcTo(clientId, "again");
		hostNet.RpcTo(clientId, "bye");
		hostNet.RpcTo(clientId, "marker");
		for (int i < 300)
		{
			Pump(host, client);
			if (markers > 0)
				break;
		}
		Test.Assert(markers == 1);
		Test.Assert(welcome == (double)(clientId * 10), "taken off: the welcome reached nothing");
		Test.Assert(onceCalls == 1, "it took itself off");
		Test.Assert(again.Calls == 11, "the second call reached the handler the first registered");
		Test.Assert(script.Calls == 1);

		// The client's session ends: its native handlers go, the script's stays.
		client.Start();
		client.Stop();
		Test.Assert(clientNet.HandlerCount == 1, scope $"the script's alone: {clientNet.HandlerCount}");
		Test.Assert(client.NetEndpoint != null, "a session with no game leaves the networking open");

		hostNet.Disconnect();
		for (int i < 600)
		{
			Pump(host, client);
			if ((client.NetEndpoint == null) || (client.NetEndpoint.Session.PeerCount == 0))
				break;
		}
		Test.Assert((client.NetEndpoint == null) || (client.NetEndpoint.Session.PeerCount == 0), "the host went");
		for (int i < 20)
			Pump(host, client);
		Test.Assert(left == -1, "its leave handler went with its session");
		clientNet.Disconnect();
	}

	/// What a native handler was handed is deleted by the facade: a replacement deletes the
	/// one it replaces, and the facade going deletes what is left, OffJoin and OffLeave included.
	[Test]
	public static void ReplacedAndLeftHandlersAreDeleted()
	{
		let instance = scope GameInstance();
		let net = instance.Get<NetFacade>();
		int calls = 0;
		net.On("name", new [&] (player) => { calls++; });
		net.OnNumber("name", new [&] (player, value) => { calls++; });
		Test.Assert(net.HandlerCount == 1, "one handler a name");
		net.OnJoin(new [&] (player) => { calls++; });
		net.OnJoin(new [&] (player) => { calls++; });
		net.OnLeave(new [&] (player) => { calls++; });
		net.OffLeave();
		net.OffJoin();
		net.OnText("other", new [&] (player, text) => { calls++; });
		net.Off("nobody");
		Test.Assert(net.HandlerCount == 2);
		net.Off("name");
		Test.Assert(net.HandlerCount == 1);
		Test.Assert(calls == 0, "nothing delivered offline");
	}
}
