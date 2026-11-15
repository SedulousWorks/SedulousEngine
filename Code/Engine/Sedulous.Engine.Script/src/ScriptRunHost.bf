using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Script;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Script;

/// The run's script runtime and the behaviour classes loaded into it.
///
/// ONE runtime per run: every behaviour class of the run is compiled into one module, a
/// fresh generation (`behaviors#N`) whenever a class is added or reloaded, each class as
/// its own section so an error names its file. Instances keep running on the generation
/// they were built from, so a previous module is kept until the run's teardown: discarding
/// it would free its global variables under the instances still reading them.
///
/// The language is the first class's; a second language in the same run is refused, since
/// the run has one gameplay context. Plain class, no runtime dependencies, so a headless
/// test drives it directly.
class ScriptRunHost
{
	/// Wires a fresh runtime: binds the surface, registers services. The host's owner
	/// supplies it, since only the application knows what a run may reach.
	public delegate void(ScriptRuntime runtime) Configure = null ~ delete _;

	private ScriptRuntime mRuntime = null ~ delete _;
	/// OWNED: this run's random numbers, `Random` to a script; seedable by the owner.
	private ScriptRandom mRandom = new .() ~ delete _;
	/// BORROWED: the services the owner installed on this host, by exact type, which its scripts
	/// find first (FindService).
	private List<(Type type, Object service)> mServices = new .() ~ delete _;
	/// BORROWED: the run this host belongs to (a GameInstance, a scene page's run), whose
	/// services its scripts find after the host's own; null outside every run (the subsystem's
	/// default host).
	public IRun OwningRun = null;
	/// BORROWED: the application's subsystems, whose services its scripts find last; set by the
	/// ScriptSubsystem that wires the host, and cleared as it shuts down. Null: none.
	public SubsystemManager Subsystems = null;
	private String mLanguage = new .() ~ delete _;
	/// BORROWED: the resource manager owns the products.
	/// The classes loaded, each in a module of its own, as COPIES of their names and sources: a
	/// ScriptClass is a product the resource manager replaces (and frees) on every hot reload,
	/// and this host outlives a play, so it must not hold one.
	private List<LoadedClass> mLoaded = new .() ~ DeleteContainerAndItems!(_);

	private class LoadedClass
	{
		public String ClassName = new .() ~ delete _;
		public String SourceName = new .() ~ delete _;
		public String Source = new .() ~ delete _;
		/// The module it loaded into.
		public String ModuleName = new .() ~ delete _;

		public void Set(ScriptClass scriptClass)
		{
			ClassName.Set(scriptClass.ClassName);
			SourceName.Set(scriptClass.SourceName);
			Source.Set(scriptClass.Source);
		}
	}
	/// How many class modules the run has loaded: each a class's own.
	private int mGeneration = 0;
	private bool mWarnedLanguage = false;

	public ScriptRuntime Runtime => mRuntime;
	public ScriptRandom Random => mRandom;

	/// A game script running on this host pins it: no teardown while it lives. Set by the
	/// game instance that launched it.
	public bool HasGameScriptHold = false;
	/// Asks the host's owner whether the host can go now (nothing pins it), and tears it down
	/// when so. Installed by the ScriptSubsystem; null for a host nobody watches. Owned.
	public delegate void(ScriptRunHost host) TeardownCheck = null ~ delete _;

	/// Runs the owner's teardown check: what a game instance calls when its game script ends.
	public void CheckTeardown()
	{
		if (TeardownCheck != null)
			TeardownCheck(this);
	}

	/// Installs a service on this host, reached by a script as the handle of its type before its
	/// run's and the application's, by the runtime now and any later one. BORROWED.
	public void SetService<T>(T service) where T : class
	{
		for (int i = 0; i < mServices.Count; i++)
		{
			if (mServices[i].type == typeof(T))
			{
				mServices[i] = (typeof(T), service);
				return;
			}
		}
		mServices.Add((typeof(T), service));
	}

	/// The service of exactly `type` this host's scripts reach: the host's own (SetService), then
	/// its run's (OwningRun), then the application's (Subsystems); null when none has one. Asked as
	/// each call is made, so a run's service that goes with the run is not found after it.
	public Object FindService(Type type)
	{
		for (let entry in mServices)
		{
			if (entry.type == type)
				return entry.service;
		}
		if (OwningRun != null)
		{
			let found = OwningRun.FindService(type);
			if (found != null)
				return found;
		}
		return (Subsystems != null) ? Subsystems.FindService(type) : null;
	}
	public bool IsActive => mRuntime != null;
	public int Generation => mGeneration;

	/// The runtime for the language, created on first use.
	public ScriptRuntime EnsureRuntime(StringView language)
	{
		if (mRuntime != null)
		{
			if (mLanguage != language)
			{
				if (!mWarnedLanguage)
				{
					GlobalLog(.Error, scope $"Script: a run has one language; '{language}' refused, the run is '{mLanguage}'");
					mWarnedLanguage = true;
				}
				return null;
			}
			return mRuntime;
		}
		let runtime = ScriptBackends.Create(language);
		if (runtime == null)
		{
			GlobalLog(.Error, scope $"Script: no backend registered for '{language}'");
			return null;
		}
		mRuntime = runtime;
		mLanguage.Set(language);
		if (Configure != null)
			Configure(runtime);
		// The run's random numbers on the runtime itself; everything else a script reaches is looked
		// up as it is asked for: the host's own, then its run's, then the application's.
		runtime.SetService(mRandom);
		runtime.Context?.SetServiceResolver(new [=this] (type) => FindService(type));
		EnsureDebugger(); // a debugger requested before the runtime existed attaches now
		return runtime;
	}

	// ---- debugging ----

	/// OWNED: the run's step debugger, made on request.
	private IScriptDebugger mDebugger = null ~ delete _;
	/// A request that arrived before the runtime existed: applied when it does.
	private delegate void(IScriptDebugger debugger) mDebuggerConfigurator = null ~ delete _;

	public IScriptDebugger Debugger => mDebugger;

	/// A call the debugger suspended is being held, which the host's ticks and handlers
	/// hold still for: starting a new update each frame would hit the breakpoint again
	/// every frame and orphan the held call.
	public bool IsDebugPaused => (mRuntime != null) && mRuntime.IsDebugPaused;

	/// Attaches the debugger, making it when the runtime exists and otherwise as soon as it
	/// does; `configurator` applies the breakpoints and takes the pointer. TAKES OWNERSHIP
	/// of the delegate. A backend without a debugger never calls it.
	public void RequestDebugger(delegate void(IScriptDebugger debugger) configurator)
	{
		delete mDebuggerConfigurator;
		mDebuggerConfigurator = configurator;
		EnsureDebugger();
	}

	private void EnsureDebugger()
	{
		if ((mRuntime == null) || (mDebuggerConfigurator == null))
			return;
		if (mDebugger == null)
			mDebugger = mRuntime.CreateDebugger();
		if (mDebugger == null)
			return;
		let configurator = mDebuggerConfigurator;
		mDebuggerConfigurator = null;
		configurator(mDebugger);
		delete configurator;
	}

	/// Advances the run's coroutines by gameplay time: its scripts' clock. Once per frame, by
	/// whoever owns the host (a game's run, a scene page's, the subsystem for its default host),
	/// never per scene: a run with three scenes has one clock, and a run with no scene yet, a game
	/// script loading its first level, still has to move. With no runtime (a run whose game has
	/// no scripts) there is nothing to move, and none is made.
	public void Advance(float deltaTime)
	{
		if ((mRuntime != null) && !IsDebugPaused)
			mRuntime.AdvanceCoroutines(deltaTime);
	}

	/// An instance of the class, its module loaded or reloaded as needed. Null on failure,
	/// logged.
	public ScriptObject Instantiate(ScriptClass scriptClass)
	{
		if (!EnsureClassLoaded(scriptClass))
			return null;
		let instance = mRuntime.Instantiate(ModuleOf(scriptClass.ClassName), scriptClass.ClassName);
		if (instance == null)
			ReportProblems();
		return instance;
	}

	/// The module class `className` loaded into; empty when it has not.
	public StringView ModuleOf(StringView className)
	{
		for (let loaded in mLoaded)
		{
			if (loaded.ClassName == className)
				return loaded.ModuleName;
		}
		return default;
	}

	/// Loads the class unless it is already loaded. Each class is compiled and cooked alone, so
	/// it loads alone, in a module of its own: no class waits on another, a class that fails to
	/// load is not kept (so it fails no class after it), and a reloaded class (the same name, a
	/// changed source) loads beside its predecessor, whose live instances keep running. False on
	/// a load failure, logged.
	public bool EnsureClassLoaded(ScriptClass scriptClass)
	{
		if (EnsureRuntime(scriptClass.Language) == null)
			return false;

		LoadedClass replaced = null;
		for (let loaded in mLoaded)
		{
			if (loaded.ClassName != scriptClass.ClassName)
				continue;
			// A reloaded product carries its class under the same name: a changed source loads
			// again, the same one does not.
			if ((loaded.Source == scriptClass.Source) && (loaded.SourceName == scriptClass.SourceName))
				return true;
			replaced = loaded;
			break;
		}

		mGeneration++;
		let moduleName = scope $"behavior:{scriptClass.ClassName}#{mGeneration}";
		ScriptSection[1] sections = .(.(scriptClass.SourceName, scriptClass.Source));
		if (!mRuntime.CompileModule(moduleName, sections))
		{
			GlobalLog(.Error, scope $"Script: class '{scriptClass.ClassName}' failed to load");
			ReportProblems();
			return false;
		}
		let loaded = replaced ?? mLoaded.Add(.. new LoadedClass());
		loaded.Set(scriptClass);
		loaded.ModuleName.Set(moduleName);
		return true;
	}

	/// Logs and clears what the runtime collected, appending each line to `outText` too when
	/// given ("; " between them).
	public void ReportProblems(String outText = null)
	{
		if (mRuntime == null)
			return;
		for (let p in mRuntime.Problems)
		{
			GlobalLog(ScriptProblems.IsWarning(p) ? .Warning : .Error, scope $"Script: {p}");
			if (outText != null)
			{
				if (!outText.IsEmpty)
					outText.Append("; ");
				outText.Append(p);
			}
		}
		ClearAndDeleteItems!(mRuntime.Problems);
	}

	/// The run's end: the runtime and every class reference go. Instances held elsewhere
	/// must have been released first.
	public void Teardown()
	{
		// The debugger before the runtime: it releases what it holds through it.
		DeleteAndNullify!(mDebugger);
		DeleteAndNullify!(mRuntime);
		mLanguage.Clear();
		ClearAndDeleteItems!(mLoaded);
		mWarnedLanguage = false;
		// The next run starts from the default seed, as a fresh run does: a second play in
		// the same tab must not continue the first one's sequence.
		delete mRandom;
		mRandom = new .();
	}
}
