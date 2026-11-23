using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.PropertyAnimation;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Sequence;
using Sedulous.Sequence.Resource;
using Sedulous.VFS;

namespace Sedulous.Sequence.Resource.Tests;

/// Counts the "step" events it hears.
class StepCounter : ISequenceListener
{
	public int Steps = 0;

	public void OnSequenceEvent(EntityHandle target, StringView name, StringView value)
	{
		if (name == "step")
			Steps++;
	}
	public void OnSequenceHeld(StringView marker) {}
	public void OnSequenceFinished() {}
}

/// A nested sequence over a section of another, on the outer cast; looping over its section; never
/// inside itself; and the factory loading a cooked sequence and binding what its tracks refer to.
class SequenceResourceTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// Moves "Actor" along X from 0 to `toX` over one second, with a "step" event at its middle.
	private static void FillWalk(Sedulous.Sequence.Sequence walk, float toX)
	{
		walk.Bindings.Add(new .("Actor"));
		let track = new PropertySequenceTrack();
		track.Binding = 0;
		track.Property.ComponentType.Set(TrackTargets.cTransform);
		track.Property.PropertyPath.Set("Position");
		track.Property.Kind = .Float3;
		track.Property.Channels[0].AddKey(.(0.0f, 0.0f));
		track.Property.Channels[0].AddKey(.(1.0f, toX));
		walk.Tracks.Add(track);
		let step = new EventSequenceTrack();
		step.Keys.Add(new .(0.5f, "step"));
		walk.Tracks.Add(step);
		walk.Duration = 1.0f;
	}

	private static NestedSequenceTrack Nested(SequenceResource inner, float start, float length, bool loop)
	{
		let track = new NestedSequenceTrack();
		track.Name.Set("nested");
		track.Nested.SetDirect(inner);
		track.Start = start;
		track.Length = length;
		track.Loop = loop;
		return track;
	}

	private static float X(Sedulous.Scene.Scene world, EntityHandle entity) => world.GetLocalTransform(entity).Position.X;

	[Test]
	public static void ANestedSequencePlaysOverItsSectionOnTheOuterCast()
	{
		SequenceResources.RegisterAll();
		let world = scope Sedulous.Scene.Scene("nested");
		let actor = world.CreateEntity("Actor");
		let walk = scope SequenceResource();
		FillWalk(walk.Sequence, 10.0f);

		let outer = scope Sedulous.Sequence.Sequence();
		outer.Bindings.Add(new .("Actor"));
		outer.Tracks.Add(Nested(walk, 1.0f, 0.0f, false));
		outer.Duration = outer.ComputeDuration();
		Test.Assert(Near(outer.Duration, 2.0f));

		let counter = scope StepCounter();
		let play = scope SequencePlay(world, outer);
		play.SetListener(counter);
		play.Bind("Actor", actor);
		play.Play();
		play.Advance(0.5f); // before the section: nothing moves
		Test.Assert(Near(X(world, actor), 0.0f));
		play.Advance(1.0f); // 1.5: halfway through the nested walk
		Test.Assert(Near(X(world, actor), 5.0f));
		Test.Assert(counter.Steps == 1, "its events reach the outer listener");
		play.Advance(1.0f); // past the end: it stays at its end
		Test.Assert(Near(X(world, actor), 10.0f));
		Test.Assert(counter.Steps == 1);
	}

	[Test]
	public static void ALoopedNestedSequenceRepeatsOverItsSection()
	{
		SequenceResources.RegisterAll();
		let world = scope Sedulous.Scene.Scene("looped");
		let actor = world.CreateEntity("Actor");
		let walk = scope SequenceResource();
		FillWalk(walk.Sequence, 10.0f);

		let outer = scope Sedulous.Sequence.Sequence();
		outer.Bindings.Add(new .("Actor"));
		outer.Tracks.Add(Nested(walk, 0.0f, 3.0f, true));
		outer.Duration = outer.ComputeDuration();

		let counter = scope StepCounter();
		let play = scope SequencePlay(world, outer);
		play.SetListener(counter);
		play.Bind("Actor", actor);
		play.Play();
		play.Advance(1.25f); // a quarter into the second pass
		Test.Assert(Near(X(world, actor), 2.5f));
		play.Advance(1.0f); // 2.25: a quarter into the third pass
		Test.Assert(Near(X(world, actor), 2.5f));
		Test.Assert(counter.Steps == 2, "once in each pass played through so far");
	}

	[Test]
	public static void ASequenceNeverPlaysInsideItself()
	{
		SequenceResources.RegisterAll();
		let world = scope Sedulous.Scene.Scene("self");
		let loop = scope SequenceResource();
		loop.Sequence.Tracks.Add(Nested(loop, 0.0f, 1.0f, false));
		loop.Sequence.Duration = 1.0f;

		let play = scope SequencePlay(world, loop.Sequence);
		play.Play(); // the nested track is refused with a warning; nothing recurses
		play.Advance(0.5f);
		Test.Assert(play.IsPlaying);
	}

	/// The cycle through another sequence is found by walking the plays it is nested in.
	[Test]
	public static void ASequenceNeverPlaysInsideItselfThroughAnother()
	{
		SequenceResources.RegisterAll();
		let world = scope Sedulous.Scene.Scene("cycle");
		let first = scope SequenceResource();
		let second = scope SequenceResource();
		first.Sequence.Tracks.Add(Nested(second, 0.0f, 1.0f, false));
		first.Sequence.Duration = 1.0f;
		second.Sequence.Tracks.Add(Nested(first, 0.0f, 1.0f, false));
		second.Sequence.Duration = 1.0f;

		let play = scope SequencePlay(world, first.Sequence);
		play.Play(); // second plays inside first; first inside that is refused
		play.Advance(0.5f);
		Test.Assert(play.IsPlaying);
	}

	[Test]
	public static void TheFactoryLoadsACookedSequenceAndBindsWhatItsTracksReferTo()
	{
		SequenceResources.RegisterAll();
		let root = "scratch_sequence_resource_db";
		RemoveDirectoryRecursive(root);
		CreateDirectory(root);
		defer RemoveDirectoryRecursive(root);
		let serializables = scope SerializableRegistry();
		SequenceResources.RegisterAll(serializables);
		let mount = scope NativeFileSystem(root);
		SerializerFactory serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		defer delete serializers;

		Guid walkId;
		Guid outerId;
		{
			let db = scope ContentDatabase(mount, serializers, "asset", serializables);
			let walkInstance = db.RootGroup.CreateInstance("walk", "Sedulous.Sequence.Resource.SequenceSource");
			let outerInstance = db.RootGroup.CreateInstance("outer", "Sedulous.Sequence.Resource.SequenceSource");
			walkId = walkInstance.Id;
			outerId = outerInstance.Id;

			let walk = scope SequenceSource();
			FillWalk(walk.Sequence, 10.0f);
			Test.Assert(walkInstance.WriteObject(walk) case .Ok);

			let outer = scope SequenceSource();
			outer.Sequence.Bindings.Add(new .("Actor"));
			let nested = new NestedSequenceTrack();
			nested.Nested.SetId(walkId);
			nested.Start = 0.5f;
			outer.Sequence.Tracks.Add(nested);
			outer.Sequence.Duration = 1.5f;
			Test.Assert(outerInstance.WriteObject(outer) case .Ok);
		}

		let db = scope ContentDatabase(mount, serializers, "asset", serializables);
		let factory = scope SequenceFactory();
		let manager = scope ResourceManager(db);
		manager.AddFactory(factory);

		let outer = manager.Bind<SequenceResource>(outerId).Get;
		Test.Assert(outer != null);
		Test.Assert(outer.Sequence.Tracks.Count == 1);
		let nested = outer.Sequence.Tracks[0] as NestedSequenceTrack;
		Test.Assert(nested != null);
		Test.Assert(Near(nested.Start, 0.5f));
		Test.Assert(nested.Nested.Get != null, "bound by the factory, through the manager");
		Test.Assert(nested.Nested.Get.Sequence.Tracks.Count == 2);
		Test.Assert(Near(nested.SectionLength, 1.0f));
	}
}
