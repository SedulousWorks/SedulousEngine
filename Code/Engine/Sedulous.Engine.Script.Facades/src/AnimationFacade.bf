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
}
