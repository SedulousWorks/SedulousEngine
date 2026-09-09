using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Logging;

namespace Sedulous.Net.Replication;

/// The ordered replicated field layout for a component type, harvested from reflection once
/// and cached.
///
/// Both peers derive the layout from the same type, so the order and the set match by
/// construction: that is the whole reason the wire format carries no field names.
static class ReplicatedLayout
{
	/// Harvested layouts, keyed by type. The FieldInfo values are stable, being views onto the
	/// type's own static data.
	private static Dictionary<Type, List<FieldInfo>> sCache = new .() ~ DeleteDictionaryAndValues!(_);

	/// Whether the field codec can encode a value of this type.
	///
	/// Enums, strings, Guids and resource references are deliberately absent: each needs a
	/// wire representation decided on purpose, and guessing one would encode something a peer
	/// could not decode back.
	public static bool IsFieldTypeSupported(Type type)
	{
		if (type == null)
			return false;

		return (type == typeof(bool))
			|| (type == typeof(float)) || (type == typeof(double))
			|| (type == typeof(int8)) || (type == typeof(uint8))
			|| (type == typeof(int16)) || (type == typeof(uint16))
			|| (type == typeof(int32)) || (type == typeof(uint32))
			|| (type == typeof(int64)) || (type == typeof(uint64))
			|| (type == typeof(Float2)) || (type == typeof(Float3)) || (type == typeof(Float4))
			|| (type == typeof(Quaternion));
	}

	/// Whether this field replicates: MARKED and of a supported type.
	///
	/// The AND is deliberate. A marked field of an unsupported type is EXCLUDED from the
	/// layout, so a server and a client harvesting the same type always agree on the field
	/// set. Including it on one side and not the other is a desync, which is far worse than a
	/// field that quietly does not replicate.
	public static bool IsReplicated(FieldInfo field)
	{
		return field.HasCustomAttribute<ReplicatedAttribute>()
			&& IsFieldTypeSupported(field.FieldType);
	}

	/// The layout for a type, in declaration order. Empty for a type with no replicated fields.
	public static Span<FieldInfo> Fields(Type type)
	{
		if (type == null)
			return .();

		if (sCache.TryGetValue(type, let cached))
			return cached;

		let layout = new List<FieldInfo>();
		for (let field in type.GetFields())
		{
			if (!field.HasCustomAttribute<ReplicatedAttribute>())
				continue;

			if (!IsFieldTypeSupported(field.FieldType))
			{
				GlobalLog(.Warning,
					"Net: replicated field '{}' on '{}' has an unsupported type and is excluded from replication",
					scope String(field.Name), type.GetName(.. scope String()));
				continue;
			}
			layout.Add(field);
		}

		sCache[type] = layout;
		return layout;
	}

	/// Whether a type has any field worth smoothing. A purely discrete component is applied
	/// directly rather than buffered, because interpolating a bool means nothing.
	public static bool HasInterpolatableField(Type type)
	{
		for (let field in Fields(type))
		{
			if (FieldInterpolation.IsInterpolatableType(field.FieldType))
				return true;
		}
		return false;
	}
}
