using System;
using System.Collections;
using System.Diagnostics;
using AngelScript;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Script.AngelScript;

/// The AngelScript backend: binds a surface, compiles modules, calls into them.
///
/// Everything registers with the generic calling convention, and every call from a script
/// into the engine lands in one trampoline that finds the table entry behind the auxiliary
/// pointer, builds a ScriptCallFrame from the generic call's arguments, invokes the emitted
/// thunk and marshals the result back. How the surface maps onto the language:
///  - a struct is a POD value type of its Beef size; the inline kinds (Float3, Guid, Entity
///    and the rest) the same, so a script holds them by value and passes them `const &in`;
///  - a class is a reference type without a count (the engine owns its objects), held by
///    handle; an object a factory creates is kept by the runtime and freed with it;
///  - a counted class (IScriptCounted) is a counted reference type whose handle is the object
///    itself: each handle a script keeps is one reference, so the object lives while a script
///    or a native holder does, and a script-made one is freed by its last release; a handle
///    converts to its counted bases';
///  - an entity is a value carrying its handle AND its scene (its place in the process's weak
///    table), so a call on it resolves in that scene however many scenes there are, and does
///    nothing once the scene is gone; a component is a counted handle holding the
///    entity, null when the entity has none: `MeshComponent::of(entity).Visible`, and a use
///    through a handle whose component has gone since is the script's error; beside `of`,
///    `X::addTo(entity)` adds one when there is none and hands it back as `of` does, and
///    `X::removeFrom(entity)` takes it off, whether there was one;
///  - a weakly held class (IScriptWeaklyHeld) is a counted handle holding a ScriptWeakRef
///    (WeakHandle), resolved on every use: IsValid answers whether its object is still there,
///    any other use of a gone one is the script's error, `==` compares handles without
///    resolving, a handle converts to its bases' and `X::Of(node)` narrows it, null when the
///    node is no X or is gone;
///  - a scene system or component manager is a read only property on Scene named for it
///    (its display name, else its type name without the role suffix): `scene.Physics.RayCast(...)`;
///    the scene, and the instance the property answers, are weakly held, so a handle a script
///    keeps past its scene reads null or gone and its calls do nothing;
///  - a service is a handle in a global property named the same way, `Service` appended
///    when the name is taken: `AudioService.PlayMusic(...)`;
///  - static members and a namespace's free functions are global functions and virtual
///    properties, the statics inside a namespace named for the type;
///  - fields and properties are virtual properties (`get_X`/`set_X`);
///  - a method with defaults is registered once per arity, the thunk fills what is missing;
///  - enums are enums, Beef `int` is `int64`, StringView and String are `string`.
/// A member whose types the language cannot take (a list, a raw pointer) is skipped and
/// noted in Problems, as is a name AngelScript refuses.
class AngelScriptRuntime : ScriptRuntime
{
	/// What a script's component handle points at: the entity FIRST, so a member reads its
	/// self exactly as from an entity, then the count. Allocated by `of`, freed by the last
	/// release.
	[CRepr]
	private struct ComponentHandle
	{
		public ScriptEntity Entity;
		public int32 References;
	}

	/// What a script's weak handle points at: the reference FIRST, so a member reads its self
	/// exactly as from the box, then the count. Each box keeps one reference on the table, so
	/// a handle a script keeps never outlives what it resolves through. Allocated by
	/// NewWeakBox, freed by the last release.
	[CRepr]
	private struct WeakHandle
	{
		public ScriptWeakRef Ref;
		public int32 References;
	}

	/// A box for a weak value, its one reference the caller's.
	private static WeakHandle* NewWeakBox(ScriptWeakRef r)
	{
		let @box = (WeakHandle*)Internal.StdMalloc(sizeof(WeakHandle));
		@box.Ref = r;
		@box.References = 1;
		r.Table?.AddRef();
		return @box;
	}

	private static void ReleaseWeakBox(WeakHandle* @box)
	{
		if (--@box.References > 0)
			return;
		let table = @box.Ref.Table;
		Internal.StdFree(@box);
		table?.ReleaseRef();
	}

	private AS.Engine* mEngine = null;
	/// Execution contexts, one per call in flight: a script calling the engine calling a
	/// script needs a second, so they are pooled rather than one.
	private List<AS.Context*> mFreeContexts = new .() ~ delete _;
	private List<AS.Context*> mAllContexts = new .() ~ delete _;

	/// Script lines between reads of the budget's clock: one read a line would cost more than
	/// the lines.
	private const int32 cLinesPerCheck = 256;
	/// Nested script calls before one fails with "Stack overflow": recursion that never ends
	/// fails its call instead of growing the script's stacks until memory runs out.
	private const uint cMaxScriptCallDepth = 20000;
	/// One script call's data stack, the frames' locals, in bytes.
	private const uint cMaxScriptStackBytes = 1 << 20;
	/// Executes in flight from the engine: the outermost starts the budget's clock.
	private int32 mExecuteDepth = 0;
	/// Since the outermost Execute began.
	private Stopwatch mCallClock = new .() ~ delete _;
	private int32 mLinesSinceCheck = 0;

	/// One live coroutine: its own context, the seconds still to wait, and the object it
	/// is a method of, so that object's teardown cancels it.
	private class Coroutine
	{
		public AS.Context* Context;
		public AS.Function* Function;
		public double Remaining;
		public void* Owner;
		/// Its context is executing: a script it runs may cancel it, which must not free the
		/// context under it.
		public bool Running;
		/// Cancelled or finished: out of the schedule, never resumed again, freed once nothing
		/// runs it.
		public bool Dropped;
		/// Paused at a breakpoint or a step: the debugger has it until it runs it on.
		public bool Held;
		/// Its `wait` asked for the suspend, which AngelScript honours after the next line begins:
		/// no breakpoint or step may stop on that line.
		public bool Suspending;
	}
	private List<Coroutine> mCoroutines = new .() ~ DeleteContainerAndItems!(_);
	/// Coroutines dropped while one ran or the scheduler walked: freed once neither holds them.
	private List<Coroutine> mRetired = new .() ~ DeleteContainerAndItems!(_);
	/// AdvanceCoroutines is walking its snapshot, whose entries must outlive the walk.
	private bool mAdvancing = false;
	/// Objects handed out by Instantiate, released with the runtime if the host did not.
	private List<AngelScriptObject> mObjects = new .() ~ DeleteContainerAndItems!(_);
	private AngelScriptCallContext mCallContext = new .() ~ delete _;
	private List<AngelScriptBinding> mBindings = new .() ~ DeleteContainerAndItems!(_);
	/// Objects factories made for scripts, freed with the runtime. Never a counted one, which
	/// its last handle frees.
	private List<Object> mOwned = new .() ~ DeleteContainerAndItems!(_);
	/// The per role-type handle a global property points at: a non-null token, since the
	/// thunk resolves the real system from the context.
	private List<void**> mTokens = new .() ~ { for (let slot in _) delete slot; delete _; };
	/// The global handle names taken, so a later one is not refused.
	private HashSet<String> mHandleNames = new .() ~ DeleteContainerAndItems!(_);
	/// The properties on Scene taken, likewise.
	private HashSet<String> mSceneProperties = new .() ~ DeleteContainerAndItems!(_);
	/// The builder each module was compiled with, by module name: it holds the module's
	/// `[metadata]`, which DescribeClass reads. Freed with the module, and before the engine.
	private Dictionary<String, AS.Builder*> mBuilders = new .() ~ DeleteDictionaryAndKeys!(_);
	/// Surface types by their AngelScript name, for declarations.
	private Dictionary<String, ScriptTypeInfo> mByName = new .() ~ DeleteDictionaryAndKeys!(_);
	/// The callback shapes declared as funcdefs, by name: once per engine, which they outlive
	/// no binding of. Recorded in the API once per binding.
	private HashSet<String> mDeclaredShapes = new .() ~ DeleteContainerAndItems!(_);
	private HashSet<String> mRecordedShapes = new .() ~ DeleteContainerAndItems!(_);

	public override StringView Name => "AngelScript";
	public override ScriptCallContext Context => mCallContext;
	public AngelScriptCallContext CallContext => mCallContext;

	/// Guards the one asPrepareMultithread call.
	private static System.Threading.Monitor sPrepareLock = new .() ~ delete _;
	private static bool sPrepared = false;

	/// AngelScript's thread manager, prepared ONCE for the process and never released. Without
	/// it the manager is created by the first engine and deleted with the last, a transition
	/// AngelScript does not guard against a second thread: a cook's workers create and release
	/// engines concurrently while the main thread holds none, and one of them can find the
	/// manager gone mid execution.
	private static void PrepareThreads()
	{
		using (sPrepareLock.Enter())
		{
			if (sPrepared)
				return;
			AS.asPrepareMultithread(null);
			sPrepared = true;
		}
	}

	/// Frees this thread's AngelScript local data: a worker's, once it is done with the library,
	/// while engines made on it live on.
	public static void ThreadCleanup() => AS.asThreadCleanup();

	public this()
	{
		PrepareThreads();
		mEngine = AS.asc_engine_create();
		AS.asc_engine_set_message_callback(mEngine, => OnMessage, Internal.UnsafeCastToPtr(this));
		AS.asc_engine_set_generic_callback(mEngine, => OnGeneric, Internal.UnsafeCastToPtr(this));
		// Value types by non-const reference, for `&out` and `&inout` on them.
		AS.asc_engine_set_property(mEngine, AS.asEP_ALLOW_UNSAFE_REFERENCES, 1);
		// A handle argument, an array or a funcdef, is the ENGINE's to release after the
		// call: the trampoline only reads an array, and a delegate or coroutine takes a
		// reference of its own. In the default mode the reference passes to the callee
		// unless the parameter is declared `@+`, which would show in every signature.
		AS.asc_engine_set_property(mEngine, AS.asEP_GENERIC_CALL_MODE, 0);
		// Global initializers run on a context the budget covers (InitGlobals), not inside the
		// build, where nothing stops one that never ends; so a build that is not a game's load
		// (a cook's, a check's) compiles without running script.
		AS.asc_engine_set_property(mEngine, AS.asEP_INIT_GLOBAL_VARS_AFTER_BUILD, 0);
		AS.asc_engine_set_property(mEngine, AS.asEP_MAX_CALL_STACK_SIZE, cMaxScriptCallDepth);
		AS.asc_engine_set_property(mEngine, AS.asEP_MAX_STACK_SIZE, cMaxScriptStackBytes);
		AS.asc_engine_register_std_string(mEngine);
		AS.asc_engine_register_script_array(mEngine, 1);
		DeclareInlineKinds();
		DeclareCoroutines();
	}

	private AS.Context* AcquireContext()
	{
		if (!mFreeContexts.IsEmpty)
			return mFreeContexts.PopBack();
		let ctx = AS.asc_engine_create_context(mEngine);
		mAllContexts.Add(ctx);
		return ctx;
	}

	private void ReleaseContext(AS.Context* ctx)
	{
		AS.asc_context_unprepare(ctx);
		mFreeContexts.Add(ctx);
	}

	// ---- the budget ----

	/// One Execute from the engine begins: the outermost starts the budget's clock; a call into
	/// script from inside one (a callback a bound call runs) runs on the outer call's clock.
	/// Paired with EndExecute.
	private void BeginExecute()
	{
		if (mExecuteDepth == 0)
		{
			mCallClock.Restart();
			mLinesSinceCheck = 0;
		}
		mExecuteDepth++;
	}

	private void EndExecute()
	{
		mExecuteDepth--;
	}

	/// Puts the budget's line callback on `ctx`. A debugger arms its own instead, which checks
	/// the budget too.
	private void ArmBudget(AS.Context* ctx)
	{
		AS.asc_context_set_line_callback(ctx, => OnBudgetLine, Internal.UnsafeCastToPtr(this));
	}

	private static void OnBudgetLine(AS.Context* ctx, void* user)
	{
		let self = Internal.UnsafeCastToObject(user) as AngelScriptRuntime;
		self.StopIfOverBudget(ctx);
	}

	/// Aborts `ctx` when the running call has used its seconds; true then. The clock is read
	/// every cLinesPerCheck lines.
	private bool StopIfOverBudget(AS.Context* ctx)
	{
		if (mExecuteDepth == 0)
			return false;
		mLinesSinceCheck++;
		if (mLinesSinceCheck < cLinesPerCheck)
			return false;
		mLinesSinceCheck = 0;
		if (mCallClock.Elapsed.TotalSeconds <= Budget.CallSeconds)
			return false;
		AS.asc_context_abort(ctx);
		return true;
	}

	/// Runs `module`'s global initializers on a context the budget covers. False when one
	/// faulted or ran past the budget, the reason in Problems.
	private bool InitGlobals(AS.Module* module)
	{
		let ctx = AcquireContext();
		defer ReleaseContext(ctx);
		ArmBudget(ctx);
		defer AS.asc_context_clear_line_callback(ctx);
		BeginExecute();
		let result = AS.asc_module_reset_global_vars(module, ctx);
		EndExecute();
		if (result >= 0)
			return true;
		// A faulting initializer's exception the engine has said already, through the message
		// callback; a budget stop it does not say.
		if (AS.asc_context_get_state(ctx) == AS.asEXECUTION_ABORTED)
			ReportExecution(ctx, AS.asEXECUTION_ABORTED, "a global variable's initializer");
		return false;
	}

	/// `startCoroutine(fn)` and `wait(seconds)`: the scheduler's surface. A coroutine is any
	/// `void f()`, a delegate to an object's method included.
	private void DeclareCoroutines()
	{
		AS.asc_engine_register_funcdef(mEngine, "void ScriptCoroutine()");
		// The callback a native API takes: `button.OnClick(ScriptCallback(this.onRetry))`.
		AS.asc_engine_register_funcdef(mEngine, "void ScriptCallback()");
		let start = new AngelScriptBinding();
		start.Kind = .StartCoroutine;
		mBindings.Add(start);
		AS.asc_engine_register_global_function(mEngine, "void startCoroutine(ScriptCoroutine@ fn)", Internal.UnsafeCastToPtr(start));
		let wait = new AngelScriptBinding();
		wait.Kind = .Wait;
		mBindings.Add(wait);
		AS.asc_engine_register_global_function(mEngine, "void wait(float seconds)", Internal.UnsafeCastToPtr(wait));
		// `yield()`: the next advance resumes it, which is what a boot loop polling a load
		// wants: `while (!Run.LoadComplete(t)) yield();`.
		let yielding = new AngelScriptBinding();
		yielding.Kind = .Yield;
		mBindings.Add(yielding);
		AS.asc_engine_register_global_function(mEngine, "void yield()", Internal.UnsafeCastToPtr(yielding));
	}

	/// The inline value kinds exist in the language whatever the surface declares, since
	/// a frame carries them by value. A surface type of the same name maps onto the one
	/// declared here and adds its members.
	private void DeclareInlineKinds()
	{
		let pod = AS.asOBJ_VALUE | AS.asOBJ_POD | AS.asOBJ_APP_CLASS;
		AS.asc_engine_register_object_type(mEngine, "Guid", sizeof(Guid), pod | AS.asOBJ_APP_CLASS_ALIGN8);
		// An entity carries its scene: what makes a component or a scene call resolve in the
		// right scene however many there are.
		AS.asc_engine_register_object_type(mEngine, "Entity", sizeof(ScriptEntity), pod | AS.asOBJ_APP_CLASS_ALIGN8);
		AS.asc_engine_register_object_type(mEngine, "Float2", sizeof(Float2), pod | AS.asOBJ_APP_CLASS_ALLFLOATS);
		AS.asc_engine_register_object_type(mEngine, "Float3", sizeof(Float3), pod | AS.asOBJ_APP_CLASS_ALLFLOATS);
		AS.asc_engine_register_object_type(mEngine, "Float4", sizeof(Float4), pod | AS.asOBJ_APP_CLASS_ALLFLOATS);
		AS.asc_engine_register_object_type(mEngine, "Quaternion", sizeof(Quaternion), pod | AS.asOBJ_APP_CLASS_ALLFLOATS);
		AS.asc_engine_register_object_type(mEngine, "Color", sizeof(Color), pod | AS.asOBJ_APP_CLASS_ALLFLOATS);
		DeclareOperators();
	}

	/// BORROWED: the debugger in force, which self registers and detaches.
	private AngelScriptDebugger mDebugger = null;

	/// BORROWED: the delegates handed to native code and still held there, told when the
	/// runtime goes so they answer dead rather than call into freed memory.
	private List<AngelScriptDelegate> mDelegates = new .() ~ delete _;
	private void RegisterDelegate(AngelScriptDelegate d) => mDelegates.Add(d);
	private void UnregisterDelegate(AngelScriptDelegate d) => mDelegates.Remove(d);

	/// Everything the bind registered, as it was spelled: the bound API.
	private List<ScriptApiType> mApi = new .() ~ DeleteContainerAndItems!(_);

	public override void DescribeBoundApi(List<ScriptApiType> outTypes)
	{
		for (let t in mApi)
		{
			let copy = new ScriptApiType();
			copy.ScriptName.Set(t.ScriptName);
			copy.TypeFullName.Set(t.TypeFullName);
			copy.IsNamespace = t.IsNamespace;
			for (let m in t.Members)
			{
				let member = new ScriptApiMember();
				member.Name.Set(m.Name);
				member.Signature.Set(m.Signature);
				member.IsStatic = m.IsStatic;
				member.Kind = m.Kind;
				member.ReadOnly = m.ReadOnly;
				copy.Members.Add(member);
			}
			outTypes.Add(copy);
		}
	}

	/// The API entry for a script name, made on first use. The global namespace is "".
	private ScriptApiType ApiType(StringView scriptName, StringView fullName, bool isNamespace)
	{
		for (let t in mApi)
		{
			if (t.ScriptName == scriptName)
				return t;
		}
		let t = new ScriptApiType();
		t.ScriptName.Set(scriptName);
		t.TypeFullName.Set(fullName);
		t.IsNamespace = isNamespace;
		mApi.Add(t);
		return t;
	}

	private void Record(ScriptApiType type, StringView name, StringView signature, bool isStatic, ScriptApiMemberKind kind, bool readOnly = false)
	{
		let m = new ScriptApiMember();
		m.Name.Set(name);
		m.Signature.Set(signature);
		m.IsStatic = isStatic;
		m.Kind = kind;
		m.ReadOnly = readOnly;
		type.Members.Add(m);
	}

	private ScriptApiType GlobalApi => ApiType("", "", true);

	/// The handle a service's instance members are reached through, `Run.LoadScene`, else
	/// the type's own name.
	private Dictionary<ScriptTypeInfo, String> mHandleOf = new .() ~ DeleteDictionaryAndValues!(_);
	private StringView ReachedAs(ScriptTypeInfo t)
	{
		if (mHandleOf.TryGetValue(t, let handle))
			return handle;
		return AsName(t);
	}

	public ~this()
	{
		if (mDebugger != null)
			mDebugger.RuntimeGone();
		for (let d in mDelegates)
			d.RuntimeGone();
		for (let co in mCoroutines)
			ReleaseCoroutineContext(co);
		for (let co in mRetired)
			ReleaseCoroutineContext(co);
		// The objects before the engine that owns their memory.
		ClearAndDeleteItems!(mObjects);
		for (let ctx in mAllContexts)
			AS.asc_context_release(ctx);
		for (let entry in mBuilders)
			AS.asc_builder_destroy(entry.value);
		// This thread's AngelScript local data, freed while the thread manager still exists:
		// the library frees it on its own only for the thread that releases the LAST engine, so
		// a cook worker whose runtime dies while the main thread's live would leak it on exit.
		AS.asThreadCleanup();
		AS.asc_engine_release(mEngine);
	}

	private static void OnMessage(char8* section, int32 row, int32 col, int32 type, char8* message, void* user)
	{
		// The compiler's notes ("Compiling void X::f()") stay quiet; its warnings and errors are
		// reported, a warning as one (ScriptProblems.IsWarning).
		if (type == AS.asMSGTYPE_INFORMATION)
			return;
		let self = Internal.UnsafeCastToObject(user) as AngelScriptRuntime;
		let kind = (type == AS.asMSGTYPE_ERROR) ? "error" : "warning";
		self.Problem(scope $"{StringView(section)}({row},{col}): {kind}: {StringView(message)}");
	}

	// ==================== binding ====================

	public override void Bind(ScriptSurface surface, Span<StringView> domains = default, Span<StringView> hidden = default)
	{
		base.Bind(surface, domains, hidden);
		ClearAndDeleteItems!(mApi);
		ClearAndDeleteItems!(mRecordedShapes);
		DeleteDictionaryAndValues!(mHandleOf);
		mHandleOf = new .();
		// The language's own globals, bound before any surface.
		Record(GlobalApi, "startCoroutine", "void startCoroutine(ScriptCoroutine@ fn)", true, .Method);
		Record(GlobalApi, "wait", "void wait(float seconds)", true, .Method);
		Record(GlobalApi, "yield", "void yield()", true, .Method);
		Record(GlobalApi, "ScriptCallback", "funcdef void ScriptCallback()", true, .Constant);
		RecordOperators(surface);

		// Declare every type before any member, since a member's declaration names types.
		for (let t in surface.Types)
		{
			if (IsBound(t))
				DeclareType(t);
		}
		for (let t in surface.Types)
		{
			if (IsBound(t))
				BindMembers(t);
		}
	}

	/// The AngelScript name of a surface type: its bare name, except the entity handle,
	/// which is `Entity` to a script.
	private static StringView AsName(ScriptTypeInfo t)
		=> (t.FullName == ScriptSceneNames.cEntityHandle) ? "Entity" : t.Name;

	private void DeclareType(ScriptTypeInfo t)
	{
		switch (t.Kind)
		{
		case .Global:
			return;
		case .Enum:
			if (Check(AS.asc_engine_register_enum(mEngine, scope String(AsName(t)).CStr()), t.FullName))
			{
				let api = ApiType(AsName(t), t.FullName, false);
				for (let v in t.EnumValues)
				{
					if (Check(AS.asc_engine_register_enum_value(mEngine, scope String(AsName(t)).CStr(), scope String(v.Name).CStr(), (int32)v.Value), t.FullName))
						Record(api, v.Name, scope $"{AsName(t)}::{v.Name} = {v.Value}", true, .Constant);
				}
				mByName[new String(AsName(t))] = t;
			}
		case .Struct:
			// Already in the language: one of the inline kinds declared up front.
			if (AS.asc_engine_get_type_info_by_name(mEngine, scope String(AsName(t)).CStr()) != null)
			{
				mByName[new String(AsName(t))] = t;
				ApiType(AsName(t), t.FullName, false);
				return;
			}
			// A component is a counted handle holding its entity (ComponentHandle), so `of`
			// can answer null; any other struct is a value of its own bytes.
			if (t.Role == .Component)
			{
				if (Check(AS.asc_engine_register_object_type(mEngine, scope String(AsName(t)).CStr(), 0, AS.asOBJ_REF), t.FullName))
				{
					mByName[new String(AsName(t))] = t;
					ApiType(AsName(t), t.FullName, false);
				}
				return;
			}
			let size = t.Size;
			let flags = AS.asOBJ_VALUE | AS.asOBJ_POD | AS.asOBJ_APP_CLASS | ((t.Align >= 8) ? AS.asOBJ_APP_CLASS_ALIGN8 : 0);
			if (Check(AS.asc_engine_register_object_type(mEngine, scope String(AsName(t)).CStr(), size, flags), t.FullName))
			{
				mByName[new String(AsName(t))] = t;
				ApiType(AsName(t), t.FullName, false);
			}
		case .Class:
			// A weakly held class, a scene's system or facade among them, is a counted handle of
			// the backend's own (WeakHandle), a counted class the object itself, counted; any
			// other is the engine's object itself, uncounted.
			let classFlags = ((t.Role == .Weak) || (t.Role == .Counted) || IsSceneBound(t)) ? AS.asOBJ_REF : (AS.asOBJ_REF | AS.asOBJ_NOCOUNT);
			if (Check(AS.asc_engine_register_object_type(mEngine, scope String(AsName(t)).CStr(), 0, classFlags), t.FullName))
			{
				mByName[new String(AsName(t))] = t;
				ApiType(AsName(t), t.FullName, false);
			}
		}
	}

	private void BindMembers(ScriptTypeInfo t)
	{
		if ((t.Kind == .Enum) || ((t.Kind != .Global) && !mByName.ContainsKey(scope String(AsName(t)))))
			return;

		// A service is reached through a global handle; a scene system or manager through
		// the scene that owns it, `scene.Physics`, a weak handle of its own.
		if (t.Role == .Service)
			DeclareRoleHandle(t);
		else if (IsSceneBound(t))
		{
			BindSceneBoundHandle(t);
			DeclareSceneProperty(t);
		}

		// A component is reached from the entity it lives on: `X::of(entity)`, a counted
		// handle, null when the entity has none; `X::addTo` and `X::removeFrom` beside it.
		if (t.Role == .Component)
			BindComponentHandle(t);
		// A weakly held class is a handle that resolves on every use: its count, IsValid,
		// `==`, its bases' conversions and `X::Of(node)`.
		if (t.Role == .Weak)
			BindWeakHandle(t);
		// A counted class: its count, and its counted bases' conversions.
		if (t.Role == .Counted)
			BindCountedHandle(t);

		let statics = scope String();
		if (t.Kind != .Global)
			statics.Set(AsName(t));

		for (let f in t.Fields)
		{
			if (f.Get == null)
				continue;
			BindField(t, f, statics);
		}
		for (let m in t.Methods)
		{
			if (!m.IsCallable)
				continue;
			BindMethod(t, m, statics);
			if (m.OnEntity)
				BindEntityMethod(t, m);
		}
		if (t.Kind == .Class)
			BindInherited(t, statics);
	}

	/// A class's handle reaches its bases' instance members too, derived first so an override
	/// (any member of the same name) wins; statics stay on the type that declares them. The
	/// base's own thunks serve, since a derived object is one of its bases.
	private void BindInherited(ScriptTypeInfo t, StringView statics)
	{
		if (t.BeefType == null)
			return;
		let taken = scope HashSet<String>();
		defer { for (let n in taken) delete n; }
		void Take(StringView name)
		{
			if (!taken.ContainsAlt(name))
				taken.Add(new String(name));
		}
		for (let f in t.Fields)
			Take(f.ScriptName);
		for (let m in t.Methods)
			Take(m.ScriptName);

		var baseType = t.BeefType.BaseType;
		while (baseType != null)
		{
			let based = SurfaceTypeOf(baseType);
			if (based != null)
			{
				for (let f in based.Fields)
				{
					if ((f.Get == null) || f.IsStatic || taken.ContainsAlt(f.ScriptName))
						continue;
					BindField(based, f, statics, t);
				}
				for (let m in based.Methods)
				{
					if (!m.IsCallable || m.IsStatic || m.IsConstructor || taken.ContainsAlt(m.ScriptName))
						continue;
					BindMethod(based, m, statics, t);
				}
				// A member a nearer base declared hides one further up.
				for (let f in based.Fields)
					Take(f.ScriptName);
				for (let m in based.Methods)
					Take(m.ScriptName);
			}
			baseType = baseType.BaseType;
		}
	}

	/// The bound surface type for a Beef type, or null when it is not on the surface.
	private ScriptTypeInfo SurfaceTypeOf(Type type)
	{
		for (let t in mByName.Values)
		{
			if (t.BeefType == type)
				return t;
		}
		return null;
	}

	/// A component's handle: its reference count, `X::of(entity)`, and beside it
	/// `X::addTo(entity)` and `X::removeFrom(entity)`.
	private void BindComponentHandle(ScriptTypeInfo t)
	{
		let typeName = scope String(AsName(t));
		for (let kind in AngelScriptBinding.Role[2](.ComponentAddRef, .ComponentRelease))
		{
			let b = new AngelScriptBinding();
			b.Kind = kind;
			b.Owner = t;
			mBindings.Add(b);
			let behaviour = (kind == .ComponentAddRef) ? AS.asBEHAVE_ADDREF : AS.asBEHAVE_RELEASE;
			Check(AS.asc_engine_register_object_behaviour(mEngine, typeName.CStr(), behaviour, "void f()", Internal.UnsafeCastToPtr(b)), t.FullName);
		}
		if (t.IsOn == null)
		{
			Problem(scope $"{t.FullName}: a component with no manager to find it by, so no {typeName}::of");
			return;
		}
		// Every handle answers IsValid, unless the type reflects its own: whether its entity still
		// has the component. Any other use of a gone handle is the script's error.
		if (!DeclaresMember(t, "IsValid"))
		{
			let valid = new AngelScriptBinding();
			valid.Kind = .ComponentIsValid;
			valid.Owner = t;
			mBindings.Add(valid);
			if (Check(AS.asc_engine_register_object_method(mEngine, typeName.CStr(), "bool get_IsValid() property", Internal.UnsafeCastToPtr(valid)), t.FullName))
				Record(ApiType(typeName, t.FullName, false), "IsValid", scope $"bool {typeName}.IsValid", false, .Property, true);
		}
		// The statics in the namespace named for the type: of, and addTo and removeFrom when the
		// surface gave them.
		AS.asc_engine_set_default_namespace(mEngine, typeName.CStr());
		BindComponentStatic(t, .ComponentOf, "of", scope $"{typeName}@", typeName);
		if (t.AddTo != null)
			BindComponentStatic(t, .ComponentAddTo, "addTo", scope $"{typeName}@", typeName);
		if (t.RemoveFrom != null)
			BindComponentStatic(t, .ComponentRemoveFrom, "removeFrom", "bool", typeName);
		AS.asc_engine_set_default_namespace(mEngine, "");
	}

	/// One of a component's statics, `{returns} {name}(const Entity &in entity)`, registered in
	/// the namespace already set and recorded as `{returns} {typeName}::{name}(...)`.
	private void BindComponentStatic(ScriptTypeInfo t, AngelScriptBinding.Role kind, StringView name, StringView returns,
		StringView typeName)
	{
		let b = new AngelScriptBinding();
		b.Kind = kind;
		b.Owner = t;
		mBindings.Add(b);
		let rc = AS.asc_engine_register_global_function(mEngine, scope $"{returns} {name}(const Entity &in entity)", Internal.UnsafeCastToPtr(b));
		if (Check(rc, scope $"{t.FullName}::{name}"))
			Record(ApiType(typeName, t.FullName, false), name, scope $"{returns} {typeName}::{name}(const Entity &in entity)", true, .Method);
	}

	/// A weak handle's count, `IsValid`, `==`, a conversion to each weakly held base and
	/// `X::Of(node)`, which narrows a handle of the family's root to X.
	private void BindWeakHandle(ScriptTypeInfo t)
	{
		let typeName = scope String(AsName(t));
		let api = ApiType(typeName, t.FullName, false);
		for (let kind in AngelScriptBinding.Role[2](.WeakAddRef, .WeakRelease))
		{
			let b = new AngelScriptBinding();
			b.Kind = kind;
			b.Owner = t;
			mBindings.Add(b);
			let behaviour = (kind == .WeakAddRef) ? AS.asBEHAVE_ADDREF : AS.asBEHAVE_RELEASE;
			Check(AS.asc_engine_register_object_behaviour(mEngine, typeName.CStr(), behaviour, "void f()", Internal.UnsafeCastToPtr(b)), t.FullName);
		}

		// Every handle answers IsValid, unless the type reflects its own: whether its object is
		// still there. Any other use of a gone handle is the script's error.
		if (!DeclaresMember(t, "IsValid"))
		{
			let valid = new AngelScriptBinding();
			valid.Kind = .WeakIsValid;
			valid.Owner = t;
			mBindings.Add(valid);
			if (Check(AS.asc_engine_register_object_method(mEngine, typeName.CStr(), "bool get_IsValid() property", Internal.UnsafeCastToPtr(valid)), t.FullName))
				Record(api, "IsValid", scope $"bool {typeName}.IsValid (read only)", false, .Property, true);
		}

		let root = (!t.WeakRootTypeName.IsEmpty) ? mSurface.Find(t.WeakRootTypeName) : null;
		let rootName = scope String(AsName(root ?? t));
		if (!mByName.ContainsKey(rootName))
			rootName.Set(typeName);

		// `a == b`: the same handle, never resolving, so it answers for a gone one too.
		let equals = new AngelScriptBinding();
		equals.Kind = .WeakEquals;
		equals.Owner = t;
		mBindings.Add(equals);
		let equalsDecl = scope $"bool opEquals(const {rootName}@ other) const";
		if (Check(AS.asc_engine_register_object_method(mEngine, typeName.CStr(), equalsDecl.CStr(), Internal.UnsafeCastToPtr(equals)), scope $"{t.FullName}.opEquals"))
			Record(api, "opEquals", scope $"bool {typeName}.opEquals(const {rootName}@ other) const", false, .Method);

		// A handle converts to a handle of each weakly held base: the same box. A base that is
		// not weakly held is an uncounted handle of another shape, so it gets no conversion.
		var baseType = (t.BeefType != null) ? t.BeefType.BaseType : null;
		while (baseType != null)
		{
			let based = SurfaceTypeOf(baseType);
			if ((based != null) && (based.Role == .Weak))
			{
				let baseName = scope String(AsName(based));
				for (int constant < 2)
				{
					let up = new AngelScriptBinding();
					up.Kind = .WeakUpcast;
					up.Owner = t;
					mBindings.Add(up);
					let decl = scope String();
					let spelled = scope String();
					if (constant == 0)
					{
						decl.AppendF("{}@ opImplCast()", baseName);
						spelled.AppendF("{}@ {}.opImplCast()", baseName, typeName);
					}
					else
					{
						decl.AppendF("const {}@ opImplCast() const", baseName);
						spelled.AppendF("const {}@ {}.opImplCast() const", baseName, typeName);
					}
					if (Check(AS.asc_engine_register_object_method(mEngine, typeName.CStr(), decl.CStr(), Internal.UnsafeCastToPtr(up)), scope $"{t.FullName} to {based.FullName}"))
						Record(api, "opImplCast", spelled, false, .Method);
				}
			}
			baseType = baseType.BaseType;
		}

		if (t.Cast == null)
		{
			Problem(scope $"{t.FullName}: a weakly held type with no cast, so no {typeName}::Of");
			return;
		}
		let of = new AngelScriptBinding();
		of.Kind = .WeakOf;
		of.Owner = t;
		mBindings.Add(of);
		AS.asc_engine_set_default_namespace(mEngine, typeName.CStr());
		let rc = AS.asc_engine_register_global_function(mEngine, scope $"{typeName}@ Of({rootName}@ node)", Internal.UnsafeCastToPtr(of));
		AS.asc_engine_set_default_namespace(mEngine, "");
		if (Check(rc, scope $"{t.FullName}::Of"))
			Record(api, "Of", scope $"{typeName}@ {typeName}::Of({rootName}@ node)", true, .Method);
	}

	/// A counted handle's count, IScriptCounted's own, and a conversion to each counted base:
	/// the same object, one more reference.
	private void BindCountedHandle(ScriptTypeInfo t)
	{
		let typeName = scope String(AsName(t));
		let api = ApiType(typeName, t.FullName, false);
		for (let kind in AngelScriptBinding.Role[2](.CountedAddRef, .CountedRelease))
		{
			let b = new AngelScriptBinding();
			b.Kind = kind;
			b.Owner = t;
			mBindings.Add(b);
			let behaviour = (kind == .CountedAddRef) ? AS.asBEHAVE_ADDREF : AS.asBEHAVE_RELEASE;
			Check(AS.asc_engine_register_object_behaviour(mEngine, typeName.CStr(), behaviour, "void f()", Internal.UnsafeCastToPtr(b)), t.FullName);
		}

		// A base that is not counted is an uncounted handle, which would drop the count on the
		// floor, so it gets no conversion.
		var baseType = (t.BeefType != null) ? t.BeefType.BaseType : null;
		while (baseType != null)
		{
			let based = SurfaceTypeOf(baseType);
			if ((based != null) && (based.Role == .Counted))
			{
				let baseName = scope String(AsName(based));
				for (int constant < 2)
				{
					let up = new AngelScriptBinding();
					up.Kind = .CountedUpcast;
					up.Owner = t;
					mBindings.Add(up);
					let decl = scope String();
					let spelled = scope String();
					if (constant == 0)
					{
						decl.AppendF("{}@ opImplCast()", baseName);
						spelled.AppendF("{}@ {}.opImplCast()", baseName, typeName);
					}
					else
					{
						decl.AppendF("const {}@ opImplCast() const", baseName);
						spelled.AppendF("const {}@ {}.opImplCast() const", baseName, typeName);
					}
					if (Check(AS.asc_engine_register_object_method(mEngine, typeName.CStr(), decl.CStr(), Internal.UnsafeCastToPtr(up)), scope $"{t.FullName} to {based.FullName}"))
						Record(api, "opImplCast", spelled, false, .Method);
				}
			}
			baseType = baseType.BaseType;
		}
	}

	/// Whether a class is one of a scene's own, a system, manager or facade: held weakly, in the
	/// same box a weakly held class's handle is, and reached from its scene.
	private static bool IsSceneBound(ScriptTypeInfo t)
		=> (t.Kind == .Class) && ((t.Role == .SceneSystem) || (t.Role == .ComponentManager) || (t.Role == .SceneFacade));

	/// A scene's system, manager or facade handle's count: its box's, as a weak handle's.
	private void BindSceneBoundHandle(ScriptTypeInfo t)
	{
		let typeName = scope String(AsName(t));
		for (let kind in AngelScriptBinding.Role[2](.WeakAddRef, .WeakRelease))
		{
			let b = new AngelScriptBinding();
			b.Kind = kind;
			b.Owner = t;
			mBindings.Add(b);
			let behaviour = (kind == .WeakAddRef) ? AS.asBEHAVE_ADDREF : AS.asBEHAVE_RELEASE;
			Check(AS.asc_engine_register_object_behaviour(mEngine, typeName.CStr(), behaviour, "void f()", Internal.UnsafeCastToPtr(b)), t.FullName);
		}
	}

	/// The counted object behind a handle's pointer: a Beef object, cast to its counting.
	private static IScriptCounted CountedAt(void* object) => Internal.UnsafeCastToObject(object) as IScriptCounted;

	/// The pointer a counted handle holds: the object itself.
	private static void* PointerOf(IScriptCounted counted) => (counted != null) ? Internal.UnsafeCastToPtr((Object)counted) : null;

	/// Whether a type reflects a field or a method of this name.
	private static bool DeclaresMember(ScriptTypeInfo t, StringView name)
	{
		for (let f in t.Fields)
		{
			if (f.Name == name)
				return true;
		}
		for (let m in t.Methods)
		{
			if (m.Name == name)
				return true;
		}
		return false;
	}

	/// The entity side of an entity-first method, on the Entity value: the parameters after
	/// the entity, one registration per arity, as the type side.
	private void BindEntityMethod(ScriptTypeInfo t, ScriptMethodInfo m)
	{
		let returnDecl = scope String();
		if (!DeclOf(m.ReturnKind, m.ReturnTypeName, returnDecl))
			return; // the type side reported it
		let paramDecls = scope List<String>();
		defer { ClearAndDeleteItems(paramDecls); }
		for (let p in m.EntityParams)
		{
			let d = new String();
			if (!ParamDecl(p, d))
			{
				delete d;
				return;
			}
			d.AppendF(" {}", p.Name);
			paramDecls.Add(d);
		}
		// The trampoline carries cMaxArgs arguments: an arity past them is not bound, so its use
		// does not compile, rather than called with its last arguments dropped.
		if (paramDecls.Count > cMaxArgs)
			Problem(scope $"{t.FullName}.{m.EntityName}: a call carries at most {cMaxArgs} arguments; past them it is not bound");
		for (int arity = m.RequiredEntityParams; arity <= Math.Min(paramDecls.Count, cMaxArgs); arity++)
		{
			let b = new AngelScriptBinding();
			b.Kind = .EntityCall;
			b.Owner = t;
			b.Method = m;
			b.Arity = arity;
			mBindings.Add(b);
			let decl = scope String();
			decl.AppendF("{} {}(", returnDecl, m.EntityName);
			for (int i = 0; i < arity; i++)
			{
				if (i > 0)
					decl.Append(", ");
				decl.Append(paramDecls[i]);
			}
			// Const: the entity value is only read, so a `const Entity &in` may call it.
			decl.Append(") const");
			if (Check(AS.asc_engine_register_object_method(mEngine, "Entity", decl.CStr(), Internal.UnsafeCastToPtr(b)), scope $"{t.FullName}.{m.Name} on Entity as {decl}"))
				Record(ApiType("Entity", ScriptSceneNames.cEntityHandle, false), m.EntityName, decl, false, .Method);
		}
	}

	/// The short name a script reaches a role type by: its display name, else its type
	/// name without the role suffix.
	private static void ShortName(ScriptTypeInfo t, String outName)
	{
		if (!t.DisplayName.IsEmpty)
		{
			outName.Set(t.DisplayName);
			outName.Replace(" ", "");
			return;
		}
		outName.Set(AsName(t));
		for (let suffix in scope String[]("SceneSystem", "ComponentManager", "Subsystem", "System", "Manager", "Facade"))
		{
			if (outName.EndsWith(suffix) && (outName.Length > suffix.Length))
			{
				outName.RemoveFromEnd(suffix.Length);
				return;
			}
		}
	}

	/// `scene.Physics`: a read only property on Scene answering the scene's instance, as a weak
	/// handle of its own, through the type's resolver. Needs Scene on the surface.
	private void DeclareSceneProperty(ScriptTypeInfo t)
	{
		if ((t.FromScene == null) || !mByName.ContainsKey(scope String("Scene")))
			return;
		let name = ShortName(t, .. scope .());
		if (mSceneProperties.Contains(name))
			name.Append("System");
		let b = new AngelScriptBinding();
		b.Kind = .Resolve;
		b.Owner = t;
		mBindings.Add(b);
		if (Check(AS.asc_engine_register_object_method(mEngine, "Scene", scope $"{AsName(t)}@ get_{name}() property".CStr(), Internal.UnsafeCastToPtr(b)), t.FullName))
		{
			mSceneProperties.Add(new String(name));
			Record(ApiType("Scene", ScriptSceneNames.cScene, false), name, scope $"{AsName(t)}@ Scene.{name}", false, .Property);
		}
	}

	private void DeclareRoleHandle(ScriptTypeInfo t)
	{
		let name = ShortName(t, .. scope .());
		// The property is a handle variable: it holds the token's address.
		let slot = new void*[1]*;
		let token = Internal.UnsafeCastToPtr(t);
		slot[0] = token;
		mTokens.Add(slot);
		// A short name a type or another handle already took gets its role appended:
		// `AudioService`. Checked BEFORE registering: a refused registration marks the
		// whole engine misconfigured, and nothing compiles after.
		if (mHandleNames.Contains(name) || (AS.asc_engine_get_type_info_by_name(mEngine, name.CStr()) != null))
			name.Append("Service");
		if (Check(AS.asc_engine_register_global_property(mEngine, scope $"{AsName(t)}@ {name}".CStr(), slot), t.FullName))
		{
			mHandleNames.Add(new String(name));
			mHandleOf[t] = new String(name);
			Record(GlobalApi, name, scope $"{AsName(t)}@ {name}", true, .Property);
		}
	}

	/// A field or property becomes a virtual property: `T get_X() property` and its setter.
	/// `on` is the type it is registered on when that is not its own: a derived class taking a
	/// base's member.
	///
	/// A struct-valued one reads as a copy, as a C# struct does, and a plain struct's own stored
	/// fields are real members at their offsets (MemberInPlace): written in place on a local
	/// (`p.X += 1`, `r.Entry.Width = 3`), while a field written through a read of a property
	/// (`light.Color.R = 0.9f`) is refused, since it would change the copy. A script copies the
	/// value, changes it and writes it back whole through the setter.
	private void BindField(ScriptTypeInfo t, ScriptFieldInfo f, StringView statics, ScriptTypeInfo on = null)
	{
		let target = on ?? t;
		let typeDecl = scope String();
		if (!DeclOf(f.Kind, f.TypeName, typeDecl))
		{
			Problem(scope $"{t.FullName}.{f.Name}: {f.TypeName} has no AngelScript type, skipped");
			return;
		}

		if ((on == null) && MemberInPlace(t, f))
		{
			let readOnly = f.Set == null;
			let decl = scope $"{readOnly ? "const " : ""}{typeDecl} {f.ScriptName}";
			if (Check(AS.asc_engine_register_object_property(mEngine, scope String(AsName(t)).CStr(), decl.CStr(), f.Offset), t.FullName))
			{
				Record(ApiType(AsName(t), t.FullName, false), f.ScriptName, scope $"{typeDecl} {ReachedAs(t)}.{f.ScriptName}{readOnly ? " (read only)" : ""}",
					false, .Property, readOnly);
			}
			return;
		}

		let get = new AngelScriptBinding();
		get.Kind = .Get;
		get.Owner = t;
		get.Field = f;
		mBindings.Add(get);

		let isGlobal = f.IsStatic || (t.Kind == .Global);
		let getDecl = scope $"{typeDecl} get_{f.ScriptName}() property";
		bool bound;
		if (isGlobal)
		{
			AS.asc_engine_set_default_namespace(mEngine, scope String(statics).CStr());
			bound = Check(AS.asc_engine_register_global_function(mEngine, getDecl.CStr(), Internal.UnsafeCastToPtr(get)), t.FullName);
		}
		else
		{
			bound = Check(AS.asc_engine_register_object_method(mEngine, scope String(AsName(target)).CStr(), getDecl.CStr(), Internal.UnsafeCastToPtr(get)), t.FullName);
		}
		bool setBound = false;
		if (f.Set != null)
		{
			let set = new AngelScriptBinding();
			set.Kind = .Set;
			set.Owner = t;
			set.Field = f;
			mBindings.Add(set);
			let paramDecl = ParamDecl(f.Kind, f.TypeName, false, .. scope .());
			// A list setter takes the array by value reference: with a handle parameter the
			// compiler routes `t.Points = next` through the getter's handle instead.
			if (f.Kind == .List)
			{
				paramDecl.RemoveFromEnd(1);
				paramDecl.Insert(0, "const ");
				paramDecl.Append(" &in");
			}
			let setDecl = scope $"void set_{f.ScriptName}({paramDecl}) property";
			if (isGlobal)
				setBound = Check(AS.asc_engine_register_global_function(mEngine, setDecl.CStr(), Internal.UnsafeCastToPtr(set)), t.FullName);
			else
				setBound = Check(AS.asc_engine_register_object_method(mEngine, scope String(AsName(target)).CStr(), setDecl.CStr(), Internal.UnsafeCastToPtr(set)), t.FullName);
		}
		if (isGlobal)
			AS.asc_engine_set_default_namespace(mEngine, "");

		// Listed as bound: when the getter registered, and writable only when the setter did too,
		// so script_api never offers an assignment the compiler then refuses.
		if (bound)
		{
			// Spelled as a script reads it: `Type::Field` for a static, `Type.Field` on an
			// instance, a bare name in the global namespace.
			let api = (t.Kind == .Global) ? GlobalApi : ApiType(AsName(target), target.FullName, false);
			let spelled = (t.Kind == .Global) ? scope:: $"{f.ScriptName}" : (isGlobal ? scope:: $"{AsName(t)}::{f.ScriptName}" : scope:: $"{ReachedAs(target)}.{f.ScriptName}");
			Record(api, f.ScriptName, scope $"{typeDecl} {spelled}{setBound ? "" : " (read only)"}", isGlobal, .Property, !setBound);
		}
	}

	/// Whether a struct's field is a real member of the script's value: the script holds the
	/// struct's own bytes (its type registered at the struct's size), and the field's script type
	/// is laid out as the engine's (a number of its width, a bool, a math value, a Guid, a struct
	/// held the same way). Anything else (a string, an entity, an enum, a list) goes through
	/// its getter and setter.
	private bool MemberInPlace(ScriptTypeInfo owner, ScriptFieldInfo f)
	{
		if (f.IsStatic || (f.Offset < 0) || (owner.Kind != .Struct) || (owner.Role == .Component))
			return false;
		if (!HeldAsItsBytes(owner))
			return false;
		switch (f.Kind)
		{
		case .Bool, .Float, .Float2, .Float3, .Float4, .Quaternion, .Color, .Guid:
			return true;
		case .Int:
			// Not an enum: a script enum is four bytes whatever the engine's is.
			switch (f.TypeName)
			{
			case "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "char8", "char32":
				return true;
			default:
				return false;
			}
		case .Struct:
			let st = mSurface.Find(f.TypeName);
			return (st != null) && (st.Kind == .Struct) && (st.Role != .Component) && HeldAsItsBytes(st);
		default:
			return false;
		}
	}

	/// Whether the script's value of `t` is its own bytes: registered as a value of its size.
	private bool HeldAsItsBytes(ScriptTypeInfo t)
	{
		let type = AS.asc_engine_get_type_info_by_name(mEngine, scope String(AsName(t)).CStr());
		return (type != null) && (t.Size > 0) && (AS.asc_typeinfo_get_size(type) == t.Size);
	}

	/// A method is registered once per arity its defaults allow.
	/// `on` as for BindField: a derived class taking a base's instance method.
	private void BindMethod(ScriptTypeInfo t, ScriptMethodInfo m, StringView statics, ScriptTypeInfo on = null)
	{
		let target = on ?? t;
		let returnDecl = scope String();
		if (m.IsConstructor)
		{
			if (t.Kind == .Class)
				returnDecl.AppendF("{}@", AsName(t));
			else
				returnDecl.Set("void");
		}
		else if (!DeclOf(m.ReturnKind, m.ReturnTypeName, returnDecl))
		{
			Problem(scope $"{t.FullName}.{m.Name}: returns {m.ReturnTypeName}, which has no AngelScript type, skipped");
			return;
		}

		let paramDecls = scope List<String>();
		defer { ClearAndDeleteItems(paramDecls); }
		for (let p in m.Params)
		{
			let d = new String();
			if (!ParamDecl(p, d))
			{
				delete d;
				Problem(scope $"{t.FullName}.{m.Name}: parameter {p.Name} is {p.TypeName}, which has no AngelScript type, skipped");
				return;
			}
			d.AppendF(" {}", p.Name);
			paramDecls.Add(d);
		}

		let isGlobal = m.IsStatic || (t.Kind == .Global);
		let name = m.IsConstructor ? "f" : m.ScriptName;
		// The trampoline carries cMaxArgs arguments: an arity past them is not bound, so its use
		// does not compile, rather than called with its last arguments dropped.
		if (m.Params.Count > cMaxArgs)
			Problem(scope $"{t.FullName}.{m.Name}: a call carries at most {cMaxArgs} arguments; past them it is not bound");
		for (int arity = m.RequiredParams; arity <= Math.Min(m.Params.Count, cMaxArgs); arity++)
		{
			let b = new AngelScriptBinding();
			b.Kind = m.IsConstructor ? .Construct : .Call;
			b.Owner = t;
			b.Method = m;
			b.Arity = arity;
			mBindings.Add(b);

			let decl = scope String();
			decl.AppendF("{} {}(", returnDecl, name);
			for (int i = 0; i < arity; i++)
			{
				if (i > 0)
					decl.Append(", ");
				decl.Append(paramDecls[i]);
			}
			decl.Append(")");

			int32 rc;
			if (m.IsConstructor)
			{
				let behaviour = (t.Kind == .Class) ? AS.asBEHAVE_FACTORY : AS.asBEHAVE_CONSTRUCT;
				rc = AS.asc_engine_register_object_behaviour(mEngine, scope String(AsName(t)).CStr(), behaviour, decl.CStr(), Internal.UnsafeCastToPtr(b));
			}
			else if (isGlobal)
			{
				if (t.Kind != .Global)
					AS.asc_engine_set_default_namespace(mEngine, scope String(statics).CStr());
				rc = AS.asc_engine_register_global_function(mEngine, decl.CStr(), Internal.UnsafeCastToPtr(b));
				if (t.Kind != .Global)
					AS.asc_engine_set_default_namespace(mEngine, "");
			}
			else
			{
				rc = AS.asc_engine_register_object_method(mEngine, scope String(AsName(target)).CStr(), decl.CStr(), Internal.UnsafeCastToPtr(b));
			}
			if (Check(rc, scope $"{t.FullName}.{m.Name} as {decl}"))
			{
				// As a script spells the call: `Type::Name(...)` for a static, `Type(...)`
				// for a constructor, the bare declaration in the global namespace.
				let api = (t.Kind == .Global) ? GlobalApi : ApiType(AsName(target), target.FullName, false);
				let spelled = scope String();
				if (m.IsConstructor)
					spelled.AppendF("{}(", AsName(t));
				else if (t.Kind == .Global)
					spelled.AppendF("{} {}(", returnDecl, name);
				else if (isGlobal)
					spelled.AppendF("{} {}::{}(", returnDecl, AsName(t), name);
				else
					spelled.AppendF("{} {}.{}(", returnDecl, ReachedAs(target), name);
				for (int i = 0; i < arity; i++)
				{
					if (i > 0)
						spelled.Append(", ");
					spelled.Append(paramDecls[i]);
				}
				spelled.Append(")");
				Record(api, m.IsConstructor ? AsName(t) : m.ScriptName, spelled, isGlobal, .Method);
			}
		}
	}

	private bool Check(int32 rc, StringView what)
	{
		if (rc >= 0)
			return true;
		Problem(scope $"{what}: AngelScript refused it ({rc})");
		return false;
	}

	// ---- declarations ----

	/// The AngelScript type for a kind, as a value: `float`, `Float3`, `Thing@`, `string`.
	private bool DeclOf(ScriptValueKind kind, StringView typeName, String outDecl)
	{
		switch (kind)
		{
		case .Nil: outDecl.Append("void"); return true;
		case .Bool: outDecl.Append("bool"); return true;
		case .Float: outDecl.Append((typeName == "double") ? "double" : "float"); return true;
		case .Int:
			switch (typeName)
			{
			case "int8": outDecl.Append("int8");
			case "int16": outDecl.Append("int16");
			case "int32": outDecl.Append("int");
			case "int64", "int": outDecl.Append("int64");
			case "uint8", "char8": outDecl.Append("uint8");
			case "uint16": outDecl.Append("uint16");
			case "uint32", "char32": outDecl.Append("uint");
			case "uint64", "uint": outDecl.Append("uint64");
			default:
				// An enum, by its surface name.
				let e = mSurface.Find(typeName);
				if ((e == null) || !mByName.ContainsKey(scope String(AsName(e))))
					return false;
				outDecl.Append(AsName(e));
			}
			return true;
		case .String: outDecl.Append("string"); return true;
		case .Guid: outDecl.Append("Guid"); return true;
		case .Entity: outDecl.Append("Entity"); return true;
		case .Float2: outDecl.Append("Float2"); return true;
		case .Float3: outDecl.Append("Float3"); return true;
		case .Float4: outDecl.Append("Float4"); return true;
		case .Quaternion: outDecl.Append("Quaternion"); return true;
		case .Color: outDecl.Append("Color"); return true;
		case .Object:
			if (typeName == "System.String")
			{
				outDecl.Append("string");
				return true;
			}
			let c = mSurface.Find(typeName);
			if ((c == null) || !mByName.ContainsKey(scope String(AsName(c))))
				return false;
			outDecl.AppendF("{}@", AsName(c));
			return true;
		case .Struct:
			let st = mSurface.Find(typeName);
			if ((st == null) || !mByName.ContainsKey(scope String(AsName(st))))
				return false;
			outDecl.Append(AsName(st));
			return true;
		case .Delegate:
			outDecl.Append("ScriptCallback@");
			return true;
		case .Weak:
			let w = mSurface.Find(typeName);
			if ((w == null) || !mByName.ContainsKey(scope String(AsName(w))))
				return false;
			outDecl.AppendF("{}@", AsName(w));
			return true;
		case .Counted:
			let counted = mSurface.Find(typeName);
			if ((counted == null) || !mByName.ContainsKey(scope String(AsName(counted))))
				return false;
			outDecl.AppendF("{}@", AsName(counted));
			return true;
		case .List:
			// A List<X> is the add-on's array<X>, by handle: the script's own array, filled
			// from the list and read back into it.
			let element = scope String();
			if (!ElementDecl(typeName, element))
				return false;
			outDecl.AppendF("array<{}>@", element);
			return true;
		}
	}

	/// The element type name of a List<X>, X in full.
	private static bool ElementTypeOf(StringView listTypeName, String outElement)
	{
		const String cPrefix = "System.Collections.List<";
		if (!listTypeName.StartsWith(cPrefix) || !listTypeName.EndsWith(">"))
			return false;
		outElement.Set(listTypeName.Substring(cPrefix.Length, listTypeName.Length - cPrefix.Length - 1));
		return true;
	}

	/// The AngelScript declaration of a List<X>'s element, from X's name alone.
	private bool ElementDecl(StringView listTypeName, String outDecl)
	{
		let element = scope String();
		if (!ElementTypeOf(listTypeName, element))
			return false;
		return DeclOf(KindOfTypeName(element), element, outDecl);
	}

	/// The kind a Beef type name crosses as, for an element the surface only names.
	private ScriptValueKind KindOfTypeName(StringView typeName)
	{
		switch (typeName)
		{
		case "float", "double": return .Float;
		case "bool": return .Bool;
		case "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "char8", "char32":
			return .Int;
		case "System.StringView": return .String;
		case "System.String": return .Object;
		}
		let inlineKind = KindOfStructName(typeName);
		if (inlineKind != .Struct)
			return inlineKind;
		if (let t = mSurface.Find(typeName))
		{
			if (t.Kind == .Enum)
				return .Int;
			if (t.Kind == .Class)
				return ((t.Role == .Weak) || IsSceneBound(t)) ? .Weak : ((t.Role == .Counted) ? .Counted : .Object);
			return .Struct;
		}
		return .Nil;
	}

	/// A surface parameter's declaration: a callback with a shape of its own takes a handle of
	/// that shape, declared the first time a parameter names it; the rest as below.
	private bool ParamDecl(ScriptParamInfo p, String outDecl)
	{
		if ((p.Kind == .Delegate) && !p.CallbackShape.IsEmpty)
		{
			let name = DeclareShape(p.CallbackShape, .. scope .());
			if (name.IsEmpty)
				return false;
			outDecl.AppendF("{}@", name);
			return true;
		}
		return ParamDecl(p.Kind, p.TypeName, p.IsByRef, outDecl);
	}

	/// A callback shape (`void NetHandler(int sender)`) as a funcdef, declared once per engine
	/// and recorded once per binding; appends its name, nothing when it does not declare.
	private void DeclareShape(StringView declaration, String outName)
	{
		let open = declaration.IndexOf('(');
		if (open <= 0)
		{
			Problem(scope $"the callback shape '{declaration}' names no function");
			return;
		}
		var head = declaration.Substring(0, open);
		head.TrimEnd();
		let space = head.LastIndexOf(' ');
		let name = StringView(head, space + 1);
		if (name.IsEmpty)
		{
			Problem(scope $"the callback shape '{declaration}' names no function");
			return;
		}
		if (!mDeclaredShapes.ContainsAlt(name))
		{
			if (AS.asc_engine_register_funcdef(mEngine, scope String(declaration).CStr()) < 0)
			{
				Problem(scope $"the callback shape '{declaration}' did not declare");
				return;
			}
			mDeclaredShapes.Add(new String(name));
		}
		if (!mRecordedShapes.ContainsAlt(name))
		{
			mRecordedShapes.Add(new String(name));
			Record(GlobalApi, name, scope $"funcdef {declaration}", true, .Constant);
		}
		outName.Append(name);
	}

	/// A parameter's declaration: primitives and handles by value, value types and strings
	/// by const reference, a by-ref parameter by `&inout`.
	private bool ParamDecl(ScriptValueKind kind, StringView typeName, bool byRef, String outDecl)
	{
		let type = scope String();
		if (!DeclOf(kind, typeName, type))
			return false;
		let isValue = ByReferenceKind(kind, typeName);
		if (byRef && (kind != .List))
			outDecl.AppendF("{} &inout", type);
		else if (isValue)
			outDecl.AppendF("const {} &in", type);
		else
			outDecl.Append(type);
		return true;
	}

	/// Whether a kind is an AngelScript value type or string, passed by reference.
	private static bool ByReferenceKind(ScriptValueKind kind, StringView typeName)
	{
		switch (kind)
		{
		case .String, .Guid, .Entity, .Float2, .Float3, .Float4, .Quaternion, .Color, .Struct:
			return true;
		case .List, .Delegate, .Weak, .Counted:
			return false;
		case .Object:
			return typeName == "System.String";
		default:
			return false;
		}
	}

	// ==================== the trampoline ====================

	private const int cMaxArgs = 16;

	private static void OnGeneric(AS.Generic* gen, void* aux, void* user)
	{
		let self = Internal.UnsafeCastToObject(user) as AngelScriptRuntime;
		let binding = Internal.UnsafeCastToObject(aux) as AngelScriptBinding;
		self.Dispatch(gen, binding);
	}

	private void Dispatch(AS.Generic* gen, AngelScriptBinding b)
	{
		let context = mCallContext;
		// Everything the call packs into scratch, lists and struct elements, is consumed
		// by the time it returns; a nested call releases only its own.
		let mark = context.ScratchMark;
		// The references the call handed over likewise, once WriteReturn has taken the
		// script's own.
		let pendingMark = context.PendingMark;
		defer
		{
			context.ReleaseScratch(mark);
			context.ReleasePending(pendingMark);
		}
		switch (b.Kind)
		{
		case .ComponentOf, .ComponentAddTo:
		{
			// addTo gives the entity the component first; then both answer whether it has one.
			let entity = AS.asc_generic_get_arg_address(gen, 0);
			var frame = ScriptCallFrame(context, default);
			frame.Self = ReadValue(entity, .Entity, "");
			if (b.Kind == .ComponentAddTo)
				b.Owner.AddTo(ref frame);
			else
				b.Owner.IsOn(ref frame);
			if (frame.Failed)
			{
				AS.asc_set_active_exception(scope String(frame.Error).CStr());
				return;
			}
			// The handle a script holds, its count the one reference returned.
			ComponentHandle* handle = null;
			if (frame.Result.AsBool)
			{
				handle = (ComponentHandle*)Internal.StdMalloc(sizeof(ComponentHandle));
				handle.Entity = *(ScriptEntity*)entity;
				handle.References = 1;
			}
			AS.asc_generic_set_return_address(gen, handle);
			return;
		}
		case .ComponentRemoveFrom:
		{
			let entity = AS.asc_generic_get_arg_address(gen, 0);
			var frame = ScriptCallFrame(context, default);
			frame.Self = ReadValue(entity, .Entity, "");
			b.Owner.RemoveFrom(ref frame);
			if (frame.Failed)
			{
				AS.asc_set_active_exception(scope String(frame.Error).CStr());
				return;
			}
			AS.asc_generic_set_return_byte(gen, frame.Result.AsBool ? 1 : 0);
			return;
		}
		case .ComponentAddRef:
			((ComponentHandle*)AS.asc_generic_get_object(gen)).References++;
			return;
		case .ComponentRelease:
			let handle = (ComponentHandle*)AS.asc_generic_get_object(gen);
			if (--handle.References == 0)
				Internal.StdFree(handle);
			return;
		case .ComponentIsValid:
		{
			let handle = (ComponentHandle*)AS.asc_generic_get_object(gen);
			var frame = ScriptCallFrame(context, default);
			frame.Self = ReadValue(&handle.Entity, .Entity, "");
			b.Owner.IsOn(ref frame);
			AS.asc_generic_set_return_byte(gen, (!frame.Failed && frame.Result.AsBool) ? 1 : 0);
			return;
		}
		case .WeakOf:
		{
			// The node narrowed by the type's cast: the same box, one more reference, or null
			// for a node of another type, a gone one, or none. Never an error.
			let node = (WeakHandle*)AS.asc_generic_get_arg_object(gen, 0);
			WeakHandle* narrowed = null;
			if ((node != null) && (b.Owner.Cast != null))
			{
				var frame = ScriptCallFrame(context, default);
				frame.Self = .FromWeakRef(node.Ref);
				b.Owner.Cast(ref frame);
				if (!frame.Failed && (frame.Result.Kind == .Weak))
				{
					node.References++;
					narrowed = node;
				}
			}
			AS.asc_generic_set_return_address(gen, narrowed);
			return;
		}
		case .WeakAddRef:
			((WeakHandle*)AS.asc_generic_get_object(gen)).References++;
			return;
		case .WeakRelease:
			ReleaseWeakBox((WeakHandle*)AS.asc_generic_get_object(gen));
			return;
		case .WeakIsValid:
		{
			let @box = (WeakHandle*)AS.asc_generic_get_object(gen);
			AS.asc_generic_set_return_byte(gen, (@box.Ref.Resolve() != null) ? 1 : 0);
			return;
		}
		case .WeakEquals:
		{
			let @box = (WeakHandle*)AS.asc_generic_get_object(gen);
			let other = (WeakHandle*)AS.asc_generic_get_arg_object(gen, 0);
			AS.asc_generic_set_return_byte(gen, ((other != null) && @box.Ref.SameAs(other.Ref)) ? 1 : 0);
			return;
		}
		case .WeakUpcast:
		{
			// The returned handle is a reference of its own.
			let @box = (WeakHandle*)AS.asc_generic_get_object(gen);
			@box.References++;
			AS.asc_generic_set_return_address(gen, @box);
			return;
		}
		case .CountedAddRef:
			CountedAt(AS.asc_generic_get_object(gen)).AddRef();
			return;
		case .CountedRelease:
			CountedAt(AS.asc_generic_get_object(gen)).ReleaseRef();
			return;
		case .CountedUpcast:
		{
			// The returned handle is a reference of its own.
			let object = AS.asc_generic_get_object(gen);
			CountedAt(object).AddRef();
			AS.asc_generic_set_return_address(gen, object);
			return;
		}
		case .StartCoroutine:
			StartCoroutine((AS.Function*)AS.asc_generic_get_arg_address(gen, 0));
			return;
		case .Wait:
			WaitCurrent(AS.asc_generic_get_arg_float(gen, 0));
			return;
		case .Yield:
			WaitCurrent(0);
			return;
		case .Operator:
			DispatchOperator(gen, b);
			return;
		case .Resolve:
			// `scene.Physics`: the scene's instance of the system, a weak handle of its own; null
			// when the scene has none, or is gone.
			var frame = ScriptCallFrame(context, default);
			frame.Self = .FromWeakRef(((WeakHandle*)AS.asc_generic_get_object(gen)).Ref);
			b.Owner.FromScene(ref frame);
			if (frame.Failed)
			{
				AS.asc_set_active_exception(scope String(frame.Error).CStr());
				return;
			}
			let held = frame.Result.AsObject as IScriptWeaklyHeld;
			AS.asc_generic_set_return_address(gen, (held != null) ? NewWeakBox(held.TakeScriptWeak()) : null);
			return;
		default:
		}

		// Arguments, from the declaration's parameters.
		ScriptValue[cMaxArgs] args = .();
		ScriptValueKind[cMaxArgs] kinds = .();
		int count = 0;
		List<ScriptParamInfo> paramInfos = null;
		if (b.Kind == .Set)
		{
			count = 1;
			kinds[0] = b.Field.Kind;
			args[0] = ReadArg(gen, 0, b.Field.Kind, b.Field.TypeName);
		}
		else if ((b.Kind == .Call) || (b.Kind == .Construct) || (b.Kind == .EntityCall))
		{
			// The entity side's parameters start after the entity, which is Self.
			int firstParam = (b.Kind == .EntityCall) ? 1 : 0;
			paramInfos = b.Method.Params;
			count = b.Arity;
			for (int i = 0; i < count; i++)
			{
				let p = paramInfos[i + firstParam];
				kinds[i] = p.Kind;
				args[i] = ReadArg(gen, i, p.Kind, p.TypeName);
			}
		}

		var frame = ScriptCallFrame(context, Span<ScriptValue>(&args[0], count));

		// Self, from what the call is on.
		let owner = b.Owner;
		let isStatic = (b.Kind == .Construct) || ((b.Kind != .Get && b.Kind != .Set) ? (b.Method.IsStatic || owner.Kind == .Global) : b.Field.IsStatic) || (owner.Kind == .Global);
		void* selfMemory = null;
		ScriptValueKind selfKind = .Nil;
		if (b.Kind == .EntityCall)
		{
			// Called on an entity value, whatever type declared the method.
			selfMemory = AS.asc_generic_get_object(gen);
			selfKind = .Entity;
			frame.Self = ReadValue(selfMemory, .Entity, "");
		}
		else if (!isStatic)
		{
			selfMemory = AS.asc_generic_get_object(gen);
			selfKind = SelfKind(owner);
			frame.Self = ReadSelf(selfMemory, selfKind, owner);
		}

		// Where a struct result goes: the value under construction, or the return location.
		void* target = null;
		ScriptValueKind resultKind = .Nil;
		if (b.Kind == .Construct)
		{
			target = AS.asc_generic_get_object(gen);
			resultKind = (owner.Role == .Component) ? .Entity : owner.Kind == .Struct ? KindOfStruct(owner) : ((owner.Role == .Counted) ? .Counted : .Object);
		}
		else if (b.Kind == .Get)
		{
			resultKind = b.Field.Kind;
			target = AS.asc_generic_get_address_of_return_location(gen);
		}
		else if ((b.Kind == .Call) || (b.Kind == .EntityCall))
		{
			resultKind = b.Method.ReturnKind;
			target = AS.asc_generic_get_address_of_return_location(gen);
		}
		context.ResultTarget = (resultKind == .Struct) ? target : null;

		// The call.
		switch (b.Kind)
		{
		case .Get: b.Field.Get(ref frame);
		case .Set: b.Field.Set(ref frame);
		case .EntityCall: b.Method.EntityInvoke(ref frame);
		default: b.Method.Invoke(ref frame);
		}
		context.ResultTarget = null;

		if (frame.Failed)
		{
			// A thunk fails only before its callee runs, so no callee took the delegates
			// ReadArg made for it: they go here, or nothing would.
			for (int i = 0; i < count; i++)
			{
				if (kinds[i] == .Delegate)
					delete args[i].AsDelegate;
			}
			AS.asc_set_active_exception(scope String(frame.Error).CStr());
			return;
		}

		// An inline struct self was copied; put it back. Not the entity of an entity call,
		// which is const to the script.
		if (!isStatic && (selfMemory != null) && (b.Kind != .EntityCall))
			WriteSelf(selfMemory, selfKind, frame.Self);

		// By-ref arguments, back into the script's variables; a list always, into the
		// script's array, since the callee may have filled it.
		if (paramInfos != null)
		{
			int firstParam = (b.Kind == .EntityCall) ? 1 : 0;
			for (int i = 0; i < count; i++)
			{
				if (kinds[i] == .List)
					UnpackArray(AS.asc_generic_get_arg_object(gen, (uint32)i), args[i]);
				else if (paramInfos[i + firstParam].IsByRef)
					WriteValue(AS.asc_generic_get_arg_address(gen, (uint32)i), kinds[i], paramInfos[i + firstParam].TypeName, args[i]);
			}
		}

		// The result.
		if (b.Kind == .Construct)
		{
			if (owner.Role == .Counted)
			{
				// A counted factory: the script's handle is a reference of its own, and the
				// one the constructor made is released with the call's, leaving the script's.
				let made = frame.Result.AsCounted;
				made?.AddRef();
				AS.asc_generic_set_return_address(gen, PointerOf(made));
			}
			else if (owner.Kind == .Class)
			{
				// A factory: the object is the script's to use and the runtime's to free.
				let made = frame.Result.AsObject;
				if (made != null)
					mOwned.Add(made);
				AS.asc_generic_set_return_address(gen, (made != null) ? Internal.UnsafeCastToPtr(made) : null);
			}
			else if (resultKind != .Struct)
			{
				WriteValue(target, resultKind, "", frame.Result);
			}
			// A Struct result was constructed in place through ResultTarget.
		}
		else if (resultKind != .Nil)
		{
			WriteReturn(gen, target, resultKind, (b.Kind == .Get) ? b.Field.TypeName : b.Method.ReturnTypeName, frame.Result);
		}
	}

	/// The kind of one of the inline value types declared up front, by its AngelScript
	/// name; Nil for any other name.
	private static ScriptValueKind InlineKindOf(StringView asName)
	{
		switch (asName)
		{
		case "Float2": return .Float2;
		case "Float3": return .Float3;
		case "Float4": return .Float4;
		case "Quaternion": return .Quaternion;
		case "Color": return .Color;
		case "Entity": return .Entity;
		case "Guid": return .Guid;
		default: return .Nil;
		}
	}

	private static ScriptValueKind KindOfStruct(ScriptTypeInfo t) => KindOfStructName(t.FullName);

	private static ScriptValueKind KindOfStructName(StringView fullName)
	{
		switch (fullName)
		{
		case "Sedulous.Core.Float2": return .Float2;
		case "Sedulous.Core.Float3": return .Float3;
		case "Sedulous.Core.Float4": return .Float4;
		case "Sedulous.Core.Quaternion": return .Quaternion;
		case "Sedulous.Core.Color": return .Color;
		case "Sedulous.Scene.EntityHandle": return .Entity;
		case "System.Guid": return .Guid;
		default: return .Struct;
		}
	}

	private static ScriptValueKind SelfKind(ScriptTypeInfo owner)
	{
		if (owner.Role == .Component)
			return .Entity;
		if ((owner.Role == .Weak) || IsSceneBound(owner))
			return .Weak;
		if (owner.Role == .Counted)
			return .Counted;
		if (owner.Kind == .Class)
			return .Object;
		return KindOfStruct(owner);
	}

	private static ScriptValue ReadSelf(void* memory, ScriptValueKind kind, ScriptTypeInfo owner)
	{
		switch (kind)
		{
		case .Object: return .FromObject(Internal.UnsafeCastToObject(memory));
		case .Weak: return .FromWeakRef(((WeakHandle*)memory).Ref);
		case .Counted: return .FromCounted(CountedAt(memory));
		case .Struct: return .FromStruct(memory, owner.BeefType);
		default: return ReadValue(memory, kind, "");
		}
	}

	private static void WriteSelf(void* memory, ScriptValueKind kind, ScriptValue value)
	{
		switch (kind)
		{
		case .Float2, .Float3, .Float4, .Quaternion, .Color, .Guid, .Entity:
			WriteValue(memory, kind, "", value);
		default:
		}
	}

	/// An argument of the generic call as a ScriptValue.
	private ScriptValue ReadArg(AS.Generic* gen, int i, ScriptValueKind kind, StringView typeName)
	{
		let arg = (uint32)i;
		switch (kind)
		{
		case .Nil: return .Nil;
		case .Bool: return .FromBool(AS.asc_generic_get_arg_byte(gen, arg) != 0);
		case .Float:
			return .FromFloat((typeName == "double") ? AS.asc_generic_get_arg_double(gen, arg) : (double)AS.asc_generic_get_arg_float(gen, arg));
		case .Int:
			switch (typeName)
			{
			case "int8": return .FromInt((int8)AS.asc_generic_get_arg_byte(gen, arg));
			case "uint8", "char8": return .FromInt(AS.asc_generic_get_arg_byte(gen, arg));
			case "int16": return .FromInt((int16)AS.asc_generic_get_arg_word(gen, arg));
			case "uint16": return .FromInt(AS.asc_generic_get_arg_word(gen, arg));
			case "int32": return .FromInt((int32)AS.asc_generic_get_arg_dword(gen, arg));
			case "uint32", "char32": return .FromInt(AS.asc_generic_get_arg_dword(gen, arg));
			case "int64", "int": return .FromInt((int64)AS.asc_generic_get_arg_qword(gen, arg));
			case "uint64", "uint": return .FromInt((int64)AS.asc_generic_get_arg_qword(gen, arg));
			default: return .FromInt((int32)AS.asc_generic_get_arg_dword(gen, arg)); // an enum
			}
		case .String:
			return .FromString(StringOf(AS.asc_generic_get_arg_address(gen, arg)));
		case .Object:
			if (typeName == "System.String")
			{
				// A Beef String the callee may fill, copied back by the caller after.
				let s = new String(StringOf(AS.asc_generic_get_arg_address(gen, arg)));
				mOwned.Add(s);
				return .FromObject(s);
			}
			return .FromObject(Internal.UnsafeCastToObject(AS.asc_generic_get_arg_object(gen, arg)));
		case .Struct:
			let st = mSurface.Find(typeName);
			return .FromStruct(AS.asc_generic_get_arg_address(gen, arg), (st != null) ? st.BeefType : null);
		case .List:
			return PackArray(AS.asc_generic_get_arg_object(gen, arg), typeName);
		case .Delegate:
			// A funcdef handle arrives as the function itself; null clears a binding. The
			// callee takes the delegate.
			let fn = (AS.Function*)AS.asc_generic_get_arg_object(gen, arg);
			return (fn != null) ? .FromDelegate(new AngelScriptDelegate(this, fn)) : .Nil;
		case .Weak:
			// The box stays the engine's, released after the call; the value borrows its table.
			let @box = (WeakHandle*)AS.asc_generic_get_arg_object(gen, arg);
			return (@box != null) ? .FromWeakRef(@box.Ref) : .Nil;
		case .Counted:
			// Borrowed: the engine releases its handle after the call, and a callee that keeps
			// the object takes a reference of its own.
			return .FromCounted(CountedAt(AS.asc_generic_get_arg_object(gen, arg)));
		default:
			return ReadValue(AS.asc_generic_get_arg_address(gen, arg), kind, typeName);
		}
	}

	/// A script array as a ScriptList in the context's scratch: each element read by its
	/// AngelScript type. A null handle is an empty list.
	private ScriptValue PackArray(void* array, StringView listTypeName)
	{
		let element = scope String();
		ElementTypeOf(listTypeName, element);
		let elementKind = KindOfTypeName(element);
		// The element type name has to outlive the call: the surface's own copy does.
		let elementName = ElementNameOf(listTypeName);
		let count = (array != null) ? (int)AS.asc_array_get_size(array) : 0;
		let packed = mCallContext.AllocList(count, elementKind, elementName);
		if (count > 0)
		{
			let typeId = AS.asc_array_get_element_type_id(array);
			for (int i < count)
				packed.Items[i] = ReadTyped(typeId, AS.asc_array_at(array, (uint32)i));
		}
		return .FromList(packed);
	}

	/// Fills a script array from a ScriptList: resized to the list, each element written
	/// by its AngelScript type.
	private void UnpackArray(void* array, ScriptValue value)
	{
		if (array == null)
			return;
		let list = value.AsList;
		let count = (list != null) ? (int)list.Count : 0;
		AS.asc_array_resize(array, (uint32)count);
		if (count == 0)
			return;
		let typeId = AS.asc_array_get_element_type_id(array);
		for (int i < count)
			WriteTyped(typeId, AS.asc_array_at(array, (uint32)i), list.Items[i]);
	}

	/// A fresh script array for a list result, the caller's to release.
	private void* ArrayFor(StringView listTypeName, ScriptValue value)
	{
		let decl = scope String();
		if (!DeclOf(.List, listTypeName, decl))
			return null;
		decl.RemoveFromEnd(1); // the handle mark: the type itself is asked for
		let list = value.AsList;
		let count = (list != null) ? (int)list.Count : 0;
		let array = AS.asc_array_create(mEngine, decl.CStr(), (uint32)count);
		if (array == null)
			return null;
		UnpackArray(array, value);
		return array;
	}

	/// The stable element name of a list type: a view into a string this runtime keeps,
	/// since a ScriptList only borrows its ElementType.
	private StringView ElementNameOf(StringView listTypeName)
	{
		let element = scope String();
		ElementTypeOf(listTypeName, element);
		if (mElementNames.TryGetValue(element, let kept))
			return kept;
		let owned = new String(element);
		mElementNames.Add(owned, owned);
		return owned;
	}
	private Dictionary<String, String> mElementNames = new .() ~ DeleteDictionaryAndKeys!(_);

	/// An inline value out of memory.
	private static ScriptValue ReadValue(void* memory, ScriptValueKind kind, StringView typeName)
	{
		switch (kind)
		{
		case .Guid: return .FromGuid(*(Guid*)memory);
		case .Entity: return .FromEntityRef(*(ScriptEntity*)memory);
		case .Float2: return .FromFloat2(*(Float2*)memory);
		case .Float3: return .FromFloat3(*(Float3*)memory);
		case .Float4: return .FromFloat4(*(Float4*)memory);
		case .Quaternion: return .FromQuaternion(*(Quaternion*)memory);
		case .Color: return .FromColor(*(Color*)memory);
		case .Bool: return .FromBool(*(bool*)memory);
		case .Float: return .FromFloat((typeName == "double") ? *(double*)memory : (double)*(float*)memory);
		case .Int:
			switch (typeName)
			{
			case "int8": return .FromInt(*(int8*)memory);
			case "uint8", "char8": return .FromInt(*(uint8*)memory);
			case "int16": return .FromInt(*(int16*)memory);
			case "uint16": return .FromInt(*(uint16*)memory);
			case "int32": return .FromInt(*(int32*)memory);
			case "uint32", "char32": return .FromInt(*(uint32*)memory);
			case "int64", "int": return .FromInt(*(int64*)memory);
			case "uint64", "uint": return .FromInt((int64)*(uint64*)memory);
			default: return .FromInt(*(int32*)memory);
			}
		default: return .Nil;
		}
	}

	/// A value into memory the script owns: a by-ref argument, a constructed value.
	private static void WriteValue(void* memory, ScriptValueKind kind, StringView typeName, ScriptValue value)
	{
		if (memory == null)
			return;
		switch (kind)
		{
		case .Guid: *(Guid*)memory = value.AsGuid;
		case .Entity: *(ScriptEntity*)memory = value.AsEntityRef;
		case .Float2: *(Float2*)memory = value.AsFloat2;
		case .Float3: *(Float3*)memory = value.AsFloat3;
		case .Float4: *(Float4*)memory = value.AsFloat4;
		case .Quaternion: *(Quaternion*)memory = value.AsQuaternion;
		case .Color: *(Color*)memory = value.AsColor;
		case .Bool: *(bool*)memory = value.AsBool;
		case .Float:
			if (typeName == "double")
				*(double*)memory = value.AsNumber;
			else
				*(float*)memory = (float)value.AsNumber;
		case .Int:
			switch (typeName)
			{
			case "int8", "uint8", "char8": *(uint8*)memory = (uint8)value.AsInt;
			case "int16", "uint16": *(uint16*)memory = (uint16)value.AsInt;
			case "int64", "int", "uint64", "uint": *(uint64*)memory = (uint64)value.AsInt;
			default: *(uint32*)memory = (uint32)value.AsInt;
			}
		case .String:
			AS.asc_string_assign(memory, value.AsString.Ptr, (uint)value.AsString.Length);
		case .Object:
			if (typeName == "System.String")
			{
				let s = value.AsObject as String;
				if (s != null)
					AS.asc_string_assign(memory, s.Ptr, (uint)s.Length);
			}
		default:
		}
	}

	/// The thunk's result, to the generic call.
	private void WriteReturn(AS.Generic* gen, void* location, ScriptValueKind kind, StringView typeName, ScriptValue value)
	{
		switch (kind)
		{
		case .List:
			// The array's one reference passes to the script with the handle.
			AS.asc_generic_set_return_address(gen, ArrayFor(typeName, value));
		case .Bool: AS.asc_generic_set_return_byte(gen, value.AsBool ? 1 : 0);
		case .Float:
			if (typeName == "double")
				AS.asc_generic_set_return_double(gen, value.AsNumber);
			else
				AS.asc_generic_set_return_float(gen, (float)value.AsNumber);
		case .Int:
			switch (typeName)
			{
			case "int8", "uint8", "char8": AS.asc_generic_set_return_byte(gen, (uint8)value.AsInt);
			case "int16", "uint16": AS.asc_generic_set_return_word(gen, (uint16)value.AsInt);
			case "int64", "int", "uint64", "uint": AS.asc_generic_set_return_qword(gen, (uint64)value.AsInt);
			default: AS.asc_generic_set_return_dword(gen, (uint32)value.AsInt);
			}
		case .String:
			AS.asc_string_construct(location, value.AsString.Ptr, (uint)value.AsString.Length);
		case .Object:
			if (typeName == "System.String")
			{
				let s = value.AsObject as String;
				AS.asc_string_construct(location, (s != null) ? s.Ptr : "", (s != null) ? (uint)s.Length : 0);
			}
			else
			{
				AS.asc_generic_set_return_address(gen, (value.AsObject != null) ? Internal.UnsafeCastToPtr(value.AsObject) : null);
			}
		case .Weak:
			// A box of its own, its one reference passing to the script with the handle.
			AS.asc_generic_set_return_address(gen, (value.Kind == .Weak) ? NewWeakBox(value.Data.Weak) : null);
		case .Counted:
			// The script's handle is a reference of its own, lent or handed over alike: a
			// handed one is released after the call.
			let counted = value.AsCounted;
			counted?.AddRef();
			AS.asc_generic_set_return_address(gen, PointerOf(counted));
		case .Struct:
			// Built in place at the return location through ResultTarget; a call that answered
			// nothing (one through a handle whose scene is gone) leaves it zeroed.
			if (value.IsNil && (location != null))
			{
				if (let st = mSurface.Find(typeName))
					Internal.MemSet(location, 0, st.Size);
			}
		default:
			WriteValue(location, kind, typeName, value);
		}
	}

	private static StringView StringOf(void* str)
	{
		uint length = 0;
		let data = AS.asc_string_data(str, &length);
		return StringView(data, (int)length);
	}

	// ==================== modules and calls ====================

	/// Builds through the SDK's script builder, which strips `[metadata]` in front of
	/// declarations from what the compiler sees and keeps it for DescribeClass; then runs the
	/// global initializers under the budget, unless asked not to.
	public override bool CompileModule(StringView moduleName, Span<ScriptSection> sections, bool runInitializers = true)
	{
		ForgetBuilder(moduleName);
		let builder = AS.asc_builder_create();
		if (builder == null)
			return false;
		mBuilders[new String(moduleName)] = builder;
		if (AS.asc_builder_start_module(builder, mEngine, scope String(moduleName).CStr()) < 0)
			return false;
		// The builder treats a repeated section name as a file already included and skips it,
		// so two classes from same-named files would lose the second: a repeat is numbered.
		let names = scope HashSet<String>();
		defer { for (let n in names) delete n; }
		for (let section in sections)
		{
			let name = scope String(section.Name);
			for (int n = 2; names.Contains(name); n++)
			{
				name.Set(section.Name);
				name.AppendF("#{}", n);
			}
			names.Add(new String(name));
			if (!AddSection(builder, name, section.Source))
				return false;
		}
		if (AS.asc_builder_build(builder) < 0)
			return false;
		if (!runInitializers)
			return true;
		let module = AS.asc_engine_get_module(mEngine, scope String(moduleName).CStr(), AS.asGM_ONLY_IF_EXISTS);
		if ((module == null) || !InitGlobals(module))
		{
			DiscardModule(moduleName);
			return false;
		}
		return true;
	}

	/// Through a builder of its own, so `[metadata]` checks as it compiles, into a module
	/// discarded before any of it could be called.
	public override bool Check(StringView sectionName, StringView source, Span<ScriptSection> includes = default)
	{
		let builder = AS.asc_builder_create();
		if (builder == null)
			return false;
		defer AS.asc_builder_destroy(builder);
		if (AS.asc_builder_start_module(builder, mEngine, cCheckModule) < 0)
			return false;
		defer
		{
			let module = AS.asc_engine_get_module(mEngine, cCheckModule, AS.asGM_ONLY_IF_EXISTS);
			if (module != null)
				AS.asc_module_discard(module);
		}
		if (!AddSection(builder, sectionName, source))
			return false;
		for (let included in includes)
		{
			if (!AddSection(builder, included.Name, included.Source))
				return false;
		}
		// A build runs no global initializer (they run in CompileModule, after it).
		return AS.asc_builder_build(builder) >= 0;
	}

	private const String cCheckModule = "__check";

	/// Adds `source` as the section `name`, its `#include` lines blanked: the files they name come
	/// as sections of their own (the cook resolved and recorded them), and the builder must not
	/// look for them.
	private static bool AddSection(AS.Builder* builder, StringView name, StringView source)
	{
		let text = BlankIncludes(source, .. scope .());
		return AS.asc_builder_add_section(builder, scope String(name).CStr(), text.Ptr, (uint)text.Length) >= 0;
	}

	/// `source` with its `#include` lines blanked, into `outText`. Blanking, not removing,
	/// keeps every other line where it was, for errors and breakpoints.
	public static void BlankIncludes(StringView source, String outText)
	{
		let start = outText.Length;
		outText.Append(source);
		int lineStart = start;
		for (int i = start; i <= outText.Length; i++)
		{
			if ((i < outText.Length) && (outText[i] != '\n'))
				continue;
			var first = lineStart;
			while ((first < i) && ((outText[first] == ' ') || (outText[first] == '\t')))
				first++;
			if (StringView(outText, first, i - first).StartsWith("#include"))
			{
				for (int k = first; k < i; k++)
				{
					if (outText[k] != '\r')
						outText[k] = ' ';
				}
			}
			lineStart = i + 1;
		}
	}

	/// The paths `source`'s `#include "<path>"` lines name, as written, in order.
	public static void IncludesOf(StringView source, List<String> outPaths)
	{
		for (var line in source.Split('\n'))
		{
			line.Trim();
			if (!line.StartsWith("#include"))
				continue;
			let open = line.IndexOf('"');
			let close = (open >= 0) ? line.IndexOf('"', open + 1) : -1;
			if (close > open)
				outPaths.Add(new String(line.Substring(open + 1, close - open - 1)));
		}
	}

	public override void DiscardModule(StringView moduleName)
	{
		let module = AS.asc_engine_get_module(mEngine, scope String(moduleName).CStr(), AS.asGM_ONLY_IF_EXISTS);
		if (module != null)
			AS.asc_module_discard(module);
		ForgetBuilder(moduleName);
	}

	public override bool ModuleInUse(StringView moduleName)
	{
		if (AS.asc_engine_get_module(mEngine, scope String(moduleName).CStr(), AS.asGM_ONLY_IF_EXISTS) == null)
			return false;
		// A call under way may run its code, and a call the debugger holds does.
		if ((AS.asc_get_active_context() != null) || ((mDebugger != null) && mDebugger.IsPaused))
			return true;
		for (let o in mObjects)
		{
			if ((o.Type != null) && InModule(AS.asc_typeinfo_get_module_name(o.Type), moduleName))
				return true;
		}
		for (let co in mCoroutines)
		{
			if (InModule(AS.asc_function_get_module_name(co.Function), moduleName))
				return true;
			if ((co.Owner != null) && InModule(AS.asc_typeinfo_get_module_name(AS.asc_object_get_type((AS.ScriptObject*)co.Owner)), moduleName))
				return true;
		}
		for (let d in mDelegates)
		{
			if (InModule(AS.asc_function_get_module_name(d.[Friend]mFunction), moduleName))
				return true;
		}
		return false;
	}

	private static bool InModule(char8* name, StringView moduleName) => (name != null) && (StringView(name) == moduleName);

	private void ForgetBuilder(StringView moduleName)
	{
		if (mBuilders.GetAndRemoveAlt(moduleName) case .Ok(let entry))
		{
			AS.asc_builder_destroy(entry.value);
			delete entry.key;
		}
	}

	/// The first `[metadata]` entry on a class property, without its brackets; empty when it
	/// has none or the module was not built here.
	private void PropertyMetadata(StringView moduleName, int32 typeId, int32 propertyIndex, String outText)
	{
		outText.Clear();
		if (!mBuilders.TryGetValueAlt(moduleName, let builder))
			return;
		if (AS.asc_builder_property_metadata_count(builder, typeId, propertyIndex) <= 0)
			return;
		let text = AS.asc_builder_property_metadata(builder, typeId, propertyIndex, 0);
		if (text != null)
			outText.Append(StringView(text));
	}

	public override bool Call(StringView moduleName, StringView declaration, Span<ScriptValue> args, ref ScriptValue result)
	{
		let module = AS.asc_engine_get_module(mEngine, scope String(moduleName).CStr(), AS.asGM_ONLY_IF_EXISTS);
		if (module == null)
		{
			Problem(scope $"no module {moduleName}");
			return false;
		}
		let fn = AS.asc_module_get_function_by_decl(module, scope String(declaration).CStr());
		if (fn == null)
		{
			Problem(scope $"{moduleName} has no {declaration}");
			return false;
		}
		return Execute(fn, null, args, ref result, declaration);
	}

	/// Runs `fn` on a pooled context, `self` set when it is a method, with the arguments
	/// marshalled by the function's own parameter types and the result by its return type.
	private bool Execute(AS.Function* fn, void* self, Span<ScriptValue> args, ref ScriptValue result, StringView what)
	{
		let ctx = AcquireContext();
		bool held = false;
		defer { if (!held) ReleaseContext(ctx); }
		if (AS.asc_context_prepare(ctx, fn) < 0)
		{
			Problem(scope $"{what}: could not prepare the call");
			return false;
		}
		if (self != null)
			AS.asc_context_set_object(ctx, self);

		let copies = scope List<void*>();
		let strings = scope List<void*>();
		for (int i = 0; i < args.Length; i++)
		{
			int32 typeId = 0;
			uint32 flags = 0;
			AS.asc_function_get_param(fn, (uint32)i, &typeId, &flags, null);
			SetContextArg(ctx, (uint32)i, typeId, flags, args[i], copies, strings);
		}

		// The debugger, when one is attached, may suspend the call at a line: it then owns
		// the context for inspection and resumption, and the call reports as paused. Its line
		// callback checks the budget too.
		if (mDebugger != null)
			mDebugger.Arm(ctx);
		else
			ArmBudget(ctx);
		BeginExecute();
		let state = AS.asc_context_execute(ctx);
		EndExecute();
		if ((state == AS.asEXECUTION_SUSPENDED) && (mDebugger != null)
			&& mDebugger.Adopt(ctx, fn, what, copies, strings))
		{
			held = true;
			return false;
		}
		// Never back to the pool carrying a line callback.
		AS.asc_context_clear_line_callback(ctx);
		FreeArgCopies(copies, strings);
		if (state != AS.asEXECUTION_FINISHED)
		{
			ReportExecution(ctx, state, what);
			return false;
		}

		uint32 returnFlags = 0;
		let returnType = AS.asc_function_get_return_type_id(fn, &returnFlags);
		result = ReadContextReturn(ctx, returnType);
		return true;
	}

	private void FreeArgCopies(List<void*> copies, List<void*> strings)
	{
		for (let p in copies)
			Internal.Free(p);
		for (let p in strings)
		{
			AS.asc_string_destruct(p);
			Internal.Free(p);
		}
		copies.Clear();
		strings.Clear();
	}

	// ---- debugging ----

	public override bool HasDebugger => true;
	public override IScriptDebugger CreateDebugger() => (mDebugger != null) ? null : new AngelScriptDebugger(this);
	public override bool IsDebugPaused => (mDebugger != null) && mDebugger.IsPaused;

	private void AttachDebugger(AngelScriptDebugger debugger) => mDebugger = debugger;
	private void DetachDebugger(AngelScriptDebugger debugger)
	{
		if (mDebugger === debugger)
			mDebugger = null;
	}

	/// The surface type behind an Object or Struct value, null for anything else.
	private ScriptTypeInfo TypeOfValue(ScriptValue value)
	{
		if (value.Kind == .Struct)
			return (value.StructType != null) ? mSurface.Find(value.StructType.GetFullName(.. scope .())) : null;
		if (value.Kind != .Object)
			return null;
		var type = value.AsObject.GetType();
		while (type != null)
		{
			if (let found = mSurface.Find(type.GetFullName(.. scope .())))
				return found;
			type = type.BaseType;
		}
		return null;
	}

	/// A value's display text, for a debugger or a log.
	public static void ValueText(ScriptValue value, String outText)
	{
		switch (value.Kind)
		{
		case .Nil: outText.Append("null");
		case .Bool: outText.Append(value.AsBool ? "true" : "false");
		case .Int: outText.AppendF("{}", value.AsInt);
		case .Float: outText.AppendF("{}", value.AsFloat);
		case .String: outText.AppendF("\"{}\"", value.AsString);
		case .Guid: value.AsGuid.ToString(outText);
		case .Entity: outText.AppendF("entity {}", value.AsEntityRef.Index);
		case .Float2: outText.AppendF("({}, {})", value.AsFloat2.X, value.AsFloat2.Y);
		case .Float3: outText.AppendF("({}, {}, {})", value.AsFloat3.X, value.AsFloat3.Y, value.AsFloat3.Z);
		case .Float4: outText.AppendF("({}, {}, {}, {})", value.AsFloat4.X, value.AsFloat4.Y, value.AsFloat4.Z, value.AsFloat4.W);
		case .Quaternion: outText.AppendF("({}, {}, {}, {})", value.AsQuaternion.X, value.AsQuaternion.Y, value.AsQuaternion.Z, value.AsQuaternion.W);
		case .Color: outText.AppendF("({}, {}, {}, {})", value.AsColor.R, value.AsColor.G, value.AsColor.B, value.AsColor.A);
		case .Object: outText.Append((value.AsObject != null) ? value.AsObject.GetType().GetName(.. scope .()) : "null");
		case .Struct: outText.Append((value.StructType != null) ? value.StructType.GetName(.. scope .()) : "struct");
		case .List: outText.AppendF("list[{}]", (value.AsList != null) ? value.AsList.Count : 0);
		case .Delegate: outText.Append("callback");
		case .Weak:
			let resolved = value.ResolveWeak();
			outText.Append((resolved != null) ? resolved.GetType().GetName(.. scope .()) : "gone");
		case .Counted:
			let counted = value.AsCounted;
			outText.Append((counted != null) ? ((Object)counted).GetType().GetName(.. scope .()) : "null");
		}
	}

	/// `ctx`'s script call stack, innermost first: a paused context's (the debugger) or one that
	/// stopped on an exception (a fault's report).
	public static void StackOf(AS.Context* ctx, List<ScriptStackFrame> outFrames)
	{
		let size = AS.asc_context_get_callstack_size(ctx);
		for (uint32 level = 0; level < size; level++)
		{
			let frame = new ScriptStackFrame();
			char8* section = null;
			frame.Line = AS.asc_context_get_line_number(ctx, level, null, &section);
			if (section != null)
				frame.File.Set(StringView(section));
			let fn = AS.asc_context_get_function(ctx, level);
			frame.Function.Set((fn != null) ? StringView(AS.asc_function_get_declaration(fn, 1, 0, 1)) : "?");
			outFrames.Add(frame);
		}
	}

	private void ReportExecution(AS.Context* ctx, int32 state, StringView what)
	{
		if (state == AS.asEXECUTION_EXCEPTION)
		{
			int32 column = 0;
			char8* section = null;
			let line = AS.asc_context_get_exception_line_number(ctx, &column, &section);
			let problem = scope $"{StringView(section)}({line},{column}): exception: {StringView(AS.asc_context_get_exception_string(ctx))}";
			// The call stack beneath the message, innermost first.
			let frames = scope List<ScriptStackFrame>();
			defer { ClearAndDeleteItems!(frames); }
			StackOf(ctx, frames);
			for (let frame in frames)
				problem.AppendF("\n  at {} ({}:{})", frame.Function, frame.File, frame.Line);
			Problem(problem);
		}
		else if (state == AS.asEXECUTION_ABORTED)
		{
			Problem(scope $"{what}: script call stopped: ran past its {Budget.CallSeconds} s budget");
		}
		else
		{
			Problem(scope $"{what}: execution ended in state {state}");
		}
	}

	// ==================== script objects ====================

	public override ScriptObject Instantiate(StringView moduleName, StringView className)
	{
		let module = AS.asc_engine_get_module(mEngine, scope String(moduleName).CStr(), AS.asGM_ONLY_IF_EXISTS);
		if (module == null)
		{
			Problem(scope $"no module {moduleName}");
			return null;
		}
		let type = AS.asc_module_get_type_info_by_name(module, scope String(className).CStr());
		if (type == null)
		{
			Problem(scope $"{moduleName} has no class {className}");
			return null;
		}
		// The default factory: `Mover @Mover()`.
		let factory = AS.asc_typeinfo_get_factory_by_decl(type, scope $"{className} @{className}()".CStr());
		if (factory == null)
		{
			Problem(scope $"{className} has no default constructor");
			return null;
		}

		let ctx = AcquireContext();
		defer ReleaseContext(ctx);
		if (AS.asc_context_prepare(ctx, factory) < 0)
			return null;
		// A constructor can loop as well as a method.
		ArmBudget(ctx);
		BeginExecute();
		let state = AS.asc_context_execute(ctx);
		EndExecute();
		AS.asc_context_clear_line_callback(ctx);
		if (state != AS.asEXECUTION_FINISHED)
		{
			ReportExecution(ctx, state, scope $"constructing {className}");
			return null;
		}
		let made = (AS.ScriptObject*)AS.asc_context_get_return_object(ctx);
		if (made == null)
			return null;
		// The context's reference dies with Unprepare; this one is the host's.
		AS.asc_object_add_ref(made);

		let object = new AngelScriptObject();
		object.Runtime = this;
		object.ClassName.Set(className);
		object.Object = made;
		object.Type = type;
		let count = AS.asc_object_get_property_count(made);
		for (uint32 i = 0; i < count; i++)
		{
			var property = AngelScriptObject.Property();
			property.Index = i;
			property.TypeId = AS.asc_object_get_property_type_id(made, i);
			object.Properties[new String(StringView(AS.asc_object_get_property_name(made, i)))] = property;
		}
		mObjects.Add(object);
		return object;
	}

	public override void Release(ScriptObject object)
	{
		let o = object as AngelScriptObject;
		if (o == null)
			return;
		CancelCoroutinesFor(o);
		mObjects.Remove(o);
		delete o;
	}

	public override bool DescribeClass(StringView moduleName, StringView className, List<ScriptMemberDesc> outMembers)
	{
		let module = AS.asc_engine_get_module(mEngine, scope String(moduleName).CStr(), AS.asGM_ONLY_IF_EXISTS);
		let type = (module != null) ? AS.asc_module_get_type_info_by_name(module, scope String(className).CStr()) : null;
		if (type == null)
			return false;

		let classTypeId = AS.asc_typeinfo_get_type_id(type);
		let metadata = scope String();
		let properties = AS.asc_typeinfo_get_property_count(type);
		for (uint32 i = 0; i < properties; i++)
		{
			// An annotated field is reported whatever its access: the annotation, not the
			// access, is what makes a property.
			PropertyMetadata(moduleName, classTypeId, (int32)i, metadata);
			int32 isPrivate = 0, isProtected = 0;
			AS.asc_typeinfo_get_property_access(type, i, &isPrivate, &isProtected);
			if (((isPrivate != 0) || (isProtected != 0)) && metadata.IsEmpty)
				continue;
			char8* name = null;
			int32 typeId = 0;
			int32 offset = 0;
			AS.asc_typeinfo_get_property(type, i, &name, &typeId, &offset);
			let m = new ScriptMemberDesc();
			m.Name.Set(StringView(name));
			m.Kind = KindOfTypeId(typeId);
			m.TypeName.Set(StringView(AS.asc_engine_get_type_declaration(mEngine, typeId, 0)));
			m.Metadata.Set(metadata);
			outMembers.Add(m);
		}
		let methods = AS.asc_typeinfo_get_method_count(type);
		for (uint32 i = 0; i < methods; i++)
		{
			let fn = AS.asc_typeinfo_get_method_by_index(type, i);
			let m = new ScriptMemberDesc();
			m.Name.Set(StringView(AS.asc_function_get_name(fn)));
			m.Arity = (int)AS.asc_function_get_param_count(fn);
			outMembers.Add(m);
		}
		return true;
	}

	/// The kind a value of AngelScript type `typeId` crosses as.
	private ScriptValueKind KindOfTypeId(int32 typeId)
	{
		switch (typeId)
		{
		case AS.asTYPEID_BOOL: return .Bool;
		case AS.asTYPEID_INT8, AS.asTYPEID_INT16, AS.asTYPEID_INT32, AS.asTYPEID_INT64,
			AS.asTYPEID_UINT8, AS.asTYPEID_UINT16, AS.asTYPEID_UINT32, AS.asTYPEID_UINT64:
			return .Int;
		case AS.asTYPEID_FLOAT, AS.asTYPEID_DOUBLE: return .Float;
		default:
			if ((typeId & AS.asTYPEID_MASK_OBJECT) == 0)
				return .Int; // an enum
			if ((typeId & AS.asTYPEID_OBJHANDLE) != 0)
			{
				if ((typeId & AS.asTYPEID_SCRIPTOBJECT) != 0)
					return .Nil;
				if (WeakTypeOfId(typeId) != null)
					return .Weak;
				return (CountedTypeOfId(typeId) != null) ? .Counted : .Object;
			}
			let name = StringView(AS.asc_typeinfo_get_name(AS.asc_engine_get_type_info_by_id(mEngine, typeId)));
			if (name == "string")
				return .String;
			let inlineKind = InlineKindOf(name);
			if (inlineKind != .Nil)
				return inlineKind;
			return mByName.ContainsKey(scope String(name)) ? .Struct : .Nil;
		}
	}

	/// The surface type of an AngelScript type id when it is a weak handle's, a scene's system,
	/// manager or facade's included, else null: what tells a box apart from a Beef object behind
	/// a handle slot.
	private ScriptTypeInfo WeakTypeOfId(int32 typeId)
		=> ClassTypeOfId(typeId, .Weak) ?? ClassTypeOfId(typeId, .SceneSystem) ?? ClassTypeOfId(typeId, .ComponentManager) ?? ClassTypeOfId(typeId, .SceneFacade);

	/// The surface type of an AngelScript type id when it is a counted class's, else null: a
	/// handle slot whose object has its count kept.
	private ScriptTypeInfo CountedTypeOfId(int32 typeId) => ClassTypeOfId(typeId, .Counted);

	private ScriptTypeInfo ClassTypeOfId(int32 typeId, ScriptTypeRole role)
	{
		if (((typeId & AS.asTYPEID_MASK_OBJECT) == 0) || ((typeId & AS.asTYPEID_SCRIPTOBJECT) != 0))
			return null;
		let info = AS.asc_engine_get_type_info_by_id(mEngine, typeId & ~AS.asTYPEID_OBJHANDLE);
		if (info == null)
			return null;
		if (mByName.TryGetValue(scope String(StringView(AS.asc_typeinfo_get_name(info))), let t) && (t.Kind == .Class) && (t.Role == role))
			return t;
		return null;
	}

	public override bool HasMethod(ScriptObject object, StringView name, int arity)
	{
		let o = object as AngelScriptObject;
		if (o == null)
			return false;
		let count = AS.asc_typeinfo_get_method_count(o.Type);
		for (uint32 i = 0; i < count; i++)
		{
			let m = AS.asc_typeinfo_get_method_by_index(o.Type, i);
			if ((StringView(AS.asc_function_get_name(m)) == name) && (AS.asc_function_get_param_count(m) == (uint32)arity))
				return true;
		}
		return false;
	}

	/// The method of that name whose parameters take these arguments: the count, and each
	/// argument's kind against the parameter's type.
	private AS.Function* FindMethod(AngelScriptObject o, StringView name, Span<ScriptValue> args)
	{
		let count = AS.asc_typeinfo_get_method_count(o.Type);
		for (uint32 i = 0; i < count; i++)
		{
			let m = AS.asc_typeinfo_get_method_by_index(o.Type, i);
			if ((StringView(AS.asc_function_get_name(m)) != name) || (AS.asc_function_get_param_count(m) != (uint32)args.Length))
				continue;
			if (Fits(m, args))
				return m;
		}
		return null;
	}

	/// Whether each argument's kind fits its parameter of `fn`.
	private bool Fits(AS.Function* fn, Span<ScriptValue> args)
	{
		for (int a = 0; a < args.Length; a++)
		{
			int32 typeId = 0;
			uint32 flags = 0;
			AS.asc_function_get_param(fn, (uint32)a, &typeId, &flags, null);
			if (!Takes(typeId, args[a]))
				return false;
		}
		return true;
	}

	/// Whether a parameter of `typeId` takes the value: a number into any numeric type, the
	/// rest by kind.
	private bool Takes(int32 typeId, ScriptValue value)
	{
		switch (typeId)
		{
		case AS.asTYPEID_BOOL: return value.Kind == .Bool;
		case AS.asTYPEID_INT8, AS.asTYPEID_INT16, AS.asTYPEID_INT32, AS.asTYPEID_INT64,
			AS.asTYPEID_UINT8, AS.asTYPEID_UINT16, AS.asTYPEID_UINT32, AS.asTYPEID_UINT64:
			return value.Kind == .Int;
		case AS.asTYPEID_FLOAT, AS.asTYPEID_DOUBLE: return value.IsNumber;
		default:
			if ((typeId & AS.asTYPEID_MASK_OBJECT) == 0)
				return value.Kind == .Int; // an enum
			if ((typeId & AS.asTYPEID_OBJHANDLE) != 0)
			{
				if (WeakTypeOfId(typeId) != null)
					return (value.Kind == .Weak) || value.IsNil;
				if (CountedTypeOfId(typeId) != null)
					return (value.Kind == .Counted) || value.IsNil;
				return (value.Kind == .Object) || value.IsNil;
			}
			let name = StringView(AS.asc_typeinfo_get_name(AS.asc_engine_get_type_info_by_id(mEngine, typeId)));
			if (name == "string")
				return value.Kind == .String;
			let inlineKind = InlineKindOf(name);
			if (inlineKind != .Nil)
				return value.Kind == inlineKind;
			if (mByName.TryGetValue(scope String(name), let t))
				return value.Kind == .Struct;
			return false;
		}
	}

	public override bool Invoke(ScriptObject object, StringView name, Span<ScriptValue> args, ref ScriptValue result)
	{
		let o = object as AngelScriptObject;
		if (o == null)
			return false;
		// What this object found before, by name and count, the arguments' kinds checked again
		// (an overload of the same count takes other kinds).
		AngelScriptObject.FoundMethod found = null;
		for (let f in o.Found)
		{
			if ((f.Arity == args.Length) && (f.Name == name) && Fits(f.Function, args))
			{
				found = f;
				break;
			}
		}
		if (found == null)
		{
			let fn = FindMethod(o, name, args);
			if (fn == null)
			{
				Problem(scope $"{o.ClassName} has no {name} taking these {args.Length} arguments");
				return false;
			}
			found = new .();
			found.Name.Set(name);
			found.Arity = args.Length;
			found.Function = fn;
			found.What.AppendF("{}.{}", o.ClassName, name);
			o.Found.Add(found);
		}
		return Execute(found.Function, o.Object, args, ref result, found.What);
	}

	public override bool GetProperty(ScriptObject object, StringView name, ref ScriptValue value)
	{
		let o = object as AngelScriptObject;
		if (o == null)
			return false;
		if (!o.Properties.TryGetValue(scope String(name), let property))
			return false;
		let address = AS.asc_object_get_address_of_property(o.Object, property.Index);
		value = ReadTyped(property.TypeId, address);
		return true;
	}

	public override bool SetProperty(ScriptObject object, StringView name, ScriptValue value)
	{
		let o = object as AngelScriptObject;
		if (o == null)
			return false;
		if (!o.Properties.TryGetValue(scope String(name), let property))
			return false;
		if (!Takes(property.TypeId, value))
			return false;
		let address = AS.asc_object_get_address_of_property(o.Object, property.Index);
		WriteTyped(property.TypeId, address, value);
		return true;
	}

	/// A value of AngelScript type `typeId` out of memory, as a ScriptValue.
	private ScriptValue ReadTyped(int32 typeId, void* address)
	{
		switch (typeId)
		{
		case AS.asTYPEID_BOOL: return .FromBool(*(bool*)address);
		case AS.asTYPEID_INT8: return .FromInt(*(int8*)address);
		case AS.asTYPEID_INT16: return .FromInt(*(int16*)address);
		case AS.asTYPEID_INT32: return .FromInt(*(int32*)address);
		case AS.asTYPEID_INT64: return .FromInt(*(int64*)address);
		case AS.asTYPEID_UINT8: return .FromInt(*(uint8*)address);
		case AS.asTYPEID_UINT16: return .FromInt(*(uint16*)address);
		case AS.asTYPEID_UINT32: return .FromInt(*(uint32*)address);
		case AS.asTYPEID_UINT64: return .FromInt((int64)*(uint64*)address);
		case AS.asTYPEID_FLOAT: return .FromFloat(*(float*)address);
		case AS.asTYPEID_DOUBLE: return .FromFloat(*(double*)address);
		default:
			if ((typeId & AS.asTYPEID_MASK_OBJECT) == 0)
				return .FromInt(*(int32*)address); // an enum
			if ((typeId & AS.asTYPEID_OBJHANDLE) != 0)
			{
				// A handle slot holds the pointer; a script object is not a Beef object.
				let target = *(void**)address;
				if ((target == null) || ((typeId & AS.asTYPEID_SCRIPTOBJECT) != 0))
					return .Nil;
				// A weak handle is the backend's box, not a Beef object.
				if (WeakTypeOfId(typeId) != null)
					return .FromWeakRef(((WeakHandle*)target).Ref);
				// A counted object, borrowed from the slot that holds its reference.
				if (CountedTypeOfId(typeId) != null)
					return .FromCounted(CountedAt(target));
				return .FromObject(Internal.UnsafeCastToObject(target));
			}
			let name = StringView(AS.asc_typeinfo_get_name(AS.asc_engine_get_type_info_by_id(mEngine, typeId)));
			if (name == "string")
				return .FromString(StringOf(address));
			let inlineKind = InlineKindOf(name);
			if (inlineKind != .Nil)
				return ReadValue(address, inlineKind, "");
			if (mByName.TryGetValue(scope String(name), let t))
				return .FromStruct(address, t.BeefType);
			return .Nil;
		}
	}

	private void WriteTyped(int32 typeId, void* address, ScriptValue value)
	{
		switch (typeId)
		{
		case AS.asTYPEID_BOOL: *(bool*)address = value.AsBool;
		case AS.asTYPEID_INT8, AS.asTYPEID_UINT8: *(uint8*)address = (uint8)value.AsInt;
		case AS.asTYPEID_INT16, AS.asTYPEID_UINT16: *(uint16*)address = (uint16)value.AsInt;
		case AS.asTYPEID_INT32, AS.asTYPEID_UINT32: *(uint32*)address = (uint32)value.AsInt;
		case AS.asTYPEID_INT64, AS.asTYPEID_UINT64: *(uint64*)address = (uint64)value.AsInt;
		case AS.asTYPEID_FLOAT: *(float*)address = (float)value.AsNumber;
		case AS.asTYPEID_DOUBLE: *(double*)address = value.AsNumber;
		default:
			if ((typeId & AS.asTYPEID_MASK_OBJECT) == 0)
			{
				*(int32*)address = (int32)value.AsInt;
				return;
			}
			if ((typeId & AS.asTYPEID_OBJHANDLE) != 0)
			{
				// A weak handle is a counted box: a new one in, the old one's reference dropped.
				if (WeakTypeOfId(typeId) != null)
				{
					let old = (WeakHandle*)*(void**)address;
					*(void**)address = (value.Kind == .Weak) ? NewWeakBox(value.Data.Weak) : null;
					if (old != null)
						ReleaseWeakBox(old);
					return;
				}
				// A counted handle: the new object's reference taken before the old one's is
				// dropped, so writing a slot its own object again never frees it.
				if (CountedTypeOfId(typeId) != null)
				{
					let previous = *(void**)address;
					let counted = value.AsCounted;
					counted?.AddRef();
					*(void**)address = PointerOf(counted);
					if (previous != null)
						CountedAt(previous).ReleaseRef();
					return;
				}
				// Only uncounted engine handles are written; a script object handle would
				// need its count kept.
				if ((typeId & AS.asTYPEID_SCRIPTOBJECT) == 0)
					*(void**)address = (value.AsObject != null) ? Internal.UnsafeCastToPtr(value.AsObject) : null;
				return;
			}
			let name = StringView(AS.asc_typeinfo_get_name(AS.asc_engine_get_type_info_by_id(mEngine, typeId)));
			if (name == "string")
			{
				AS.asc_string_assign(address, value.AsString.Ptr, (uint)value.AsString.Length);
				return;
			}
			let inlineKind = InlineKindOf(name);
			if (inlineKind != .Nil)
			{
				WriteValue(address, inlineKind, "", value);
				return;
			}
			if (mByName.TryGetValue(scope String(name), let t) && (value.AsStruct != null))
				Internal.MemCpy(address, value.AsStruct, t.Size);
		}
	}

	// ==================== coroutines ====================

	public override int CoroutineCount => mCoroutines.Count;

	/// `startCoroutine(fn)`: a context of its own, run at once until it waits or ends.
	private void StartCoroutine(AS.Function* fn)
	{
		if (fn == null)
		{
			AS.asc_set_active_exception("startCoroutine: null function");
			return;
		}
		let co = new Coroutine();
		co.Context = AS.asc_engine_create_context(mEngine);
		co.Function = fn;
		AS.asc_function_add_ref(fn);
		co.Owner = AS.asc_function_get_delegate_object(fn);
		AS.asc_context_set_user_data(co.Context, Internal.UnsafeCastToPtr(co));
		// Its own context, armed for its life: each run between its waits is a call.
		ArmBudget(co.Context);
		mCoroutines.Add(co);
		if (AS.asc_context_prepare(co.Context, fn) < 0)
		{
			Drop(co);
			return;
		}
		Step(co);
	}

	/// `wait(seconds)` on a coroutine's own context: bank the wait and suspend. On any
	/// other context there is nothing to suspend, and the wait is a fault.
	private void WaitCurrent(float seconds)
	{
		let active = AS.asc_get_active_context();
		let co = (active != null) ? Internal.UnsafeCastToObject(AS.asc_context_get_user_data(active)) as Coroutine : null;
		if (co == null)
		{
			AS.asc_set_active_exception("wait() is only valid inside a coroutine");
			return;
		}
		co.Remaining = seconds;
		co.Suspending = true;
		AS.asc_context_suspend(active);
	}

	/// Resumes the coroutine: it runs until it waits again, finishes or faults, or a debugger
	/// pauses it, which then holds it until it runs it on.
	private void Step(Coroutine co)
	{
		co.Running = true;
		co.Suspending = false;
		// Armed for each run between its waits: the debugger's line callback (which checks the
		// budget too) when one is attached, a debugger attached since its last run included,
		// else the budget's.
		if (mDebugger != null)
			mDebugger.Arm(co.Context);
		else
			ArmBudget(co.Context);
		BeginExecute();
		let state = AS.asc_context_execute(co.Context);
		EndExecute();
		co.Running = false;
		if ((mDebugger != null) && (state == AS.asEXECUTION_SUSPENDED))
		{
			if (co.Dropped)
				mDebugger.Forget(co.Context); // cancelled by what it ran: nothing to hold
			else if (mDebugger.AdoptCoroutine(co.Context))
			{
				co.Held = true;
				return;
			}
		}
		Settle(co, state);
	}

	/// After a run of the coroutine that did not leave it held: a fault reported, and the
	/// coroutine dropped unless it waits again.
	private void Settle(Coroutine co, int32 state)
	{
		if ((state != AS.asEXECUTION_SUSPENDED) && (state != AS.asEXECUTION_FINISHED))
			ReportExecution(co.Context, state, "coroutine");
		if (co.Dropped)
		{
			// Cancelled by a script it ran (its owner destroyed): it is retired, and freed
			// here unless the scheduler's walk still holds it.
			if (!mAdvancing)
				FreeRetired();
			return;
		}
		if (state != AS.asEXECUTION_SUSPENDED)
			Drop(co);
	}

	/// Takes the coroutine out of the schedule. One that is running, or that the
	/// scheduler's snapshot holds, is only retired: freeing it would release a context still
	/// executing, or let a coroutine started meanwhile reuse its address in the snapshot.
	private void Drop(Coroutine co)
	{
		if (co.Held)
		{
			// Cancelled under the debugger: it lets go.
			co.Held = false;
			if (mDebugger != null)
				mDebugger.Forget(co.Context);
		}
		mCoroutines.Remove(co);
		co.Dropped = true;
		if (co.Running || mAdvancing)
		{
			mRetired.Add(co);
			return;
		}
		Free(co);
	}

	private void Free(Coroutine co)
	{
		ReleaseCoroutineContext(co);
		delete co;
	}

	/// Lets go of a coroutine's own context and function. Its line callback goes first: the
	/// shim keeps the callback's record with the context, and only clearing it frees that.
	private static void ReleaseCoroutineContext(Coroutine co)
	{
		AS.asc_context_abort(co.Context);
		AS.asc_context_clear_line_callback(co.Context);
		AS.asc_context_release(co.Context);
		AS.asc_function_release(co.Function);
	}

	/// Frees the retired coroutines nothing runs any more.
	private void FreeRetired()
	{
		for (int i = mRetired.Count - 1; i >= 0; i--)
		{
			let co = mRetired[i];
			if (co.Running)
				continue;
			mRetired.RemoveAt(i);
			Free(co);
		}
	}

	public override void AdvanceCoroutines(double deltaSeconds)
	{
		// A walk under way already covers every coroutine.
		if (mAdvancing)
			return;
		// A snapshot: a step may start another coroutine, or end or cancel any of them. A
		// dropped one stays allocated, retired, until the walk ends, so its flag is safe to read.
		mAdvancing = true;
		let due = scope List<Coroutine>();
		for (let co in mCoroutines)
		{
			if (co.Held)
				continue; // waits for the debugger
			co.Remaining -= deltaSeconds;
			if (co.Remaining <= 0)
				due.Add(co);
		}
		for (let co in due)
		{
			if (!co.Dropped)
				Step(co);
		}
		mAdvancing = false;
		FreeRetired();
	}

	/// The coroutine running on `ctx`; null for a call's context.
	private static Coroutine CoroutineOf(AS.Context* ctx)
	{
		let data = AS.asc_context_get_user_data(ctx);
		return (data != null) ? Internal.UnsafeCastToObject(data) as Coroutine : null;
	}

	/// Whether `ctx` is a coroutine whose `wait` is suspending it.
	private bool IsWaitSuspending(AS.Context* ctx)
	{
		let co = CoroutineOf(ctx);
		return (co != null) && co.Suspending;
	}

	/// The debugger runs a held coroutine on (`running`), or has run it.
	private void HeldCoroutineRunning(AS.Context* ctx, bool running)
	{
		let co = CoroutineOf(ctx);
		if (co == null)
			return;
		co.Running = running;
		if (running)
			co.Suspending = false;
	}

	/// The debugger ran a held coroutine on and it did not pause again: it waits again, or it
	/// ended and is reported and dropped, as from the scheduler.
	private void ReleaseHeldCoroutine(AS.Context* ctx, int32 state)
	{
		let co = CoroutineOf(ctx);
		if (co == null)
			return;
		co.Held = false;
		AS.asc_context_clear_line_callback(ctx);
		Settle(co, state);
	}

	/// The debugger holding the coroutine on `ctx` is going away: the coroutine goes too.
	private void DropHeldCoroutine(AS.Context* ctx)
	{
		let co = CoroutineOf(ctx);
		if (co == null)
			return;
		co.Held = false;
		AS.asc_context_clear_line_callback(ctx);
		if (!co.Dropped)
			Drop(co);
	}

	public override void CancelCoroutinesFor(ScriptObject object)
	{
		let o = object as AngelScriptObject;
		if (o == null)
			return;
		for (int i = mCoroutines.Count - 1; i >= 0; i--)
		{
			if (mCoroutines[i].Owner == o.Object)
				Drop(mCoroutines[i]);
		}
	}

	private void SetContextArg(AS.Context* mContext, uint32 i, int32 typeId, uint32 flags, ScriptValue value,
		List<void*> mArgCopies, List<void*> mArgStrings)
	{
		switch (typeId)
		{
		case AS.asTYPEID_BOOL, AS.asTYPEID_INT8, AS.asTYPEID_UINT8:
			AS.asc_context_set_arg_byte(mContext, i, (value.Kind == .Bool) ? (value.AsBool ? 1 : 0) : (uint8)value.AsInt);
		case AS.asTYPEID_INT16, AS.asTYPEID_UINT16:
			AS.asc_context_set_arg_word(mContext, i, (uint16)value.AsInt);
		case AS.asTYPEID_INT32, AS.asTYPEID_UINT32:
			AS.asc_context_set_arg_dword(mContext, i, (uint32)value.AsInt);
		case AS.asTYPEID_INT64, AS.asTYPEID_UINT64:
			AS.asc_context_set_arg_qword(mContext, i, (uint64)value.AsInt);
		case AS.asTYPEID_FLOAT:
			AS.asc_context_set_arg_float(mContext, i, (float)value.AsNumber);
		case AS.asTYPEID_DOUBLE:
			AS.asc_context_set_arg_double(mContext, i, value.AsNumber);
		default:
			if ((typeId & AS.asTYPEID_MASK_OBJECT) == 0)
			{
				// An enum.
				AS.asc_context_set_arg_dword(mContext, i, (uint32)value.AsInt);
			}
			else if ((typeId & AS.asTYPEID_OBJHANDLE) != 0)
			{
				if (WeakTypeOfId(typeId) != null)
				{
					// SetArgObject takes the context's own reference on a handle argument, which
					// the call releases when it is done with it (as_context.cpp, SetArgObject;
					// SetArgAddress takes none). The new box's reference is dropped at once, so
					// the context's is the only one.
					if (value.Kind == .Weak)
					{
						let @box = NewWeakBox(value.Data.Weak);
						AS.asc_context_set_arg_object(mContext, i, @box);
						ReleaseWeakBox(@box);
					}
					else
					{
						AS.asc_context_set_arg_address(mContext, i, null);
					}
				}
				else if (CountedTypeOfId(typeId) != null)
				{
					// SetArgObject takes the context's own reference, as for a weak box, which
					// the call releases; the value stays borrowed.
					let counted = value.AsCounted;
					if (counted != null)
						AS.asc_context_set_arg_object(mContext, i, PointerOf(counted));
					else
						AS.asc_context_set_arg_address(mContext, i, null);
				}
				else
				{
					AS.asc_context_set_arg_address(mContext, i, (value.AsObject != null) ? Internal.UnsafeCastToPtr(value.AsObject) : null);
				}
			}
			else if (value.Kind == .Struct)
			{
				AS.asc_context_set_arg_object(mContext, i, value.AsStruct);
			}
			else if (value.Kind == .String)
			{
				let s = Internal.Malloc((int)AS.asc_string_size());
				AS.asc_string_construct(s, value.AsString.Ptr, (uint)value.AsString.Length);
				mArgStrings.Add(s);
				AS.asc_context_set_arg_object(mContext, i, s);
			}
			else
			{
				// An inline value type, by a copy that lives until the call returns.
				let copy = Internal.Malloc(sizeof(ScriptValueData));
				*(ScriptValueData*)copy = value.Data;
				mArgCopies.Add(copy);
				AS.asc_context_set_arg_object(mContext, i, copy);
			}
		}
	}

	private ScriptValue ReadContextReturn(AS.Context* mContext, int32 typeId)
	{
		switch (typeId)
		{
		case AS.asTYPEID_VOID: return .Nil;
		case AS.asTYPEID_BOOL: return .FromBool(AS.asc_context_get_return_byte(mContext) != 0);
		case AS.asTYPEID_INT8: return .FromInt((int8)AS.asc_context_get_return_byte(mContext));
		case AS.asTYPEID_UINT8: return .FromInt(AS.asc_context_get_return_byte(mContext));
		case AS.asTYPEID_INT16: return .FromInt((int16)AS.asc_context_get_return_word(mContext));
		case AS.asTYPEID_UINT16: return .FromInt(AS.asc_context_get_return_word(mContext));
		case AS.asTYPEID_INT32: return .FromInt((int32)AS.asc_context_get_return_dword(mContext));
		case AS.asTYPEID_UINT32: return .FromInt(AS.asc_context_get_return_dword(mContext));
		case AS.asTYPEID_INT64: return .FromInt((int64)AS.asc_context_get_return_qword(mContext));
		case AS.asTYPEID_UINT64: return .FromInt((int64)AS.asc_context_get_return_qword(mContext));
		case AS.asTYPEID_FLOAT: return .FromFloat(AS.asc_context_get_return_float(mContext));
		case AS.asTYPEID_DOUBLE: return .FromFloat(AS.asc_context_get_return_double(mContext));
		default:
			if ((typeId & AS.asTYPEID_MASK_OBJECT) == 0)
				return .FromInt((int32)AS.asc_context_get_return_dword(mContext));
			if ((typeId & AS.asTYPEID_OBJHANDLE) != 0)
			{
				let returned = AS.asc_context_get_return_address(mContext);
				// A weak handle's box dies with Unprepare; the value only borrows its table.
				if (WeakTypeOfId(typeId) != null)
					return (returned != null) ? .FromWeakRef(((WeakHandle*)returned).Ref) : .Nil;
				// A counted object's context reference dies with Unprepare too: one taken here
				// keeps it for the caller, released with the call that consumes the result, or
				// with the context.
				if (CountedTypeOfId(typeId) != null)
				{
					let counted = CountedAt(returned);
					if (counted != null)
					{
						counted.AddRef();
						mCallContext.ReleaseAfterCall(counted);
					}
					return .FromCounted(counted);
				}
				return .FromObject(Internal.UnsafeCastToObject(returned));
			}
			// A value type: known by its name.
			let name = StringView(AS.asc_typeinfo_get_name(AS.asc_engine_get_type_info_by_id(mEngine, typeId)));
			let memory = AS.asc_context_get_return_object(mContext);
			if (name == "string")
			{
				// Copied out: the context's return value dies with Unprepare.
				let s = new String(StringOf(memory));
				mOwned.Add(s);
				return .FromString(s);
			}
			let inlineKind = InlineKindOf(name);
			if (inlineKind != .Nil)
				return ReadValue(memory, inlineKind, "");
			if (mByName.TryGetValue(scope String(name), let t))
			{
				// Copied into scratch: the return object dies with Unprepare.
				let copy = mCallContext.AllocScratch(t.Size, t.Align);
				Internal.MemCpy(copy, memory, t.Size);
				return .FromStruct(copy, t.BeefType);
			}
			return .Nil;
		}
	}
}
