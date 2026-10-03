using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;

namespace Sedulous.Engine.Project;

/// A field a settings editor offers: its label and, for an asset setting (a guid or a list of
/// them), the asset type it takes and what unset means. The Project Settings dialog builds its
/// rows from these and the MCP tools their arguments, so a field added with one is offered by
/// both rather than by whichever hand list remembered it. A count's bounds are its `Range`; a
/// choice's enum reflects its cases (`[Reflect(.StaticFields)]`), the names it is offered by.
[AttributeUsage(.Field, .ReflectAttribute, ReflectUser = .Type | .NonStaticFields)]
struct SettingAttribute : Attribute
{
	public String Label;
	/// The asset type a guid takes ("SceneDocument"), as the asset picker filters by; null for
	/// a setting that is not an asset.
	public String AssetType;
	/// What an unset asset setting means: "(none)", "(built-in)".
	public String EmptyText;

	public this(String label)
	{
		Label = label;
		AssetType = null;
		EmptyText = null;
	}

	public this(String label, String assetType, String emptyText)
	{
		Label = label;
		AssetType = assetType;
		EmptyText = emptyText;
	}
}

/// What a setting field holds, which decides how it is shown, read and checked.
enum SettingKind
{
	Text,
	/// A list of texts, set whole.
	TextList,
	/// An asset's guid; nil is unset.
	Asset,
	/// Assets' guids in order, set whole.
	AssetList,
	/// A uint32 within its Range.
	Count,
	Flag,
	/// An enum, by its cases' names.
	Choice
}

/// The setting fields of a type, read from its reflection.
static class SettingFields
{
	/// The fields of `type` that carry a Setting and are of a kind a settings editor handles,
	/// in declaration order.
	public static void Of(Type type, List<FieldInfo> outFields)
	{
		for (let field in type.GetFields())
		{
			if (!field.IsEnumCase && (Setting(field) != null) && KindOf(field, ?))
				outFields.Add(field);
		}
	}

	/// The field's Setting, or null.
	public static SettingAttribute? Setting(FieldInfo field)
	{
		if (field.GetCustomAttribute<SettingAttribute>() case .Ok(let setting))
			return setting;
		return null;
	}

	/// What the field holds; false for a type no settings editor handles.
	public static bool KindOf(FieldInfo field, out SettingKind kind)
	{
		kind = .Text;
		let type = field.FieldType;
		let setting = Setting(field);
		let isAsset = setting.HasValue && (setting.Value.AssetType != null);
		if (type == typeof(String))
			kind = .Text;
		else if (type == typeof(List<String>))
			kind = .TextList;
		else if ((type == typeof(Guid)) && isAsset)
			kind = .Asset;
		else if ((type == typeof(List<Guid>)) && isAsset)
			kind = .AssetList;
		else if (type == typeof(uint32))
			kind = .Count;
		else if (type == typeof(bool))
			kind = .Flag;
		else if (type.IsEnum && (type.Size <= 8))
			kind = .Choice;
		else
			return false;
		return true;
	}

	/// The key a tool names the field by: its name with the first letter lowered
	/// ("DefaultSceneId" is "defaultSceneId").
	public static void Key(FieldInfo field, String outKey)
	{
		let start = outKey.Length;
		outKey.Append(field.Name);
		if (outKey.Length > start)
			outKey[start] = outKey[start].ToLower;
	}

	/// The field's storage in `record`.
	public static void* Address(Object record, FieldInfo field) =>
		(uint8*)Internal.UnsafeCastToPtr(record) + field.MemberOffset;

	/// A count's bounds: its Range, else every uint32.
	public static void CountRange(FieldInfo field, out uint32 least, out uint32 most)
	{
		least = 0;
		most = uint32.MaxValue;
		if (field.GetCustomAttribute<RangeAttribute>() case .Ok(let range))
		{
			least = (uint32)Math.Max(range.Min, 0.0f);
			most = (uint32)range.Max;
		}
	}

	/// A choice field's value.
	public static int64 ReadChoice(Object record, FieldInfo field)
	{
		let address = Address(record, field);
		switch (field.FieldType.Size)
		{
		case 1: return *(int8*)address;
		case 2: return *(int16*)address;
		case 4: return *(int32*)address;
		default: return *(int64*)address;
		}
	}

	public static void WriteChoice(Object record, FieldInfo field, int64 value)
	{
		let address = Address(record, field);
		switch (field.FieldType.Size)
		{
		case 1: *(int8*)address = (int8)value;
		case 2: *(int16*)address = (int16)value;
		case 4: *(int32*)address = (int32)value;
		default: *(int64*)address = value;
		}
	}

	/// Every asset `record`'s settings name, with the setting's key: an asset setting's guid
	/// (nil when unset) and each of an asset list's.
	public static void ForEachAsset(Object record, delegate void(StringView key, Guid id) visit)
	{
		let fields = scope List<FieldInfo>();
		Of(record.GetType(), fields);
		let key = scope String();
		for (let field in fields)
		{
			KindOf(field, let kind);
			Key(field, key..Clear());
			if (kind == .Asset)
				visit(key, *(Guid*)Address(record, field));
			else if (kind == .AssetList)
			{
				for (let id in *(List<Guid>*)Address(record, field))
					visit(key, id);
			}
		}
	}

	/// A choice field's case names, comma separated: what a refusal lists.
	public static void ChoiceNames(Type type, String outNames)
	{
		for (let name in Enum.GetNames(type))
		{
			if (!outNames.IsEmpty)
				outNames.Append(", ");
			outNames.Append(name);
		}
	}
}
