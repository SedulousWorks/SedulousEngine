using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Animation;

namespace Sedulous.Engine.Script.Facades;

/// `scene.Animation`: a skeletal clip and an animation graph on an entity, one surface.
[Scriptable, SceneFacade("Animation")]
class AnimationFacade : SceneFacade
{
	private SkeletalAnimationComponentManager Skeletal => Scene.GetSystem<SkeletalAnimationComponentManager>();
	private AnimationGraphComponentManager Graphs => Scene.GetSystem<AnimationGraphComponentManager>();

	[Scriptable]
	public void Play(EntityHandle entity) => Skeletal?.Play(entity);
	[Scriptable]
	public void Stop(EntityHandle entity) => Skeletal?.Stop(entity);
	[Scriptable]
	public void Pause(EntityHandle entity) => Skeletal?.Pause(entity);
	[Scriptable]
	public void Resume(EntityHandle entity) => Skeletal?.Resume(entity);
	[Scriptable]
	public bool IsPlaying(EntityHandle entity) => Skeletal?.IsPlaying(entity) ?? false;
	[Scriptable]
	public float Time(EntityHandle entity) => Skeletal?.Time(entity) ?? 0.0f;
	[Scriptable]
	public void SetTime(EntityHandle entity, float seconds) => Skeletal?.SetTime(entity, seconds);
	/// The clip by asset id.
	[Scriptable]
	public void SetClip(EntityHandle entity, Guid clip) => Skeletal?.SetClip(entity, clip);

	/// A graph parameter on the entity's animation graph.
	[Scriptable]
	public void SetFloat(EntityHandle entity, StringView name, float value) => Graphs?.SetFloat(entity, name, value);
	[Scriptable]
	public void SetBool(EntityHandle entity, StringView name, bool value) => Graphs?.SetBool(entity, name, value);
	[Scriptable]
	public void SetTrigger(EntityHandle entity, StringView name) => Graphs?.SetTrigger(entity, name);

	// ---- root motion (Script mode) ----

	/// The entity's animator's travel over its last tick, in the world: a script steering by the
	/// clip's own speed (an animator in Script mode moves nothing itself). One frame late, the
	/// animators ticking after scripts. Zero for an entity with no animator.
	[Scriptable]
	public Float3 RootMotionTranslation(EntityHandle entity) => RootMotionOf(entity).WorldTranslation;
	/// And its turn about up, radians.
	[Scriptable]
	public float RootMotionYaw(EntityHandle entity) => RootMotionOf(entity).Yaw;

	private RootMotionRuntime RootMotionOf(EntityHandle entity)
	{
		if (let graph = Graphs?.Get(entity))
			return graph.RootMotionState;
		if (let clip = Skeletal?.Get(entity))
			return clip.RootMotionState;
		return .();
	}

	// ---- inverse kinematics: the Two Bone IK and Aim IK components on the entity ----

	/// The world point the entity's IK components reach for while they name no target entity.
	[Scriptable]
	public void SetIkTarget(EntityHandle entity, Float3 worldPosition) => IkScene.SetTarget(Scene, entity, worldPosition);
	/// Whether every IK component on the entity reached its target on the last solve.
	[Scriptable]
	public bool IkReached(EntityHandle entity) => IkScene.Reached(Scene, entity);
	/// The largest miss on the last solve: metres for a two bone chain, radians for an aim.
	[Scriptable]
	public float IkError(EntityHandle entity) => IkScene.Error(Scene, entity);
}
