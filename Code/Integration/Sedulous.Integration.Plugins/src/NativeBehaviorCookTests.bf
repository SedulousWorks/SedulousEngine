using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Script.Pipeline;
using Sedulous.Engine.Behavior;

namespace Sedulous.Integration.Plugins;

/// A native class as a game writes one: properties of its own (a number with a description, an
/// asset, a text), a field that is not one (Hits), handlers, and a method that is no handler.
[NativeBehavior]
class NativeCookTarget : EntityBehavior
{
	[BehaviorProperty, Description("Hits it takes")]
	public float Toughness = 3.0f;
	[BehaviorProperty("AudioClip")]
	public Guid Sound;
	[BehaviorProperty]
	public String Label = new .("crate") ~ delete _;
	public int32 Hits = 0;
	public String LastBy = new .() ~ delete _;

	public void OnStart()
	{
		Hits = 0;
	}

	/// An entity event: its argument an entity.
	public void OnHit(EntityHandle by)
	{
		Hits++;
		let scene = Scene;
		LastBy.Set((scene != null) ? scene.GetEntityName(by) : "");
	}

	public void Shake()
	{
	}
}

/// A class that marks a field of a type no property holds.
[NativeBehavior]
class NativeCookOdd : EntityBehavior
{
	[BehaviorProperty]
	public Float2 Turn;
}

/// A class that marks a Guid a property without naming the asset type it holds.
[NativeBehavior]
class NativeCookUntyped : EntityBehavior
{
	[BehaviorProperty]
	public Guid Clip;
}

/// The Native Behavior cook reads a class's declaration from its reflection, and what it cooks runs
/// on a scene.
class NativeBehaviorCookTests
{
	const String cTarget = "Sedulous.Integration.Plugins.NativeCookTarget";

	[Test]
	public static void TheCookHarvestsAClassesKindItsMarkedFieldsWithTheirDefaultsAndItsHandlers()
	{
		let type = NativeBehaviorTypes.FindClass(cTarget);
		Test.Assert(type != null);
		let cooked = scope BehaviorClassSource();
		let why = scope String();
		Test.Assert(NativeBehaviorHarvest.Harvest(type, cooked, why), why);
		Test.Assert(cooked.Language == NativeBehaviorTypes.cLanguage);
		Test.Assert(cooked.ClassName == cTarget);
		Test.Assert(cooked.Kind == .Entity);
		Test.Assert(cooked.Properties.Count == 3); // toughness, sound, label: not hits
		Test.Assert(cooked.Properties[0].Name == "toughness");
		Test.Assert(cooked.Properties[0].Type == .Float);
		Test.Assert(Math.Abs(cooked.Properties[0].Default.Number - 3.0) < 0.0001);
		Test.Assert(cooked.Properties[0].Description == "Hits it takes");
		Test.Assert(cooked.Properties[0].Hash == ScriptPropertyNames.HashOf("toughness"));
		Test.Assert(cooked.Properties[1].Type == .Asset);
		Test.Assert(cooked.Properties[1].AssetType == "AudioClip");
		Test.Assert(cooked.Properties[2].Type == .String);
		Test.Assert(cooked.Properties[2].Default.Text == "crate");
		Test.Assert(cooked.Handlers.Count == 2); // onStart, onHit: not Shake
		Test.Assert(cooked.Handlers.Contains("onStart"));
		Test.Assert(cooked.Handlers.Contains("onHit"));
		Test.Assert(NativeBehaviorHarvest.DeclarationsHash() != 0);

		let odd = scope BehaviorClassSource();
		why.Clear();
		Test.Assert(!NativeBehaviorHarvest.Harvest(NativeBehaviorTypes.FindClass("Sedulous.Integration.Plugins.NativeCookOdd"), odd, why));
		Test.Assert(why.Contains("Turn"), why);
		why.Clear();
		Test.Assert(!NativeBehaviorHarvest.Harvest(NativeBehaviorTypes.FindClass("Sedulous.Integration.Plugins.NativeCookUntyped"), scope BehaviorClassSource(), why));
		Test.Assert(why.Contains("Clip"), why);
		Test.Assert(NativeBehaviorTypes.KindOf(typeof(Float3)) == .None);
	}

	[Test]
	public static void ACookedNativeClassTakesAnEntitysOverrideAndHearsAnEntityEvent()
	{
		let cooked = scope BehaviorClassSource();
		let why = scope String();
		Test.Assert(NativeBehaviorHarvest.Harvest(NativeBehaviorTypes.FindClass(cTarget), cooked, why), why);
		let product = scope BehaviorClass();
		product.From(cooked);

		let run = scope RunBase("native");
		let host = scope BehaviorRunHost();
		let scene = scope Scene("native");
		scene.SetRun(run);
		BehaviorScene.AddBehaviorSceneManagers(scene);
		scene.GetSystem<BehaviorSystem>().SetRunHost(host);
		let components = scene.GetSystem<BehaviorComponentManager>();

		let target = scene.CreateEntity("crate");
		let rock = scene.CreateEntity("rock");
		let behavior = new AttachedBehavior();
		behavior.BehaviorClass.SetDirect(product);
		behavior.SetOverride(ScriptPropertyNames.HashOf("toughness"), .Float(5.0));
		components.Add(target).Behaviors.Add(behavior);

		scene.Start();
		scene.Update(1.0f / 60.0f);
		run.Events.Publish(StringHash("Hit"), ScriptPayloads.Of(rock));
		run.Events.Drain();
		scene.Update(1.0f / 60.0f);

		let instance = components.Get(target).Behaviors[0].Instance;
		Test.Assert(instance != null);
		Test.Assert(host.Scripts.Runtime == null); // no script runtime was made for it
		let object = (instance as NativeBehaviorObject).Object as NativeCookTarget;
		Test.Assert(Math.Abs(object.Toughness - 5.0f) < 0.0001f); // the override, over the default
		Test.Assert(object.Hits == 1);
		Test.Assert(object.LastBy == "rock");
		Test.Assert(!components.Get(target).Behaviors[0].Faulted);
		scene.Stop();
	}
}
