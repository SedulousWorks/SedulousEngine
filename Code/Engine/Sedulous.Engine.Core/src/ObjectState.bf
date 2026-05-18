namespace Sedulous.Engine.Core;

using System;
using System.Collections;

/// Per-entity modification state: tracks which properties differ from
/// the prefab template, and which children were added or removed.
///
/// Owned by LocalModifications. One instance per entity that has
/// any modifications relative to its prefab template.
public class ObjectState
{
	/// Properties that differ from the template.
	private HashSet<PropertyPath> mModifiedProperties = new .() ~ {
		for (var path in _) path.Dispose();
		delete _;
	};

	/// Child entity GUIDs locally added (not in the template).
	private HashSet<Guid> mAddedChildren = new .() ~ delete _;

	/// Child entity GUIDs from the template that were removed on this instance.
	private HashSet<Guid> mRemovedChildren = new .() ~ delete _;

	// --- Modified Properties ---

	/// Whether a specific property is marked as modified.
	public bool IsPropertyModified(StringView componentTypeId, StringView propertyName)
	{
		for (let path in mModifiedProperties)
		{
			if (StringView(path.ComponentTypeId) == componentTypeId
				&& StringView(path.PropertyName) == propertyName)
				return true;
		}
		return false;
	}

	/// Marks a property as modified. Creates owned string copies.
	/// No-op if already marked.
	public void AddModifiedProperty(StringView componentTypeId, StringView propertyName)
	{
		if (IsPropertyModified(componentTypeId, propertyName))
			return;
		mModifiedProperties.Add(PropertyPath.Create(componentTypeId, propertyName));
	}

	/// Removes a property from the modified set. Frees the owned strings.
	/// Returns true if the property was found and removed.
	public bool RemoveModifiedProperty(StringView componentTypeId, StringView propertyName)
	{
		PropertyPath found = default;
		bool didFind = false;
		for (let path in mModifiedProperties)
		{
			if (StringView(path.ComponentTypeId) == componentTypeId
				&& StringView(path.PropertyName) == propertyName)
			{
				found = path;
				didFind = true;
				break;
			}
		}
		if (didFind)
		{
			mModifiedProperties.Remove(found);
			found.Dispose();
			return true;
		}
		return false;
	}

	/// Number of modified properties.
	public int ModifiedPropertyCount => mModifiedProperties.Count;

	/// Read-only access to modified property paths.
	public HashSet<PropertyPath> ModifiedProperties => mModifiedProperties;

	// --- Added Children ---

	public void AddChild(Guid childId) { mAddedChildren.Add(childId); }
	public bool RemoveAddedChild(Guid childId) => mAddedChildren.Remove(childId);
	public bool IsChildAdded(Guid childId) => mAddedChildren.Contains(childId);
	public int AddedChildCount => mAddedChildren.Count;
	public HashSet<Guid> AddedChildren => mAddedChildren;

	// --- Removed Children ---

	public void RemoveChild(Guid childId) { mRemovedChildren.Add(childId); }
	public bool UnremoveChild(Guid childId) => mRemovedChildren.Remove(childId);
	public bool IsChildRemoved(Guid childId) => mRemovedChildren.Contains(childId);
	public int RemovedChildCount => mRemovedChildren.Count;
	public HashSet<Guid> RemovedChildren => mRemovedChildren;

	// --- Utility ---

	/// Whether any property on a given component type is modified.
	public bool IsPropertyModifiedForComponent(StringView componentTypeId)
	{
		for (let path in mModifiedProperties)
		{
			if (StringView(path.ComponentTypeId) == componentTypeId)
				return true;
		}
		return false;
	}

	/// Whether this object state has any modifications at all.
	public bool IsEmpty => mModifiedProperties.Count == 0
		&& mAddedChildren.Count == 0
		&& mRemovedChildren.Count == 0;

	/// Clears all modification tracking. Frees owned strings.
	public void Clear()
	{
		for (var path in mModifiedProperties)
			path.Dispose();
		mModifiedProperties.Clear();
		mAddedChildren.Clear();
		mRemovedChildren.Clear();
	}
}
