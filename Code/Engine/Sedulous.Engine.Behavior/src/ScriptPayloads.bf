using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;

namespace Sedulous.Engine.Behavior;

/// How a bus payload crosses into a handler's argument.
static class ScriptPayloads
{
	/// A bus payload in the frame's kinds: the scalar kinds, a Float3 or a Float4, a string,
	/// an entity tagged with `scene`, or a [ScriptPayload] struct by its bytes (a sequence's
	/// notice), which the handler's runtime copies. Anything else is Nil, and the
	/// handler is called without it.
	///
	/// By reference: a struct crosses as the address of the payload's own bytes, which for a small
	/// one are inside the Variant itself, so the caller's Variant must outlive the call it feeds.
	public static ScriptValue ValueOf(ref Variant payload, Scene scene)
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
		if (type == typeof(Float4)) return .FromFloat4(payload.Get<Float4>());
		if (type == typeof(String)) return .FromString(payload.Get<String>());
		if (IsScriptStruct(type)) return .FromStruct(payload.DataPtr, type);
		return .Nil;
	}

	/// A struct the script surface declares as a bus payload ([ScriptPayload]), so a handler's
	/// runtime knows its layout.
	private static bool IsScriptStruct(Type type)
	{
		return type.IsStruct && !type.IsPrimitive && !type.IsEnum && type.HasCustomAttribute<ScriptPayloadAttribute>();
	}

	/// The bus payload an Emit overload carries: what BehaviorSystem and the run share.
	public static Variant Of(float value) => Variant.Create(value);
	public static Variant Of(int32 value) => Variant.Create(value);
	public static Variant Of(bool value) => Variant.Create(value);
	public static Variant Of(StringView value) => Variant.Create(new String(value), true);
	public static Variant Of(EntityHandle value) => Variant.Create(value);
	public static Variant Of(Float3 value) => Variant.Create(value);
	public static Variant Of(Float4 value) => Variant.Create(value);
}
