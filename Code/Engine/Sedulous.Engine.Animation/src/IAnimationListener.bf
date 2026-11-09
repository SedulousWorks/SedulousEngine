using System;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// A one-shot that ended on an entity (the Animation facade's PlayOneShot): the scene, the
/// entity and the clip.
struct AnimationOneShotEnded
{
	/// BORROWED.
	public Scene Scene;
	public EntityHandle Entity;
	public Guid Clip;

	public this(Scene scene, EntityHandle entity, Guid clip)
	{
		Scene = scene;
		Entity = entity;
		Clip = clip;
	}
}

/// A consumer of the animation's events. The host bridges them to scripts, so the animation
/// stays script agnostic, as physics contacts do.
interface IAnimationListener
{
	void OnOneShotEnded(AnimationOneShotEnded ended);
}
