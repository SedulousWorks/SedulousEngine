using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Resource;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Engine.Behavior;
using Sedulous.Engine.Composition;

namespace Sedulous.Engine.Integration.Tests;

/// A context with the scene, animation and script subsystems started and a live scene, acting
/// as its OWN composition root: the animation posts its events to the scene and the scene's
/// behavior system hears them, as ContactWorld does for contacts.
class AnimationWorld
{
	private static bool sRegistered = false;

	public SubsystemManager Context = new .();
	public SceneSubsystem Scenes;
	public AnimationSubsystem Animations;
	public BehaviorSubsystem Scripts;
	public SceneManager Manager = new .();
	public RunBase SceneRun = new .("animations");
	public Scene Scene;

	private ScriptSurface mSurface = new .();
	private List<BehaviorClass> mClasses = new .();
	private int mHarvested = 0;

	// Modules are addressed by pointer, so they live as long as the composition.
	private SceneModule mScriptModule;
	private SceneModule mAnimationModule;

	public this()
	{
		if (!sRegistered)
		{
			AngelScriptBackend.Register();
			sRegistered = true;
		}
		EngineScriptSurface.Populate(mSurface);

		Scenes = Context.AddSubsystem<SceneSubsystem>();
		Animations = Context.AddSubsystem<AnimationSubsystem>();
		Scripts = Context.AddSubsystem<BehaviorSubsystem>();
		Scripts.Configure = new (runtime) =>
			{
				runtime.Bind(mSurface);
				ClearAndDeleteItems!(runtime.Problems);
			};
		mScriptModule = .("behavior", => BehaviorScene.AddBehaviorSceneManagers, null);
		mAnimationModule = .("animation", => AnimationScene.AddAnimationSceneManagers, null);
		var modules = SceneModule*[2](&mScriptModule, &mAnimationModule);
		Scenes.SetComposition(SceneComposition.Build(modules));
		Context.Startup();

		Scenes.RegisterManager(Manager);
		Manager.SetSceneRun(SceneRun);
		Scene = Manager.CreateScene("level");
		// The animators feed meshes, and tick only beside a mesh manager.
		Scene.AddSystem<MeshComponentManager>();
	}

	public ~this()
	{
		// The scenes before the host they script on, and before their manager is unregistered.
		Manager.Clear();
		Scenes.UnregisterManager(Manager);
		Context.Shutdown();
		delete Manager;
		delete Context;
		delete SceneRun;
		ClearAndDeleteItems!(mClasses);
		delete mClasses;
		delete mSurface;
	}

	/// Compiles and harvests a class through the run's own runtime, as ContactWorld does.
	public BehaviorClass Class(StringView className, StringView source)
	{
		let runtime = Scripts.Host.Scripts.EnsureRuntime(AngelScriptBackend.cLanguage);
		Test.Assert(runtime != null);
		let module = scope $"harvest#{mHarvested++}";
		let ok = runtime.Compile(module, "Test.as", source);
		for (let p in runtime.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "the class compiled");
		let record = scope BehaviorClassSource();
		record.Language.Set(AngelScriptBackend.cLanguage);
		record.ClassName.Set(className);
		record.Kind = .Entity;
		record.SourceName.Set("Test.as");
		record.Source.Set(source);
		Test.Assert(ScriptHarvest.Harvest(runtime, module, className, record), "harvested");
		runtime.DiscardModule(module);
		let product = new BehaviorClass();
		product.From(record);
		mClasses.Add(product);
		return product;
	}

	public AttachedBehavior Attach(EntityHandle entity, BehaviorClass scriptClass)
	{
		let components = Scene.GetSystem<BehaviorComponentManager>();
		var component = components.Get(entity);
		if (component == null)
			component = components.Add(entity);
		let behavior = new AttachedBehavior();
		behavior.BehaviorClass.SetDirect(scriptClass);
		component.Behaviors.Add(behavior);
		return behavior;
	}

	public AttachedBehavior BehaviorOf(EntityHandle entity)
		=> Scene.GetSystem<BehaviorComponentManager>().Get(entity).Behaviors[0];

	public ScriptValue Prop(EntityHandle entity, StringView name)
	{
		var value = ScriptValue.Nil;
		let runtime = Scripts.Host.Scripts.EnsureRuntime(AngelScriptBackend.cLanguage);
		runtime.GetProperty(BehaviorOf(entity).Instance, name, ref value);
		return value;
	}

	public void Play(int frames)
	{
		Scene.UpdateTransforms();
		Scene.Start();
		Scene.SetSimulationEnabled(true);
		Step(frames);
	}

	public void Step(int frames)
	{
		for (int i < frames)
		{
			Context.BeginFrame(1.0f / 60.0f);
			Context.Update(1.0f / 60.0f);
			Context.PostUpdate(1.0f / 60.0f);
			Context.EndFrame();
		}
	}
}

/// A real animation's one-shot ending reaching the entity's behaviours as
/// onAnimationFinished(clip), posted to the scene with nothing between the two.
static class AnimationEventTests
{
	[Test]
	public static void AOneShotThatEndsCallsTheEntitysBehavioursOnAnimationFinished()
	{
		let world = scope AnimationWorld();
		let skeleton = scope Skeleton(1);
		skeleton.Bones[0].Index = 0;
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		let stand = scope AnimationClip("Stand", 1.0f, true);
		let hop = scope AnimationClip("Hop", 0.25f, true);

		let pet = world.Scene.CreateEntity("pet");
		let animator = world.Scene.GetSystem<SkeletalAnimationComponentManager>().Add(pet);
		animator.Skeleton.SetDirect(skeleton);
		animator.Clip.SetDirect(stand);
		let watcher = world.Class("Watcher", """
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
			""");
		world.Attach(pet, watcher);

		world.Play(3); // the animator's player is built
		let hopId = Guid(0x51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8);
		// What scene.Animation.PlayOneShot asks for, with a clip made in code.
		animator.OneShot.Clip.SetDirect(hop);
		animator.OneShot.Clip.SetId(hopId);
		animator.OneShot.Settings = .(1.0f, 0.0f, 0.0f, 0);
		animator.OneShot.Pending = true;
		world.Step(5);
		Test.Assert(world.Prop(pet, "finished").AsInt == 0, "still playing");
		// A quarter second has passed: it ended, and a later tick delivered it, once.
		world.Step(20);
		Test.Assert(world.Prop(pet, "finished").AsInt == 1, scope $"heard {world.Prop(pet, "finished").AsInt} times");
		Test.Assert(world.Prop(pet, "clip").AsGuid == hopId);
		Test.Assert(!world.BehaviorOf(pet).Faulted);
	}

	/// A clip's authored event reaches the entity's behaviours as onAnimationEvent(name).
	[Test]
	public static void AClipsEventCallsTheEntitysBehavioursOnAnimationEvent()
	{
		let world = scope AnimationWorld();
		let skeleton = scope Skeleton(1);
		skeleton.Bones[0].Index = 0;
		skeleton.Bones[0].ParentIndex = -1;
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
		let walk = scope AnimationClip("Walk", 1.0f, true);
		walk.AddEvent(0.1f, "Footstep");

		let pet = world.Scene.CreateEntity("pet");
		let animator = world.Scene.GetSystem<SkeletalAnimationComponentManager>().Add(pet);
		animator.Skeleton.SetDirect(skeleton);
		animator.Clip.SetDirect(walk);
		let listener = world.Class("Listener", """
			class Listener
			{
				Entity self;
				int heard = 0;
				string last;
				void onAnimationEvent(string name)
				{
					heard++;
					last = name;
				}
			}
			""");
		world.Attach(pet, listener);

		world.Play(20); // past 0.1 s, and the next tick delivered it
		Test.Assert(world.Prop(pet, "heard").AsInt == 1, scope $"heard {world.Prop(pet, "heard").AsInt} times");
		Test.Assert(world.Prop(pet, "last").AsString == "Footstep", scope $"heard '{world.Prop(pet, "last").AsString}'");
		Test.Assert(!world.BehaviorOf(pet).Faulted);
	}
}
