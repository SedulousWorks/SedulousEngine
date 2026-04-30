namespace Sedulous.Audio.Graph;

using System;
using System.Collections;

/// Base class for all audio graph nodes.
/// Nodes have inputs and outputs, process float32 stereo interleaved buffers,
/// and support lazy evaluation via mix-version caching.
public abstract class AudioNode : IDisposable
{
	private List<AudioNode> mInputs = new .() ~ delete _;
	private List<AudioNode> mOutputs = new .() ~ delete _;
	private float* mCachedBuffer;
	private int32 mCachedBufferCapacity;
	private uint64 mLastMixVersion;
	private bool mEnabled = true;

	/// Whether this node is active. Disabled nodes produce silence.
	public bool Enabled
	{
		get => mEnabled;
		set => mEnabled = value;
	}

	/// Number of input connections.
	public int InputCount => mInputs.Count;

	/// Number of output connections.
	public int OutputCount => mOutputs.Count;

	/// Gets the input node at the specified index.
	public AudioNode GetInput(int index) => mInputs[index];

	/// Gets the output node at the specified index.
	public AudioNode GetOutput(int index) => mOutputs[index];

	/// Adds an input connection from another node.
	public void AddInput(AudioNode node)
	{
		if (node == null || node == this || mInputs.Contains(node))
			return;

		mInputs.Add(node);
		node.mOutputs.Add(this);
	}

	/// Removes an input connection.
	public void RemoveInput(AudioNode node)
	{
		if (node == null)
			return;

		if (mInputs.Remove(node))
			node.mOutputs.Remove(this);
	}

	/// Inserts a node between this node and all its current inputs.
	/// Before: [inputs] -> [this]
	/// After:  [inputs] -> [newNode] -> [this]
	public void InsertBefore(AudioNode newNode)
	{
		if (newNode == null || newNode == this)
			return;

		for (let input in mInputs)
		{
			input.mOutputs.Remove(this);
			input.mOutputs.Add(newNode);
			newNode.mInputs.Add(input);
		}
		mInputs.Clear();
		AddInput(newNode);
	}

	/// Inserts a node between this node and all its current outputs.
	/// Before: [this] -> [outputs]
	/// After:  [this] -> [newNode] -> [outputs]
	public void InsertAfter(AudioNode newNode)
	{
		if (newNode == null || newNode == this)
			return;

		for (let output in mOutputs)
		{
			output.mInputs.Remove(this);
			output.mInputs.Add(newNode);
			newNode.mOutputs.Add(output);
		}
		mOutputs.Clear();
		newNode.AddInput(this);
	}

	/// Disconnects this node from all inputs and outputs.
	public void DisconnectAll()
	{
		for (let input in mInputs)
			input.mOutputs.Remove(this);
		mInputs.Clear();

		for (let output in mOutputs)
			output.mInputs.Remove(this);
		mOutputs.Clear();
	}

	/// Evaluates this node, writing float32 stereo interleaved samples into buffer.
	/// Uses mix-version caching to avoid re-evaluation within the same frame.
	public void GetOutputSamples(float* buffer, int32 frameCount, int32 sampleRate, uint64 mixVersion)
	{
		if (mLastMixVersion == mixVersion && mCachedBuffer != null)
		{
			// Already evaluated this frame - copy from cache
			let sampleCount = frameCount * 2; // stereo
			Internal.MemCpy(buffer, mCachedBuffer, sampleCount * sizeof(float));
			return;
		}

		mLastMixVersion = mixVersion;
		EnsureCacheBuffer(frameCount);

		if (!mEnabled)
		{
			let sampleCount = frameCount * 2;
			Internal.MemSet(buffer, 0, sampleCount * sizeof(float));
			Internal.MemSet(mCachedBuffer, 0, sampleCount * sizeof(float));
			return;
		}

		ProcessAudio(buffer, frameCount, sampleRate);

		// Cache the result
		let sampleCount = frameCount * 2;
		Internal.MemCpy(mCachedBuffer, buffer, sampleCount * sizeof(float));
	}

	/// Override in subclasses to produce or process audio.
	/// buffer is zeroed before this call.
	protected abstract void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate);

	/// Sums all input node outputs into buffer (additive).
	protected void AccumulateInputSamples(float* buffer, int32 frameCount, int32 sampleRate, uint64 mixVersion)
	{
		let sampleCount = frameCount * 2;
		Internal.MemSet(buffer, 0, sampleCount * sizeof(float));

		if (mInputs.Count == 0)
			return;

		// First input: copy directly
		mInputs[0].GetOutputSamples(buffer, frameCount, sampleRate, mixVersion);

		if (mInputs.Count == 1)
			return;

		// Remaining inputs: accumulate
		let tempBuffer = new float[sampleCount]*;
		defer delete tempBuffer;

		for (int i = 1; i < mInputs.Count; i++)
		{
			Internal.MemSet(tempBuffer, 0, sampleCount * sizeof(float));
			mInputs[i].GetOutputSamples(tempBuffer, frameCount, sampleRate, mixVersion);

			for (int s = 0; s < sampleCount; s++)
				buffer[s] += tempBuffer[s];
		}
	}

	/// Gets the current mix version this node was last evaluated at.
	public uint64 LastMixVersion => mLastMixVersion;

	private void EnsureCacheBuffer(int32 frameCount)
	{
		let needed = frameCount * 2;
		if (mCachedBuffer == null || mCachedBufferCapacity < needed)
		{
			if (mCachedBuffer != null)
				delete mCachedBuffer;
			mCachedBuffer = new float[needed]*;
			mCachedBufferCapacity = needed;
		}
	}

	public ~this()
	{
		Dispose();
	}

	public virtual void Dispose()
	{
		DisconnectAll();
		if (mCachedBuffer != null)
		{
			delete mCachedBuffer;
			mCachedBuffer = null;
		}
	}
}
