namespace Sedulous.Engine.Core;

using System;

/// Identifies a specific property on a specific component type.
/// Used as a key in ObjectState's modified property set.
///
/// OWNERSHIP: The Strings are heap-allocated. The container that holds
/// PropertyPath values (ObjectState's HashSet) is responsible for
/// calling Dispose() to free them.
public struct PropertyPath : IHashable, IEquatable<PropertyPath>
{
	/// Serialization type ID of the component (e.g., "Sedulous.MeshComponent").
	public String ComponentTypeId;

	/// Property field name (e.g., "Health", "MeshRef").
	public String PropertyName;

	/// Creates a PropertyPath with owned copies of the input strings.
	public static PropertyPath Create(StringView componentTypeId, StringView propertyName)
	{
		return .() {
			ComponentTypeId = new String(componentTypeId),
			PropertyName = new String(propertyName)
		};
	}

	/// Deletes the owned strings. Called by ObjectState when removing entries.
	public void Dispose() mut
	{
		if (ComponentTypeId != null) { delete ComponentTypeId; ComponentTypeId = null; }
		if (PropertyName != null) { delete PropertyName; PropertyName = null; }
	}

	public int GetHashCode()
	{
		int hash = 17;
		if (ComponentTypeId != null) hash = hash * 31 + ComponentTypeId.GetHashCode();
		if (PropertyName != null) hash = hash * 31 + PropertyName.GetHashCode();
		return hash;
	}

	public bool Equals(PropertyPath other)
	{
		return StringView(ComponentTypeId ?? "") == StringView(other.ComponentTypeId ?? "")
			&& StringView(PropertyName ?? "") == StringView(other.PropertyName ?? "");
	}

	public static bool operator ==(PropertyPath a, PropertyPath b) => a.Equals(b);
	public static bool operator !=(PropertyPath a, PropertyPath b) => !a.Equals(b);
}
