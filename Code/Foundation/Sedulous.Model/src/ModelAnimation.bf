using System;
using System.Collections;

namespace Sedulous.Model;

/// One animation clip: a set of channels and how long they run for.
class ModelAnimation
{
	public String Name = new .() ~ delete _;

	/// OWNED. A clip is meaningless without its channels, so it holds them.
	private List<AnimationChannel> mChannels = new .() ~ DeleteContainerAndItems!(_);

	/// The clip's length in seconds.
	public float Duration;

	public Span<AnimationChannel> Channels => .(mChannels.Ptr, mChannels.Count);
	public int ChannelCount => mChannels.Count;

	/// Adds a channel and TAKES OWNERSHIP of it.
	public void AddChannel(AnimationChannel channel) => mChannels.Add(channel);

	/// Recomputes the duration as the latest keyframe in any channel.
	///
	/// Derived rather than trusted from the file, so a clip whose declared length
	/// disagrees with its own keys plays all of them.
	public void CalculateDuration()
	{
		Duration = 0.0f;
		for (let channel in mChannels)
		{
			for (let keyframe in channel.Keyframes)
			{
				if (keyframe.Time > Duration)
					Duration = keyframe.Time;
			}
		}
	}
}
