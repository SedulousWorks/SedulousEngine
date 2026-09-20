using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
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

	// ---- the control surface ----
	//
	// The player is the manager's and is built on the first tick that has a skeleton, so a
	// call before then, from a start hook say, is a no-op; from an update it is live.

	/// Plays the bound clip from the start. AutoPlay covers the first start; this is the
	/// manual re-trigger.
	public void Play(EntityHandle entity)
	{
		let component = Get(entity);
		if ((component == null) || (component.Player == null))
			return;

		let clip = component.Clip.Get;
		if (clip != null)
			component.Player.Play(clip);
	}

	public void Stop(EntityHandle entity)
	{
		if (let player = Player(entity))
			player.Stop();
	}

	public void Pause(EntityHandle entity)
	{
		if (let player = Player(entity))
			player.Pause();
	}

	public void Resume(EntityHandle entity)
	{
		if (let player = Player(entity))
			player.Resume();
	}

	public bool IsPlaying(EntityHandle entity)
	{
		let player = Player(entity);
		return (player != null) && (player.State == .Playing);
	}

	/// The clip clock, in seconds. Nought without a player.
	public float Time(EntityHandle entity)
	{
		let player = Player(entity);
		return (player != null) ? player.CurrentTime : 0.0f;
	}

	public void SetTime(EntityHandle entity, float seconds)
	{
		if (let player = Player(entity))
			player.SetCurrentTime(seconds);
	}

	/// Swaps the clip to the resource with this id, bound through the manager the scene was
	/// resolved with. The next tick picks it up, and AutoPlay plays it.
	public void SetClip(EntityHandle entity, Guid id)
	{
		let component = Get(entity);
		if (component == null)
			return;

		component.Clip.SetId(id);
		component.Clip.Rebind(Resources);
	}

	private AnimationPlayer Player(EntityHandle entity)
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
