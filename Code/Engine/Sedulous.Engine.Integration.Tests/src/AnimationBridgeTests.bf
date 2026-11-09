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
using Sedulous.Engine.Script;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Integration;

namespace Sedulous.Engine.Integration.Tests;

/// A context with the scene, animation and script subsystems started and a live scene, acting
/// as its OWN composition root: the animation's events reach the script subsystem through the
/// SAME bridge DefaultApplication installs, as ContactWorld does for contacts.
class AnimationWorld
{
	private static bool sRegistered = false;

	public SubsystemManager Context = new .();
	public SceneSubsystem Scenes;
	public AnimationSubsystem Animations;
	public ScriptSubsystem Scripts;
	public ScriptAnimationBridge Bridge = new .();
	public SceneManager Manager = new .();
	public RunBase SceneRun = new .("animations");
	public Scene Scene;

	private ScriptSurface mSurface = new .();
	private List<ScriptClass> mClasses = new .();
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
		Scripts = Context.AddSubsystem<ScriptSubsystem>();
		Scripts.Configure = new (runtime) =>
			{
				runtime.Bind(mSurface);
				ClearAndDeleteItems!(runtime.Problems);
			};
		mScriptModule = .("script", => ScriptScene.AddScriptSceneManagers, null);
		mAnimationModule = .("animation", => AnimationScene.AddAnimationSceneManagers, null);
		var modules = SceneModule*[2](&mScriptModule, &mAnimationModule);
		Scenes.SetComposition(SceneComposition.Build(modules));
		Context.Startup();
		Bridge.Install(Animations, Scripts);

		Scenes.RegisterManager(Manager);
		Manager.SetSceneRun(SceneRun);
		Scene = Manager.CreateScene("level");
		// The animators feed meshes, and tick only beside a mesh manager.
		Scene.AddSystem<MeshComponentManager>();
	}

	public ~this()
	{
		// The bridge before the animation subsystem goes; the scenes before the host they
		// script on, and before their manager is unregistered.
		Bridge.Uninstall();
		Manager.Clear();
		Scenes.UnregisterManager(Manager);
		Context.Shutdown();
		delete Bridge;
		delete Manager;
		delete Context;
		delete SceneRun;
		ClearAndDeleteItems!(mClasses);
		delete mClasses;
		delete mSurface;
	}

	/// Compiles and harvests a class through the run's own runtime, as ContactWorld does.
	public ScriptClass Class(StringView className, StringView source)
	{
		let runtime = Scripts.Host.EnsureRuntime(AngelScriptBackend.cLanguage);
		Test.Assert(runtime != null);
		let module = scope $"harvest#{mHarvested++}";
		let ok = runtime.Compile(module, "Test.as", source);
		for (let p in runtime.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "the class compiled");
		let record = scope ScriptClassSource();
		record.Language.Set(AngelScriptBackend.cLanguage);
		record.ClassName.Set(className);
		record.SourceName.Set("Test.as");
		record.Source.Set(source);
		Test.Assert(ScriptHarvest.Harvest(runtime, module, className, record), "harvested");
		runtime.DiscardModule(module);
		let product = new ScriptClass();
		product.From(record);
		mClasses.Add(product);
		return product;
	}

	public ScriptBehavior Attach(EntityHandle entity, ScriptClass scriptClass)
	{
		let components = Scene.GetSystem<ScriptComponentManager>();
		var component = components.Get(entity);
		if (component == null)
			component = components.Add(entity);
		let behavior = new ScriptBehavior();
		behavior.Script.SetDirect(scriptClass);
		component.Behaviors.Add(behavior);
		return behavior;
	}

	public ScriptBehavior BehaviorOf(EntityHandle entity)
		=> Scene.GetSystem<ScriptComponentManager>().Get(entity).Behaviors[0];

	public ScriptValue Prop(EntityHandle entity, StringView name)
	{
		var value = ScriptValue.Nil;
		let runtime = Scripts.Host.EnsureRuntime(AngelScriptBackend.cLanguage);
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

/// The animation to script bridge: the install contract, and a one-shot's end reaching the
/// entity's behaviours as onAnimationFinished(clip).
static class AnimationBridgeTests
{
	[Test]
	public static void TheAnimationBridgeInstallsOnTheAnimationSubsystemAndLetsGo()
	{
		let bridge = scope ScriptAnimationBridge();
		Test.Assert(!bridge.Installed);
		bridge.Uninstall(); // idempotent when never installed
		bridge.Install(null, null);
		Test.Assert(!bridge.Installed, "half a wiring is no wiring");
		// An event with nothing behind it is dropped, not dereferenced.
		bridge.OnOneShotEnded(.(null, .Invalid, Guid()));

		let animation = scope AnimationSubsystem();
		let scripts = scope ScriptSubsystem();
		bridge.Install(animation, scripts);
		Test.Assert(bridge.Installed);
		bridge.Install(animation, scripts); // re-points cleanly
		Test.Assert(bridge.Installed);
		bridge.Uninstall();
		Test.Assert(!bridge.Installed);
	}

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
}
