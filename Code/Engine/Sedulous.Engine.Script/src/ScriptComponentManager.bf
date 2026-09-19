using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Script;

/// The pool of script components. Entity and component destruction route onDestroy
/// through the scene's script system, which the system wires when the scene composes.
[Scriptable]
class ScriptComponentManager : ResourceBindingComponentManager<ScriptComponent>
{
	/// BORROWED: the system of the same scene.
	private ScriptSceneSystem mSystem = null;

	public void SetScriptSystem(ScriptSceneSystem system)
	{
		mSystem = system;
	}

	public ScriptSceneSystem ScriptSystem => mSystem;

	protected override void OnComponentCreated(ScriptComponent* component, EntityHandle entity)
	{
		component.Behaviors = new List<ScriptBehavior>();
	}

	protected override void OnComponentDestroyed(ScriptComponent* component, EntityHandle entity)
	{
		if (mSystem != null)
			mSystem.ReleaseComponentInstances(component, entity);
		DeleteContainerAndItems!(component.Behaviors);
		component.Behaviors = null;
	}

	/// Adds a behaviour to the entity's component, adding the component when it has none.
	/// The behaviour's class is bound through the manager the scene was resolved with.
	[Scriptable]
	public bool AddBehavior(EntityHandle entity, Guid scriptClass)
	{
		var component = Get(entity);
		if (component == null)
		{
			if (!Scene.IsValid(entity))
				return false;
			component = Add(entity);
		}
		let behavior = new ScriptBehavior();
		behavior.Script.SetId(scriptClass);
		behavior.Script.Rebind(Resources);
		component.Behaviors.Add(behavior);
		return true;
	}
}
