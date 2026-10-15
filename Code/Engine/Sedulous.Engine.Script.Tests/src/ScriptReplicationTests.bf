using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Script.Tests;

/// A networked entity's behaviours replicate their marked properties: the host writes the live
/// values, a client writes them into its own behaviour (kept as an override for an instance
/// made later, set through the instance when it runs). A behaviour of another class in the
/// slot is left alone. The bytes are carried by hand, as the host's endpoint would.
static class ScriptReplicationTests
{
	private const String cGuest = """
		class Guest
		{
			[0.0, replicated] float activity;
			[5.0] float chatty;
			[0.0] float driver;
			void onUpdate(float dt) { if (driver > 0) activity = activity + 1; }
		}
		""";
	private const String cOther = """
		class Other
		{
			[0.0, replicated] float activity;
			void onUpdate(float dt) {}
		}
		""";

	[Test]
	public static void ABehavioursReplicatedPropertyReachesTheClientsInstance()
	{
		let host = scope ScriptPlayScene("host");
		let hostGuest = host.Class("Guest", cGuest);
		let onHost = host.AddBehavior(hostGuest, "Guest");
		// The host's copy drives (an override, local only); activity is replicated, chatty not.
		host.BehaviorOf(onHost).SetOverride(ScriptPropertyNames.HashOf("driver"), .Float(1));
		host.Start();

		let client = scope ScriptPlayScene("client");
		let clientGuest = client.Class("Guest", cGuest);
		let onClient = client.AddBehavior(clientGuest, "Guest");
		client.Start();

		let state = scope List<uint8>();
		void Send()
		{
			Test.Assert(host.Components.WriteReplicatedState(onHost, state), "the host has state to send");
			client.Components.ReadReplicatedState(onClient, state);
		}

		host.Step(); // the host's script moves activity to 1
		Send(); // the client's behaviour has no instance yet: kept as an override
		Test.Assert(client.BehaviorOf(onClient).Instance == null);
		let kept = client.BehaviorOf(onClient).FindOverride(ScriptPropertyNames.HashOf("activity"));
		Test.Assert((kept != null) && (kept.Value.Number == 1));
		client.Step(); // the instance is made with the host's value
		Test.Assert(client.PropFloat(onClient, "activity") == 1);

		host.Step(2); // 3
		Send(); // the live instance is written
		Test.Assert(client.PropFloat(onClient, "activity") == 3, scope $"{client.PropFloat(onClient, "activity")}");
		Test.Assert(client.PropFloat(onClient, "chatty") == 5, "not replicated: the client's own");

		// A different class in that slot (not the behaviour the host meant) is left alone.
		let clientOther = client.Class("Other", cOther);
		let otherEntity = client.AddBehavior(clientOther, "Other");
		client.Components.ReadReplicatedState(otherEntity, state);
		Test.Assert(client.BehaviorOf(otherEntity).FindOverride(ScriptPropertyNames.HashOf("activity")) == null, "the Guest's value never reached an Other");

		// An entity with no replicated property writes nothing.
		let quiet = host.AddBehavior(host.Class("Other2", "class Other2 { [0.0] float x; void onUpdate(float dt) {} }"), "Quiet");
		Test.Assert(!host.Components.WriteReplicatedState(quiet, state));
	}
}
