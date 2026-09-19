using System;
using System.Collections;

namespace Sedulous.Script;

/// How a Beef type crosses the boundary: the ScriptValue kind it takes, the expression that
/// reads it out of a value, and the one that puts it in. Comptime only; the walker asks it
/// for every parameter, return and field it emits.
///
/// A class, struct or enum crosses only when it is itself on the surface (`known`): a
/// script cannot hold, size or name a type the surface does not describe. Ref<T> crosses as
/// the Guid it holds, whatever T.
static class ScriptValueMap
{
	/// Whether a named type is on the surface.
	[Comptime]
	public static bool IsKnown(StringView fullName, List<String> known)
	{
		for (let k in known)
		{
			if (k == fullName)
				return true;
		}
		return false;
	}

	/// The ScriptValueKind a type crosses as, as the emitted `.Kind` text. Nil for void and
	/// for a type that cannot cross.
	[Comptime]
	public static void KindOf(Type type, String outKind)
	{
		let name = type.GetFullName(.. scope .());
		switch (name)
		{
		case "void": outKind.Append("Nil"); return;
		case "float", "double": outKind.Append("Float"); return;
		case "bool": outKind.Append("Bool"); return;
		case "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "char8", "char32":
			outKind.Append("Int"); return;
		case "System.StringView": outKind.Append("String"); return;
		case "System.String": outKind.Append("Object"); return;
		case "System.Guid": outKind.Append("Guid"); return;
		case "Sedulous.Scene.EntityHandle": outKind.Append("Entity"); return;
		case "Sedulous.Core.Float2", "Sedulous.Core.Float3", "Sedulous.Core.Float4",
			"Sedulous.Core.Quaternion", "Sedulous.Core.Color":
			outKind.Append(name.Substring("Sedulous.Core.".Length)); return;
		}
		if (type.IsEnum)
			outKind.Append("Int");
		else if (IsRef(name))
			outKind.Append("Guid");
		else if (type.IsObject)
			outKind.Append("Object");
		else if (type.IsStruct && !type.IsPointer && !name.EndsWith("]"))
			outKind.Append("Struct");
		else
			outKind.Append("Nil");
	}

	/// The check a thunk makes before reading argument `i` as `type`: the kind, and the
	/// type name for a class or struct.
	[Comptime]
	public static void ExpectFor(Type type, int i, String outCode)
	{
		let kind = KindOf(type, .. scope .());
		if ((kind == "Object") || (kind == "Struct"))
			outCode.AppendF("\tif (!frame.Expect({}, .{}, \"{}\")) return;\n", i, kind, type.GetFullName(.. scope .()));
		else
			outCode.AppendF("\tif (!frame.Expect({}, .{})) return;\n", i, kind);
	}

	/// The dispatch key of a type: what an overload resolver can tell apart at the boundary.
	/// Integers and enums are all Int, floats all Float; a class or struct is its own key.
	[Comptime]
	public static void KindKey(Type type, String outKey)
	{
		let name = type.GetFullName(.. scope .());
		switch (name)
		{
		case "float", "double": outKey.Append("Float"); return;
		case "bool": outKey.Append("Bool"); return;
		case "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "char8", "char32":
			outKey.Append("Int"); return;
		case "System.StringView": outKey.Append("String"); return;
		case "System.String": outKey.Append("Object:System.String"); return;
		case "System.Guid": outKey.Append("Guid"); return;
		case "Sedulous.Scene.EntityHandle": outKey.Append("Entity"); return;
		case "Sedulous.Core.Float2", "Sedulous.Core.Float3", "Sedulous.Core.Float4",
			"Sedulous.Core.Quaternion", "Sedulous.Core.Color":
			outKey.Append(name.Substring("Sedulous.Core.".Length)); return;
		}
		if (type.IsEnum)
			outKey.Append("Int");
		else if (IsRef(name))
			outKey.Append("Guid");
		else if (type.IsObject)
			outKey.AppendF("Object:{}", name);
		else
			outKey.AppendF("Struct:{}", name);
	}

	/// The full name of Ref<T>, which crosses as the Guid it holds.
	public const String cRefPrefix = "Sedulous.Resource.Ref<";

	[Comptime]
	public static bool IsRef(StringView fullName) => fullName.StartsWith(cRefPrefix);

	/// Whether the type is one of the inline value kinds, which are copied and written
	/// back rather than reached through a pointer.
	[Comptime]
	public static bool IsInlineStruct(StringView fullName)
	{
		switch (fullName)
		{
		case "Sedulous.Core.Float2", "Sedulous.Core.Float3", "Sedulous.Core.Float4",
			"Sedulous.Core.Quaternion", "Sedulous.Core.Color", "Sedulous.Scene.EntityHandle",
			"System.Guid":
			return true;
		default:
			return false;
		}
	}

	/// The expression reading a value of `type` from `value` (a ScriptValue expression).
	/// False when the type cannot cross, with the reason in outCode.
	[Comptime]
	public static bool Read(Type type, StringView value, List<String> known, String outCode)
	{
		let name = type.GetFullName(.. scope .());
		switch (name)
		{
		case "float": outCode.AppendF("(float){}.AsNumber", value); return true;
		case "double": outCode.AppendF("{}.AsNumber", value); return true;
		case "bool": outCode.AppendF("{}.AsBool", value); return true;
		case "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "char8", "char32":
			outCode.AppendF("({}){}.AsInt", name, value); return true;
		case "System.StringView": outCode.AppendF("{}.AsString", value); return true;
		case "System.String": outCode.AppendF("(System.String){}.AsObject", value); return true;
		case "System.Guid": outCode.AppendF("{}.AsGuid", value); return true;
		case "Sedulous.Scene.EntityHandle": outCode.AppendF("{}.AsEntity", value); return true;
		case "Sedulous.Core.Float2": outCode.AppendF("{}.AsFloat2", value); return true;
		case "Sedulous.Core.Float3": outCode.AppendF("{}.AsFloat3", value); return true;
		case "Sedulous.Core.Float4": outCode.AppendF("{}.AsFloat4", value); return true;
		case "Sedulous.Core.Quaternion": outCode.AppendF("{}.AsQuaternion", value); return true;
		case "Sedulous.Core.Color": outCode.AppendF("{}.AsColor", value); return true;
		}

		if (!Crossable(type, name, known, outCode))
			return false;
		if (type.IsEnum)
			outCode.AppendF("({}){}.AsInt", name, value);
		else if (type.IsObject)
			outCode.AppendF("({}){}.AsObject", name, value);
		else
			outCode.AppendF("*({}*){}.AsStruct", name, value);
		return true;
	}

	/// Whether a non-inline type can cross at all: a class, enum or plain struct that is on
	/// the surface. The reason goes in outCode when not.
	[Comptime]
	private static bool Crossable(Type type, StringView name, List<String> known, String outCode)
	{
		if (!(type.IsEnum || type.IsObject || (type.IsStruct && !type.IsPointer && !IsRef(name) && !name.EndsWith("]"))))
		{
			outCode.Set(name);
			return false;
		}
		if (IsKnown(name, known))
			return true;
		// A list of a surface type is an object a VM binds natively.
		const String cList = "System.Collections.List<";
		if (name.StartsWith(cList) && name.EndsWith(">")
			&& IsKnown(name.Substring(cList.Length, name.Length - cList.Length - 1), known))
			return true;
		outCode.AppendF("{} is not on the surface", name);
		return false;
	}

	/// The statement storing `expr`, of `type`, into `slot` (a ScriptValue lvalue), or into
	/// the frame's struct storage when it is a pointer kind. False when it cannot cross.
	[Comptime]
	public static bool Write(Type type, StringView expr, StringView slot, List<String> known, String outCode,
		StringView entityScene = "null")
	{
		let name = type.GetFullName(.. scope .());
		switch (name)
		{
		case "void": outCode.AppendF("{}; {} = .Nil;", expr, slot); return true;
		case "float", "double": outCode.AppendF("{} = .FromFloat({});", slot, expr); return true;
		case "bool": outCode.AppendF("{} = .FromBool({});", slot, expr); return true;
		case "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "char8", "char32":
			outCode.AppendF("{} = .FromInt((int64){});", slot, expr); return true;
		case "System.StringView": outCode.AppendF("{} = .FromString({});", slot, expr); return true;
		case "System.String": outCode.AppendF("{} = .FromObject({});", slot, expr); return true;
		case "System.Guid": outCode.AppendF("{} = .FromGuid({});", slot, expr); return true;
		case "Sedulous.Scene.EntityHandle": outCode.AppendF("{} = .FromEntity({}, {});", slot, expr, entityScene); return true;
		case "Sedulous.Core.Float2": outCode.AppendF("{} = .FromFloat2({});", slot, expr); return true;
		case "Sedulous.Core.Float3": outCode.AppendF("{} = .FromFloat3({});", slot, expr); return true;
		case "Sedulous.Core.Float4": outCode.AppendF("{} = .FromFloat4({});", slot, expr); return true;
		case "Sedulous.Core.Quaternion": outCode.AppendF("{} = .FromQuaternion({});", slot, expr); return true;
		case "Sedulous.Core.Color": outCode.AppendF("{} = .FromColor({});", slot, expr); return true;
		}

		if (!Crossable(type, name, known, outCode))
			return false;
		if (type.IsEnum)
		{
			outCode.AppendF("{} = .FromInt((int64){});", slot, expr);
		}
		else if (type.IsObject)
		{
			outCode.AppendF("{} = .FromObject({});", slot, expr);
		}
		else
		{
			// Only the frame's result has struct storage.
			if (slot != "frame.Result")
			{
				outCode.Set(name);
				return false;
			}
			outCode.AppendF("frame.SetStruct<{}>({});", name, expr);
		}
		return true;
	}
}
