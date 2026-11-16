using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.Profiler;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Ticks every skeletal animation in the animation phase, before extraction: advance each
/// player and evaluate its pose, recording which meshes it poses; drawing asks for a mesh's
/// palette (ISkinningPaletteSource) and reads it from the player as it is then.
///
/// Time is SIMULATION GATED. Animation is gameplay side state and must not advance in a scene
/// that is not simulating: watching things animate in an editor's edit mode is wrong. A consumer
/// that wants live animation in a context that looks paused enables simulation on its OWN preview
/// scene; scenes simulate by default, so a player and a headless test are unaffected. The pose
/// is not: in a scene standing still the manager still feeds its meshes the player's standing
/// pose (the rig's rest pose before any clip), since a skinned mesh fed nothing draws its raw
/// vertices, which an FBX file keeps lying in its authoring tool's axes.
class SkeletalAnimationComponentManager : ResourceBindingComponentManager<SkeletalAnimationComponent>, ISkinningPaletteSource
{
	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	/// Which of its animators posed each mesh at the last update.
	private PosedMeshes mPosed = new .() ~ delete _;
	/// The one-shots that ended since the last DrainEnded.
	private List<OneShotEnded> mEnded = new .() ~ delete _;
	/// The clip events passed since the last DrainEvents.
	private List<ClipEventFired> mEvents = new .() ~ DeleteContainerAndItems!(_);

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// The base's destructor sweeps the components through OnComponentDestroyed; mid teardown the
	/// scene's other systems may be gone, so a driven character is not released then.
	public ~this()
	{
		mScene = null;
	}

	protected override void OnComponentCreated(SkeletalAnimationComponent* component,
		EntityHandle entity)
	{
		component.MeshEntities = new List<EntityRef>();
	}

	protected override void OnComponentDestroyed(SkeletalAnimationComponent* component,
		EntityHandle entity)
	{
		// A character this animator was walking stops with it.
		if (mScene != null)
			RootMotionApply.Release(mScene, ref component.RootMotionState);
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
	/// resolved with. The next tick picks it up, and AutoPlay plays it, easing from the pose
	/// shown now into the new clip over `blendSeconds` (0: at once).
	public void SetClip(EntityHandle entity, Guid id, float blendSeconds = 0.0f)
	{
		let component = Get(entity);
		if (component == null)
			return;

		component.ClipFade = Max(0.0f, blendSeconds);
		component.Clip.SetId(id);
		component.Clip.Rebind(Resources);
	}

	// ---- one-shots: a clip once over the entity's clip, blended in and out ----

	/// Asks for `clip` to play over the entity's clip once its clip has loaded. One already
	/// playing gives way.
	public void PlayOneShot(EntityHandle entity, Guid clip, OneShotSettings settings)
	{
		let component = Get(entity);
		if (component != null)
			OneShots.Request(ref component.OneShot, Resources, clip, settings);
	}

	/// Blends the entity's one-shot out over `blendOut` seconds; it then reports its end.
	public void StopOneShot(EntityHandle entity, float blendOut)
	{
		let component = Get(entity);
		if (component != null)
			OneShots.Stop(ref component.OneShot, component.Player?.Overlay, blendOut);
	}

	/// From the request until the one-shot has blended out.
	public bool IsPlayingOneShot(EntityHandle entity)
	{
		let component = Get(entity);
		return (component != null) && OneShots.IsPlaying(component.OneShot, component.Player?.Overlay);
	}

	/// The one-shots that ended since the last call, added to `outEnded` (the animation
	/// subsystem tells its listeners).
	/// The clip events passed since the last call, handed to `outEvents`, which owns them.
	public void DrainEvents(List<ClipEventFired> outEvents)
	{
		outEvents.AddRange(mEvents);
		mEvents.Clear();
	}

	public void DrainEnded(List<OneShotEnded> outEnded)
	{
		outEnded.AddRange(mEnded);
		mEnded.Clear();
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
			// Recorded again below: an animator gone, or a mesh it stopped naming, drops out.
			mPosed.Clear();
			ForEach(scope (component, owner) =>
				{
					Tick(meshes, component, owner, deltaTime);
				});
		}
	}

	private void Tick(MeshComponentManager meshes, SkeletalAnimationComponent* component,
		EntityHandle owner, float deltaTime)
	{
		// Recorded first, so a frozen animator's meshes keep its last pose.
		mPosed.RecordAll(mScene, meshes, owner, component.MeshEntities);
		// Frozen: time does not advance.
		if (!mScene.IsEffectivelyActive(owner))
		{
			RootMotionApply.Release(mScene, ref component.RootMotionState);
			return;
		}

		let skeleton = component.Skeleton.Get;
		if (skeleton == null)
		{
			RootMotionApply.Release(mScene, ref component.RootMotionState);
			return;
		}

		// (Re)build the player when the skeleton OBJECT changed: the first tick, an editor
		// pick, or a hot reload swapping the product behind the reference.
		if ((component.Player == null) || (component.PlayerSkeleton !== skeleton))
		{
			delete component.Player;
			component.Player = new AnimationPlayer(skeleton);
			// Its clip events, for the animation subsystem to tell its listeners.
			component.Player.SetEventHandler(new (name, time) => { mEvents.Add(new ClipEventFired(owner, name)); });
			component.PlayerSkeleton = skeleton;
			// The new player has no clip, so the block below plays one.
			component.PlayerClip = null;
		}

		// The CLIP changes independently of the skeleton: an editor's picks land one at a
		// time, and a hot reload swaps the product mid play. Automatic playback starts the new
		// clip; anyone driving the player by hand keeps doing so. Not while the scene stands
		// still: the clip starts when the simulation does.
		let clip = component.Clip.Get;
		if (!mScene.SimulationEnabled)
		{
			RootMotionApply.Release(mScene, ref component.RootMotionState);
		}
		else if (clip !== component.PlayerClip)
		{
			component.PlayerClip = clip;
			if (component.AutoPlay && (clip != null))
			{
				// A clip changed mid play eases in when asked (SetClip's blend); the first clip,
				// and the start time, start at once.
				component.Player.CrossFadeTo(clip, component.ClipFade);
				if ((component.StartTime != 0.0f) && (component.ClipFade <= 0.0f))
					component.Player.SetCurrentTime(component.StartTime);
			}
			component.ClipFade = 0.0f;
		}

		component.Player.Speed = component.Speed;
		if (mScene.SimulationEnabled)
		{
			OneShots.Start(ref component.OneShot, component.Player.Overlay);
			component.Player.Update(deltaTime);
			OneShots.Ended(ref component.OneShot, component.Player.ConsumeOneShotEnded(), owner, mEnded);
			RootMotionApply.Apply(mScene, owner, component.MeshEntities, component.RootMotionTarget, component.RootMotion,
				ref component.RootMotionState, component.Player.ConsumeRootMotion(), deltaTime);
		}

		// The pose is evaluated here, once a frame, whether or not anything draws it: its
		// modifiers (foot IK's ground probes) step with the frame, not with a reader.
		component.Player.GetSkinningMatrices();
	}

	public override ISkinningPaletteSource AsSkinningPaletteSource => this;

	/// The palette of the animator that posed `mesh` at its last update, read from its player
	/// as it is now; false once the animator is gone (its player with it): the mesh draws static.
	public bool SkinningPaletteOf(EntityHandle mesh, out SkinningPalette outPalette)
	{
		outPalette = .();
		let animator = mPosed.AnimatorOf(mesh);
		let component = animator.IsAssigned ? Get(animator) : null;
		if ((component == null) || (component.Player == null))
			return false;
		let current = component.Player.EvaluatedSkinningMatrices;
		outPalette.Current = current.Ptr;
		outPalette.Previous = component.Player.GetPrevSkinningMatrices().Ptr;
		outPalette.BoneCount = (uint32)current.Length;
		return true;
	}
}
