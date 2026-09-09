using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.PropertyAnimation;

/// A cooked or authored clip: a duration and its tracks.
///
/// IMMUTABLE SHARED DATA at runtime. A playing component owns only its time, its state and its
/// binding cache, so one clip serves every entity playing it. How it loops belongs to the
/// component, not here: two entities can play the same clip differently.
class PropertyAnimationClip
{
	public float Duration = 0.0f;
	public List<PropertyTrack> Tracks = new .() ~ DeleteContainerAndItems!(_);

	/// The longest track's span. Called after editing, to refresh the duration.
	public float ComputeDuration()
	{
		var duration = 0.0f;
		for (let track in Tracks)
			duration = Max(duration, track.Duration);
		return duration;
	}
}
