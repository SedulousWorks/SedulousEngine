using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Script.Resource;

/// Fills a script class record from a compiled class: the authored properties, typed by
/// what the language reports and defaulted by what a fresh instance holds, and the
/// handlers it declares. What the cook does, and what a headless host does for a class it
/// compiled itself.
///
/// A property is authored when it is public and of a kind the wire carries: float, int,
/// bool, string, Color, Float3, Entity, or a resource handle (an asset, by its type name).
/// `self` and `scene` are the host's to fill, not the author's, and are not harvested.
/// A handler is any `on` prefixed method.
static class ScriptHarvest
{
	/// What the host injects into every instance that declares it.
	public const String cSelf = "self";
	public const String cScene = "scene";

	public static bool Harvest(ScriptRuntime runtime, StringView moduleName, StringView className, ScriptClassSource outSource)
	{
		let members = scope List<ScriptMemberDesc>();
		defer { ClearAndDeleteItems(members); }
		if (!runtime.DescribeClass(moduleName, className, members))
			return false;

		// The defaults come off a fresh instance.
		let instance = runtime.Instantiate(moduleName, className);
		defer { if (instance != null) runtime.Release(instance); }

		ClearAndDeleteItems!(outSource.Properties);
		ClearAndDeleteItems!(outSource.Handlers);
		// Starting a coroutine is a call in the source; a class that never makes it pays
		// nothing at teardown.
		outSource.UsesCoroutines = outSource.Source.Contains("startCoroutine");
		for (let m in members)
		{
			if (m.IsMethod)
			{
				if (m.Name.StartsWith("on") && (m.Name.Length > 2) && m.Name[2].IsUpper)
					outSource.Handlers.Add(new String(m.Name));
				continue;
			}

			if ((m.Name == cSelf) || (m.Name == cScene))
				continue;
			let desc = new ScriptPropertyDesc();
			desc.Name.Set(m.Name);
			desc.Hash = ScriptPropertyNames.HashOf(m.Name);
			var value = ScriptValue.Nil;
			if (instance != null)
				runtime.GetProperty(instance, m.Name, ref value);
			switch (m.Kind)
			{
			case .Float:
				desc.Type = .Float;
				desc.Default = .Float(value.AsNumber);
			case .Int:
				// An enum is an int on the wire.
				desc.Type = .Int;
				desc.Default = .Int(value.AsInt);
			case .Bool:
				desc.Type = .Bool;
				desc.Default = .Bool(value.AsBool);
			case .String:
				desc.Type = .String;
				desc.Default = .Str(new String(value.AsString));
			case .Color:
				desc.Type = .Color;
				desc.Default = .Colour(value.AsColor);
			case .Float3:
				desc.Type = .Vec3;
				desc.Default = .Vec3(value.AsFloat3);
			case .Entity:
				desc.Type = .Entity;
			case .Object:
				// A resource handle: `AudioClip@` names the asset type.
				desc.Type = .Asset;
				let typeName = scope String(m.TypeName);
				typeName.Replace("@", "");
				typeName.Replace("const ", "");
				desc.AssetType.Set(typeName);
			default:
				delete desc;
				continue;
			}
			outSource.Properties.Add(desc);
		}
		return true;
	}
}
