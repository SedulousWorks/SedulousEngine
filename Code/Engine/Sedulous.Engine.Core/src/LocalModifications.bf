namespace Sedulous.Engine.Core;

using System;
using System.Collections;

/// Scene-owned tracker for prefab instance modifications.
/// Maps entity handles to their ObjectState (per-entity diff state).
///
/// NOT a SceneModule — it is a plain class owned directly by Scene
/// as a member field. Tracks which properties on which entities differ
/// from their prefab template. Does NOT store override values — the
/// live component already has the current value.
public class LocalModifications
{
	private Dictionary<EntityHandle, ObjectState> mStates = new .() ~ {
		for (let kv in _) delete kv.value;
		delete _;
	};

	/// Check if a specific property is modified on an entity.
	public bool IsPropertyModified(EntityHandle entity, StringView componentTypeId, StringView propertyName)
	{
		if (mStates.TryGetValue(entity, let state))
			return state.IsPropertyModified(componentTypeId, propertyName);
		return false;
	}

	/// Mark a property as modified on an entity.
	/// Creates the ObjectState for the entity if it doesn't exist.
	public void SetPropertyModified(EntityHandle entity, StringView componentTypeId, StringView propertyName)
	{
		let state = GetOrCreateState(entity);
		state.AddModifiedProperty(componentTypeId, propertyName);
	}

	/// Remove a property modification from an entity.
	/// If the entity's ObjectState becomes empty, removes it from the map.
	public void ClearPropertyModified(EntityHandle entity, StringView componentTypeId, StringView propertyName)
	{
		if (mStates.TryGetValue(entity, let state))
		{
			state.RemoveModifiedProperty(componentTypeId, propertyName);
			if (state.IsEmpty)
			{
				delete state;
				mStates.Remove(entity);
			}
		}
	}

	/// Get the full ObjectState for an entity. Returns null if unmodified.
	public ObjectState GetObjectState(EntityHandle entity)
	{
		if (mStates.TryGetValue(entity, let state))
			return state;
		return null;
	}

	/// Whether an entity has any modifications tracked.
	public bool HasModifications(EntityHandle entity)
	{
		return mStates.ContainsKey(entity);
	}

	/// Track a locally added child on an entity.
	public void AddChild(EntityHandle entity, Guid childId)
	{
		GetOrCreateState(entity).AddChild(childId);
	}

	/// Track a removed template child on an entity.
	public void RemoveChild(EntityHandle entity, Guid childId)
	{
		GetOrCreateState(entity).RemoveChild(childId);
	}

	/// Remove all modification tracking for an entity.
	/// Call on entity destroy or "revert all".
	public void ClearEntity(EntityHandle entity)
	{
		if (mStates.TryGetValue(entity, let state))
		{
			delete state;
			mStates.Remove(entity);
		}
	}

	/// Remove all tracked modifications for all entities.
	public void ClearAll()
	{
		for (let kv in mStates)
			delete kv.value;
		mStates.Clear();
	}

	/// Number of entities with modification state.
	public int TrackedEntityCount => mStates.Count;

	private ObjectState GetOrCreateState(EntityHandle entity)
	{
		if (mStates.TryGetValue(entity, let state))
			return state;
		let newState = new ObjectState();
		mStates[entity] = newState;
		return newState;
	}
}
