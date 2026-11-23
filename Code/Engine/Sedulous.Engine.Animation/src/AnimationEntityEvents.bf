using System;

namespace Sedulous.Engine.Animation;

/// The entity events an animation posts to its scene (Scene.PostEntityEvent), which an entity's
/// behaviors hear as on<Name>: a one-shot that ended (SceneAnimation.PlayOneShot), with its clip's
/// id, and a clip event the animation passed, with the event's name.
static class AnimationEntityEvents
{
	public const String Finished = "animationFinished";
	public const String ClipEvent = "animationEvent";
}
