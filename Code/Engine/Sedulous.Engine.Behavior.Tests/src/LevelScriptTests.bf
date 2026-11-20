using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Engine.Behavior;

namespace Sedulous.Engine.Behavior.Tests;

/// The scene's own script: one Level per scene, its lifecycle, its properties, its wire.
static class LevelScriptTests
{
	private const String cLevel = """
		class Level
		{
			Scene@ scene;
			[9.0, "Gravity"] float gravity;
			int starts = 0;
			int updates = 0;
			int fixedUpdates = 0;
			int stops = 0;
			string sceneName;
			void onStart() { starts++; sceneName = scene.Name; }
			void onUpdate(float dt) { updates++; }
			void onFixedUpdate(float dt) { fixedUpdates++; }
			void onStop() { stops++; }
		}
		""";

	private static int Int(ScriptPlayScene play, ScriptObject level, StringView name)
	{
		var v = ScriptValue.Nil;
		play.Runtime.GetProperty(level, name, ref v);
		return (int)v.AsInt;
	}

	/// A scene's script slot takes a SceneBehavior and an entity's slot an EntityBehavior: a class
	/// of another kind set in either is refused, and nothing of it runs.
	[Test]
	public static void EachSlotTakesOnlyItsOwnKindOfBehavior()
	{
		let play = scope ScriptPlayScene("world");
		let entityKind = play.Class("Level", cLevel, "Test.as", .Entity);
		play.Scripts.Settings.BehaviorClass.SetDirect(entityKind);
		let sceneKind = play.Class("Level", cLevel, "Other.as", .Scene);
		let e = play.AddBehavior(sceneKind);
		play.Start();
		play.Step(2);
		Test.Assert(play.Scripts.Level == null, "an EntityBehavior is no Level");
		Test.Assert(play.BehaviorOf(e).Instance == null, "a SceneBehavior is no entity's behavior");
		Test.Assert(play.Scripts.InstanceCount == 0);

		// Each in its own slot runs.
		let other = scope ScriptPlayScene("world2");
		other.Scripts.Settings.BehaviorClass.SetDirect(other.Class("Level", cLevel, "Test.as", .Scene));
		let f = other.AddBehavior(other.Class("Level", cLevel, "Other.as", .Entity));
		other.Start();
		other.Step();
		Test.Assert(other.Scripts.Level != null);
		Test.Assert(other.BehaviorOf(f).Instance != null);
		other.Stop();
		play.Stop();
	}

	[Test]
	public static void ALevelRunsItsLifecycleSimGated()
	{
		let play = scope ScriptPlayScene("world");
		let level = play.Class("Level", cLevel, "Test.as", .Scene);
		play.Scripts.Settings.BehaviorClass.SetDirect(level);
		play.Scripts.Settings.SetOverride(ScriptPropertyNames.HashOf("gravity"), .Float(2));

		Test.Assert(play.Scripts.Level == null, "nothing before simulation");
		var read = ScriptValue.Nil;
		Test.Assert(!play.Scripts.GetLevelProperty("updates", ref read), "no Level to read");
		play.Start();
		play.Step(3);
		let object = play.Scripts.Level;
		Test.Assert(object != null);
		Test.Assert(Int(play, object, "starts") == 1);
		Test.Assert(Int(play, object, "updates") == 3);
		Test.Assert(play.Scripts.GetLevelProperty("updates", ref read) && (read.AsInt == 3), "read through the scene's system");
		Test.Assert(!play.Scripts.GetLevelProperty("lives", ref read), "no such property");
		var v = ScriptValue.Nil;
		play.Runtime.GetProperty(object, "gravity", ref v);
		Test.Assert(v.AsFloat == 2, "the override, before onStart");
		play.Runtime.GetProperty(object, "sceneName", ref v);
		Test.Assert(v.AsString == "world", "bound to its scene");

		play.Scene.FixedUpdate(1.0f / 30.0f);
		Test.Assert(Int(play, object, "fixedUpdates") == 1);

		play.Stop();
		Test.Assert(play.Scripts.Level == null, "released on stop, after onStop");
		Test.Assert(!play.Scripts.GetLevelProperty("updates", ref read), "gone with it");
		Test.Assert(play.Scripts.InstanceCount == 0);
	}

	[Test]
	public static void TwoScenesSharingALevelClassGetIndependentObjects()
	{
		let play = scope ScriptPlayScene("a");
		let level = play.Class("Level", cLevel, "Test.as", .Scene);
		let b = play.AddScene("b");
		play.Scripts.Settings.BehaviorClass.SetDirect(level);
		b.GetSystem<BehaviorSystem>().Settings.BehaviorClass.SetDirect(level);
		play.Start();
		play.Step(2);
		let levelA = play.Scripts.Level;
		let levelB = b.GetSystem<BehaviorSystem>().Level;
		Test.Assert((levelA != null) && (levelB != null) && (levelA !== levelB));
		var v = ScriptValue.Nil;
		play.Runtime.GetProperty(levelA, "sceneName", ref v);
		Test.Assert(v.AsString == "a");
		play.Runtime.GetProperty(levelB, "sceneName", ref v);
		Test.Assert(v.AsString == "b");
	}

	[Test]
	public static void AFaultingLevelDisablesThatSceneOnly()
	{
		let play = scope ScriptPlayScene("a");
		let good = play.Class("Level", cLevel, "Test.as", .Scene);
		let bad = play.Class("BadLevel", "class BadLevel { int updates = 0; void onUpdate(float dt) { updates++; int[] x; x[9] = 1; } }", "Test.as", .Scene);
		let b = play.AddScene("b");
		play.Scripts.Settings.BehaviorClass.SetDirect(bad);
		b.GetSystem<BehaviorSystem>().Settings.BehaviorClass.SetDirect(good);
		play.Start();
		play.Step(3);
		Test.Assert(Int(play, play.Scripts.Level, "updates") == 1, "faulted once and stopped");
		Test.Assert(Int(play, b.GetSystem<BehaviorSystem>().Level, "updates") == 3, "the other scene's Level runs on");
	}

	[Test]
	public static void TheSettingsRoundTrip()
	{
		let play = scope ScriptPlayScene();
		let id = Guid.Create();
		play.Scripts.Settings.BehaviorClass.SetId(id);
		play.Scripts.Settings.Enabled = false;
		play.Scripts.Settings.SetOverride(ScriptPropertyNames.HashOf("gravity"), .Float(2));

		let blob = scope MemoryStream();
		{
			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, play.Scene);
			Test.Assert(writer.IsOk);
		}
		let loaded = scope Scene("loaded");
		BehaviorScene.AddBehaviorSceneManagers(loaded);
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}
		let settings = loaded.GetSystem<BehaviorSystem>().Settings;
		Test.Assert(settings.BehaviorClass.Id == id);
		Test.Assert(!settings.Enabled);
		Test.Assert(settings.FindOverride(ScriptPropertyNames.HashOf("gravity")).Value.Number == 2);
	}
}
