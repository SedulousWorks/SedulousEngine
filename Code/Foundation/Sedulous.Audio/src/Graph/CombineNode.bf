namespace Sedulous.Audio.Graph;

using System;

/// Audio graph node that sums all input signals.
/// Used as the input point for audio buses - multiple sources mix into one combine node.
public class CombineNode : AudioNode
{
	protected override void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate)
	{
		AccumulateInputSamples(buffer, frameCount, sampleRate, LastMixVersion);
	}
}
