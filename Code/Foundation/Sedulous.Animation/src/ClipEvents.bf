using System;

namespace Sedulous.Animation;

/// Firing a clip's events from NORMALISED times, which is what every state node reports in.
static class ClipEvents
{
	/// Fires what the span crossed, aware of a wrap.
	///
	/// A blend tree fires its DOMINANT clip's events rather than every blended one: two walk
	/// clips both carrying a footstep would otherwise fire it twice for one step.
	public static void Fire(AnimationClip clip, float prevNorm, float currentNorm, bool looping,
		AnimationEventHandler handler)
	{
		if ((handler == null) || (clip == null) || clip.Events.IsEmpty
			|| (clip.Duration <= 0.0f))
			return;

		let prevAbs = prevNorm * clip.Duration;
		let currentAbs = currentNorm * clip.Duration;

		// The normalised time going BACKWARDS is how a wrap shows up here: the clip's own
		// firing takes an absolute time that ran past the end, which this one never sees.
		if (looping && (currentNorm < prevNorm))
		{
			for (let event in clip.Events)
			{
				if ((event.Time > prevAbs) && (event.Time <= clip.Duration))
					handler(event.Name, event.Time);
			}
			for (let event in clip.Events)
			{
				if (event.Time <= currentAbs)
					handler(event.Name, event.Time);
			}
			return;
		}

		clip.FireEvents(prevAbs, currentAbs, handler);
	}
}
