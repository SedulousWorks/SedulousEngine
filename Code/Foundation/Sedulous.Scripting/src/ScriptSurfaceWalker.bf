using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scripting;

/// The comptime walk that turns the [Scriptable] marks in a build into a surface table.
///
/// A composition root calls Emit from its own TypeInit, and gets a `Populate(ScriptSurface)`
/// method emitted into itself that adds every marked type the root's dependency closure
/// declares. The closure is the coarse cut: a runtime root never references the editor, so
/// editor types do not exist in its compile. The domains the root allows are the fine cut,
/// and a marked type whose [TypeDomain] is not allowed FAILS THE BUILD, because it means a
/// layering slip put an editor type where a game could reach it.
///
/// What counts as on the surface:
///  - a type marked [Scriptable]; its data members when AllPublic, else the marked ones;
///    its marked methods and constructors always, since the policy covers data only;
///  - a namespace static block's marked methods, as a Global type named for the namespace;
///  - an enum marked [Scriptable], with its cases.
/// [Hidden] wins over AllPublic. The walk is by declaration, not by use, so a marked type
/// nothing references is still on the surface.
///
/// Comptime only. The root MUST NOT be resolved by its own walk, which is a data cycle the
/// compiler rejects; Emit skips it by name.
static class ScriptSurfaceWalker
{
	/// The prefix of the static block declaration Beef makes for a namespace's static
	/// members: its name is `@` and its full name is the namespace.
	private const String cStaticBlockName = "@";

	/// One collected type, kept until the whole set is sorted so the emitted table is stable
	/// across builds and readable in a diff.
	private class Entry
	{
		public String FullName = new .();
		public String Code = new .();
	}

	/// Component type name to manager type name.
	private class ManagerTable
	{
		public List<String> Components = new .();
		public List<String> Managers = new .();

		public void Add(StringView component, StringView manager)
		{
			Components.Add(new String(component));
			Managers.Add(new String(manager));
		}

		public String Find(StringView component)
		{
			for (int i = 0; i < Components.Count; i++)
			{
				if (Components[i] == component)
					return Managers[i];
			}
			return null;
		}
	}

	[Comptime]
	public static void Emit(Type root, StringView namespacePrefix, Span<StringView> allowedDomains)
	{
		let rootName = root.GetFullName(.. scope .());
		// Nothing here is deleted: the comptime heap is discarded with the evaluation, and
		// deleting on it is what it rejects.
		let entries = scope List<Entry>();

		// Component managers, by the component they pool, so a component's entry can name it.
		// Two lists rather than a dictionary: the comptime heap rejects the dictionary's
		// delete.
		let managers = scope ManagerTable();
		for (let decl in Type.TypeDeclarations)
		{
			let fullName = decl.GetFullName(.. scope .());
			if (!fullName.StartsWith(namespacePrefix) || (fullName == rootName))
				continue;
			if (!fullName.EndsWith("Manager"))
				continue;

			let type = decl.ResolvedType;
			if (type == null)
				continue;
			let component = PooledComponent(type, .. scope .());
			if (!component.IsEmpty && (managers.Find(component) == null))
				managers.Add(component, fullName);
		}

		for (let decl in Type.TypeDeclarations)
		{
			let fullName = decl.GetFullName(.. scope .());
			if (!fullName.StartsWith(namespacePrefix) || (fullName == rootName))
				continue;

			let name = decl.GetName(.. scope .());
			let isStaticBlock = name == cStaticBlockName;
			if (!isStaticBlock && !decl.HasCustomAttribute<ScriptableAttribute>())
				continue;

			let type = decl.ResolvedType;
			if (type == null)
				Runtime.FatalError(scope $"ScriptSurface: {fullName} is marked but did not resolve");

			let code = scope String();
			if (isStaticBlock)
			{
				if (!EmitGlobal(fullName, type, code))
					continue;
			}
			else
			{
				EmitType(decl, fullName, type, managers, allowedDomains, code);
			}

			let entry = new Entry();
			entry.FullName.Set(fullName);
			entry.Code.Set(code);
			entries.Add(entry);
		}

		entries.Sort(scope (a, b) => a.FullName <=> b.FullName);

		let body = scope String();
		body.Append("/// Emitted by ScriptSurfaceWalker: every [Scriptable] type this root's closure declares.\n");
		body.Append("public static void Populate(ScriptSurface surface)\n{\n");
		for (let e in entries)
			body.Append(e.Code);
		body.AppendF("}}\n\n/// The count the walk found, a tripwire for the tests.\npublic const int TypeCount = {};\n", entries.Count);
		Compiler.EmitTypeBody(root, body);
	}

	// ---- one type ----

	[Comptime]
	private static void EmitType(TypeDeclaration decl, StringView fullName, Type type,
		ManagerTable managers, Span<StringView> allowedDomains, String code)
	{
		let domain = scope String(ScriptDomains.Runtime);
		if (decl.GetCustomAttribute<TypeDomainAttribute>() case .Ok(let td))
			domain.Set(td.Domain);
		if (!Allowed(domain, allowedDomains))
			Runtime.FatalError(scope $"ScriptSurface: {fullName} is in domain {domain}, which this surface does not allow");

		var kind = ScriptTypeKind.Class;
		if (type.IsEnum)
			kind = .Enum;
		else if (type.IsStruct)
			kind = .Struct;
		code.AppendF("\t{{\n\t\tlet t = surface.AddType({}, .{}, {});\n", Quote(fullName, .. scope .()), kind, Quote(domain, .. scope .()));

		bool allPublic = false;
		if (decl.GetCustomAttribute<ScriptableAttribute>() case .Ok(let s))
			allPublic = s.Members == .AllPublic;
		if (allPublic)
			code.Append("\t\tt.Everything();\n");

		if (decl.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let dn))
			code.AppendF("\t\tt.Display({});\n", Quote(dn.Name, .. scope .()));
		if (decl.GetCustomAttribute<DescriptionAttribute>() case .Ok(let ds))
			code.AppendF("\t\tt.Describe({});\n", Quote(ds.Text, .. scope .()));
		if (decl.GetCustomAttribute<CategoryAttribute>() case .Ok(let c))
			code.AppendF("\t\tt.Categorised({});\n", Quote(c.Name, .. scope .()));

		EmitRole(decl, fullName, type, managers, code);

		if (kind == .Enum)
		{
			EmitEnumValues(type, code);
		}
		else
		{
			EmitFields(type, allPublic, code);
			EmitProperties(type, allPublic, code);
			EmitMethods(type, code);
		}
		code.Append("\t}\n");
	}

	[Comptime]
	private static void EmitRole(TypeDeclaration decl, StringView fullName, Type type,
		ManagerTable managers, String code)
	{
		if (type.IsStruct)
		{
			// Component data: a struct the scene pools. Either attribute makes it one.
			let typeId = scope String();
			bool isComponent = decl.HasCustomAttribute<ComponentAttribute>();
			if (decl.GetCustomAttribute<SerializableComponentAttribute>() case .Ok(let sc))
			{
				isComponent = true;
				typeId.Set(sc.TypeId);
			}
			if (!isComponent)
				return;

			let manager = scope String();
			if (let m = managers.Find(fullName))
				manager.Set(m);
			code.AppendF("\t\tt.As(.Component, {}, {});\n", Quote(manager, .. scope .()), Quote(typeId, .. scope .()));
			return;
		}

		if (!type.IsObject)
			return;

		if (!PooledComponent(type, .. scope .()).IsEmpty)
		{
			code.Append("\t\tt.As(.ComponentManager);\n");
			return;
		}

		let role = BaseRole(type);
		if (role != .Plain)
			code.AppendF("\t\tt.As(.{});\n", role);
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

	// ---- the members ----

	[Comptime]
	private static void EmitFields(Type type, bool allPublic, String code)
	{
		for (let f in type.GetFields(.Public | .Instance | .Static | .DeclaredOnly))
		{
			if (f.IsEnumCase || !f.IsPublic)
				continue;
			if (f.HasCustomAttribute<HiddenAttribute>())
				continue;
			if (!allPublic && !f.HasCustomAttribute<ScriptableAttribute>())
				continue;

			let typeName = f.FieldType.GetFullName(.. scope .());
			code.AppendF("\t\tt.AddField({}, {}, {})", Quote(f.Name, .. scope .()), Quote(typeName, .. scope .()), Bool(f.IsStatic));
			if (f.IsReadOnly || f.IsConst)
				code.Append(".ReadOnly()");
			EmitFieldMetadata(f, code);
			code.Append(";\n");
		}
	}

	/// Properties are their accessors in reflection: `get__X` and `set__X`. The getter
	/// carries the property's attributes, and a missing setter makes it read only.
	[Comptime]
	private static void EmitProperties(Type type, bool allPublic, String code)
	{
		for (let m in type.GetMethods(.Public | .Instance | .Static | .DeclaredOnly))
		{
			if (!m.Name.StartsWith("get__") || !m.IsPublic)
				continue;
			let name = m.Name.Substring(5);
			if (name.IsEmpty)
				continue; // an indexer
			if (m.HasCustomAttribute<HiddenAttribute>())
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
			code.AppendF("\t\tt.AddField({}, {}, {}, true)", Quote(name, .. scope .()), Quote(typeName, .. scope .()), Bool(m.IsStatic));
			if (!canWrite)
				code.Append(".ReadOnly()");
			EmitMethodMetadataAsField(m, code);
			code.Append(";\n");
		}
	}

	[Comptime]
	private static void EmitMethods(Type type, String code)
	{
		for (let m in type.GetMethods(.Public | .Instance | .Static | .DeclaredOnly))
		{
			if (!m.IsPublic || m.IsDestructor || m.IsMixin)
				continue;
			if (m.Name.StartsWith("get__") || m.Name.StartsWith("set__"))
				continue;
			if (!m.HasCustomAttribute<ScriptableAttribute>())
				continue;

			if (m.IsConstructor)
			{
				code.Append("\t\tt.AddConstructor()");
			}
			else
			{
				let ret = m.ReturnType.GetFullName(.. scope .());
				code.AppendF("\t\tt.AddMethod({}, {}, {})", Quote(m.Name, .. scope .()), Quote(ret, .. scope .()), Bool(m.IsStatic));
			}

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
				code.AppendF(".Param({}, {}{})", Quote(m.GetParamName(i), .. scope .()), Quote(ptn, .. scope .()), byRef ? ", true" : "");
			}

			if (m.GetCustomAttribute<ScriptNameAttribute>() case .Ok(let sn))
				code.AppendF(".Named({})", Quote(sn.Name, .. scope .()));
			if (m.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let dn))
				code.AppendF(".Display({})", Quote(dn.Name, .. scope .()));
			if (m.GetCustomAttribute<DescriptionAttribute>() case .Ok(let ds))
				code.AppendF(".Describe({})", Quote(ds.Text, .. scope .()));
			code.Append(";\n");
		}
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
	private static bool EmitGlobal(StringView ns, Type type, String code)
	{
		let methods = scope String();
		let scratch = scope String();
		for (let m in type.GetMethods(.Public | .Static | .DeclaredOnly))
		{
			if (!m.IsPublic || !m.HasCustomAttribute<ScriptableAttribute>())
				continue;

			let ret = m.ReturnType.GetFullName(.. scope .());
			methods.AppendF("\t\tt.AddMethod({}, {}, true)", Quote(m.Name, .. scope .()), Quote(ret, .. scope .()));
			for (int i = 0; i < m.ParamCount; i++)
			{
				var pt = m.GetParamType(i);
				bool byRef = false;
				if (let r = pt as RefType)
				{
					byRef = true;
					pt = r.UnderlyingType;
				}
				scratch.Clear();
				pt.GetFullName(scratch);
				methods.AppendF(".Param({}, {}{})", Quote(m.GetParamName(i), .. scope .()), Quote(scratch, .. scope .()), byRef ? ", true" : "");
			}
			if (m.GetCustomAttribute<ScriptNameAttribute>() case .Ok(let sn))
				methods.AppendF(".Named({})", Quote(sn.Name, .. scope .()));
			if (m.GetCustomAttribute<DescriptionAttribute>() case .Ok(let ds))
				methods.AppendF(".Describe({})", Quote(ds.Text, .. scope .()));
			methods.Append(";\n");
		}

		if (methods.IsEmpty)
			return false;

		code.AppendF("\t{{\n\t\tlet t = surface.AddType({}, .Global, {});\n", Quote(ns, .. scope .()), Quote(ScriptDomains.Runtime, .. scope .()));
		code.Append(methods);
		code.Append("\t}\n");
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
