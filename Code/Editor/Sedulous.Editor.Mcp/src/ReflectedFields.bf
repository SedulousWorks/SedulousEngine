using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Mcp;

/// A record's [Setting] fields over MCP, read from its reflection rather than spelled out per
/// tool: the project's settings (project_info, project_settings_set) and an export preset
/// (export_presets, export_preset_set). A field is named by its key ("defaultSceneId"). The
/// answer, the arguments' schema, the check of given values and their write are each one
/// function here, so the tools differ only in their own rules (MSAA's levels, a preset's
/// platform and config).
static class ReflectedFields
{
	/// One given value, checked and held until every one is: a refusal leaves the record as it
	/// was.
	public class Change
	{
		public FieldInfo Field;
		public SettingKind Kind;
		public Guid Id;
		/// An asset list's whole list.
		public List<Guid> Ids = new .() ~ delete _;
		/// A text list's whole list.
		public List<String> Texts = new .() ~ DeleteContainerAndItems!(_);
		public String Text = new .() ~ delete _;
		public bool Flag;
		public int64 Choice;
		public uint32 Number;
	}

	/// The fields' keys, comma separated: what a refusal of an unknown one lists.
	public static void Keys(Span<FieldInfo> fields, String outKeys)
	{
		for (let field in fields)
		{
			if (!outKeys.IsEmpty)
				outKeys.Append(", ");
			SettingFields.Key(field, outKeys);
		}
	}

	/// The first argument that names no field and is not one of `extra` (the tool's own), in
	/// `outKey`: a misspelled field is refused, not ignored. False when every one is known.
	public static bool UnknownArgument(JsonValue arguments, Span<FieldInfo> fields, Span<StringView> extra, String outKey)
	{
		let key = scope String();
		for (let argument in arguments.Keys)
		{
			bool known = false;
			for (let field in fields)
			{
				SettingFields.Key(field, key..Clear());
				known |= (key == argument);
			}
			for (let name in extra)
				known |= (name == argument);
			if (!known)
			{
				outKey.Set(argument);
				return true;
			}
		}
		return false;
	}

	/// An asset a field names, as {guid, path}; the path is null when the guid names nothing
	/// (or there is no database to look in).
	private static JsonValue AssetJson(ContentDatabase db, Guid id)
	{
		let instance = (db != null) ? db.GetInstance(id) : null;
		let entry = JsonValue.MakeObject();
		entry.Set("guid", McpTools.GuidToJson(id));
		entry.Set("path", (instance != null) ? JsonValue.MakeString(instance.GetPath(.. scope .())) : JsonValue.MakeNull());
		return entry;
	}

	/// The fields' values: an asset as {guid, path} (null when unset), a list as an array, a
	/// text as text, a flag as a bool, a choice by its case's name, a count as a number.
	public static JsonValue ToJson(Object record, Span<FieldInfo> fields, ContentDatabase db)
	{
		let json = JsonValue.MakeObject();
		let key = scope String();
		for (let field in fields)
		{
			SettingFields.Key(field, key..Clear());
			SettingFields.KindOf(field, let kind);
			let address = SettingFields.Address(record, field);
			switch (kind)
			{
			case .Asset:
				let id = *(Guid*)address;
				json.Set(key, id.IsSet ? AssetJson(db, id) : JsonValue.MakeNull());
			case .AssetList:
				let list = JsonValue.MakeArray();
				for (let id in *(List<Guid>*)address)
					list.Add(AssetJson(db, id));
				json.Set(key, list);
			case .TextList:
				let list = JsonValue.MakeArray();
				for (let text in *(List<String>*)address)
					list.Add(JsonValue.MakeString(text));
				json.Set(key, list);
			case .Text:
				json.Set(key, JsonValue.MakeString(*(String*)address));
			case .Flag:
				json.Set(key, JsonValue.MakeBool(*(bool*)address));
			case .Choice:
				let name = scope String();
				Enum.EnumToString(field.FieldType, name, SettingFields.ReadChoice(record, field));
				json.Set(key, JsonValue.MakeString(name));
			case .Count:
				json.Set(key, JsonValue.MakeNumber(*(uint32*)address));
			}
		}
		return json;
	}

	/// One argument per field, as reflection describes it.
	public static void AddToSchema(SchemaBuilder schema, Span<FieldInfo> fields)
	{
		let key = scope String();
		let text = scope String();
		for (let field in fields)
		{
			SettingFields.Key(field, key..Clear());
			SettingFields.KindOf(field, let kind);
			let setting = SettingFields.Setting(field).Value;
			text.Clear();
			switch (kind)
			{
			case .AssetList:
				text.AppendF("{}: the guids of assets of type {}, in order; the whole list, [] for none", setting.Label, setting.AssetType);
				schema.Arr(key, "string", text);
			case .Asset:
				text.AppendF("{}: the guid of an asset of type {}; \"\" clears it ({})", setting.Label, setting.AssetType, setting.EmptyText);
				schema.Str(key, text);
			case .TextList:
				text.AppendF("{}: the whole list, [] for none", setting.Label);
				schema.Arr(key, "string", text);
			case .Text:
				schema.Str(key, setting.Label);
			case .Flag:
				schema.Boolean(key, setting.Label);
			case .Choice:
				let names = scope List<StringView>();
				for (let name in Enum.GetNames(field.FieldType))
					names.Add(name);
				schema.Enum(key, names, setting.Label);
			case .Count:
				SettingFields.CountRange(field, let least, let most);
				if (most == uint32.MaxValue)
					text.Append(setting.Label);
				else
					text.AppendF("{}: {} to {}", setting.Label, least, most);
				schema.Integer(key, text);
			}
		}
	}

	/// The stored type name against the setting's short name ("SceneDocument").
	public static bool IsType(Instance instance, StringView shortName)
	{
		let typeName = instance.TypeName;
		return (typeName == shortName) || (typeName.EndsWith(shortName) && (typeName.Length > shortName.Length) && (typeName[typeName.Length - shortName.Length - 1] == '.'));
	}

	/// One guid naming an asset of the setting's type in `db`; the refusal, naming `place`,
	/// appended to outError when it does not.
	private static bool CheckAsset(ContentDatabase db, StringView place, StringView assetType, StringView text, out Guid id, String outError)
	{
		id = .Empty;
		if (Guid.Parse(text) case .Ok(let parsed))
			id = parsed;
		else
		{
			outError.AppendF("`{}`: '{}' is not a valid guid", place, text);
			return false;
		}
		let instance = (db != null) ? db.GetInstance(id) : null;
		if (instance == null)
		{
			outError.AppendF("`{}`: no asset with guid {} in the project", place, text);
			return false;
		}
		if (!IsType(instance, assetType))
		{
			outError.AppendF("`{}` takes an asset of type {}; '{}' is of type {}", place, assetType, instance.Name, instance.TypeName);
			return false;
		}
		return true;
	}

	/// Checks every argument that names one of `fields` against its kind: an asset must exist
	/// in `db` and be of the setting's type (an asset list's entries once each), a count within
	/// its range, a choice one of its cases, a flag a bool. The changes, OWNED by the caller, or
	/// false with the refusal.
	public static bool Check(JsonValue arguments, Span<FieldInfo> fields, ContentDatabase db, List<Change> outChanges, String outError)
	{
		let key = scope String();
		for (let field in fields)
		{
			SettingFields.Key(field, key..Clear());
			let value = arguments.Get(key);
			if (value == null)
				continue;
			let change = new Change();
			outChanges.Add(change);
			change.Field = field;
			SettingFields.KindOf(field, out change.Kind);
			let setting = SettingFields.Setting(field).Value;
			switch (change.Kind)
			{
			case .AssetList:
				if (!value.IsArray)
				{
					outError.AppendF("`{}` takes an array of {} guids", key, setting.AssetType);
					return false;
				}
				for (int i < value.Count)
				{
					if (!CheckAsset(db, scope $"{key}[{i}]", setting.AssetType, value.At(i).AsString(), let id, outError))
						return false;
					if (!change.Ids.Contains(id))
						change.Ids.Add(id); // once each
				}
			case .Asset:
				let text = value.AsString();
				if (!text.IsEmpty && !CheckAsset(db, key, setting.AssetType, text, out change.Id, outError))
					return false;
			case .TextList:
				if (!value.IsArray)
				{
					outError.AppendF("`{}` takes an array of texts", key);
					return false;
				}
				for (int i < value.Count)
					change.Texts.Add(new String(value.At(i).AsString()));
			case .Text:
				change.Text.Set(value.AsString());
			case .Flag:
				if (!value.IsBool)
				{
					outError.AppendF("`{}` takes true or false", key);
					return false;
				}
				change.Flag = value.AsBool();
			case .Choice:
				// By a case's name only (Enum.Parse would take a number too).
				bool named = false;
				for (var (name, data) in Enum.GetEnumerator(field.FieldType))
				{
					if (value.IsString && (name == value.AsString()))
					{
						named = true;
						change.Choice = data;
					}
				}
				if (!named)
				{
					outError.AppendF("`{}` takes {}", key, SettingFields.ChoiceNames(field.FieldType, .. scope .()));
					return false;
				}
			case .Count:
				SettingFields.CountRange(field, let least, let most);
				let number = value.AsNumber(-1.0);
				if (!value.IsNumber || (number < least) || (number > most) || (number != Math.Floor(number)))
				{
					if (most == uint32.MaxValue)
						outError.AppendF("`{}` takes a count from {}", key, least);
					else
						outError.AppendF("`{}` takes {} to {}", key, least, most);
					return false;
				}
				change.Number = (uint32)number;
			}
		}
		return true;
	}

	/// Writes checked changes into `record`.
	public static void Apply(Object record, Span<Change> changes)
	{
		for (let change in changes)
		{
			let address = SettingFields.Address(record, change.Field);
			switch (change.Kind)
			{
			case .AssetList:
				let ids = (List<Guid>*)address;
				(*ids).Clear();
				(*ids).AddRange(change.Ids);
			case .Asset:
				*(Guid*)address = change.Id;
			case .TextList:
				let texts = *(List<String>*)address;
				ClearAndDeleteItems(texts);
				for (let text in change.Texts)
					texts.Add(new String(text));
			case .Text:
				(*(String*)address).Set(change.Text);
			case .Flag:
				*(bool*)address = change.Flag;
			case .Choice:
				SettingFields.WriteChoice(record, change.Field, change.Choice);
			case .Count:
				*(uint32*)address = change.Number;
			}
		}
	}
}
