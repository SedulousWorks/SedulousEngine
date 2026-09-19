using System;
using System.Collections;
using AngelScript;
using Sedulous.Core;
using Sedulous.Scene;
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
///  - an entity is a value carrying its handle AND its scene, so a call on it resolves in
///    that scene however many scenes there are; a component is a value holding the entity:
///    `MeshComponent(entity).Visible`;
///  - a scene system or component manager is a read only property on Scene named for it
///    (its display name, else its type name without the role suffix): `scene.Physics.RayCast(...)`;
///    the handle is the scene's own instance, and a script may keep it;
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
	private AS.Engine* mEngine = null;
	/// Execution contexts, one per call in flight: a script calling the engine calling a
	/// script needs a second, so they are pooled rather than one.
	private List<AS.Context*> mFreeContexts = new .() ~ delete _;
	private List<AS.Context*> mAllContexts = new .() ~ delete _;

	/// One live coroutine: its own context, the seconds still to wait, and the object it
	/// is a method of, so that object's teardown cancels it.
	private class Coroutine
	{
		public AS.Context* Context;
		public AS.Function* Function;
		public double Remaining;
		public void* Owner;
	}
	private List<Coroutine> mCoroutines = new .() ~ DeleteContainerAndItems!(_);
	/// Objects handed out by Instantiate, released with the runtime if the host did not.
	private List<AngelScriptObject> mObjects = new .() ~ DeleteContainerAndItems!(_);
	private AngelScriptCallContext mCallContext = new .() ~ delete _;
	private List<AngelScriptBinding> mBindings = new .() ~ DeleteContainerAndItems!(_);
	/// Objects factories made for scripts, freed with the runtime.
	private List<Object> mOwned = new .() ~ DeleteContainerAndItems!(_);
	/// The per role-type handle a global property points at: a non-null token, since the
	/// thunk resolves the real system from the context.
	private List<void*> mTokens = new .() ~ delete _;
	/// The global handle names taken, so a later one is not refused.
	private HashSet<String> mHandleNames = new .() ~ DeleteContainerAndItems!(_);
	/// The properties on Scene taken, likewise.
	private HashSet<String> mSceneProperties = new .() ~ DeleteContainerAndItems!(_);
	/// Surface types by their AngelScript name, for declarations.
	private Dictionary<String, ScriptTypeInfo> mByName = new .() ~ DeleteDictionaryAndKeys!(_);

	public override StringView Name => "AngelScript";
	public override ScriptCallContext Context => mCallContext;
	public AngelScriptCallContext CallContext => mCallContext;

	public this()
	{
		mEngine = AS.asc_engine_create();
		AS.asc_engine_set_message_callback(mEngine, => OnMessage, Internal.UnsafeCastToPtr(this));
		AS.asc_engine_set_generic_callback(mEngine, => OnGeneric, Internal.UnsafeCastToPtr(this));
		// Value types by non-const reference, for `&out` and `&inout` on them.
		AS.asc_engine_set_property(mEngine, AS.asEP_ALLOW_UNSAFE_REFERENCES, 1);
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

	/// `startCoroutine(fn)` and `wait(seconds)`: the scheduler's surface. A coroutine is any
	/// `void f()`, a delegate to an object's method included.
	private void DeclareCoroutines()
	{
		AS.asc_engine_register_funcdef(mEngine, "void ScriptCoroutine()");
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
	}

	/// BORROWED: the debugger in force, which self registers and detaches.
	private AngelScriptDebugger mDebugger = null;

	public ~this()
	{
		if (mDebugger != null)
			mDebugger.RuntimeGone();
		for (let co in mCoroutines)
		{
			AS.asc_context_abort(co.Context);
			AS.asc_context_release(co.Context);
			AS.asc_function_release(co.Function);
		}
		// The objects before the engine that owns their memory.
		ClearAndDeleteItems!(mObjects);
		for (let ctx in mAllContexts)
			AS.asc_context_release(ctx);
		AS.asc_engine_release(mEngine);
	}

	private static void OnMessage(char8* section, int32 row, int32 col, int32 type, char8* message, void* user)
	{
		let self = Internal.UnsafeCastToObject(user) as AngelScriptRuntime;
		let kind = (type == AS.asMSGTYPE_ERROR) ? "error" : ((type == AS.asMSGTYPE_WARNING) ? "warning" : "info");
		self.Problem(scope $"{StringView(section)}({row},{col}): {kind}: {StringView(message)}");
	}

	// ==================== binding ====================

	public override void Bind(ScriptSurface surface, Span<StringView> domains = default)
	{
		base.Bind(surface, domains);

		// Declare every type before any member, since a member's declaration names types.
		for (let t in surface.Types)
		{
			if (InBoundDomains(t))
				DeclareType(t);
		}
		for (let t in surface.Types)
		{
			if (InBoundDomains(t))
				BindMembers(t);
		}
	}

	/// The AngelScript name of a surface type: its bare name, except the entity handle,
	/// which is `Entity` to a script.
	private static StringView AsName(ScriptTypeInfo t)
		=> (t.FullName == "Sedulous.Scene.EntityHandle") ? "Entity" : t.Name;

	private void DeclareType(ScriptTypeInfo t)
	{
		switch (t.Kind)
		{
		case .Global:
			return;
		case .Enum:
			if (Check(AS.asc_engine_register_enum(mEngine, scope String(AsName(t)).CStr()), t.FullName))
			{
				for (let v in t.EnumValues)
					Check(AS.asc_engine_register_enum_value(mEngine, scope String(AsName(t)).CStr(), scope String(v.Name).CStr(), (int32)v.Value), t.FullName);
				mByName[new String(AsName(t))] = t;
			}
		case .Struct:
			// Already in the language: one of the inline kinds declared up front.
			if (AS.asc_engine_get_type_info_by_name(mEngine, scope String(AsName(t)).CStr()) != null)
			{
				mByName[new String(AsName(t))] = t;
				return;
			}
			// A component is held by its entity; any other struct by its own bytes.
			let size = (t.Role == .Component) ? (int32)sizeof(ScriptEntity) : t.Size;
			let flags = AS.asOBJ_VALUE | AS.asOBJ_POD | AS.asOBJ_APP_CLASS | ((t.Align >= 8) ? AS.asOBJ_APP_CLASS_ALIGN8 : 0);
			if (Check(AS.asc_engine_register_object_type(mEngine, scope String(AsName(t)).CStr(), size, flags), t.FullName))
				mByName[new String(AsName(t))] = t;
		case .Class:
			if (Check(AS.asc_engine_register_object_type(mEngine, scope String(AsName(t)).CStr(), 0, AS.asOBJ_REF | AS.asOBJ_NOCOUNT), t.FullName))
				mByName[new String(AsName(t))] = t;
		}
	}

	private void BindMembers(ScriptTypeInfo t)
	{
		if ((t.Kind == .Enum) || ((t.Kind != .Global) && !mByName.ContainsKey(scope String(AsName(t)))))
			return;

		// A service is reached through a global handle; a scene system or manager through
		// the scene that owns it, `scene.Physics`.
		if (t.Role == .Service)
			DeclareRoleHandle(t);
		else if ((t.Role == .SceneSystem) || (t.Role == .ComponentManager))
			DeclareSceneProperty(t);

		// A component is constructed from the entity it lives on.
		if (t.Role == .Component)
		{
			let b = new AngelScriptBinding();
			b.Kind = .ComponentFromEntity;
			b.Owner = t;
			mBindings.Add(b);
			Check(AS.asc_engine_register_object_behaviour(mEngine, scope String(AsName(t)).CStr(), AS.asBEHAVE_CONSTRUCT, "void f(const Entity &in)", Internal.UnsafeCastToPtr(b)), t.FullName);
		}

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
			if (!ParamDecl(p.Kind, p.TypeName, p.IsByRef, d))
			{
				delete d;
				return;
			}
			d.AppendF(" {}", p.Name);
			paramDecls.Add(d);
		}
		for (int arity = m.RequiredEntityParams; arity <= paramDecls.Count; arity++)
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
			Check(AS.asc_engine_register_object_method(mEngine, "Entity", decl.CStr(), Internal.UnsafeCastToPtr(b)), scope $"{t.FullName}.{m.Name} on Entity as {decl}");
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
		for (let suffix in scope String[]("SceneSystem", "ComponentManager", "Subsystem", "System", "Manager"))
		{
			if (outName.EndsWith(suffix) && (outName.Length > suffix.Length))
			{
				outName.RemoveFromEnd(suffix.Length);
				return;
			}
		}
	}

	/// `scene.Physics`: a read only property on Scene answering the scene's instance,
	/// through the type's resolver. Needs Scene on the surface.
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
			mSceneProperties.Add(new String(name));
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
			mHandleNames.Add(new String(name));
	}

	/// A field or property becomes a virtual property: `T get_X() property` and its setter.
	private void BindField(ScriptTypeInfo t, ScriptFieldInfo f, StringView statics)
	{
		let typeDecl = scope String();
		if (!DeclOf(f.Kind, f.TypeName, typeDecl))
		{
			Problem(scope $"{t.FullName}.{f.Name}: {f.TypeName} has no AngelScript type, skipped");
			return;
		}

		let get = new AngelScriptBinding();
		get.Kind = .Get;
		get.Owner = t;
		get.Field = f;
		mBindings.Add(get);

		let isGlobal = f.IsStatic || (t.Kind == .Global);
		let getDecl = scope $"{typeDecl} get_{f.ScriptName}() property";
		if (isGlobal)
		{
			AS.asc_engine_set_default_namespace(mEngine, scope String(statics).CStr());
			Check(AS.asc_engine_register_global_function(mEngine, getDecl.CStr(), Internal.UnsafeCastToPtr(get)), t.FullName);
		}
		else
		{
			Check(AS.asc_engine_register_object_method(mEngine, scope String(AsName(t)).CStr(), getDecl.CStr(), Internal.UnsafeCastToPtr(get)), t.FullName);
		}

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
				Check(AS.asc_engine_register_global_function(mEngine, setDecl.CStr(), Internal.UnsafeCastToPtr(set)), t.FullName);
			else
				Check(AS.asc_engine_register_object_method(mEngine, scope String(AsName(t)).CStr(), setDecl.CStr(), Internal.UnsafeCastToPtr(set)), t.FullName);
		}
		if (isGlobal)
			AS.asc_engine_set_default_namespace(mEngine, "");
	}

	/// A method is registered once per arity its defaults allow.
	private void BindMethod(ScriptTypeInfo t, ScriptMethodInfo m, StringView statics)
	{
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
			if (!ParamDecl(p.Kind, p.TypeName, p.IsByRef, d))
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
		for (int arity = m.RequiredParams; arity <= m.Params.Count; arity++)
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
				rc = AS.asc_engine_register_object_method(mEngine, scope String(AsName(t)).CStr(), decl.CStr(), Internal.UnsafeCastToPtr(b));
			}
			Check(rc, scope $"{t.FullName}.{m.Name} as {decl}");
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
				return .Object;
			return .Struct;
		}
		return .Nil;
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
		case .List:
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
		defer { context.ReleaseScratch(mark); }
		switch (b.Kind)
		{
		case .ComponentFromEntity:
			// The value's bytes ARE the entity, scene included.
			let entity = *(ScriptEntity*)AS.asc_generic_get_arg_address(gen, 0);
			*(ScriptEntity*)AS.asc_generic_get_object(gen) = entity;
			return;
		case .StartCoroutine:
			StartCoroutine((AS.Function*)AS.asc_generic_get_arg_address(gen, 0));
			return;
		case .Wait:
			WaitCurrent(AS.asc_generic_get_arg_float(gen, 0));
			return;
		case .Yield:
			WaitCurrent(0);
			return;
		case .Resolve:
			// `scene.Physics`: the scene's instance of the system.
			var frame = ScriptCallFrame(context, default);
			frame.Self = .FromObject(Internal.UnsafeCastToObject(AS.asc_generic_get_object(gen)));
			b.Owner.FromScene(ref frame);
			if (frame.Failed)
			{
				AS.asc_set_active_exception(scope String(frame.Error).CStr());
				return;
			}
			AS.asc_generic_set_return_address(gen, (frame.Result.AsObject != null) ? Internal.UnsafeCastToPtr(frame.Result.AsObject) : null);
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
			resultKind = (owner.Role == .Component) ? .Entity : owner.Kind == .Struct ? KindOfStruct(owner) : .Object;
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
			if (owner.Kind == .Class)
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
		if (owner.Kind == .Class)
			return .Object;
		return KindOfStruct(owner);
	}

	private static ScriptValue ReadSelf(void* memory, ScriptValueKind kind, ScriptTypeInfo owner)
	{
		switch (kind)
		{
		case .Object: return .FromObject(Internal.UnsafeCastToObject(memory));
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
		case .Entity:
			let e = *(ScriptEntity*)memory;
			return .FromEntity(e.Handle, e.Scene);
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
		case .Entity: *(ScriptEntity*)memory = .(value.AsEntity, value.AsEntityScene);
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
		case .Struct:
			// Built in place at the return location through ResultTarget; nothing to do,
			// unless the thunk answered nothing.
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

	public override bool CompileModule(StringView moduleName, Span<ScriptSection> sections)
	{
		let module = AS.asc_engine_get_module(mEngine, scope String(moduleName).CStr(), AS.asGM_ALWAYS_CREATE);
		for (let section in sections)
		{
			if (AS.asc_module_add_script_section(module, scope String(section.Name).CStr(), section.Source.Ptr, (uint)section.Source.Length) < 0)
				return false;
		}
		return AS.asc_module_build(module) >= 0;
	}

	public override void DiscardModule(StringView moduleName)
	{
		let module = AS.asc_engine_get_module(mEngine, scope String(moduleName).CStr(), AS.asGM_ONLY_IF_EXISTS);
		if (module != null)
			AS.asc_module_discard(module);
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
		// the context for inspection and resumption, and the call reports as paused.
		if (mDebugger != null)
			mDebugger.Arm(ctx);
		let state = AS.asc_context_execute(ctx);
		if ((state == AS.asEXECUTION_SUSPENDED) && (mDebugger != null)
			&& mDebugger.Adopt(ctx, fn, what, copies, strings))
		{
			held = true;
			return false;
		}
		if (mDebugger != null)
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
		case .Entity: outText.AppendF("entity {}", value.AsEntity.Index);
		case .Float2: outText.AppendF("({}, {})", value.AsFloat2.X, value.AsFloat2.Y);
		case .Float3: outText.AppendF("({}, {}, {})", value.AsFloat3.X, value.AsFloat3.Y, value.AsFloat3.Z);
		case .Float4: outText.AppendF("({}, {}, {}, {})", value.AsFloat4.X, value.AsFloat4.Y, value.AsFloat4.Z, value.AsFloat4.W);
		case .Quaternion: outText.AppendF("({}, {}, {}, {})", value.AsQuaternion.X, value.AsQuaternion.Y, value.AsQuaternion.Z, value.AsQuaternion.W);
		case .Color: outText.AppendF("({}, {}, {}, {})", value.AsColor.R, value.AsColor.G, value.AsColor.B, value.AsColor.A);
		case .Object: outText.Append((value.AsObject != null) ? value.AsObject.GetType().GetName(.. scope .()) : "null");
		case .Struct: outText.Append((value.StructType != null) ? value.StructType.GetName(.. scope .()) : "struct");
		case .List: outText.AppendF("list[{}]", (value.AsList != null) ? value.AsList.Count : 0);
		}
	}

	private void ReportExecution(AS.Context* ctx, int32 state, StringView what)
	{
		if (state == AS.asEXECUTION_EXCEPTION)
		{
			int32 column = 0;
			char8* section = null;
			let line = AS.asc_context_get_exception_line_number(ctx, &column, &section);
			Problem(scope $"{StringView(section)}({line},{column}): exception: {StringView(AS.asc_context_get_exception_string(ctx))}");
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
		let state = AS.asc_context_execute(ctx);
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

		let properties = AS.asc_typeinfo_get_property_count(type);
		for (uint32 i = 0; i < properties; i++)
		{
			int32 isPrivate = 0, isProtected = 0;
			AS.asc_typeinfo_get_property_access(type, i, &isPrivate, &isProtected);
			if ((isPrivate != 0) || (isProtected != 0))
				continue;
			char8* name = null;
			int32 typeId = 0;
			int32 offset = 0;
			AS.asc_typeinfo_get_property(type, i, &name, &typeId, &offset);
			let m = new ScriptMemberDesc();
			m.Name.Set(StringView(name));
			m.Kind = KindOfTypeId(typeId);
			m.TypeName.Set(StringView(AS.asc_engine_get_type_declaration(mEngine, typeId, 0)));
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
				return ((typeId & AS.asTYPEID_SCRIPTOBJECT) != 0) ? .Nil : .Object;
			let name = StringView(AS.asc_typeinfo_get_name(AS.asc_engine_get_type_info_by_id(mEngine, typeId)));
			if (name == "string")
				return .String;
			let inlineKind = InlineKindOf(name);
			if (inlineKind != .Nil)
				return inlineKind;
			return mByName.ContainsKey(scope String(name)) ? .Struct : .Nil;
		}
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
			bool fits = true;
			for (int a = 0; a < args.Length; a++)
			{
				int32 typeId = 0;
				uint32 flags = 0;
				AS.asc_function_get_param(m, (uint32)a, &typeId, &flags, null);
				if (!Takes(typeId, args[a]))
				{
					fits = false;
					break;
				}
			}
			if (fits)
				return m;
		}
		return null;
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
				return (value.Kind == .Object) || value.IsNil;
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
		let fn = FindMethod(o, name, args);
		if (fn == null)
		{
			Problem(scope $"{o.ClassName} has no {name} taking these {args.Length} arguments");
			return false;
		}
		return Execute(fn, o.Object, args, ref result, scope $"{o.ClassName}.{name}");
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
		AS.asc_context_suspend(active);
	}

	/// Resumes the coroutine: it runs until it waits again, finishes or faults.
	private void Step(Coroutine co)
	{
		let state = AS.asc_context_execute(co.Context);
		if (state == AS.asEXECUTION_SUSPENDED)
			return;
		if (state != AS.asEXECUTION_FINISHED)
			ReportExecution(co.Context, state, "coroutine");
		Drop(co);
	}

	private void Drop(Coroutine co)
	{
		mCoroutines.Remove(co);
		AS.asc_context_abort(co.Context);
		AS.asc_context_release(co.Context);
		AS.asc_function_release(co.Function);
		delete co;
	}

	public override void AdvanceCoroutines(double deltaSeconds)
	{
		// A snapshot: a step may start another coroutine, or end this one.
		let due = scope List<Coroutine>();
		for (let co in mCoroutines)
		{
			co.Remaining -= deltaSeconds;
			if (co.Remaining <= 0)
				due.Add(co);
		}
		for (let co in due)
		{
			if (mCoroutines.Contains(co))
				Step(co);
		}
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
				AS.asc_context_set_arg_address(mContext, i, (value.AsObject != null) ? Internal.UnsafeCastToPtr(value.AsObject) : null);
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
				return .FromObject(Internal.UnsafeCastToObject(AS.asc_context_get_return_address(mContext)));
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
