using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Behavior;

/// The pool of behavior components. Entity and component destruction route onDestroy
/// through the scene's script system, which the system wires when the scene composes.
class BehaviorComponentManager : ResourceBindingComponentManager<BehaviorComponent>, IReplicatedStateSource
{
	/// Its behaviours' replicated properties travel with a networked entity (ScriptReplication).
	public override IReplicatedStateSource AsReplicatedStateSource => this;

	/// BORROWED: the system of the same scene.
	private BehaviorSystem mSystem = null;

	public void SetScriptSystem(BehaviorSystem system)
	{
		mSystem = system;
	}

	public BehaviorSystem ScriptSystem => mSystem;

	protected override void OnComponentCreated(BehaviorComponent* component, EntityHandle entity)
	{
		component.Behaviors = new List<AttachedBehavior>();
	}

	protected override void OnComponentDestroyed(BehaviorComponent* component, EntityHandle entity)
	{
		if (mSystem != null)
			mSystem.ReleaseComponentInstances(component, entity);
		DeleteContainerAndItems!(component.Behaviors);
		component.Behaviors = null;
	}

	/// Every behaviour's asset-valued overrides: a script property holds an id the script
	/// binds itself, so the post load pass leaves it unbound.
	public override void CollectUnboundReferences(List<Guid> outIds)
	{
		ForEach(scope (component, owner) =>
		{
			for (let behavior in component.Behaviors)
				ScriptPropertyOverride.CollectAssetIds(behavior.Overrides, outIds);
		});
	}

	/// Every behaviour's class, and the assets its overrides name: the behaviours are a list the
	/// reflection walk does not follow, so they are reported here. An asset an override names
	/// stays loaded while the scene is, so a script that binds it when it uses it finds it so.
	public override void CollectResourceIds(HashSet<Guid> outIds)
	{
		base.CollectResourceIds(outIds);
		let assets = scope List<Guid>();
		ForEach(scope (component, owner) =>
		{
			if (component.Behaviors == null)
				return;
			for (let behavior in component.Behaviors)
			{
				if (!behavior.BehaviorClass.Id.IsNil)
					outIds.Add(behavior.BehaviorClass.Id);
				ScriptPropertyOverride.CollectAssetIds(behavior.Overrides, assets);
			}
		});
		for (let id in assets)
		{
			if (!id.IsNil)
				outIds.Add(id);
		}
	}

	/// Adds a behaviour to the entity's component, adding the component when it has none.
	/// The behaviour's class is bound through the manager the scene was resolved with.
	public bool AddBehavior(EntityHandle entity, Guid scriptClass)
	{
		// No class names nothing to run: refused, rather than an empty behaviour (and a script
		// component the entity did not have).
		if (scriptClass.IsNil)
			return false;
		var component = Get(entity);
		if (component == null)
		{
			if (!Scene.IsValid(entity))
				return false;
			component = Add(entity);
		}
		let behavior = new AttachedBehavior();
		behavior.BehaviorClass.SetId(scriptClass);
		behavior.BehaviorClass.Rebind(Resources);
		component.Behaviors.Add(behavior);
		return true;
	}
}
