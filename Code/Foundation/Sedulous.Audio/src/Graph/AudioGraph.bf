namespace Sedulous.Audio.Graph;

using System;
using System.Collections;

/// Evaluates a directed acyclic graph of AudioNodes by pulling from the OutputNode.
/// The graph does NOT own external nodes - it only owns the OutputNode it creates.
/// Node lifetime is managed by whoever creates them (buses own bus nodes,
/// sources own source nodes, etc.). The graph structure is defined by
/// node connections (AddInput/RemoveInput), not by a node list.
public class AudioGraph : IDisposable
{
	private OutputNode mOutputNode;
	private uint64 mMixVersion;

	/// The output node - root of graph evaluation. Owned by the graph.
	public OutputNode Output => mOutputNode;

	/// Current mix version (incremented each Evaluate call).
	public uint64 MixVersion => mMixVersion;

	public this()
	{
		mOutputNode = new OutputNode();
	}

	/// Evaluates the graph: increments mix version, pulls from output node.
	/// outputBuffer receives float32 stereo interleaved samples.
	public void Evaluate(float* outputBuffer, int32 frameCount, int32 sampleRate)
	{
		mMixVersion++;
		mOutputNode.GetOutputSamples(outputBuffer, frameCount, sampleRate, mMixVersion);
	}

	public ~this()
	{
		Dispose();
	}

	public void Dispose()
	{
		if (mOutputNode != null)
		{
			mOutputNode.DisconnectAll();
			mOutputNode.Dispose();
			delete mOutputNode;
			mOutputNode = null;
		}
	}
}
