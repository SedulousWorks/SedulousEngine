namespace Sedulous.Audio;

using System;
using Sedulous.Audio.Graph;

/// Abstract audio mixer. Owns the AudioGraph, manages the bus system,
/// and defines the Mix() method for platform backends to implement.
public abstract class AudioMixer : IDisposable
{
	private AudioGraph mGraph;
	private AudioBusSystem mBusSystem;
	private float* mMixBuffer;
	private int32 mFramesPerMix;
	private int32 mSampleRate;

	/// The audio graph (owns OutputNode only).
	public AudioGraph Graph => mGraph;

	/// The bus system managing named buses.
	public AudioBusSystem BusSystem => mBusSystem;

	/// Sample rate used for mixing.
	public int32 SampleRate => mSampleRate;

	/// Number of frames processed per mix call.
	public int32 FramesPerMix => mFramesPerMix;

	/// The float32 stereo interleaved mix buffer. Available to subclasses for output.
	protected float* MixBuffer => mMixBuffer;

	public this(int32 sampleRate = 48000, int32 framesPerMix = 1024)
	{
		mSampleRate = sampleRate;
		mFramesPerMix = framesPerMix;
		mGraph = new AudioGraph();
		mBusSystem = new AudioBusSystem(mGraph);

		let sampleCount = framesPerMix * 2; // stereo
		mMixBuffer = new float[sampleCount]*;
	}

	/// Evaluates the audio graph into the mix buffer, then calls OutputMix()
	/// for the backend to push to the device.
	public void Mix()
	{
		let sampleCount = mFramesPerMix * 2;
		Internal.MemSet(mMixBuffer, 0, sampleCount * sizeof(float));

		mGraph.Evaluate(mMixBuffer, mFramesPerMix, mSampleRate);

		OutputMix(mMixBuffer, mFramesPerMix, mSampleRate);
	}

	/// Platform-specific: push the mixed float32 stereo buffer to the audio device.
	protected abstract void OutputMix(float* buffer, int32 frameCount, int32 sampleRate);

	public virtual void Dispose()
	{
		if (mBusSystem != null)
		{
			delete mBusSystem;
			mBusSystem = null;
		}

		if (mGraph != null)
		{
			mGraph.Dispose();
			delete mGraph;
			mGraph = null;
		}

		if (mMixBuffer != null)
		{
			delete mMixBuffer;
			mMixBuffer = null;
		}
	}

	public ~this()
	{
		Dispose();
	}
}
