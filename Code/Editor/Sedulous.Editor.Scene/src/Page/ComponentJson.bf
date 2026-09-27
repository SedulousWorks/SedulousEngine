using System;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene;

/// A reflected component's fields as JSON, and a JSON value as the Variant a field takes: what
/// entity_inspect reads and component_set writes. Everything goes through the component's RUN
/// TIME field reflection ([Component] and [SerializableComponent] ask for it), from an address
/// inside the pool plus a type, never a per component ladder:
///
/// - a leaf by its type: numbers, booleans, strings, guids, vectors, quaternions, colours;
/// - a resource reference (a Ref<T>) as its asset guid, through ReferenceShape;
/// - an enum by its case's name;
/// - an entity reference as its guid;
/// - a list as an array of its elements, through IReflectedList;
/// - a nested structure with reflected fields, recursed into;
/// - anything else named as unreadable, so the agent knows something is there.
///
/// Shown fields are the inspector's: public, instance, not [Hidden].
static class ComponentJson
{
	public static bool IsShown(FieldInfo field) => field.IsPublic && !field.IsStatic && !field.HasCustomAttribute<HiddenAttribute>();

	/// The shown fields of the value at `address`, by name, in declaration order.
	public static JsonValue FieldsJson(Type type, void* address)
	{
		let json = JsonValue.MakeObject();
		for (let field in type.GetFields())
		{
			if (IsShown(field))
				json.Set(field.Name, ValueJson(field.FieldType, (uint8*)address + field.MemberOffset));
		}
		return json;
	}

	public static JsonValue ValueJson(Type type, void* address)
	{
		if (ReferenceShape.Is(type))
		{
			if ((ReferenceShape.Id(type, address) case .Ok(let id)) && (id != .()))
				return GuidJson(id);
			return JsonValue.MakeNull();
		}
		if (type == typeof(EntityRef))
		{
			let id = ((EntityRef*)address).Id;
			return (id != .()) ? GuidJson(id) : JsonValue.MakeNull();
		}
		if (type.IsEnum)
		{
			let name = scope String();
			Enum.EnumToString(type, name, RawFieldAccess.ReadRawInt(address, type.Size));
			return JsonValue.MakeString(name);
		}
		switch (type)
		{
		case typeof(bool): return JsonValue.MakeBool(*(bool*)address);
		case typeof(float): return JsonValue.MakeNumber(*(float*)address);
		case typeof(double): return JsonValue.MakeNumber(*(double*)address);
		case typeof(int8): return JsonValue.MakeNumber(*(int8*)address);
		case typeof(uint8): return JsonValue.MakeNumber(*(uint8*)address);
		case typeof(int16): return JsonValue.MakeNumber(*(int16*)address);
		case typeof(uint16): return JsonValue.MakeNumber(*(uint16*)address);
		case typeof(int32): return JsonValue.MakeNumber(*(int32*)address);
		case typeof(uint32): return JsonValue.MakeNumber(*(uint32*)address);
		case typeof(int64): return JsonValue.MakeNumber(*(int64*)address);
		case typeof(uint64): return JsonValue.MakeNumber(*(uint64*)address);
		case typeof(int): return JsonValue.MakeNumber(*(int*)address);
		case typeof(uint): return JsonValue.MakeNumber(*(uint*)address);
		case typeof(Guid): return GuidJson(*(Guid*)address);
		case typeof(String):
			let text = *(String*)address;
			return (text != null) ? JsonValue.MakeString(text) : JsonValue.MakeNull();
		case typeof(Float2):
			let v = *(Float2*)address;
			return Numbers(v.X, v.Y);
		case typeof(Float3):
			let v = *(Float3*)address;
			return Numbers(v.X, v.Y, v.Z);
		case typeof(Float4):
			let v = *(Float4*)address;
			return Numbers(v.X, v.Y, v.Z, v.W);
		case typeof(Quaternion):
			let q = *(Quaternion*)address;
			return Numbers(q.X, q.Y, q.Z, q.W);
		case typeof(Color):
			let c = *(Color*)address;
			return Numbers(c.R, c.G, c.B, c.A);
		default:
		}
		if (type.IsObject)
		{
			let obj = *(Object*)address;
			if (obj == null)
				return JsonValue.MakeNull();
			if (let list = obj as IReflectedList)
			{
				let items = JsonValue.MakeArray();
				for (int i < list.Count)
					items.Add(ValueJson(list.ElementType, list.ElementAddress(i)));
				return items;
			}
		}
		else if (type.IsStruct && !type.IsPrimitive && HasShownFields(type))
		{
			return FieldsJson(type, address);
		}
		// A type this reader has no spelling for: its name, so the agent knows there is
		// something here it cannot read yet.
		let unreadable = JsonValue.MakeObject();
		unreadable.Set("unreadable", JsonValue.MakeString(type.GetFullName(.. scope .())));
		return unreadable;
	}

	/// What a field that component_set does not write is, for its refusal: "list", "structure"
	/// or "object"; null when component_set writes it.
	public static StringView NestedKind(Type type)
	{
		if (ReferenceShape.Is(type) || (type == typeof(EntityRef)) || type.IsEnum || (Shape(type) != null))
			return null;
		if (let generic = type as SpecializedGenericType)
		{
			if (generic.UnspecializedType == typeof(System.Collections.List<>))
				return "list";
		}
		if (type.IsStruct)
			return "structure";
		return type.IsObject ? "object" : null;
	}

	/// The JSON shape a leaf field takes, for a refusal that teaches; null when it is no leaf.
	public static String Shape(Type type)
	{
		switch (type)
		{
		case typeof(bool): return "a boolean";
		case typeof(String): return "a string";
		case typeof(Guid): return "a guid string";
		case typeof(Float2): return "[x, y]";
		case typeof(Float3): return "[x, y, z]";
		case typeof(Float4), typeof(Quaternion): return "[x, y, z, w]";
		case typeof(Color): return "[r, g, b, a]";
		case typeof(float), typeof(double), typeof(int8), typeof(uint8), typeof(int16), typeof(uint16),
			typeof(int32), typeof(uint32), typeof(int64), typeof(uint64), typeof(int), typeof(uint):
			return "a number";
		default: return null;
		}
	}

	/// A JSON value as the Variant a leaf field of `type` takes; an empty Variant when the JSON
	/// has the wrong shape (the refusal names the shape). A String is not written by Variant:
	/// component_set sets it in place.
	public static Variant LeafVariant(Type type, JsonValue value)
	{
		if (value == null)
			return .();
		switch (type)
		{
		case typeof(bool): return value.IsBool ? Variant.Create(value.AsBool()) : .();
		case typeof(float): return value.IsNumber ? Variant.Create((float)value.AsNumber()) : .();
		case typeof(double): return value.IsNumber ? Variant.Create(value.AsNumber()) : .();
		case typeof(int8): return value.IsNumber ? Variant.Create((int8)value.AsNumber()) : .();
		case typeof(uint8): return value.IsNumber ? Variant.Create((uint8)value.AsNumber()) : .();
		case typeof(int16): return value.IsNumber ? Variant.Create((int16)value.AsNumber()) : .();
		case typeof(uint16): return value.IsNumber ? Variant.Create((uint16)value.AsNumber()) : .();
		case typeof(int32): return value.IsNumber ? Variant.Create((int32)value.AsNumber()) : .();
		case typeof(uint32): return value.IsNumber ? Variant.Create((uint32)value.AsNumber()) : .();
		case typeof(int64): return value.IsNumber ? Variant.Create((int64)value.AsNumber()) : .();
		case typeof(uint64): return value.IsNumber ? Variant.Create((uint64)value.AsNumber()) : .();
		case typeof(int): return value.IsNumber ? Variant.Create((int)value.AsNumber()) : .();
		case typeof(uint): return value.IsNumber ? Variant.Create((uint)value.AsNumber()) : .();
		case typeof(Guid):
			if (value.IsString && (Guid.Parse(value.AsString()) case .Ok(let id)))
				return Variant.Create(id);
			return .();
		case typeof(Float2):
			float[4] n = ?;
			return Numbers(value, 2, ref n) ? Variant.Create(Float2(n[0], n[1])) : .();
		case typeof(Float3):
			float[4] n = ?;
			return Numbers(value, 3, ref n) ? Variant.Create(Float3(n[0], n[1], n[2])) : .();
		case typeof(Float4):
			float[4] n = ?;
			return Numbers(value, 4, ref n) ? Variant.Create(Float4(n[0], n[1], n[2], n[3])) : .();
		case typeof(Quaternion):
			float[4] n = ?;
			return Numbers(value, 4, ref n) ? Variant.Create(Quaternion(n[0], n[1], n[2], n[3])) : .();
		case typeof(Color):
			float[4] n = ?;
			return Numbers(value, 4, ref n) ? Variant.Create(Color(n[0], n[1], n[2], n[3])) : .();
		default: return .();
		}
	}

	/// An enum case by name or by number; false when neither names one.
	public static bool EnumValueOf(Type type, JsonValue value, out int64 outValue)
	{
		outValue = 0;
		if (value == null)
			return false;
		for (var (name, data) in Enum.GetEnumerator(type))
		{
			if ((value.IsString && (value.AsString() == name)) || (value.IsNumber && ((int64)value.AsNumber() == data)))
			{
				outValue = data;
				return true;
			}
		}
		return false;
	}

	public static void EnumNames(Type type, String outNames)
	{
		for (var (name, data) in Enum.GetEnumerator(type))
		{
			if (!outNames.IsEmpty)
				outNames.Append(", ");
			outNames.Append(name);
		}
	}

	public static JsonValue GuidJson(Guid id) => JsonValue.MakeString(id.ToString(.. scope .()));

	private static bool HasShownFields(Type type)
	{
		for (let field in type.GetFields())
		{
			if (IsShown(field))
				return true;
		}
		return false;
	}

	private static JsonValue Numbers(params float[] values)
	{
		let json = JsonValue.MakeArray();
		for (let v in values)
			json.Add(JsonValue.MakeNumber(v));
		return json;
	}

	private static bool Numbers(JsonValue value, int count, ref float[4] outValues)
	{
		if (!value.IsArray || (value.Count != count))
			return false;
		for (int i < count)
		{
			let item = value.At(i);
			if (!item.IsNumber)
				return false;
			outValues[i] = (float)item.AsNumber();
		}
		return true;
	}
}
