using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Behavior;

namespace Sedulous.Engine.Behavior.Tests;

/// An engine event posted to the scene (an animation's one-shot ending): its handler gets its
/// arguments on the next drain, never inside the post, and it is no bus subscription.
static class BehaviorEngineEventTests
{
	private const String cWatcher = """
		class Watcher
		{
			Entity self;
			int finished = 0;
			Guid clip;
			void onAnimationFinished(Guid ended)
			{
				finished++;
				clip = ended;
			}
		}
		""";

	[Test]
	public static void AnEngineEventReachesItsHandlerWithItsArgumentsAtTheDrain()
	{
		let play = scope ScriptPlayScene();
		let watcher = play.Class("Watcher", cWatcher);
		let pet = play.AddBehavior(watcher, "pet");
		play.Start();
		play.Step();

		let clipId = Guid(0x51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9);
		var clip = EntityEventArg.FromGuid(clipId);
		play.Scene.PostEntityEvent(.(pet, "animationFinished", .(&clip, 1)));
		Test.Assert(play.PropInt(pet, "finished") == 0, "queued, not delivered inside the post");
		play.Step();

		Test.Assert(play.PropInt(pet, "finished") == 1);
		Test.Assert(play.Prop(pet, "clip").AsGuid == clipId, "the clip crossed");
		// No event name, nothing queued.
		play.Scene.PostEntityEvent(.(pet, "", .(&clip, 1)));
		play.Step();
		Test.Assert(play.PropInt(pet, "finished") == 1);
		Test.Assert(!play.BehaviorOf(pet).Faulted);
	}

	/// The engine's own events are delivered to the entity, not heard off the bus.
	[Test]
	public static void AnEngineEventsHandlerIsNoBusSubscription()
	{
		let name = scope String();
		BehaviorSystem.EventNameOf("onAnimationFinished", name);
		Test.Assert(name.IsEmpty);
		BehaviorSystem.EventNameOf("onContactBegin", name);
		Test.Assert(name.IsEmpty);
		BehaviorSystem.EventNameOf("onOrbCollected", name);
		Test.Assert(name == "OrbCollected");
	}
}
