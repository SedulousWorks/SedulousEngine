using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Particles;

namespace Sedulous.Engine.Script.Facades;

/// `scene.Particles`: the effect on an entity.
[Scriptable, SceneFacade("Particles")]
class ParticlesFacade : SceneFacade
{
	private ParticleEffectComponentManager Effects => Scene.GetSystem<ParticleEffectComponentManager>();

	/// The effect by asset id: attached on the next tick, as a scene load's would be.
	[Scriptable]
	public void SetEffect(EntityHandle entity, Guid effect)
	{
		let manager = Effects;
		let component = manager?.Get(entity);
		if (component == null)
			return;
		component.EffectAsset.SetId(effect);
		if (manager.Resources != null)
			component.EffectAsset.Rebind(manager.Resources);
		else
			component.EffectAsset.ClearBinding();
	}
	[Scriptable]
	public void Play(EntityHandle entity) => Effects?.Play(entity);
	[Scriptable]
	public void Stop(EntityHandle entity) => Effects?.Stop(entity);
	[Scriptable]
	public void Restart(EntityHandle entity) => Effects?.Restart(entity);
	[Scriptable]
	public void SetPaused(EntityHandle entity, bool paused) => Effects?.SetPaused(entity, paused);
	[Scriptable]
	public bool IsPlaying(EntityHandle entity) => Effects?.IsPlaying(entity) ?? false;
}
