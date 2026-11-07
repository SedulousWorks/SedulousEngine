using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Gameplay;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// A behaviour saved and read back, as a struct component is: through the scene serializer in
/// both encodings (mirroring SceneRoundTripTests and SceneTextRoundTripTests), refused at a
/// version it does not read (SceneRefusalTests), and kept verbatim where its manager is absent.
///
/// What a behaviour adds over a component: only its public fields travel, and a read makes a
/// fresh instance, so runtime state never survives one.
class BehaviourSerializationTests
{
	private static void Populate(Scene scene)
	{
		scene.SetName("arena");
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let markers = scene.AddSystem<BehaviourManager<Marker>>();

		let hero = scene.CreateEntity("Hero");
		let goal = scene.CreateEntity("Goal");

		let mover = movers.Add(hero);
		mover.Speed = 7.5f;
		mover.Lives = 9;
		mover.Flying = true;
		mover.Label.Set("runner");
		mover.Heading = .(1.0f, 2.0f, 3.0f);
		mover.Target = .(scene.GetEntityId(goal));
		mover.Mood = .Asleep;
		mover.Bob = 4.0f; // runtime state: not saved

		let marker = markers.Add(goal);
		marker.Enabled = false; // a disabled behaviour stays disabled on disk
	}

	private static void RoundTrip(Scene source, Scene target, SceneStreamEncoding encoding)
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			SceneSerializer.SerializeScene(writer, source, .Referenced, true, encoding);
		}
		buffer.Seek(0, .Begin);
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, target, .Referenced, true, encoding);
		Test.Assert(reader.IsOk);
	}

	private static void WriteText(Scene scene, String outText)
	{
		let serializer = scope XmlSerializer();
		SceneSerializer.SerializeScene(serializer, scene, .Referenced, true, .Text);
		Test.Assert(serializer.IsOk);
		serializer.GetOutput(outText);
	}

	private static void ReadText(StringView text, Scene target)
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse(text) == .Ok, "the scene just written parses as XML");
		let reader = scope XmlSerializer(document);
		SceneSerializer.SerializeScene(reader, target, .Referenced, true, .Text);
		Test.Assert(reader.IsOk);
	}

	/// Every saved field came back on the right entity; the private state did not.
	private static void CheckRestored(Scene source, Scene target)
	{
		let movers = target.GetSystem<BehaviourManager<Mover>>();
		let markers = target.GetSystem<BehaviourManager<Marker>>();
		let hero = target.FindEntityByName("Hero");
		let goal = target.FindEntityByName("Goal");
		Test.Assert(hero.IsAssigned && goal.IsAssigned);

		Test.Assert(movers.Count == 1);
		let mover = movers.Get(hero);
		Test.Assert(mover != null);
		Test.Assert(mover.Scene == target);
		Test.Assert(mover.Entity == hero);
		Test.Assert(mover.Enabled);
		Test.Assert(mover.Speed == 7.5f);
		Test.Assert(mover.Lives == 9);
		Test.Assert(mover.Flying);
		Test.Assert(mover.Label == "runner");
		Test.Assert(mover.Heading.Z == 3.0f);
		Test.Assert(mover.Target.Id == source.GetEntityId(source.FindEntityByName("Goal")));
		Test.Assert(target.FindEntity(mover.Target.Id) == goal, "the reference names the goal in the copy");
		Test.Assert(mover.Mood == .Asleep);
		Test.Assert(mover.Bob == 0.0f, "runtime state is not saved");

		Test.Assert(markers.Count == 1);
		Test.Assert(markers.Get(hero) == null);
		Test.Assert(!markers.Get(goal).Enabled, "a disabled behaviour stays disabled");
	}

	[Test]
	public static void ABehaviourSurvivesABinaryRoundTrip()
	{
		let source = scope Scene();
		Populate(source);

		let target = scope Scene();
		target.AddSystem<BehaviourManager<Mover>>();
		target.AddSystem<BehaviourManager<Marker>>();
		RoundTrip(source, target, .Binary);

		Test.Assert(target.Name == "arena");
		CheckRestored(source, target);
	}

	[Test]
	public static void ABehaviourSurvivesATextRoundTrip()
	{
		let source = scope Scene();
		Populate(source);

		let text = scope String();
		WriteText(source, text);
		Test.Assert(text.Contains("\"speed\""), "a public field is written under its key");
		Test.Assert(text.Contains("\"enabled\""), "the base's Enabled leads the record");
		Test.Assert(!text.Contains("mBob"), "a private field is not written");

		let target = scope Scene();
		target.AddSystem<BehaviourManager<Mover>>();
		target.AddSystem<BehaviourManager<Marker>>();
		ReadText(text, target);

		CheckRestored(source, target);
	}

	/// Reading a record onto an entity that already has the behaviour REPLACES the instance:
	/// runtime state set before is gone, and the old one, having started, saw OnDestroy.
	[Test]
	public static void ReadingARecordReplacesTheInstance()
	{
		let scene = scope Scene();
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let entity = scene.CreateEntity("e");
		movers.Add(entity).Speed = 11.0f;

		let blob = scope List<uint8>();
		SceneStreamFormat.ComponentToBlob(movers, entity, blob);

		let before = movers.Get(entity);
		before.Bob = 6.0f;
		before.Speed = 1.0f;
		before.mStarted = true;
		Mover.Destroyed = 0;

		SceneStreamFormat.ComponentFromBlob(movers, entity, blob);

		let after = movers.Get(entity);
		Test.Assert(after != null);
		Test.Assert(movers.Count == 1, "replaced, not added beside");
		Test.Assert(after.Speed == 11.0f, "the record's value");
		Test.Assert(after.Bob == 0.0f, "no runtime state survives a read");
		Test.Assert(!after.mStarted, "the fresh instance has not started");
		Test.Assert(after.Scene == scene && after.Entity == entity);
		Test.Assert(Mover.Destroyed == 1, "the started instance it replaced saw OnDestroy");
	}

	/// A payload stamped with a version the manager does not read is not read into the
	/// instance: the instance is there, at its defaults.
	[Test]
	public static void ARefusedPayloadIsLeftUnread()
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			BeginVersionedPayload(writer, TypeIdOf("test.mover"), 2); // the class is at 1
			var enabled = true;
			var speed = 99.0f;
			SerializeValue(writer, "enabled", ref enabled);
			SerializeValue(writer, "speed", ref speed);
			EndVersionedPayload(writer);
		}
		buffer.Seek(0, .Begin);

		let scene = scope Scene();
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let entity = scene.CreateEntity("e");
		let reader = scope BinarySerializer(buffer, .Read);
		movers.ReadComponent(reader, entity);

		Test.Assert(reader.Status case .Err(.NotSupported));
		Test.Assert(movers.Get(entity) != null);
		Test.Assert(movers.Get(entity).Speed == 2.5f, "the refused payload was not read");
	}

	/// A behaviour record whose manager is ABSENT is kept verbatim and written back, then
	/// becomes a behaviour again in a scene that has the manager (mirrors
	/// SceneRoundTripTests.AComponentWithNoManagerIsPreservedAndWrittenBack).
	[Test]
	public static void AnAbsentBehavioursRecordIsPreservedAndWrittenBack()
	{
		let source = scope Scene();
		Populate(source);

		// Movers have nowhere to go; markers do.
		let bare = scope Scene();
		bare.AddSystem<BehaviourManager<Marker>>();
		RoundTrip(source, bare, .Binary);

		Test.Assert(bare.UnresolvedComponents.Length == 1, "the mover's record was kept");
		Test.Assert(bare.UnresolvedComponents[0].TypeId == "test.mover");
		Test.Assert(!bare.UnresolvedComponents[0].Payload.IsEmpty);

		let restored = scope Scene();
		restored.AddSystem<BehaviourManager<Mover>>();
		restored.AddSystem<BehaviourManager<Marker>>();
		RoundTrip(bare, restored, .Binary);

		Test.Assert(restored.UnresolvedComponents.IsEmpty);
		CheckRestored(source, restored);
	}

	/// The same through the text encoding, whose kept record is raw markup.
	[Test]
	public static void AnAbsentBehavioursRecordSurvivesTheTextPath()
	{
		let source = scope Scene();
		Populate(source);
		let text = scope String();
		WriteText(source, text);

		let bare = scope Scene();
		bare.AddSystem<BehaviourManager<Marker>>();
		ReadText(text, bare);
		Test.Assert(bare.UnresolvedComponents.Length == 1);
		Test.Assert(bare.UnresolvedComponents[0].TypeId == "test.mover");

		let again = scope String();
		WriteText(bare, again);
		let restored = scope Scene();
		restored.AddSystem<BehaviourManager<Mover>>();
		restored.AddSystem<BehaviourManager<Marker>>();
		ReadText(again, restored);

		Test.Assert(restored.UnresolvedComponents.IsEmpty);
		CheckRestored(source, restored);
	}
}
