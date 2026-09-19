using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Resource;
using Sedulous.VFS;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Script;
using Sedulous.Engine.ScriptSurface;

namespace Sedulous.Engine.GameScript.Tests;

/// A game instance wired the way the default application wires one, without an application:
/// its run host bound to the engine surface, its scenes composed with the script managers,
/// a scene database of authored levels for `Run.LoadSceneAsync`, and an exit request that
/// records the code. Driven by hand, one frame at a time.
class GameRun
{
	private static bool sRegistered = false;

	public GameInstance Instance = new .();
	public ScriptSurface Surface = new .();
	public ResourceManager Resources;
	public int32 ExitCode = -1;
	public int Exits = 0;

	private NativeFileSystem mMount ~ delete _;
	private SerializerFactory mFactory ~ delete _;
	private ContentDatabase mDatabase ~ delete _;
	private String mRoot = new .() ~ delete _;
	private List<ScriptClass> mClasses = new .();
	private delegate void(Scene) mInstaller ~ delete _;
	private int mHarvested = 0;

	public this(StringView name)
	{
		if (!sRegistered)
		{
			AngelScriptBackend.Register();
			ScriptResources.RegisterAll();
			SceneResources.RegisterAll();
			sRegistered = true;
		}
		EngineScriptSurface.Populate(Surface);

		mRoot.Set(name);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);
		mMount = new NativeFileSystem(mRoot);
		mFactory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		mDatabase = new ContentDatabase(mMount, mFactory, "asset");
		Resources = new ResourceManager(mDatabase);

		// What the application does: the host wired to the surface, the run's verbs backed.
		Instance.RunHost.Configure = new (runtime) =>
			{
				runtime.Bind(Surface);
				ClearAndDeleteItems!(runtime.Problems);
			};
		mInstaller = new (scene) => ScriptScene.AddScriptSceneManagers(scene);
		Instance.Scenes.SetSceneInstaller(mInstaller);
		Instance.SetSceneLoader(new (sceneId) =>
			{
				let sceneInstance = mDatabase.GetInstance(sceneId);
				if (sceneInstance == null)
				{
					var failed = SceneLoadHandle();
					failed.Failed = true;
					return failed;
				}
				return Instance.LoadSceneAsync(sceneInstance, Resources, null);
			});
		Instance.SetExitRequest(new (code) => { ExitCode = code; Exits++; });
		Instance.SetSceneActivationPolicy(new (scene) =>
			{
				scene.Start();
				scene.SetSimulationEnabled(true);
			});
	}

	public ~this()
	{
		// The instance first: its scenes and its script go before the database they came from.
		delete Instance;
		delete Resources;
		ClearAndDeleteItems!(mClasses);
		delete mClasses;
		delete Surface;
		RemoveDirectoryRecursive(mRoot);
	}

	/// An authored, entities only level in the scene database, by id.
	public Guid AuthorLevel(StringView name, int entities = 2)
	{
		let sceneInstance = mDatabase.RootGroup.CreateInstance(name, "Sedulous.Scene.Resource.SceneDocument");
		let authored = scope Scene(name);
		for (int i < entities)
			authored.CreateEntity(scope $"e{i}");
		Test.Assert(SceneStorage.SaveScene(authored, sceneInstance) case .Ok);
		return sceneInstance.Id;
	}

	/// Compiles and harvests a class through the run's own runtime: what the cook produces.
	public ScriptClass Class(StringView className, StringView source)
	{
		let runtime = Instance.RunHost.EnsureRuntime(AngelScriptBackend.cLanguage);
		Test.Assert(runtime != null);
		let module = scope $"harvest#{mHarvested++}";
		let ok = runtime.Compile(module, "Game.as", source);
		for (let p in runtime.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "the class compiled");
		let record = scope ScriptClassSource();
		record.Language.Set(AngelScriptBackend.cLanguage);
		record.ClassName.Set(className);
		record.SourceName.Set("Game.as");
		record.Source.Set(source);
		Test.Assert(ScriptHarvest.Harvest(runtime, module, className, record), "harvested");
		runtime.DiscardModule(module);
		let product = new ScriptClass();
		product.From(record);
		mClasses.Add(product);
		return product;
	}

	/// One application frame for the instance: loads pumped, the script ticked, the bus
	/// drained, the scenes updated.
	public void Step(int frames = 1, float dt = 1.0f / 60.0f)
	{
		for (int i < frames)
		{
			Resources.Pump(0.010);
			Instance.PumpLoads();
			Instance.TickScript(dt, 1.0f);
			Instance.DrainRunEvents();
			Instance.Scenes.Update(FrameTime(dt));
		}
	}

	public ScriptObject Game => Instance.[Friend]mGame;

	public ScriptValue Prop(StringView name)
	{
		var v = ScriptValue.Nil;
		if (Game != null)
			Instance.RunHost.Runtime.GetProperty(Game, name, ref v);
		return v;
	}
	public int PropInt(StringView name) => (int)Prop(name).AsInt;
	public float PropFloat(StringView name) => (float)Prop(name).AsNumber;
	public bool PropBool(StringView name) => Prop(name).AsBool;
}
