namespace Sedulous.Audio.Graph;

using System;

/// Final output node of the audio graph.
/// Collects all input signals - the graph evaluator reads from this node.
public class OutputNode : AudioNode
{
	protected override void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate)
	{
		AccumulateInputSamples(buffer, frameCount, sampleRate, LastMixVersion);
	}
}
