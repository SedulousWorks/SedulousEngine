using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;
using Sedulous.Net.Replication;

namespace Sedulous.Engine.Script.Tests;

/// A behaviour and a network identity: it reads Authority to gate what it drives, and one
/// that assigns it never starts, since no setter exists and its class does not build.
static class NetworkIdentityScriptTests
{
	[Test]
	public static void ABehaviourGatesOnAuthorityAndReadsTheId()
	{
		let play = scope ScriptPlayScene();
		let networks = play.Scene.AddSystem<NetworkComponentManager>();
		let gate = play.Class("Gate", """
			class Gate
			{
				Entity self;
				int seen = -1;
				void onStart()
				{
					NetworkComponent network = NetworkComponent(self);
					seen = ((network.Authority == NetworkAuthority::Server) ? 1000 : 0) + int(network.Id.Value);
				}
			}
			""");
		let e = play.AddBehavior(gate);
		let identity = networks.Add(e);
		identity.Id = .(42);
		play.Start();
		play.Step();
		Test.Assert(!play.BehaviorOf(e).Faulted);
		Test.Assert(play.PropInt(e, "seen") == 1042, scope $"seen {play.PropInt(e, "seen")}");
		Test.Assert(networks.Get(e).Authority == .Server, "read, untouched");
	}

	/// The class arrives as a cooked product would; the run host builds it and the build
	/// refuses the assignment, so the behaviour is disabled before onStart ever runs.
	[Test]
	public static void ABehaviourThatAssignsAuthorityNeverStarts()
	{
		// Outlives the scene that binds it, as the resource manager's product would.
		let tweaker = scope ScriptClass();
		let play = scope ScriptPlayScene();
		let networks = play.Scene.AddSystem<NetworkComponentManager>();
		let record = scope ScriptClassSource();
		record.Language.Set(Sedulous.Script.AngelScript.AngelScriptBackend.cLanguage);
		record.ClassName.Set("Tweaker");
		record.SourceName.Set("Tweaker.as");
		record.Source.Set("""
			class Tweaker
			{
				Entity self;
				void onStart() { NetworkComponent(self).Authority = NetworkAuthority::Client; }
			}
			""");
		record.Handlers.Add(new String("onStart"));
		tweaker.From(record);

		let e = play.AddBehavior(tweaker);
		networks.Add(e).Authority = .Server;
		play.Start();
		play.Step();
		let behavior = play.BehaviorOf(e);
		Test.Assert(behavior.Faulted, "the class does not build: no setter exists");
		Test.Assert(!behavior.Started, "onStart never ran");
		Test.Assert(networks.Get(e).Authority == .Server);
	}
}
