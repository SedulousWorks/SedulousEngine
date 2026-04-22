namespace Sedulous.Engine.Core.Resources;

using System;
using System.Collections;
using Sedulous.Engine.Core;

typealias ComponentManagerFactory = delegate SceneModule();

/// Registry of component types for serialization.
/// Maps type IDs (strings) to factory functions that create the appropriate ComponentManager.
/// Subsystems register their component types during initialization.
class ComponentTypeRegistry
{
	private Dictionary<String, ComponentManagerFactory> mFactories = new .() ~ {
		for (let kv in _)
		{
			delete kv.key;
			delete kv.value;
		}
		delete _;
	};

	/// Registers a component manager factory for a given type ID.
	/// The type ID is stored in serialized scenes to identify which manager handles which components.
	public void Register(StringView typeId, ComponentManagerFactory factory)
	{
		mFactories[new .(typeId)] = factory;
	}

	/// Creates a scene module (component manager) for the given type ID.
	/// Returns null if the type ID is not registered.
	public SceneModule CreateManager(StringView typeId)
	{
		for (let kv in mFactories)
		{
			if (StringView(kv.key) == typeId)
				return kv.value();
		}
		return null;
	}

	/// Checks if a type ID is registered.
	public bool IsRegistered(StringView typeId)
	{
		for (let key in mFactories.Keys)
		{
			if (StringView(key) == typeId)
				return true;
		}
		return false;
	}

	/// Gets all registered type IDs.
	public Dictionary<String, ComponentManagerFactory>.KeyEnumerator TypeIds => mFactories.Keys;
}
