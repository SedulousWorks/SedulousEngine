using System;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The scene's half of the JSON the MCP tools speak (FieldJson, in Editor.App, is the values'):
/// an entity found by what an agent names it with, and a game script's value.
static class ComponentJson
{
	/// An entity by guid, slash path or name; invalid when none.
	public static EntityHandle FindEntity(Sedulous.Scene.Scene scene, StringView text)
	{
		Guid id;
		if (Guid.Parse(text) case .Ok(out id))
			return scene.FindEntity(id);
		if (text.Contains('/'))
			return scene.FindEntityByPath(text);
		return scene.FindEntityByName(text);
	}

	/// A game script value as JSON, OWNED.
	public static JsonValue ScriptJson(ScriptValue value, Sedulous.Scene.Scene scene)
	{
		switch (value.Kind)
		{
		case .Bool: return JsonValue.MakeBool(value.AsBool);
		case .Int: return JsonValue.MakeNumber((double)value.AsInt);
		case .Float: return JsonValue.MakeNumber(value.AsFloat);
		case .String: return JsonValue.MakeString(value.AsString);
		case .Guid: return FieldJson.GuidJson(value.AsGuid);
		case .Float2: var v2 = value.AsFloat2; return FieldJson.ValueJson(typeof(Float2), &v2);
		case .Float3: var v3 = value.AsFloat3; return FieldJson.ValueJson(typeof(Float3), &v3);
		case .Float4: var v4 = value.AsFloat4; return FieldJson.ValueJson(typeof(Float4), &v4);
		case .Quaternion: var q = value.AsQuaternion; return FieldJson.ValueJson(typeof(Quaternion), &q);
		case .Color: var c = value.AsColor; return FieldJson.ValueJson(typeof(Color), &c);
		case .Entity:
			let owner = (value.AsEntityScene != null) ? value.AsEntityScene : scene;
			if ((owner == null) || !owner.IsValid(value.AsEntity))
				return JsonValue.MakeNull();
			return FieldJson.GuidJson(owner.GetEntityId(value.AsEntity));
		case .Nil: return JsonValue.MakeNull();
		default:
			return JsonValue.MakeString(scope $"<{value.Kind}>");
		}
	}
}
