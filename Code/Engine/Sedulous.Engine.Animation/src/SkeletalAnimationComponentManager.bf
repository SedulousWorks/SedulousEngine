using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Engine.Render;
using Sedulous.Profiler;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Ticks every skeletal animation in the animation phase, before extraction: advance each
/// player, then write its current and previous skinning matrices into the target meshes.
///
/// SIMULATION GATED. Animation is gameplay side state and must not advance in a scene that is
/// not simulating: watching things animate in an editor's edit mode is wrong. A consumer that
/// wants live animation in a context that looks paused enables simulation on its OWN preview
/// scene; scenes simulate by default, so a player and a headless test are unaffected.
class SkeletalAnimationComponentManager : ResourceBindingComponentManager<SkeletalAnimationComponent>
{
	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	public override bool IsSimulationOnly => true;

	protected override void OnComponentCreated(SkeletalAnimationComponent* component,
		EntityHandle entity)
	{
		component.MeshEntities = new List<EntityRef>();
	}

	protected override void OnComponentDestroyed(SkeletalAnimationComponent* component,
		EntityHandle entity)
	{
		DeleteAndNullify!(component.Player);
		DeleteAndNullify!(component.MeshEntities);
		component.PlayerSkeleton = null;
		component.PlayerClip = null;
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .PostUpdate) || (mScene == null))
			return;

		let meshes = mScene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		using (ProfileScope("Animation.Skeletal"))
		{
			ForEach(scope (component, owner) =>
				{
					Tick(meshes, component, owner, deltaTime);
				});
		}
	}

	private void Tick(MeshComponentManager meshes, SkeletalAnimationComponent* component,
		EntityHandle owner, float deltaTime)
	{
		// Frozen: time does not advance.
		if (!mScene.IsEffectivelyActive(owner))
			return;

		let skeleton = component.Skeleton.Get;
		if (skeleton == null)
			return;

		// (Re)build the player when the skeleton OBJECT changed: the first tick, an editor
		// pick, or a hot reload swapping the product behind the reference.
		if ((component.Player == null) || (component.PlayerSkeleton !== skeleton))
		{
			delete component.Player;
			component.Player = new AnimationPlayer(skeleton);
			component.PlayerSkeleton = skeleton;
			// The new player has no clip, so the block below plays one.
			component.PlayerClip = null;
		}

		// The CLIP changes independently of the skeleton: an editor's picks land one at a
		// time, and a hot reload swaps the product mid play. Automatic playback starts the new
		// clip; anyone driving the player by hand keeps doing so.
		let clip = component.Clip.Get;
		if (clip !== component.PlayerClip)
		{
			component.PlayerClip = clip;
			if (component.AutoPlay && (clip != null))
			{
				component.Player.Play(clip);
				if (component.StartTime != 0.0f)
					component.Player.SetCurrentTime(component.StartTime);
			}
		}

		component.Player.Speed = component.Speed;
		component.Player.Update(deltaTime);

		AnimationFeed.FeedAll(mScene, meshes, owner, component.MeshEntities,
			component.Player.GetSkinningMatrices(), component.Player.GetPrevSkinningMatrices());
	}
}
