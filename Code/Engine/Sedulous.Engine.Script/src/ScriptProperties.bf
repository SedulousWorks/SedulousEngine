using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Script;

/// Applying authored values to a live instance: the class's harvested defaults first,
/// then the hash-keyed overrides, which win. Shared by the behaviour tier and the Level
/// tier, so both apply identically.
static class ScriptProperties
{
	/// One value onto the instance, resolved against `scene` for an entity reference.
	public static bool Apply(ScriptRuntime runtime, ScriptObject instance, ScriptPropertyDesc property,
		ScriptPropertyValue value, Scene scene)
	{
		var v = ScriptValue.Nil;
		switch (value.Kind)
		{
		case .Float: v = .FromFloat(value.Number);
		case .Int: v = .FromInt((int64)value.Number);
		case .Bool: v = .FromBool(value.Boolean);
		case .String: v = .FromString(value.Text ?? "");
		case .Color: v = .FromColor(value.Color);
		case .Vec3: v = .FromFloat3(value.Vector);
		case .Entity:
			// A guid to the live handle, in this scene; an unresolved one is the invalid
			// handle, never a stale one.
			let handle = (scene != null) ? scene.FindEntity(value.Id) : EntityHandle.Invalid;
			v = .FromEntity(handle, scene);
		case .Asset:
			// The id; a script that wants the product binds it through the surface.
			v = .FromGuid(value.Id);
		case .None:
			return true;
		}
		return runtime.SetProperty(instance, property.Name, v);
	}

	/// Defaults, then overrides. A property the instance no longer has, or whose type no
	/// longer matches, is reported by name rather than dropped silently.
	public static void ApplyAll(ScriptRuntime runtime, ScriptObject instance, ScriptClass scriptClass,
		List<ScriptPropertyOverride> overrides, Scene scene, StringView ownerName)
	{
		for (let property in scriptClass.Properties)
		{
			var value = property.Default;
			for (let entry in overrides)
			{
				if (entry.Hash == property.Hash)
				{
					value = entry.Value;
					break;
				}
			}
			if (!Apply(runtime, instance, property, value, scene))
				GlobalLog(.Warning, scope $"Script: '{ownerName}': {scriptClass.ClassName} has no '{property.Name}' of the authored type; the value was not applied");
		}
	}
}
