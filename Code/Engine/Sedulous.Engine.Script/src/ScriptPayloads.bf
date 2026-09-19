using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;

namespace Sedulous.Engine.Script;

/// How a bus payload crosses into a handler's argument.
static class ScriptPayloads
{
	/// A bus payload in the frame's kinds: the scalar kinds, a string, an entity tagged
	/// with `scene`. Anything else is Nil, and the handler is called without it.
	public static ScriptValue ValueOf(Variant payload, Scene scene)
	{
		if (!payload.HasValue)
			return .Nil;
		let type = payload.VariantType;
		if (type == typeof(float)) return .FromFloat(payload.Get<float>());
		if (type == typeof(double)) return .FromFloat(payload.Get<double>());
		if (type == typeof(int32)) return .FromInt(payload.Get<int32>());
		if (type == typeof(int)) return .FromInt(payload.Get<int>());
		if (type == typeof(int64)) return .FromInt(payload.Get<int64>());
		if (type == typeof(bool)) return .FromBool(payload.Get<bool>());
		if (type == typeof(EntityHandle)) return .FromEntity(payload.Get<EntityHandle>(), scene);
		if (type == typeof(Float3)) return .FromFloat3(payload.Get<Float3>());
		if (type == typeof(String)) return .FromString(payload.Get<String>());
		return .Nil;
	}

	/// The bus payload an Emit overload carries: what ScriptSceneSystem and the run share.
	public static Variant Of(float value) => Variant.Create(value);
	public static Variant Of(int32 value) => Variant.Create(value);
	public static Variant Of(bool value) => Variant.Create(value);
	public static Variant Of(StringView value) => Variant.Create(new String(value), true);
	public static Variant Of(EntityHandle value) => Variant.Create(value);
}
