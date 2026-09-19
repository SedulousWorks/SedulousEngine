using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Script.Tests;

/// Authored values: harvested defaults, overrides that win, entity references that
/// resolve, the wire.
static class BehaviorPropertyTests
{
	private const String cMover = """
		class Mover
		{
			float speed = 2;
			int lives = 3;
			bool armed = true;
			string label = "m";
			Color tint = Color(1, 0, 0, 1);
			Float3 offset = Float3(1, 2, 3);
			Entity target;
			Entity self;
			Scene@ scene;
			float seen = -1;
			string targetName;
			void onStart() { seen = speed; if (scene !is null && scene.IsValid(target)) targetName = scene.GetEntityName(target); }
		}
		""";

	[Test]
	public static void HarvestedDefaultsApplyAndOverridesWin()
	{
		let play = scope ScriptPlayScene();
		let mover = play.Class("Mover", cMover);

		// The harvest saw every authored kind, not the injected self and scene, and no
		// lifecycle handler as a property.
		Test.Assert(mover.Properties.Count == 9, scope $"harvested {mover.Properties.Count}");
		Test.Assert((mover.FindProperty("self") == null) && (mover.FindProperty("scene") == null));
		Test.Assert(mover.FindProperty("speed").Type == .Float && mover.FindProperty("speed").Default.Number == 2);
		Test.Assert(mover.FindProperty("lives").Type == .Int);
		Test.Assert(mover.FindProperty("label").Type == .String && mover.FindProperty("label").Default.Text == "m");
		Test.Assert(mover.FindProperty("tint").Type == .Color);
		Test.Assert(mover.FindProperty("offset").Type == .Vec3 && mover.FindProperty("offset").Default.Vector.Z == 3);
		Test.Assert(mover.FindProperty("target").Type == .Entity);
		Test.Assert(mover.HasHandler("onStart") && !mover.HasHandler("speed"));

		let e = play.AddBehavior(mover);
		play.BehaviorOf(e).SetOverride(ScriptPropertyNames.HashOf("speed"), .Float(7));
		play.BehaviorOf(e).SetOverride(ScriptPropertyNames.HashOf("label"), .Str(new String("over")));
		play.Start();
		play.Step();
		Test.Assert(play.PropFloat(e, "speed") == 7, "the override");
		Test.Assert(play.PropInt(e, "lives") == 3, "the default");
		Test.Assert(play.Prop(e, "label").AsString == "over");
		Test.Assert(play.PropFloat(e, "seen") == 7, "applied BEFORE onStart");
		Test.Assert(play.Prop(e, "self").AsEntity == e, "self is the entity");
		Test.Assert(play.Prop(e, "self").AsEntityScene === play.Scene, "and knows its scene");
	}

	[Test]
	public static void AnEntityPropertyResolvesItsGuidToTheLiveHandle()
	{
		let play = scope ScriptPlayScene();
		let mover = play.Class("Mover", cMover);
		let target = play.Scene.CreateEntity("the target");
		let e = play.AddBehavior(mover);
		play.BehaviorOf(e).SetOverride(ScriptPropertyNames.HashOf("target"), .Entity(play.Scene.GetEntityId(target)));
		play.Start();
		play.Step();
		Test.Assert(play.Prop(e, "target").AsEntity == target);
		Test.Assert(play.Prop(e, "targetName").AsString == "the target", "the script reached it through its scene");

		// An unknown guid is the invalid handle, never a stale one.
		let other = play.AddBehavior(mover, "other");
		play.BehaviorOf(other).SetOverride(ScriptPropertyNames.HashOf("target"), .Entity(Guid.Create()));
		play.Step();
		Test.Assert(!play.Prop(other, "target").AsEntity.IsAssigned);
	}

	[Test]
	public static void TheComponentRoundTripsTheWire()
	{
		let play = scope ScriptPlayScene();
		let mover = play.Class("Mover", cMover);
		let classId = Guid.Create();
		let e = play.AddBehavior(mover);
		let behavior = play.BehaviorOf(e);
		behavior.Script.SetId(classId);
		behavior.UpdateInterval = 0.25f;
		behavior.Enabled = false;
		behavior.SetOverride(ScriptPropertyNames.HashOf("speed"), .Float(7));
		behavior.SetOverride(ScriptPropertyNames.HashOf("label"), .Str(new String("wire")));

		let blob = scope MemoryStream();
		{
			let writer = scope BinarySerializer(blob, .Write);
			SceneSerializer.SerializeScene(writer, play.Scene);
			Test.Assert(writer.IsOk);
		}

		let loaded = scope Scene("loaded");
		ScriptScene.AddScriptSceneManagers(loaded);
		blob.Seek(0, .Begin);
		{
			let reader = scope BinarySerializer(blob, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}
		let components = loaded.GetSystem<ScriptComponentManager>();
		Test.Assert(components.ComponentCount == 1);
		ScriptBehavior read = null;
		components.ForEach(scope [&] (component, owner) => { read = component.Behaviors[0]; });
		Test.Assert(read != null);
		Test.Assert(read.Script.Id == classId);
		Test.Assert(read.UpdateInterval == 0.25f);
		Test.Assert(!read.Enabled);
		Test.Assert(read.Overrides.Count == 2);
		Test.Assert(read.FindOverride(ScriptPropertyNames.HashOf("speed")).Value.Number == 7);
		Test.Assert(read.FindOverride(ScriptPropertyNames.HashOf("label")).Value.Text == "wire");
		Test.Assert((read.Instance == null) && !read.Started, "runtime state is not on the wire");
	}
}
