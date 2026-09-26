using System;
using System.Reflection;
using Sedulous.Json;
using Sedulous.Mcp;

namespace Sedulous.Mcp.Reflection;

/// The reflection tool contribution: type_list and type_info, registered against an McpServer.
///
/// These let an agent discover the authored surface (types, fields, methods, enum values) so it
/// can write correct scripts and scene edits. Pure queries over Beef's own type table, with no
/// project or pipeline dependency. A module contributes its own tools, and this is the
/// reflection module's contribution.
///
/// Two consequences of the reflection being Beef's own rather than a hand-rolled registry:
///
/// - No `domain` or `inPlayer` key. Beef offers nothing to derive one from, and reporting
///   a guess would be worse than omitting the field.
/// - The `properties` array carries Beef FIELDS: a field is the reflection of a data
///   member, and the key keeps the generic name so one agent prompt reads naturally.
static class ReflectionTools
{
	/// Registers type_list and type_info against `server`.
	///
	/// Beef's type table is global and process-wide, so there is no registry to pass and no
	/// lifetime to manage: this cannot be pointed at a private registry. The table is read
	/// LIVE at call time.
	public static void Register(McpServer server)
	{
		let listSchema = scope SchemaBuilder();
		listSchema.Str("namespace", "only types whose namespace starts with this prefix");
		server.RegisterTool("type_list",
			"List reflected types (name + namespace), optionally filtered by a namespace prefix.",
			listSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => TypeList(arguments, outResult));

		let infoSchema = scope SchemaBuilder();
		infoSchema.Str("type", "the unqualified type name (e.g. \"JsonValue\")", true);
		infoSchema.Str("namespace", "the exact namespace, to disambiguate a duplicated name");
		server.RegisterTool("type_info",
			"Describe a reflected type: its fields, methods (with params/returns), and enum values.",
			infoSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => TypeInfo(arguments, outResult, outError));
	}

	// ---- Tools -----------------------------------------------------------------------------

	private static bool TypeList(JsonValue arguments, JsonValue outResult)
	{
		let filter = ArgString(arguments, "namespace", .. scope String());

		let name = scope String();
		let namespaceName = scope String();
		let types = JsonValue.MakeArray();

		for (let type in Type.Types)
		{
			if (!IsAuthoredType(type))
				continue;

			SplitQualifiedName(type.GetFullName(.. scope:: String()), namespaceName, name);
			if (!filter.IsEmpty && !((StringView)namespaceName).StartsWith(filter))
				continue;

			let entry = JsonValue.MakeObject();
			entry.Set("name", JsonValue.MakeString(name));
			entry.Set("namespace", JsonValue.MakeString(namespaceName));
			types.Add(entry);
		}

		outResult.Set("count", JsonValue.MakeNumber((double)types.Count));
		outResult.Set("types", types);
		return true;
	}

	private static bool TypeInfo(JsonValue arguments, JsonValue outResult, String outError)
	{
		let wantedType = ArgString(arguments, "type", .. scope String());
		let wantedNamespace = ArgString(arguments, "namespace", .. scope String());

		let name = scope String();
		let namespaceName = scope String();
		Type found = null;

		for (let type in Type.Types)
		{
			if (!IsAuthoredType(type))
				continue;

			SplitQualifiedName(type.GetFullName(.. scope:: String()), namespaceName, name);
			if (name != wantedType)
				continue;
			// An empty namespace argument takes the FIRST match, which is why the argument
			// exists: a name that appears twice needs it to pick one.
			if (!wantedNamespace.IsEmpty && (namespaceName != wantedNamespace))
				continue;

			found = type;
			break;
		}

		if (found == null)
		{
			outError.AppendF("unknown type '{}'", wantedType);
			return false;
		}

		Describe(found, outResult);
		return true;
	}

	// ---- Description -----------------------------------------------------------------------

	private static void Describe(Type type, JsonValue outResult)
	{
		let name = scope String();
		let namespaceName = scope String();
		SplitQualifiedName(type.GetFullName(.. scope String()), namespaceName, name);

		outResult.Set("name", JsonValue.MakeString(name));
		outResult.Set("namespace", JsonValue.MakeString(namespaceName));

		if (let instance = type as TypeInstance)
		{
			if (instance.BaseType != null)
				outResult.Set("base",
					JsonValue.MakeString(instance.BaseType.GetName(.. scope String())));
		}

		let properties = JsonValue.MakeArray();
		for (let field in type.GetFields())
		{
			// Enum cases are fields too, and they are reported under `enum` instead.
			if (field.IsEnumCase)
				continue;

			let entry = JsonValue.MakeObject();
			entry.Set("name", JsonValue.MakeString(field.Name));
			entry.Set("type", JsonValue.MakeString(TypeName(field.FieldType, .. scope String())));
			properties.Add(entry);
		}
		outResult.Set("properties", properties);

		let methods = JsonValue.MakeArray();
		for (let method in type.GetMethods())
		{
			if (method.IsDestructor)
				continue;

			let entry = JsonValue.MakeObject();
			entry.Set("name", JsonValue.MakeString(method.Name));
			entry.Set("returns",
				JsonValue.MakeString(TypeName(method.ReturnType, .. scope String())));

			let parameters = JsonValue.MakeArray();
			for (int i < method.ParamCount)
			{
				let parameter = JsonValue.MakeObject();
				parameter.Set("name", JsonValue.MakeString(method.GetParamName(i)));
				parameter.Set("type",
					JsonValue.MakeString(TypeName(method.GetParamType(i), .. scope String())));
				parameters.Add(parameter);
			}
			entry.Set("params", parameters);
			methods.Add(entry);
		}
		outResult.Set("methods", methods);

		if (type.IsEnum)
		{
			let values = JsonValue.MakeArray();
			for (let (caseName, caseValue) in Enum.GetEnumerator(type))
			{
				let entry = JsonValue.MakeObject();
				entry.Set("name", JsonValue.MakeString(caseName));
				entry.Set("value", JsonValue.MakeNumber((double)caseValue));
				values.Add(entry);
			}
			// Only when there is something to say: a payload enum with no cases would emit an
			// empty array, which reads as "this is an enum with no values".
			if (values.Count > 0)
				outResult.Set("enum", values);
			else
				delete values;
		}
	}

	// ---- Helpers ---------------------------------------------------------------------------

	/// Whether a type is one somebody WROTE, rather than one the compiler derived from it.
	///
	/// Beef's table holds every pointer, array, boxed wrapper and generic parameter it ever
	/// built. Listing the derived ones would bury the authored surface these tools exist to
	/// expose.
	private static bool IsAuthoredType(Type type)
	{
		if (!(type is TypeInstance))
			return false;
		return !type.IsBoxed && !type.IsPointer && !type.IsArray && !type.IsSizedArray
			&& !type.IsGenericParam && !type.IsTuple;
	}

	/// Beef's runtime Type exposes only the qualified name, so the namespace is whatever sits
	/// before the last dot. The scan stops at the first '<' so that a GENERIC ARGUMENT's own
	/// namespace is never mistaken for this type's.
	private static void SplitQualifiedName(StringView full, String outNamespace, String outName)
	{
		outNamespace.Clear();
		outName.Clear();

		int limit = full.Length;
		let generic = full.IndexOf('<');
		if (generic >= 0)
			limit = generic;

		int dot = -1;
		for (int i < limit)
		{
			if (full[i] == '.')
				dot = i;
		}

		if (dot < 0)
		{
			outName.Set(full);
			return;
		}
		outNamespace.Set(full.Substring(0, dot));
		outName.Set(full.Substring(dot + 1));
	}

	/// A member type's name, or "void" when there is none, which is how an agent reads an
	/// absent return type.
	private static void TypeName(Type type, String outName)
	{
		if (type == null)
		{
			outName.Set("void");
			return;
		}
		type.GetName(outName);
	}

	/// A string argument, or empty when absent. The schema has already accepted the call, so a
	/// missing optional field is simply not there.
	private static void ArgString(JsonValue arguments, StringView key, String outValue)
	{
		let value = arguments.Get(key);
		if ((value != null) && value.IsString)
			outValue.Set(value.AsString());
	}
}
