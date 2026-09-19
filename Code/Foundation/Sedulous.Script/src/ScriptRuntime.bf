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
	/// domains given. A host holding a wider surface than a script may use (the cook, with
	/// the pipeline's) binds the runtime subset for a game script.
	public virtual void Bind(ScriptSurface surface, Span<StringView> domains = default)
	{
		mSurface = surface;
		ClearAndDeleteItems!(mDomains);
		for (let d in domains)
			mDomains.Add(new String(d));
	}

	/// The domains bound, empty for all.
	protected List<String> mDomains = new .() ~ DeleteContainerAndItems!(_);

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
	/// a game instance say, is installed on that run's runtime alone, so one run's script
	/// never reaches another's.
	public void SetService<T>(T service) where T : class
	{
		if (Context != null)
			Context.SetService(typeof(T), service);
	}

	/// Compiles `source` into the module, replacing what it held. False on a compile error,
	/// with the messages in Problems.
	public bool Compile(StringView moduleName, StringView sectionName, StringView source)
		=> CompileModule(moduleName, scope ScriptSection[](.(sectionName, source)));

	/// Compiles the sections into one module, replacing what it held: every behaviour
	/// class of a run in one module, each keeping its own file identity for errors.
	public virtual bool CompileModule(StringView moduleName, Span<ScriptSection> sections) => false;

	/// Drops a module and everything compiled into it.
	public virtual void DiscardModule(StringView moduleName) {}

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
