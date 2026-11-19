using System;
using System.Collections;

namespace Sedulous.Script;

/// A script backend.
///
/// Thin by design: a backend is handed a surface and registers it, compiles source into
/// named modules, and calls into them. The null backend does only the first.
abstract class ScriptRuntime
{
	/// BORROWED for the runtime's life: the host owns the surface.
	protected ScriptSurface mSurface = null;

	public ScriptSurface Surface => mSurface;

	public abstract StringView Name { get; }

	/// Registers the surface's types with the backend: every one, or only those in the
	/// domains given, less the `hidden` ones (by full name). A host holding a wider surface
	/// than a script may use (the cook, with the pipeline's) binds the runtime subset for a
	/// game script; the surface of a platform without some plugins is the full one less their
	/// types, so a script checked against it fails where it uses one of them.
	public virtual void Bind(ScriptSurface surface, Span<StringView> domains = default, Span<StringView> hidden = default)
	{
		mSurface = surface;
		ClearAndDeleteItems!(mDomains);
		for (let d in domains)
			mDomains.Add(new String(d));
		ClearAndDeleteItems!(mHidden);
		for (let h in hidden)
			mHidden.Add(new String(h));
	}

	/// The domains bound, empty for all.
	protected List<String> mDomains = new .() ~ DeleteContainerAndItems!(_);
	/// The types left out by full name.
	protected List<String> mHidden = new .() ~ DeleteContainerAndItems!(_);

	/// Whether Bind registers `t`: in a bound domain and not hidden.
	protected bool IsBound(ScriptTypeInfo t)
	{
		for (let h in mHidden)
		{
			if (h == t.FullName)
				return false;
		}
		return InBoundDomains(t);
	}

	protected bool InBoundDomains(ScriptTypeInfo t)
	{
		if (mDomains.IsEmpty)
			return true;
		for (let d in mDomains)
		{
			if (d == t.Domain)
				return true;
		}
		return false;
	}

	/// What the bound calls reach: the scene, the services. Null for a backend with no calls.
	public virtual ScriptCallContext Context => null;

	/// Installs a Service role object, reached by its exact type: what a script's
	/// `Audio.Play(...)` or `Run.LoadSceneAsync(...)` resolves. BORROWED. A per run service,
	/// an application run say, is installed on that run's runtime alone, so one run's script
	/// never reaches another's.
	public void SetService<T>(T service) where T : class
	{
		if (Context != null)
			Context.SetService(typeof(T), service);
	}

	/// The budget every call into this runtime's script runs under, from the next call on.
	public ScriptBudget Budget = .();

	/// Compiles `source` into the module, replacing what it held, and runs its global
	/// initializers under the budget. False on a compile error or a failed initializer, with
	/// the messages in Problems. With `runInitializers` false nothing in the source runs, and
	/// its globals hold nothing: what a cook compiles with to read a class's members.
	public bool Compile(StringView moduleName, StringView sectionName, StringView source, bool runInitializers = true)
		=> CompileModule(moduleName, scope ScriptSection[](.(sectionName, source)), runInitializers);

	/// Compiles the sections into one module, replacing what it held: a class's source and the
	/// files it includes, each keeping its own file identity for errors and breakpoints. The
	/// global initializers run as Compile's do.
	public virtual bool CompileModule(StringView moduleName, Span<ScriptSection> sections, bool runInitializers = true) => false;

	/// Loads the module from a built image in place of compiling `sections`: the assembly a
	/// language that builds a project's classes together made of them, with its debug `symbols`
	/// (empty when there are none) so a fault names its file and line. `sections` are the class's
	/// own files, kept for the names its errors and breakpoints key on. False, with the reason in
	/// Problems, for a backend that only compiles source.
	public virtual bool LoadModuleImage(StringView moduleName, Span<ScriptSection> sections, Span<uint8> image, Span<uint8> symbols)
	{
		Problem(scope $"'{Name}' loads no built image; its classes compile from source");
		return false;
	}

	/// Drops a module and everything compiled into it.
	public virtual void DiscardModule(StringView moduleName) {}

	/// The bound API as the declarations file an external editor reads to complete and check
	/// scripts: its file name into `outFileName` (empty for a backend that writes none) and its
	/// text into `outText`. From what this runtime bound, so exactly what a script compiles against.
	public virtual void Declarations(String outFileName, String outText) {}

	/// Whether anything still runs code of the module: a call under way, an instance of one of
	/// its classes, a coroutine of it, a delegate to one of its functions. Discarding a module
	/// resets its globals, so one in use must stay. True when the runtime cannot tell.
	public virtual bool ModuleInUse(StringView moduleName) => true;

	/// Compiles `source` against the bound surface WITHOUT running any of it: no global
	/// initializer runs, and no module is kept. For checking code as it is typed, where a
	/// compile that ran it would run whatever is half written. `includes` are the files it
	/// includes, each a section named by its path (a language without an include directive
	/// ignores them). False on a compile error, with the messages in Problems.
	public virtual bool Check(StringView sectionName, StringView source, Span<ScriptSection> includes = default) => false;

	/// Calls a global function of a module by its declaration, `float f(int, int)` say.
	/// False when it is not there, or the call failed; the reason is in Problems.
	public virtual bool Call(StringView moduleName, StringView declaration, Span<ScriptValue> args, ref ScriptValue result) => false;

	// ---- script objects ----
	//
	// A behaviour is an instance of a script class: created from a module, driven through
	// its methods and properties by name, released when its entity goes. A method is
	// resolved by name and the arguments' kinds, so a script may overload a handler on its
	// payload's type; HasMethod answers without calling.

	/// Creates an instance of `className` from the module, null when the class is not
	/// there or its construction faulted (the reason in Problems).
	public virtual ScriptObject Instantiate(StringView moduleName, StringView className) => null;

	public virtual void Release(ScriptObject object) {}

	/// The public properties and methods of a compiled class, as the language reports
	/// them. What a cook harvests properties and handlers from. False when the class is
	/// not in the module.
	public virtual bool DescribeClass(StringView moduleName, StringView className, List<ScriptMemberDesc> outMembers) => false;

	/// Whether the object's class has a method of that name taking `arity` arguments.
	public virtual bool HasMethod(ScriptObject object, StringView name, int arity) => false;

	/// Calls the method matching the name and the arguments; false with the reason in
	/// Problems when there is none or the call faulted.
	public virtual bool Invoke(ScriptObject object, StringView name, Span<ScriptValue> args, ref ScriptValue result) => false;

	/// The object's property by name, in the kinds a frame carries. False when it has none.
	public virtual bool GetProperty(ScriptObject object, StringView name, ref ScriptValue value) => false;
	public virtual bool SetProperty(ScriptObject object, StringView name, ScriptValue value) => false;

	// ---- coroutines ----
	//
	// A script may start a coroutine (`startCoroutine(fn)`) that waits (`wait(seconds)`)
	// between steps. The host resumes the due ones ONCE per simulated frame at the tick's
	// top level, where no script call is active, and cancels an object's when it goes.

	// ---- introspection ----

	/// What this backend actually bound and how a script spells it: the source for an API
	/// browser or completion, which the surface listing is not, since a language spells a
	/// static as `Float3::Dot` or a property as `get_X`, and a backend may have refused a
	/// member. The caller owns what comes back.
	public virtual void DescribeBoundApi(List<ScriptApiType> outTypes) {}

	// ---- debugging ----

	/// Whether this backend debugs: CreateDebugger answers one.
	public virtual bool HasDebugger => false;

	/// The runtime's step debugger, made on request and owned by the caller; null for a
	/// backend without one. One at a time: it arms every call the runtime makes while it
	/// lives, and a call it suspended reports as paused, not failed, through IsDebugPaused.
	public virtual IScriptDebugger CreateDebugger() => null;

	/// A call the debugger suspended is being held: what a caller checks when a call
	/// answered false before treating it as a fault, and what a host gates its ticks on.
	public virtual bool IsDebugPaused => false;

	public virtual void AdvanceCoroutines(double deltaSeconds) {}
	public virtual void CancelCoroutinesFor(ScriptObject object) {}
	public virtual int CoroutineCount => 0;

	/// What went wrong, in order: registration, compile and runtime messages.
	public List<String> Problems = new .() ~ DeleteContainerAndItems!(_);

	protected void Problem(StringView text)
	{
		Problems.Add(new String(text));
	}
}
