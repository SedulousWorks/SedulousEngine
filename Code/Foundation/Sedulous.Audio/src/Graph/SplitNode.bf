namespace Sedulous.Audio.Graph;

using System;

/// Audio graph node that passes input through to all outputs.
/// Used for send/return routing - one signal can feed multiple destinations.
/// Each output node pulls from this node independently; mix-version caching
/// ensures the input is only evaluated once per frame.
public class SplitNode : AudioNode
{
	protected override void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate)
	{
		AccumulateInputSamples(buffer, frameCount, sampleRate, LastMixVersion);
	}
}
