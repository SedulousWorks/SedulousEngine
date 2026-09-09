using System;

namespace Sedulous.Animation;

/// A named moment in a clip, which fires as playback crosses it.
class AnimationEvent
{
	public float Time = 0.0f;
	public String Name = new .() ~ delete _;

	public this() {}

	public this(float time, StringView name)
	{
		Time = time;
		Name.Set(name);
	}
}
