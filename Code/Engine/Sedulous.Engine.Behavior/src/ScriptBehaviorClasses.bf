using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Script;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Behavior;

/// The script half of a run's behaviors: the run's script runtime, made for the first class in a
/// language that needs one, the classes loaded into it, its debugger and its coroutines. Its run
/// host holds one (BehaviorRunHost.Scripts); a run whose classes need no language never makes a
/// runtime.
///
/// ONE runtime per run: each behaviour class of the run loads into a module of its own,
/// named by generation (`behavior:<Class>#N`, ModuleOf), so a fresh name per load gives hot
/// reload clean semantics. Instances of a replaced class keep running on its old module until
/// they end; the module is discarded once nothing runs it (DiscardUnusedReplaced), as
/// discarding it earlier would free its global variables under the instances still reading
/// them.
///
/// The language is the first class's; a second language in the same run is refused, since
/// the run has one gameplay context. Plain class, no runtime dependencies, so a headless
/// test drives it directly.
class ScriptBehaviorClasses
{
	/// Wires a fresh runtime: binds the surface, registers services. The host's owner
	/// supplies it, since only the application knows what a run may reach.
	public delegate void(ScriptRuntime runtime) Configure = null ~ delete _;

	/// BORROWED: the run host that holds this, whose services the runtime's calls find and whose
	/// random numbers its scripts draw.
	private BehaviorRunHost mHost;
	private ScriptRuntime mRuntime = null ~ delete _;
	private String mLanguage = new .() ~ delete _;
	/// BORROWED: the resource manager owns the products.
	/// The classes loaded, each in a module of its own, as COPIES of their names and sources: a
	/// BehaviorClass is a product the resource manager replaces (and frees) on every hot reload,
	/// and this host outlives a play, so it must not hold one.
	private List<LoadedClass> mLoaded = new .() ~ DeleteContainerAndItems!(_);

	private class LoadedClass
	{
		public String ClassName = new .() ~ delete _;
		public String SourceName = new .() ~ delete _;
		public String Source = new .() ~ delete _;
		/// The module it loaded into.
		public String ModuleName = new .() ~ delete _;
		/// The files it included, path and text, each pair in turn.
		public List<String> Includes = new .() ~ DeleteContainerAndItems!(_);
		/// The assembly image and symbols it loaded from, hashed (ImageHashOf); 0 for a class
		/// compiled from source. Another file of its project changes the image and not the class's
		/// source, and the class loads again for it.
		public uint64 ImageHash = 0;

		public void Set(BehaviorClass scriptClass)
		{
			ClassName.Set(scriptClass.ClassName);
			SourceName.Set(scriptClass.SourceName);
			Source.Set(scriptClass.Source);
			ClearAndDeleteItems!(Includes);
			for (let included in scriptClass.Includes)
			{
				Includes.Add(new String(included.Path));
				Includes.Add(new String(included.Source));
			}
			ImageHash = ImageHashOf(scriptClass);
		}

		/// Whether `scriptClass` is what was loaded: its source, its file, what it includes and the
		/// assembly it was built into.
		public bool Matches(BehaviorClass scriptClass)
		{
			if ((Source != scriptClass.Source) || (SourceName != scriptClass.SourceName) || (Includes.Count != scriptClass.Includes.Count * 2))
				return false;
			if (ImageHash != ImageHashOf(scriptClass))
				return false;
			for (int i < scriptClass.Includes.Count)
			{
				if ((Includes[i * 2] != scriptClass.Includes[i].Path) || (Includes[i * 2 + 1] != scriptClass.Includes[i].Source))
					return false;
			}
			return true;
		}
	}
	/// The class's assembly image and symbols hashed, 0 when it compiles from source.
	private static uint64 ImageHashOf(BehaviorClass scriptClass)
	{
		let assembly = scriptClass.Assembly;
		if (assembly == null)
			return 0;
		let image = HashBytes(assembly.Image.Ptr, assembly.Image.Count);
		return HashBytes(assembly.Symbols.Ptr, assembly.Symbols.Count, image);
	}


	/// How many class modules the run has loaded: each a class's own.
	private int mGeneration = 0;
	/// Modules of classes a reload replaced, discarded once nothing runs their code: discarding
	/// resets a module's globals, which an instance made before the reload may still read.
	private List<String> mReplaced = new .() ~ DeleteContainerAndItems!(_);
	private bool mWarnedLanguage = false;
	/// Why the last class failed to load or instantiate, kept until taken (TakeLastError).
	private String mLastError = new .() ~ delete _;

	public this(BehaviorRunHost host)
	{
		mHost = host;
	}

	public ScriptRuntime Runtime => mRuntime;
	public bool IsActive => mRuntime != null;
	public int Generation => mGeneration;

	/// Appends why the last class failed to load or instantiate, then forgets it; appends nothing
	/// when none failed since the last take.
	public void TakeLastError(String outText)
	{
		outText.Append(mLastError);
		mLastError.Clear();
	}

	/// The runtime for the language, created on first use.
	public ScriptRuntime EnsureRuntime(StringView language)
	{
		if (mRuntime != null)
		{
			if (mLanguage != language)
			{
				mLastError.Set(scope $"a run has one language; '{language}' refused, the run is '{mLanguage}'");
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
			mLastError.Set(scope $"no backend registered for '{language}'");
			return null;
		}
		mRuntime = runtime;
		mLanguage.Set(language);
		if (Configure != null)
			Configure(runtime);
		// The run's random numbers on the runtime itself; everything else a script reaches is looked
		// up as it is asked for: the host's own, then its run's, then the application's.
		runtime.SetService(mHost.Random);
		let host = mHost;
		runtime.Context?.SetServiceResolver(new [=host] (type) => host.FindService(type));
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


	/// Advances the run's coroutines by gameplay time, unless a debugger holds the run, and
	/// discards the replaced modules nothing runs any more. With no runtime there is nothing to
	/// move, and none is made.
	public void Advance(float deltaTime)
	{
		if ((mRuntime != null) && !IsDebugPaused)
			mRuntime.AdvanceCoroutines(deltaTime);
		DiscardUnusedReplaced();
	}

	/// How many replaced class modules still wait for what runs their code.
	public int ReplacedModuleCount => mReplaced.Count;

	/// Discards each replaced class module nothing runs code of any more.
	private void DiscardUnusedReplaced()
	{
		if (mRuntime == null)
			return;
		for (int i = mReplaced.Count - 1; i >= 0; i--)
		{
			if (mRuntime.ModuleInUse(mReplaced[i]))
				continue;
			mRuntime.DiscardModule(mReplaced[i]);
			delete mReplaced[i];
			mReplaced.RemoveAt(i);
		}
	}

	/// An object of `scriptClass`, its class loaded into the run's runtime first (or reloaded).
	/// Null on failure, logged.
	public BehaviorObject Create(BehaviorClass scriptClass)
	{
		if (!EnsureClassLoaded(scriptClass))
			return null;
		let instance = mRuntime.Instantiate(ModuleOf(scriptClass.ClassName), scriptClass.ClassName);
		if (instance == null)
		{
			mLastError.Clear();
			ReportProblems(mLastError);
			if (mLastError.IsEmpty)
				mLastError.AppendF("class '{}' did not instantiate", scriptClass.ClassName);
		}
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
	public bool EnsureClassLoaded(BehaviorClass scriptClass)
	{
		if (EnsureRuntime(scriptClass.Language) == null)
			return false;

		LoadedClass replaced = null;
		for (let loaded in mLoaded)
		{
			if (loaded.ClassName != scriptClass.ClassName)
				continue;
			// A reloaded product carries its class under the same name: a changed source, or a
			// changed file it includes, loads again; the same one does not.
			if (loaded.Matches(scriptClass))
				return true;
			replaced = loaded;
			break;
		}

		mGeneration++;
		let moduleName = scope $"behavior:{scriptClass.ClassName}#{mGeneration}";
		// Its own source and the files it includes, each a section named by its path.
		let sections = scope List<ScriptSection>();
		sections.Add(.(scriptClass.SourceName, scriptClass.Source));
		for (let included in scriptClass.Includes)
			sections.Add(.(included.Path, included.Source));
		// A class built into its project's assembly loads the assembly, with its symbols so a fault
		// names its file and line; any other compiles its source.
		let assembly = scriptClass.Assembly;
		let loadedModule = (assembly != null)
			? mRuntime.LoadModuleImage(moduleName, sections, assembly.Image, assembly.Symbols)
			: mRuntime.CompileModule(moduleName, sections);
		if (!loadedModule)
		{
			GlobalLog(.Error, scope $"Script: class '{scriptClass.ClassName}' failed to load");
			mLastError.Clear();
			ReportProblems(mLastError);
			if (mLastError.IsEmpty)
				mLastError.AppendF("class '{}' failed to load", scriptClass.ClassName);
			return false;
		}
		if (replaced != null)
			mReplaced.Add(new String(replaced.ModuleName));
		let loaded = replaced ?? mLoaded.Add(.. new LoadedClass());
		loaded.Set(scriptClass);
		loaded.ModuleName.Set(moduleName);
		DiscardUnusedReplaced();
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
		ClearAndDeleteItems!(mReplaced);
		mWarnedLanguage = false;
		mLastError.Clear();
	}
}
