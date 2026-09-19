using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.Profiler;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Ticks every graph animation in the animation phase, exactly as the clip manager does but
/// evaluating a graph player.
///
/// It runs at a LOWER update order than the clip manager, so a graph backed entity is driven
/// by its graph. An entity is expected to carry one or the other: both push to the same mesh,
/// and the later writer would win.
[Scriptable]
class AnimationGraphComponentManager : ResourceBindingComponentManager<AnimationGraphComponent>
{
	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// Simulation gated, for the reason the clip manager gives.
	public override bool IsSimulationOnly => true;

	/// Before the clip manager, which sits at nought.
	public override int32 UpdateOrder => -1;

	protected override void OnComponentCreated(AnimationGraphComponent* component,
		EntityHandle entity)
	{
		component.MeshEntities = new List<EntityRef>();
	}

	protected override void OnComponentDestroyed(AnimationGraphComponent* component,
		EntityHandle entity)
	{
		DeleteAndNullify!(component.Player);
		DeleteAndNullify!(component.MeshEntities);
		component.PlayerSkeleton = null;
		component.PlayerGraph = null;
	}

	// ---- the parameters ----
	//
	// The player is built on the first tick that has a skeleton and a graph; before then
	// these are no-ops. An unknown name is a no-op in the player.

	[Scriptable]
	public void SetFloat(EntityHandle entity, StringView name, float value)
	{
		if (let player = Player(entity))
			player.SetFloat(name, value);
	}

	[Scriptable]
	public void SetBool(EntityHandle entity, StringView name, bool value)
	{
		if (let player = Player(entity))
			player.SetBool(name, value);
	}

	/// Fires a trigger; the graph consumes it on the transition that reads it.
	[Scriptable]
	public void SetTrigger(EntityHandle entity, StringView name)
	{
		if (let player = Player(entity))
			player.SetTrigger(name);
	}

	private AnimationGraphPlayer Player(EntityHandle entity)
	{
		let component = Get(entity);
		return (component != null) ? component.Player : null;
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .PostUpdate) || (mScene == null))
			return;

		let meshes = mScene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		using (ProfileScope("Animation.Graph"))
		{
			ForEach(scope (component, owner) =>
				{
					Tick(meshes, component, owner, deltaTime);
				});
		}
	}

	private void Tick(MeshComponentManager meshes, AnimationGraphComponent* component,
		EntityHandle owner, float deltaTime)
	{
		// Frozen.
		if (!mScene.IsEffectivelyActive(owner))
			return;

		let skeleton = component.Skeleton.Get;
		let graph = component.Graph.Get;
		if ((skeleton == null) || (graph == null))
			return;

		// (Re)build when EITHER object changed: the first tick, a pick, a reload.
		if ((component.Player == null) || (component.PlayerSkeleton !== skeleton)
			|| (component.PlayerGraph !== graph))
		{
			delete component.Player;
			component.Player = new AnimationGraphPlayer(graph, skeleton);
			component.PlayerSkeleton = skeleton;
			component.PlayerGraph = graph;
		}

		if (!component.Active)
			return;

		component.Player.Update(deltaTime);

		AnimationFeed.FeedAll(mScene, meshes, owner, component.MeshEntities,
			component.Player.GetSkinningMatrices(), component.Player.GetPrevSkinningMatrices());
	}
}
