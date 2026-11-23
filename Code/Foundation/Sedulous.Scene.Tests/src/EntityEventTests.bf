using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// A scene's entity events: a domain tells an entity's listeners something happened to it (a
/// contact, an animation ending) through the scene, with no bridge between the domain and them.
class EntityEventTests
{
	/// Keeps what each post told it.
	private class RecordingSink : IEntityEventSink
	{
		public struct Record
		{
			public Scene Scene;
			public EntityHandle Target;
			public String Name;
			public int ArgCount;
			public EntityHandle Other; // an entity argument, first
			public double Speed; // then a number
		}

		public List<Record> Heard = new .() ~ { for (let h in _) delete h.Name; delete _; };
		/// Where this sink's turn is written, to check the order of sinks.
		public int* Order = null;
		public int Turn = 0;

		public void OnEntityEvent(Scene scene, EntityEvent entityEvent)
		{
			Record h = default;
			h.Scene = scene;
			h.Target = entityEvent.Target;
			h.Name = new String(entityEvent.Name);
			h.ArgCount = entityEvent.Args.Length;
			if (entityEvent.Args.Length == 2)
			{
				h.Other = entityEvent.Args[0].Entity;
				h.Speed = entityEvent.Args[1].Float;
			}
			Heard.Add(h);
			if (Order != null)
				Turn = ++*Order;
		}
	}

	[Test]
	public static void APostReachesEverySinkAtOnceInTheOrderTheyWereAdded()
	{
		let scene = scope Scene("events");
		let pebble = scene.CreateEntity("pebble");
		let floor = scene.CreateEntity("floor");
		Test.Assert(!scene.WantsEntityEvents, "no sink: a poster builds nothing");

		let first = scope RecordingSink();
		let second = scope RecordingSink();
		int order = 0;
		first.Order = &order;
		second.Order = &order;
		scene.AddEntityEventSink(first);
		scene.AddEntityEventSink(second);
		scene.AddEntityEventSink(first); // once only
		Test.Assert(scene.WantsEntityEvents);

		// An entity travels as an argument like any other value.
		var args = EntityEventArg[2](.FromEntity(floor), .FromFloat(3.5));
		scene.PostEntityEvent(.(pebble, "contactBegin", args));
		Test.Assert((first.Heard.Count == 1) && (second.Heard.Count == 1));
		Test.Assert((first.Turn == 1) && (second.Turn == 2), "in the order added, and the first once");
		let h = first.Heard[0];
		Test.Assert(h.Scene === scene);
		Test.Assert(h.Target == pebble);
		Test.Assert(h.Name == "contactBegin");
		Test.Assert(h.ArgCount == 2);
		Test.Assert(h.Other == floor);
		Test.Assert(h.Speed == 3.5);

		// Removed, a sink hears no more; the scene stores nothing for it meanwhile.
		scene.RemoveEntityEventSink(first);
		scene.PostEntityEvent(.(pebble, "animationFinished")); // no arguments at all
		Test.Assert(first.Heard.Count == 1);
		Test.Assert(second.Heard.Count == 2);
		Test.Assert(second.Heard[1].ArgCount == 0);
		scene.RemoveEntityEventSink(second);
		Test.Assert(!scene.WantsEntityEvents);
	}
}
