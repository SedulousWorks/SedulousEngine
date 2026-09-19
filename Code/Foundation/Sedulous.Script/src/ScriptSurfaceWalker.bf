using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Script;

/// The comptime walk that turns the [Scriptable] marks in a build into a surface table and
/// the thunks that make it callable.
///
/// A composition root calls Emit from its own TypeInit, and gets emitted into itself a
/// `Populate(ScriptSurface)` method that adds every marked type the root's dependency
/// closure declares, plus one static thunk per member, bound into the table. The closure
/// is the coarse cut: a runtime root never references the editor, so editor types are not
/// on its surface. Type.TypeDeclarations sees the WHOLE workspace build, not only the
/// closure, so the walk keeps a declaration only when it is in the root's project or one
/// the root depends on. The domains the root allows are the fine cut, and a marked type
/// whose [TypeDomain] is not allowed FAILS THE BUILD, because it means a layering slip put
/// an editor type where a game could reach it.
///
/// What counts as on the surface:
///  - a type marked [Scriptable]; its data members when AllPublic, else the marked ones;
///    its marked methods and constructors always, since the policy covers data only;
///  - a namespace static block's marked methods, as a Global type named for the namespace;
///  - an enum marked [Scriptable], with its cases.
/// [Hidden] wins over AllPublic. The walk is by declaration, not by use, so a marked type
/// nothing references is still on the surface.
///
/// Overloads: two callables on one type may share a script name and staticness only when
/// their parameter kinds differ somewhere (see ScriptValueMap.KindKey), which is what a
/// resolver at the boundary can tell apart. Two that do not FAIL THE BUILD, and [ScriptName]
/// splits them.
///
/// A thunk resolves what it is called on from the type's role: a scene system from the
/// object in Self, else the context's scene; a component through its manager in the ENTITY'S
/// scene (an entity value carries the scene it lives in) and the entity in Self; a service
/// through the context; a class or struct from Self itself. A scene system also gets a
/// resolver, the scene's instance from a Scene self, which is how a script reaches
/// `scene.Physics`. An entity a scene bound call answers is tagged with that scene, and an
/// entity it takes is checked to be in it. A member whose types cannot cross the
/// boundary (see ScriptValueMap) is still on the table, marked Blocked with the type that
/// stopped it, so the listing shows the gap.
///
/// Emitted code refers to a namespace static block's members bare, so the root's file
/// carries a `using` for each namespace that has globals.
///
/// Comptime only. The root MUST NOT be resolved by its own walk, which is a data cycle the
/// compiler rejects; Emit skips it by name.
static class ScriptSurfaceWalker
{
	/// The prefix of the static block declaration Beef makes for a namespace's static
	/// members: its name is `@` and its full name is the namespace.
	private const String cStaticBlockName = "@";

	/// One collected type, kept until the whole set is sorted so the emitted table is stable
	/// across builds and readable in a diff. Nothing here is deleted: the comptime heap is
	/// discarded with the evaluation, and deleting on it is what it rejects.
	private class Entry
	{
		/// Namespace, then name, so a listing groups by namespace.
		public String SortKey = new .();
		public String Code = new .();
		public String Thunks = new .();
	}

	/// Component type name to manager type name. Two lists rather than a dictionary: the
	/// comptime heap rejects the dictionary's delete.
	private class ManagerTable
	{
		public List<String> Components = new .();
		public List<String> Managers = new .();
		/// Whether the manager is a ResourceBindingComponentManager, with a Resources to
		/// rebind a swapped reference through.
		public List<bool> Binds = new .();

		public void Add(StringView component, StringView manager, bool binds)
		{
			Components.Add(new String(component));
			Managers.Add(new String(manager));
			Binds.Add(binds);
		}

		public int IndexOf(StringView component)
		{
			for (int i = 0; i < Components.Count; i++)
			{
				if (Components[i] == component)
					return i;
			}
			return -1;
		}
	}

	/// What the emitter needs to know about the type whose members it is emitting.
	private class TypeCtx
	{
		public String FullName = new .();
		public String Name = new .();
		public Type Type;
		public ScriptTypeKind Kind;
		public ScriptTypeRole Role = .Plain;
		public String Manager = new .();
		/// The manager can rebind a swapped Ref<T> through its Resources.
		public bool ManagerBinds = false;
		/// Thunk name prefix, unique in the root.
		public String Prefix = new .();
		public int Counter = 0;
		/// The registration code and the thunk functions.
		public String Code = new .();
		public String Thunks = new .();
		/// Every type on the surface, for the closure check.
		public List<String> Known;
		/// The callables seen so far: script name, staticness and kinds, for the overload rule.
		public List<String> Signatures = new .();
		/// Every violation of it in the whole walk, reported together.
		public String Violations;

		/// One of the inline value kinds, copied and written back rather than pointed at.
		public bool IsInlineStruct = false;

		public void NextThunk(String outName)
		{
			outName.AppendF("{}_{}", Prefix, Counter);
			Counter++;
		}
	}

	[Comptime]
	public static void Emit(Type root, Span<StringView> namespacePrefixes, Span<StringView> allowedDomains)
	{
		let rootName = root.GetFullName(.. scope .());
		let entries = scope List<Entry>();

		// Component managers, by the component they pool, so a component's entry can name it.
		let managers = scope ManagerTable();
		for (let decl in Type.TypeDeclarations)
		{
			if (!InClosure(decl))
				continue;
			let fullName = decl.GetFullName(.. scope .());
			if (!HasPrefix(fullName, namespacePrefixes) || (fullName == rootName))
				continue;
			if (!fullName.EndsWith("Manager"))
				continue;

			let type = decl.ResolvedType;
			if (type == null)
				continue;
			let component = PooledComponent(type, .. scope .());
			if (!component.IsEmpty && (managers.IndexOf(component) < 0))
				managers.Add(component, fullName, HasBase(type, "Sedulous.Scene.ResourceBindingComponentManager<"));
		}

		// Every marked declaration first, so the emitter knows the whole surface before it
		// emits any member of it: a member's class, struct or enum type must be on it.
		let candidates = scope List<TypeDeclaration>();
		let known = scope List<String>();
		for (let decl in Type.TypeDeclarations)
		{
			if (!InClosure(decl))
				continue;
			let fullName = decl.GetFullName(.. scope .());
			if (!HasPrefix(fullName, namespacePrefixes) || (fullName == rootName))
				continue;

			let name = decl.GetName(.. scope .());
			let isStaticBlock = name == cStaticBlockName;
			// A declaration carries its own attributes; a mark on an EXTENSION of the type
			// (`[Scriptable] extension Guid {}`) is only on the resolved type. Every
			// declaration under the prefix is resolved to find those.
			let type = decl.ResolvedType;
			if (type == null)
			{
				if (isStaticBlock || !decl.HasCustomAttribute<ScriptableAttribute>())
					continue;
				Runtime.FatalError(scope $"ScriptSurface: {fullName} is marked but did not resolve");
			}
			if (!isStaticBlock && !decl.HasCustomAttribute<ScriptableAttribute>()
				&& !type.HasCustomAttribute<ScriptableAttribute>())
				continue;

			candidates.Add(decl);
			if (!isStaticBlock)
				known.Add(new String(fullName));
		}

		let violations = scope String();
		int typeIndex = 0;
		for (let decl in candidates)
		{
			let fullName = decl.GetFullName(.. scope .());
			let name = decl.GetName(.. scope .());
			let isStaticBlock = name == cStaticBlockName;
			let type = decl.ResolvedType;

			let ctx = scope TypeCtx();
			ctx.Known = known;
			ctx.Violations = violations;
			ctx.FullName.Set(fullName);
			ctx.IsInlineStruct = type.IsStruct && !type.IsEnum && ScriptValueMap.IsInlineStruct(fullName);
			ctx.Name.Set(isStaticBlock ? "" : name);
			ctx.Type = type;
			ctx.Prefix.AppendF("T{}", typeIndex);
			typeIndex++;

			if (isStaticBlock)
			{
				if (!EmitGlobal(ctx))
					continue;
			}
			else
			{
				EmitType(ctx, managers, allowedDomains);
			}

			let entry = new Entry();
			if (isStaticBlock)
				entry.SortKey.AppendF("{}\n", fullName);
			else
				entry.SortKey.AppendF("{}\n{}", decl.GetNamespace(.. scope .()), name);
			entry.Code.Set(ctx.Code);
			entry.Thunks.Set(ctx.Thunks);
			entries.Add(entry);
		}

		if (!violations.IsEmpty)
			Runtime.FatalError(scope $"ScriptSurface: callables a resolver could not tell apart; [ScriptName] one of each pair, or unmark it:\n{violations}");

		entries.Sort(scope (a, b) => a.SortKey <=> b.SortKey);

		let body = scope String();
		body.Append("/// Emitted by ScriptSurfaceWalker: every [Scriptable] type this root's closure declares.\n");
		body.Append("public static void Populate(ScriptSurface surface)\n{\n");
		for (let e in entries)
			body.Append(e.Code);
		body.AppendF("}}\n\n/// The count the walk found, a tripwire for the tests.\npublic const int TypeCount = {};\n\n", entries.Count);
		for (let e in entries)
			body.Append(e.Thunks);
		Compiler.EmitTypeBody(root, body);
	}

	// ---- one type ----
	//
	// Type level attributes are read off the RESOLVED type, which merges what the
	// declaration and every extension carry.

	[Comptime]
	private static void EmitType(TypeCtx ctx, ManagerTable managers, Span<StringView> allowedDomains)
	{
		let type = ctx.Type;
		let code = ctx.Code;
		let fullName = ctx.FullName;

		let domain = scope String(ScriptDomains.Runtime);
		if (type.GetCustomAttribute<TypeDomainAttribute>() case .Ok(let td))
			domain.Set(td.Domain);
		if (!Allowed(domain, allowedDomains))
			Runtime.FatalError(scope $"ScriptSurface: {fullName} is in domain {domain}, which this surface does not allow");

		var kind = ScriptTypeKind.Class;
		if (type.IsEnum)
			kind = .Enum;
		else if (type.IsStruct)
			kind = .Struct;
		ctx.Kind = kind;
		let header = scope String();
		header.AppendF("surface.AddType({}, .{}, {}).Typed(typeof({}), {}, {})", Quote(fullName, .. scope .()), kind, Quote(domain, .. scope .()), fullName, type.Size, type.Align);
		// The members are emitted first, so a type with none is added without a `t` the
		// compiler would warn about; and a warning forces a full rebuild.
		let members = scope String();
		let savedCode = ctx.Code;
		ctx.Code = members;

		bool allPublic = false;
		if (type.GetCustomAttribute<ScriptableAttribute>() case .Ok(let s))
			allPublic = s.Members == .AllPublic;
		if (allPublic)
			members.Append("\t\tt.Everything();\n");

		if (type.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let dn))
			members.AppendF("\t\tt.Display({});\n", Quote(dn.Name, .. scope .()));
		if (type.GetCustomAttribute<DescriptionAttribute>() case .Ok(let ds))
			members.AppendF("\t\tt.Describe({});\n", Quote(ds.Text, .. scope .()));
		if (type.GetCustomAttribute<CategoryAttribute>() case .Ok(let c))
			members.AppendF("\t\tt.Categorised({});\n", Quote(c.Name, .. scope .()));

		EmitRole(ctx, managers);

		if (kind == .Enum)
		{
			EmitEnumValues(type, members);
		}
		else
		{
			EmitFields(ctx, allPublic);
			EmitProperties(ctx, allPublic);
			EmitMethods(ctx);
		}

		ctx.Code = savedCode;
		if (members.IsEmpty)
			code.AppendF("\t{};\n", header);
		else
			code.AppendF("\t{{\n\t\tlet t = {};\n{}\t}}\n", header, members);
	}

	[Comptime]
	private static void EmitRole(TypeCtx ctx, ManagerTable managers)
	{
		let type = ctx.Type;
		if (type.IsStruct)
		{
			// Component data: a struct the scene pools. Either attribute makes it one.
			let typeId = scope String();
			bool isComponent = type.HasCustomAttribute<ComponentAttribute>();
			if (type.GetCustomAttribute<SerializableComponentAttribute>() case .Ok(let sc))
			{
				isComponent = true;
				typeId.Set(sc.TypeId);
			}
			if (!isComponent)
				return;

			let at = managers.IndexOf(ctx.FullName);
			if (at >= 0)
			{
				ctx.Manager.Set(managers.Managers[at]);
				ctx.ManagerBinds = managers.Binds[at];
			}
			ctx.Role = .Component;
			ctx.Code.AppendF("\t\tt.As(.Component, {}, {});\n", Quote(ctx.Manager, .. scope .()), Quote(typeId, .. scope .()));
			return;
		}

		if (!type.IsObject)
			return;

		if (!PooledComponent(type, .. scope .()).IsEmpty)
			ctx.Role = .ComponentManager;
		else
			ctx.Role = BaseRole(type);
		if (ctx.Role != .Plain)
			ctx.Code.AppendF("\t\tt.As(.{});\n", ctx.Role);
		if ((ctx.Role == .SceneSystem) || (ctx.Role == .ComponentManager))
			EmitResolver(ctx);
	}

	/// The role a class's bases give it: a scene system, or an engine service.
	[Comptime]
	private static ScriptTypeRole BaseRole(Type type)
	{
		var t = type;
		while (t != null)
		{
			let n = t.GetFullName(.. scope .());
			if (n == "Sedulous.Scene.SceneSystem")
				return .SceneSystem;
			if (n == "Sedulous.Runtime.Subsystem")
				return .Service;
			t = t.BaseType;
		}
		return .Plain;
	}

	/// Whether a base of the type has this full name prefix.
	[Comptime]
	private static bool HasBase(Type type, StringView prefix)
	{
		var t = type.BaseType;
		while (t != null)
		{
			if (t.GetFullName(.. scope .()).StartsWith(prefix))
				return true;
			t = t.BaseType;
		}
		return false;
	}

	/// The component type a manager pools, from a ComponentManager<T> in its bases. Empty
	/// when it is not one. Read off the base's full name: `Sedulous.Scene.ComponentManager<X>`.
	[Comptime]
	private static void PooledComponent(Type type, String outComponent)
	{
		const String cPrefix = "Sedulous.Scene.ComponentManager<";
		var t = type;
		while (t != null)
		{
			let n = t.GetFullName(.. scope .());
			if (n.StartsWith(cPrefix) && n.EndsWith(">"))
			{
				outComponent.Append(n.Substring(cPrefix.Length, n.Length - cPrefix.Length - 1));
				return;
			}
			t = t.BaseType;
		}
	}

	// ---- self ----

	/// The lines that resolve `self` for an instance member, per the type's role, and
	/// whether the self value must be written back after the call (an inline struct).
	/// `sceneExpr` is how the body names the scene the call is in, empty when it has none:
	/// entities it answers are tagged with it, entities it takes are checked against it.
	[Comptime]
	private static void SelfPrologue(TypeCtx ctx, String outCode, out bool writeBack, String sceneExpr)
	{
		writeBack = false;
		let t = ctx.FullName;
		switch (ctx.Role)
		{
		case .SceneSystem, .ComponentManager:
			// The system a script holds, else the ambient scene's, for a host with no object.
			outCode.AppendF("\tvar self = frame.Self.AsObject as {};\n\tif (self == null)\n\t{{\n\t\tlet ambient = frame.Context.Scene;\n\t\tself = (ambient != null) ? ambient.GetSystem<{}>() : null;\n\t}}\n\tif (self == null) {{ frame.Fail(\"no {} in the scene\"); return; }}\n", t, t, ctx.Name);
			sceneExpr.Set("self.Scene");
		case .Component:
			// The entity's own scene, else the ambient one.
			outCode.AppendF("\tlet scene = frame.SceneOf(frame.Self);\n\tlet manager = (scene != null) ? scene.GetSystem<{}>() : null;\n\tlet self = (manager != null) ? manager.Get(frame.Self.AsEntity) : null;\n\tif (self == null) {{ frame.Fail(\"the entity has no {}\"); return; }}\n", ctx.Manager, ctx.Name);
			sceneExpr.Set("scene");
		case .Service:
			outCode.AppendF("\tlet self = frame.Context.FindService(typeof({})) as {};\n\tif (self == null) {{ frame.Fail(\"no {} service\"); return; }}\n", t, t, ctx.Name);
		case .Plain:
			if (ctx.Kind == .Class)
			{
				outCode.AppendF("\tlet self = frame.Self.AsObject as {};\n\tif (self == null) {{ frame.Fail(\"self is not a {}\"); return; }}\n", t, ctx.Name);
				if (t == "Sedulous.Scene.Scene")
					sceneExpr.Set("self");
			}
			else if (ctx.IsInlineStruct)
			{
				let read = scope String();
				ScriptValueMap.Read(ctx.Type, "frame.Self", ctx.Known, read);
				outCode.AppendF("\tvar self = {};\n", read);
				writeBack = true;
			}
			else
			{
				outCode.AppendF("\tlet self = ({}*)frame.Self.AsStruct;\n\tif (self == null) {{ frame.Fail(\"self is not a {}\"); return; }}\n", t, ctx.Name);
			}
		}
	}

	[Comptime]
	private static void SelfWriteBack(TypeCtx ctx, bool writeBack, String outCode)
	{
		if (!writeBack)
			return;
		let write = scope String();
		ScriptValueMap.Write(ctx.Type, "self", "frame.Self", ctx.Known, write);
		outCode.AppendF("\t{}\n", write);
	}

	/// Whether a component role can bind at all: it needs a manager to reach the pool.
	[Comptime]
	private static bool CanReachSelf(TypeCtx ctx) => (ctx.Role != .Component) || !ctx.Manager.IsEmpty;

	// ---- the members ----

	[Comptime]
	private static void EmitFields(TypeCtx ctx, bool allPublic)
	{
		for (let f in ctx.Type.GetFields(.Public | .Instance | .Static | .DeclaredOnly))
		{
			if (f.IsEnumCase || !f.IsPublic)
				continue;
			if (f.HasCustomAttribute<HiddenAttribute>())
				continue;
			if (!allPublic && !f.HasCustomAttribute<ScriptableAttribute>())
				continue;

			let typeName = f.FieldType.GetFullName(.. scope .());
			let code = ctx.Code;
			code.AppendF("\t\tt.AddField({}, {}, {}).OfKind(.{})", Quote(f.Name, .. scope .()), Quote(typeName, .. scope .()), Bool(f.IsStatic), ScriptValueMap.KindOf(f.FieldType, .. scope .()));
			let readOnly = f.IsReadOnly || f.IsConst;
			if (readOnly)
				code.Append(".ReadOnly()");
			EmitFieldMetadata(f, code);
			EmitAccessors(ctx, f.Name, f.FieldType, f.IsStatic, readOnly);
			code.Append(";\n");
		}
	}

	/// An override carries none of the base's attributes, so a [Hidden] on the base
	/// property has to be looked for up the chain.
	[Comptime]
	private static bool HiddenOnABase(Type type, StringView accessorName)
	{
		var t = type.BaseType;
		while (t != null)
		{
			for (let m in t.GetMethods(.Public | .Instance | .Static | .DeclaredOnly))
			{
				if ((m.Name == accessorName) && m.HasCustomAttribute<HiddenAttribute>())
					return true;
			}
			t = t.BaseType;
		}
		return false;
	}

	/// Properties are their accessors in reflection: `get__X` and `set__X`. The getter
	/// carries the property's attributes, and a missing setter makes it read only.
	[Comptime]
	private static void EmitProperties(TypeCtx ctx, bool allPublic)
	{
		let type = ctx.Type;
		for (let m in type.GetMethods(.Public | .Instance | .Static | .DeclaredOnly))
		{
			if (!m.Name.StartsWith("get__") || !m.IsPublic)
				continue;
			let name = m.Name.Substring(5);
			if (name.IsEmpty)
				continue; // an indexer
			if (m.HasCustomAttribute<HiddenAttribute>() || HiddenOnABase(type, m.Name))
				continue;
			if (!allPublic && !m.HasCustomAttribute<ScriptableAttribute>())
				continue;

			bool canWrite = false;
			let setter = scope String("set__");
			setter.Append(name);
			for (let s in type.GetMethods(.Public | .Instance | .Static | .DeclaredOnly))
			{
				if ((s.Name == setter) && s.IsPublic)
				{
					canWrite = true;
					break;
				}
			}

			let typeName = m.ReturnType.GetFullName(.. scope .());
			let code = ctx.Code;
			code.AppendF("\t\tt.AddField({}, {}, {}, true).OfKind(.{})", Quote(name, .. scope .()), Quote(typeName, .. scope .()), Bool(m.IsStatic), ScriptValueMap.KindOf(m.ReturnType, .. scope .()));
			if (!canWrite)
				code.Append(".ReadOnly()");
			EmitMethodMetadataAsField(m, code);
			EmitAccessors(ctx, name, m.ReturnType, m.IsStatic, !canWrite);
			code.Append(";\n");
		}
	}

	/// The get and set thunks for a field or property, bound into the registration, or the
	/// member marked Blocked when its type cannot cross.
	[Comptime]
	private static void EmitAccessors(TypeCtx ctx, StringView member, Type memberType, bool isStatic, bool readOnly)
	{
		let code = ctx.Code;
		if (!isStatic && !CanReachSelf(ctx))
		{
			code.Append(".Blocked(\"no manager for the component\")");
			return;
		}

		let owner = scope String();
		if (isStatic)
			owner.Set(ctx.FullName);
		else
			owner.Set("self");
		let access = scope $"{owner}.{member}";

		let memberName = memberType.GetFullName(.. scope .());
		let isRef = ScriptValueMap.IsRef(memberName);

		// Get.
		let getBody = scope String();
		if (isRef)
		{
			getBody.AppendF("\tframe.Result = .FromGuid({}.Id);\n", access);
		}
		else
		{
			let sceneExpr = scope String("null");
			let s = SceneExprFor(ctx, isStatic, .. scope .());
			if (!s.IsEmpty)
				sceneExpr.Set(s);
			let write = scope String();
			if (!ScriptValueMap.Write(memberType, access, "frame.Result", ctx.Known, write, sceneExpr))
			{
				code.AppendF(".Blocked({})", Quote(write, .. scope .()));
				return;
			}
			getBody.AppendF("\t{}\n", write);
		}

		let getName = ctx.NextThunk(.. scope .());
		EmitThunk(ctx, getName, isStatic, getBody, false);

		if (readOnly)
		{
			code.AppendF(".Bind(=> {}, null)", getName);
			return;
		}

		// Set.
		let setBody = scope String();
		setBody.Append("\tif (!frame.ExpectArgs(1)) return;\n");
		if (isRef)
		{
			setBody.Append("\tif (!frame.Expect(0, .Guid)) return;\n");
			if ((ctx.Role == .Component) && ctx.ManagerBinds)
			{
				// The pool's manager binds it, through what the scene was resolved with.
				setBody.AppendF("\t{}.SetId(frame.Args[0].AsGuid);\n\t{}.Rebind(manager.Resources);\n", access, access);
			}
			else
			{
				// No manager to bind through: the identity lands and the old binding is
				// dropped, so nothing stale is rendered; the next resolve binds it.
				setBody.AppendF("\t{}.SetId(frame.Args[0].AsGuid);\n\t{}.ClearBinding();\n", access, access);
			}
		}
		else
		{
			let read = scope String();
			if (!ScriptValueMap.Read(memberType, "frame.Args[0]", ctx.Known, read))
			{
				code.AppendF(".Bind(=> {}, null).Blocked({})", getName, Quote(read, .. scope .()));
				return;
			}
			ScriptValueMap.ExpectFor(memberType, 0, setBody);
			setBody.AppendF("\t{} = {};\n", access, read);
		}
		let setName = ctx.NextThunk(.. scope .());
		EmitThunk(ctx, setName, isStatic, setBody, true);
		code.AppendF(".Bind(=> {}, => {})", getName, setName);
	}

	[Comptime]
	private static void EmitMethods(TypeCtx ctx)
	{
		let type = ctx.Type;
		for (let m in type.GetMethods(.Public | .Instance | .Static | .DeclaredOnly))
		{
			if (!m.IsPublic || m.IsDestructor || m.IsMixin)
				continue;
			if (m.Name.StartsWith("get__") || m.Name.StartsWith("set__"))
				continue;
			if (!m.HasCustomAttribute<ScriptableAttribute>())
				continue;

			let code = ctx.Code;
			if (m.IsConstructor)
			{
				code.AppendF("\t\tt.AddConstructor().Returns(.{})", ScriptValueMap.KindOf(ctx.Type, .. scope .()));
			}
			else
			{
				let ret = m.ReturnType.GetFullName(.. scope .());
				code.AppendF("\t\tt.AddMethod({}, {}, {}).Returns(.{})", Quote(m.Name, .. scope .()), Quote(ret, .. scope .()), Bool(m.IsStatic), ScriptValueMap.KindOf(m.ReturnType, .. scope .()));
			}
			EmitParams(m, code);
			if (m.GetCustomAttribute<ScriptNameAttribute>() case .Ok(let sn))
				code.AppendF(".Named({})", Quote(sn.Name, .. scope .()));
			if (m.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let dn))
				code.AppendF(".Display({})", Quote(dn.Name, .. scope .()));
			if (m.GetCustomAttribute<DescriptionAttribute>() case .Ok(let ds))
				code.AppendF(".Describe({})", Quote(ds.Text, .. scope .()));
			EmitCall(ctx, m, false);
			code.Append(";\n");
		}
	}

	[Comptime]
	private static void EmitParams(MethodInfo m, String code)
	{
		for (int i = 0; i < m.ParamCount; i++)
		{
			var pt = m.GetParamType(i);
			bool byRef = false;
			if (let r = pt as RefType)
			{
				byRef = true;
				pt = r.UnderlyingType;
			}
			let ptn = pt.GetFullName(.. scope .());
			code.AppendF(".Param({}, {}, .{}", Quote(m.GetParamName(i), .. scope .()), Quote(ptn, .. scope .()), ScriptValueMap.KindOf(pt, .. scope .()));
			let defaultText = m.GetParamDefault(i);
			if (!defaultText.IsEmpty)
				code.AppendF(", {}, {})", Bool(byRef), Quote(defaultText, .. scope .()));
			else if (byRef)
				code.Append(", true)");
			else
				code.Append(")");
		}
	}

	/// The thunk for a method or constructor, bound into the registration, or the member
	/// marked Blocked when a type cannot cross.
	[Comptime]
	private static void EmitCall(TypeCtx ctx, MethodInfo m, bool isGlobal)
	{
		let code = ctx.Code;
		let isStatic = m.IsStatic || m.IsConstructor || isGlobal;
		CheckOverload(ctx, m, isStatic);
		if (!isStatic && !CanReachSelf(ctx))
		{
			code.Append(".Blocked(\"no manager for the component\")");
			return;
		}

		let body = scope String();
		let args = scope String();
		let after = scope String();
		let sceneExpr = SceneExprFor(ctx, isStatic, .. scope .());
		int required = 0;
		for (int i = 0; i < m.ParamCount; i++)
		{
			if (m.GetParamDefault(i).IsEmpty)
				required = i + 1;
		}
		body.AppendF("\tif (!frame.ExpectArgs({})) return;\n", required);
		for (int i = 0; i < m.ParamCount; i++)
		{
			var pt = m.GetParamType(i);
			var refKind = RefType.RefKind.Ref;
			bool byRef = false;
			if (let r = pt as RefType)
			{
				byRef = true;
				refKind = r.RefKind;
				pt = r.UnderlyingType;
			}
			let ptn = pt.GetFullName(.. scope .());
			let slot = scope $"frame.Args[{i}]";
			let read = scope String();
			if (!ScriptValueMap.Read(pt, slot, ctx.Known, read))
			{
				code.AppendF(".Blocked({})", Quote(read, .. scope .()));
				return;
			}

			ScriptValueMap.ExpectFor(pt, i, body);
			if (!sceneExpr.IsEmpty && (ptn == "Sedulous.Scene.EntityHandle"))
				body.AppendF("\tif (!frame.ExpectEntityIn({}, {})) return;\n", i, sceneExpr);
			let defaultText = m.GetParamDefault(i);
			if (!defaultText.IsEmpty)
				body.AppendF("\t{} a{} = {};\n\tif (frame.Args.Length > {})\n\t\ta{} = {};\n", ptn, i, defaultText, i, i, read);
			else
				body.AppendF("\tvar a{} = {};\n", i, read);

			if (i > 0)
				args.Append(", ");
			if (byRef)
			{
				switch (refKind)
				{
				case .Out: args.Append("out ");
				case .In: args.Append("in ");
				default: args.Append("ref ");
				}
				// Written back so the caller sees what the callee did to it.
				if (refKind != .In)
				{
					let write = scope String();
					if (ScriptValueMap.Write(pt, scope $"a{i}", slot, ctx.Known, write, sceneExpr.IsEmpty ? "null" : sceneExpr))
						after.AppendF("\t{}\n", write);
					else if (pt.IsStruct)
						after.AppendF("\t*({}*){}.AsStruct = a{};\n", ptn, slot, i);
				}
			}
			args.AppendF("a{}", i);
		}

		let call = scope String();
		if (m.IsConstructor)
		{
			if (ctx.Kind == .Class)
				call.AppendF("new {}({})", ctx.FullName, args);
			else
				call.AppendF("{}({})", ctx.FullName, args);
		}
		else if (isGlobal)
		{
			call.AppendF("{}({})", m.Name, args);
		}
		else if (m.IsStatic)
		{
			call.AppendF("{}.{}({})", ctx.FullName, m.Name, args);
		}
		else
		{
			call.AppendF("self.{}({})", m.Name, args);
		}

		let write = scope String();
		let resultType = m.IsConstructor ? ctx.Type : m.ReturnType;
		if (!ScriptValueMap.Write(resultType, call, "frame.Result", ctx.Known, write, sceneExpr.IsEmpty ? "null" : sceneExpr))
		{
			code.AppendF(".Blocked({})", Quote(write, .. scope .()));
			return;
		}
		body.AppendF("\t{}\n", write);
		body.Append(after);

		let name = ctx.NextThunk(.. scope .());
		EmitThunk(ctx, name, isStatic, body, true);
		code.AppendF(".Bind(=> {})", name);
	}

	/// The overload rule: the script name, staticness and parameter kinds together must be
	/// unique on the type, or a resolver could not pick.
	[Comptime]
	private static void CheckOverload(TypeCtx ctx, MethodInfo m, bool isStatic)
	{
		let signature = scope String();
		if (m.GetCustomAttribute<ScriptNameAttribute>() case .Ok(let sn))
			signature.Append(sn.Name);
		else
			signature.Append(m.Name);
		signature.Append(isStatic ? "|static(" : "|(");
		for (int i = 0; i < m.ParamCount; i++)
		{
			var pt = m.GetParamType(i);
			if (let r = pt as RefType)
				pt = r.UnderlyingType;
			if (i > 0)
				signature.Append(", ");
			ScriptValueMap.KindKey(pt, signature);
		}
		signature.Append(")");

		for (let seen in ctx.Signatures)
		{
			if (seen == signature)
				ctx.Violations.AppendF("  {}: {}\n", ctx.FullName, signature);
		}
		ctx.Signatures.Add(new String(signature));
	}

	/// The scene expression a member's body may use, per the role, or empty. What
	/// SelfPrologue will set, known before the body is written.
	[Comptime]
	private static void SceneExprFor(TypeCtx ctx, bool isStatic, String outExpr)
	{
		if (isStatic)
			return;
		switch (ctx.Role)
		{
		case .SceneSystem, .ComponentManager: outExpr.Set("self.Scene");
		case .Component: outExpr.Set("scene");
		case .Plain:
			if ((ctx.Kind == .Class) && (ctx.FullName == "Sedulous.Scene.Scene"))
				outExpr.Set("self");
		default:
		}
	}

	/// One static thunk function: the self prologue, the body, the self write back.
	[Comptime]
	private static void EmitThunk(TypeCtx ctx, StringView name, bool isStatic, StringView body, bool mutatesSelf)
	{
		let t = ctx.Thunks;
		t.AppendF("static void {}(ref ScriptCallFrame frame)\n{{\n\tframe.Begin();\n", name);
		bool writeBack = false;
		if (!isStatic)
		{
			let prologue = scope String();
			SelfPrologue(ctx, prologue, out writeBack, scope String());
			t.Append(prologue);
		}
		t.Append(body);
		if (mutatesSelf)
			SelfWriteBack(ctx, writeBack, t);
		t.Append("}\n\n");
	}

	/// The resolver a scene system or manager gets: the scene's instance, Self the scene.
	[Comptime]
	private static void EmitResolver(TypeCtx ctx)
	{
		let name = ctx.NextThunk(.. scope .());
		ctx.Thunks.AppendF("static void {}(ref ScriptCallFrame frame)\n{{\n\tframe.Begin();\n\tlet scene = frame.Self.AsObject as Sedulous.Scene.Scene;\n\tif (scene == null) {{ frame.Fail(\"self is not a Scene\"); return; }}\n\tframe.Result = .FromObject(scene.GetSystem<{}>());\n}}\n\n", name, ctx.FullName);
		ctx.Code.AppendF("\t\tt.ResolvedBy(=> {});\n", name);
	}

	[Comptime]
	private static void EmitEnumValues(Type type, String code)
	{
		for (let f in type.GetFields())
		{
			if (!f.IsEnumCase)
				continue;
			// A case's constant lives in the field's data slot, as Enum.GetValues reads it.
			let value = (int64)f.[Friend]mFieldData.mData;
			code.AppendF("\t\tt.AddEnumValue({}, {});\n", Quote(f.Name, .. scope .()), value);
		}
	}

	[Comptime]
	private static void EmitFieldMetadata(FieldInfo f, String code)
	{
		if (f.GetCustomAttribute<ScriptNameAttribute>() case .Ok(let sn))
			code.AppendF(".Named({})", Quote(sn.Name, .. scope .()));
		if (f.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let dn))
			code.AppendF(".Display({})", Quote(dn.Name, .. scope .()));
		if (f.GetCustomAttribute<DescriptionAttribute>() case .Ok(let ds))
			code.AppendF(".Describe({})", Quote(ds.Text, .. scope .()));
		if (f.GetCustomAttribute<CategoryAttribute>() case .Ok(let c))
			code.AppendF(".Categorised({})", Quote(c.Name, .. scope .()));
		if (f.GetCustomAttribute<RangeAttribute>() case .Ok(let r))
			code.AppendF(".Ranged({}f, {}f, {}f)", r.Min, r.Max, r.Step);
		if (f.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let v))
			code.AppendF(".When({})", Quote(v.Condition, .. scope .()));
	}

	[Comptime]
	private static void EmitMethodMetadataAsField(MethodInfo m, String code)
	{
		if (m.GetCustomAttribute<ScriptNameAttribute>() case .Ok(let sn))
			code.AppendF(".Named({})", Quote(sn.Name, .. scope .()));
		if (m.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let dn))
			code.AppendF(".Display({})", Quote(dn.Name, .. scope .()));
		if (m.GetCustomAttribute<DescriptionAttribute>() case .Ok(let ds))
			code.AppendF(".Describe({})", Quote(ds.Text, .. scope .()));
		if (m.GetCustomAttribute<CategoryAttribute>() case .Ok(let c))
			code.AppendF(".Categorised({})", Quote(c.Name, .. scope .()));
		if (m.GetCustomAttribute<RangeAttribute>() case .Ok(let r))
			code.AppendF(".Ranged({}f, {}f, {}f)", r.Min, r.Max, r.Step);
		if (m.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let v))
			code.AppendF(".When({})", Quote(v.Condition, .. scope .()));
	}

	// ---- a namespace's static block ----

	/// Emits the block's marked methods as a Global. False when it has none, so a namespace
	/// with only unmarked helpers adds nothing.
	[Comptime]
	private static bool EmitGlobal(TypeCtx ctx)
	{
		ctx.Kind = .Global;
		let methods = scope String();
		let savedCode = ctx.Code;
		ctx.Code = methods;
		for (let m in ctx.Type.GetMethods(.Public | .Static | .DeclaredOnly))
		{
			if (!m.IsPublic || !m.HasCustomAttribute<ScriptableAttribute>())
				continue;

			let ret = m.ReturnType.GetFullName(.. scope .());
			methods.AppendF("\t\tt.AddMethod({}, {}, true).Returns(.{})", Quote(m.Name, .. scope .()), Quote(ret, .. scope .()), ScriptValueMap.KindOf(m.ReturnType, .. scope .()));
			EmitParams(m, methods);
			if (m.GetCustomAttribute<ScriptNameAttribute>() case .Ok(let sn))
				methods.AppendF(".Named({})", Quote(sn.Name, .. scope .()));
			if (m.GetCustomAttribute<DescriptionAttribute>() case .Ok(let ds))
				methods.AppendF(".Describe({})", Quote(ds.Text, .. scope .()));
			EmitCall(ctx, m, true);
			methods.Append(";\n");
		}
		ctx.Code = savedCode;

		if (methods.IsEmpty)
			return false;

		ctx.Code.AppendF("\t{{\n\t\tlet t = surface.AddType({}, .Global, {});\n", Quote(ctx.FullName, .. scope .()), Quote(ScriptDomains.Runtime, .. scope .()));
		ctx.Code.Append(methods);
		ctx.Code.Append("\t}\n");
		return true;
	}

	// ---- helpers ----

	[Comptime]
	private static bool Allowed(StringView domain, Span<StringView> allowed)
	{
		for (let a in allowed)
		{
			if (a == domain)
				return true;
		}
		return false;
	}

	[Comptime]
	private static bool HasPrefix(StringView name, Span<StringView> prefixes)
	{
		for (let p in prefixes)
		{
			if (name.StartsWith(p))
				return true;
		}
		return false;
	}

	/// Declared in the root's own project, or in one it depends on. The flags are relative
	/// to the type whose TypeInit is running, which is the root.
	[Comptime]
	private static bool InClosure(TypeDeclaration decl)
		=> decl.DeclaredInDependency || decl.[Friend]mFlags.HasFlag(.DeclaredInCurrent);

	[Comptime]
	private static StringView Bool(bool value) => value ? "true" : "false";

	/// A Beef string literal for the emitted code.
	[Comptime]
	private static void Quote(StringView text, String outLiteral)
	{
		outLiteral.Append('"');
		for (let c in text)
		{
			switch (c)
			{
			case '"': outLiteral.Append("\\\"");
			case '\\': outLiteral.Append("\\\\");
			case '\n': outLiteral.Append("\\n");
			case '\t': outLiteral.Append("\\t");
			default: outLiteral.Append(c);
			}
		}
		outLiteral.Append('"');
	}
}
