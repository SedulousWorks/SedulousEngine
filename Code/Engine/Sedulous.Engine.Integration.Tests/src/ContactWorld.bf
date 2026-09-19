using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Messaging;
using Sedulous.Physics;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Resource;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Scene;
using Sedulous.Engine.Script;
using Sedulous.Engine.ScriptSurface;
using Sedulous.Engine.Integration;

namespace Sedulous.Engine.Integration.Tests;

/// A context with the scene, physics and script subsystems started and a live scene, acting
/// as its OWN composition root: physics contacts reach the script subsystem's neutral
/// ingress through the SAME bridge DefaultApplication installs, so a contact test here
/// exercises the adapter, and the script subsystem keeps no physics dependency.
class ContactWorld
{
	private static bool sRegistered = false;

	public Context Context = new .();
	public SceneSubsystem Scenes;
	public PhysicsSubsystem Physics;
	public ScriptSubsystem Scripts;
	public ScriptPhysicsContactBridge Bridge = new .();
	public SceneManager Manager = new .();
	public EventBus Bus = new .();
	public Scene Scene;

	private ScriptSurface mSurface = new .();
	private List<ScriptClass> mClasses = new .();
	private int mHarvested = 0;

	// Modules are addressed by pointer, so they live as long as the composition.
	private SceneModule mScriptModule;
	private SceneModule mPhysicsModule;

	public this()
	{
		if (!sRegistered)
		{
			AngelScriptBackend.Register();
			sRegistered = true;
		}
		EngineScriptSurface.Populate(mSurface);

		Scenes = Context.AddSubsystem<SceneSubsystem>();
		Physics = Context.AddSubsystem<PhysicsSubsystem>();
		Scripts = Context.AddSubsystem<ScriptSubsystem>();
		Scripts.Configure = new (runtime) =>
			{
				runtime.Bind(mSurface);
				ClearAndDeleteItems!(runtime.Problems);
			};
		mScriptModule = .("script", => ScriptScene.AddScriptSceneManagers, null);
		mPhysicsModule = .("physics", => PhysicsScene.AddPhysicsSceneManagers, null);
		var modules = SceneModule*[2](&mScriptModule, &mPhysicsModule);
		Scenes.SetComposition(SceneComposition.Build(modules));
		Context.Startup();
		Bridge.Install(Physics, Scripts);

		Scenes.RegisterManager(Manager);
		Scene = Manager.CreateScene("level");
		Scene.SetEventBus(Bus);
	}

	public ~this()
	{
		// The bridge before the physics subsystem goes; the scenes before the host they
		// script on.
		Bridge.Uninstall();
		Scenes.UnregisterManager(Manager);
		Manager.Clear();
		Context.Shutdown();
		delete Bridge;
		delete Manager;
		delete Context;
		delete Bus;
		ClearAndDeleteItems!(mClasses);
		delete mClasses;
		delete mSurface;
	}

	public EntityHandle AddBody(StringView name, Float3 position, MotionKind motion, Float3 halfExtents,
		bool trigger = false)
	{
		let entity = Scene.CreateEntity(name);
		Scene.SetLocalPosition(entity, position);
		let body = Scene.GetSystem<RigidBodyComponentManager>().Add(entity);
		body.Motion = motion;
		body.Layer = (motion == .Static) ? PhysicsLayer.Static
			: (motion == .Kinematic) ? PhysicsLayer.Kinematic : PhysicsLayer.Dynamic;
		body.HalfExtents = halfExtents;
		body.IsTrigger = trigger;
		return entity;
	}

	/// Compiles and harvests a class through the run's own runtime, as the fixture in
	/// Engine.Script.Tests does.
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

	/// Starts the scene and runs `frames` context frames: fixed steps push contacts through
	/// the bridge onto the script queue, the scene tick drains them.
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
