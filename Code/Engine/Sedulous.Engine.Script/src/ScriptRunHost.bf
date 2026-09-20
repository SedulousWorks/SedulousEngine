using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Script;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Script;

/// The run's script runtime and the behaviour classes loaded into it.
///
/// ONE runtime per run: every behaviour class of the run is compiled into one module, a
/// fresh generation (`behaviors#N`) whenever a class is added or reloaded, each class as
/// its own section so an error names its file. Instances keep running on the generation
/// they were built from; the old module is discarded and goes when they do.
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
	/// BORROWED: the services the owner installed on this run, by exact type, applied to
	/// the runtime when it exists and to the next one after a teardown.
	private List<(Type type, Object service)> mServices = new .() ~ delete _;
	private String mLanguage = new .() ~ delete _;
	/// BORROWED: the resource manager owns the products.
	private List<ScriptClass> mLoaded = new .() ~ delete _;
	private bool mModuleCurrent = false;
	private int mGeneration = 0;
	private String mModuleName = new .() ~ delete _;
	private bool mWarnedLanguage = false;

	public ScriptRuntime Runtime => mRuntime;
	public ScriptRandom Random => mRandom;

	/// Installs a service on this run, `Input` say: reached by a script as the handle of
	/// its type, on the runtime now and on any later one. BORROWED.
	public void SetService<T>(T service) where T : class
	{
		for (int i = 0; i < mServices.Count; i++)
		{
			if (mServices[i].type == typeof(T))
			{
				mServices[i] = (typeof(T), service);
				if (mRuntime?.Context != null)
					mRuntime.Context.SetService(typeof(T), service);
				return;
			}
		}
		mServices.Add((typeof(T), service));
		if (mRuntime?.Context != null)
			mRuntime.Context.SetService(typeof(T), service);
	}
	public bool IsActive => mRuntime != null;
	public StringView ModuleName => mModuleName;
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
		// The run's own services: its random numbers, and what the owner installed.
		runtime.SetService(mRandom);
		for (let entry in mServices)
			runtime.Context?.SetService(entry.type, entry.service);
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

	/// Advances the run's coroutines by gameplay time. Once per frame, by the host's OWNER,
	/// the game instance or the subsystem, never per scene: a run with three scenes has one
	/// clock, and a run with no scene yet, a game script loading its first level, still has
	/// to move.
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
		let instance = mRuntime.Instantiate(mModuleName, scriptClass.ClassName);
		if (instance == null)
			ReportProblems();
		return instance;
	}

	/// Compiles the class, with every other class of the run, into the current generation.
	public bool EnsureClassLoaded(ScriptClass scriptClass)
	{
		if (EnsureRuntime(scriptClass.Language) == null)
			return false;

		bool present = false;
		for (int i = 0; i < mLoaded.Count; i++)
		{
			if (mLoaded[i] === scriptClass)
			{
				present = true;
				break;
			}
			// A reloaded product replaces its predecessor of the same name.
			if (mLoaded[i].ClassName == scriptClass.ClassName)
			{
				mLoaded[i] = scriptClass;
				mModuleCurrent = false;
				present = true;
				break;
			}
		}
		if (!present)
		{
			mLoaded.Add(scriptClass);
			mModuleCurrent = false;
		}
		if (mModuleCurrent)
			return true;

		let sections = scope List<ScriptSection>();
		for (let loaded in mLoaded)
			sections.Add(.(loaded.SourceName, loaded.Source));
		let previous = scope String(mModuleName);
		mGeneration++;
		mModuleName.Set(scope $"behaviors#{mGeneration}");
		if (!mRuntime.CompileModule(mModuleName, sections))
		{
			GlobalLog(.Error, scope $"Script: the behaviours module failed to compile (class '{scriptClass.ClassName}' newly added)");
			ReportProblems();
			return false;
		}
		if (!previous.IsEmpty)
			mRuntime.DiscardModule(previous);
		mModuleCurrent = true;
		return true;
	}

	/// Logs and clears what the runtime collected.
	public void ReportProblems()
	{
		if (mRuntime == null)
			return;
		for (let p in mRuntime.Problems)
			GlobalLog(.Error, scope $"Script: {p}");
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
		mLoaded.Clear();
		mModuleCurrent = false;
		mModuleName.Clear();
		mWarnedLanguage = false;
	}
}
