using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.PropertyAnimation;

namespace Sedulous.Editor.PropertyAnimation;

/// The reflected-type to track-kind mapping and the animatable-property walk over a component
/// type: own fields, nested structs recursing with dotted paths, each seed validated against the
/// runtime's binding resolver so every one is a path the animator can drive.
static class AnimatableProperties
{
	/// The kind a leaf value type animates as; null when it is not animatable: only float,
	/// Float3, Color and Quaternion are.
	public static TrackValueKind? InferTrackKind(Type leafType)
	{
		if (leafType == typeof(float))
			return .Float;
		if (leafType == typeof(Float3))
			return .Float3;
		if (leafType == typeof(Color))
			return .Color;
		if (leafType == typeof(Quaternion))
			return .Quat;
		return null;
	}

	/// Enumerates the animatable leaf properties of a component type. The list owns the
	/// entries.
	public static void Collect(Type componentType, List<AnimatablePropertyInfo> outInfos)
	{
		let name = scope String();
		componentType.GetName(name);
		CollectInto(componentType, name, componentType, "", outInfos);
	}

	private static void CollectInto(Type componentType, StringView componentName, Type current, StringView prefix, List<AnimatablePropertyInfo> outInfos)
	{
		for (let field in current.GetFields())
		{
			if (!field.IsInstanceField)
				continue;
			let fieldType = field.FieldType;
			if (fieldType == null)
				continue;
			let path = scope String(prefix);
			if (!path.IsEmpty)
				path.Append(".");
			path.Append(field.Name);
			if (let kind = InferTrackKind(fieldType))
			{
				// Only properties the runtime can actually resolve and drive are seeded.
				let binding = scope PropertyBinding();
				PropertyBindingResolver.Resolve(componentType, path, binding);
				if (!binding.IsResolved)
					continue;
				outInfos.Add(new AnimatablePropertyInfo(componentName, path, kind));
				continue;
			}
			// A nested struct recurses; anything else (ints, strings, lists, references) is not
			// animatable and not walked.
			if (fieldType.IsStruct && !fieldType.IsPrimitive && !fieldType.IsEnum && !fieldType.IsPointer && !fieldType.IsSizedArray)
				CollectInto(componentType, componentName, fieldType, path, outInfos);
		}
	}
}
