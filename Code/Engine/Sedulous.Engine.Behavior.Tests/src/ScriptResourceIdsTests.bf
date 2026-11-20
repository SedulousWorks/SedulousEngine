using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script.Resource;
using Sedulous.Engine.Behavior;

namespace Sedulous.Engine.Behavior.Tests;

/// What a scene's scripts name to a resource manager about to release: each behaviour's class
/// and the assets its overrides hold, which the reflection walk cannot see (the behaviours are a
/// list of runtime objects), and the Level's override assets.
static class ScriptResourceIdsTests
{
	[Test]
	public static void BehaviourClassesAndOverrideAssetsAreNamed()
	{
		let play = scope ScriptPlayScene();
		let counter = play.Class("Held", "class Held { }");
		let e = play.AddBehavior(counter);
		let classId = Guid.Create();
		let assetId = Guid.Create();
		let levelAssetId = Guid.Create();
		let behavior = play.BehaviorOf(e);
		behavior.BehaviorClass.SetId(classId);
		behavior.SetOverride(ScriptPropertyNames.HashOf("clip"), .Asset(assetId));
		let levelOverride = new ScriptPropertyOverride();
		levelOverride.Hash = ScriptPropertyNames.HashOf("music");
		levelOverride.Value = .Asset(levelAssetId);
		play.Scripts.Settings.Overrides.Add(levelOverride);

		let held = scope HashSet<Guid>();
		play.Scene.CollectResourceIds(held);
		Test.Assert(held.Contains(classId), "the behaviour's class");
		Test.Assert(held.Contains(assetId), "the asset its override holds");
		Test.Assert(held.Contains(levelAssetId), "the Level's override asset");
	}
}
