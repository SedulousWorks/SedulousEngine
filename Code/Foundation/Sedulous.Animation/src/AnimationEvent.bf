namespace Sedulous.Animation;

using System;

/// Delegate type for animation event callbacks.
/// @param eventName The name of the event that fired.
/// @param eventTime The time in seconds at which the event is placed in the clip.
public delegate void AnimationEventHandler(StringView eventName, float eventTime);

/// An animation event placed at a specific time in a clip.
/// When playback crosses the event's time, the event fires.
public class AnimationEvent
{
	/// Time in seconds from the start of the animation clip.
	public float Time;

	/// Name identifying this event (e.g., "Footstep", "FireProjectile").
	public String Name ~ delete _;

	public this(float time, StringView name)
	{
		Time = time;
		Name = new .(name);
	}
}
