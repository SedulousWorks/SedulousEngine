using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Messaging;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;
using Sedulous.Engine.ScriptSurface;

namespace Sedulous.Engine.Script.Tests;

/// A headless scene with the script systems, an event bus, and a run host on the real
/// backend bound to the real engine surface. Script classes are compiled and harvested
/// here from source, standing in for the cook.
class ScriptPlayScene
{
	public Scene Scene;
	public EventBus Bus = new .();
	public ScriptComponentManager Components;
	public ScriptSceneSystem Scripts;
	public ScriptRunHost Host = new .();
	private ScriptSurface mSurface = new .();
	private List<ScriptClass> mClasses = new .();
	private int mHarvested = 0;

	/// The scenes go first: their teardown releases instances through the host, which
	/// must still be there; then the host, the classes, the surface.
	public ~this()
	{
		delete Scene;
		DeleteContainerAndItems!(mExtraScenes);
		delete Host;
		DeleteContainerAndItems!(mClasses);
		delete Bus;
		delete mSurface;
	}

	private static bool sRegistered = false;

	public this(StringView name = "play")
	{
		if (!sRegistered)
		{
			AngelScriptBackend.Register();
			sRegistered = true;
		}
		EngineScriptSurface.Populate(mSurface);
		Host.Configure = new (runtime) =>
			{
				runtime.Bind(mSurface);
				// The binding's known gaps (the lists) are not this test's business.
				ClearAndDeleteItems!(runtime.Problems);
			};

		Scene = new Scene(name);
		Scene.SetEventBus(Bus);
		ScriptScene.AddScriptSceneManagers(Scene);
		Components = Scene.GetSystem<ScriptComponentManager>();
		Scripts = Scene.GetSystem<ScriptSceneSystem>();
		Scripts.SetRunHost(Host);
	}

	/// A second scene on the same run host.
	public Scene AddScene(StringView name)
	{
		let scene = new Scene(name);
		scene.SetEventBus(Bus);
		ScriptScene.AddScriptSceneManagers(scene);
		scene.GetSystem<ScriptSceneSystem>().SetRunHost(Host);
		mExtraScenes.Add(scene);
		return scene;
	}
	private List<Scene> mExtraScenes = new .();

	/// Compiles `source` as `sourceName`, harvests `className` from it, and answers the
	/// product. The class is owned here, as a resource manager would own it.
	public ScriptClass Class(StringView className, StringView source, StringView sourceName = "Test.as")
	{
		let runtime = Host.EnsureRuntime(AngelScriptBackend.cLanguage);
		Test.Assert(runtime != null);
		let module = scope $"harvest#{mHarvested++}";
		let ok = runtime.Compile(module, sourceName, source);
		for (let p in runtime.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "the class compiled");

		let record = scope ScriptClassSource();
		record.Language.Set(AngelScriptBackend.cLanguage);
		record.ClassName.Set(className);
		record.SourceName.Set(sourceName);
		record.Source.Set(source);
		Test.Assert(ScriptHarvest.Harvest(runtime, module, className, record), "harvested");
		runtime.DiscardModule(module);

		let product = new ScriptClass();
		product.From(record);
		mClasses.Add(product);
		return product;
	}

	/// An entity with one behaviour of the class.
	public EntityHandle AddBehavior(ScriptClass scriptClass, StringView entityName = "e", Scene into = null)
	{
		let scene = into ?? Scene;
		let entity = scene.CreateEntity(entityName);
		Attach(entity, scriptClass, scene);
		return entity;
	}

	public ScriptBehavior Attach(EntityHandle entity, ScriptClass scriptClass, Scene into = null)
	{
		let scene = into ?? Scene;
		let components = scene.GetSystem<ScriptComponentManager>();
		var component = components.Get(entity);
		if (component == null)
			component = components.Add(entity);
		let behavior = new ScriptBehavior();
		behavior.Script.SetDirect(scriptClass);
		component.Behaviors.Add(behavior);
		return behavior;
	}

	public ScriptBehavior BehaviorOf(EntityHandle entity, int index = 0, Scene into = null)
	{
		let scene = into ?? Scene;
		return scene.GetSystem<ScriptComponentManager>().Get(entity).Behaviors[index];
	}

	public void Start()
	{
		Scene.Start();
		for (let s in mExtraScenes)
			s.Start();
	}

	public void Stop()
	{
		Scene.Stop();
		for (let s in mExtraScenes)
			s.Stop();
	}

	/// Ticks the scene(s) and drains the bus, as a frame does.
	public void Step(int frames = 1, float dt = 1.0f / 60.0f)
	{
		for (int i = 0; i < frames; i++)
		{
			Scene.Update(dt);
			for (let s in mExtraScenes)
				s.Update(dt);
			Bus.Drain();
			// Once per frame, as the host's owner does: the run's one clock.
			Host.Advance(dt);
		}
	}

	public ScriptRuntime Runtime => Host.Runtime;

	/// A property of the entity's first behaviour's instance.
	public ScriptValue Prop(EntityHandle entity, StringView name, Scene into = null)
	{
		let behavior = BehaviorOf(entity, 0, into);
		var v = ScriptValue.Nil;
		if (behavior.Instance != null)
			Runtime.GetProperty(behavior.Instance, name, ref v);
		return v;
	}

	public int PropInt(EntityHandle entity, StringView name, Scene into = null) => (int)Prop(entity, name, into).AsInt;
	public float PropFloat(EntityHandle entity, StringView name, Scene into = null) => (float)Prop(entity, name, into).AsNumber;
}
