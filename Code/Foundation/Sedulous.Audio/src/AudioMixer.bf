namespace Sedulous.Audio;

using System;
using System.Collections;
using System.Threading;
using Sedulous.Audio.Graph;

/// Abstract audio mixer. Owns the AudioGraph and AudioBusSystem.
/// Supports threaded mixing via a command queue: the main thread enqueues
/// structural changes, the mix thread drains and applies them before
/// evaluating the graph.
public abstract class AudioMixer : IDisposable
{
	private AudioGraph mGraph;
	private AudioBusSystem mBusSystem;
	private float* mMixBuffer;
	private int32 mFramesPerMix;
	private int32 mSampleRate;

	// Thread-safe command queue: main thread enqueues, mix thread drains
	private List<delegate void()> mCommandQueue = new .() ~ DeleteContainerAndItems!(_);
	private List<delegate void()> mDrainBuffer = new .() ~ DeleteContainerAndItems!(_);
	private Monitor mCommandLock = new .() ~ delete _;
	private bool mThreaded;

	/// The audio graph (owns OutputNode only).
	public AudioGraph Graph => mGraph;

	/// The bus system managing named buses.
	public AudioBusSystem BusSystem => mBusSystem;

	/// Sample rate used for mixing.
	public int32 SampleRate => mSampleRate;

	/// Number of frames processed per mix call.
	public int32 FramesPerMix => mFramesPerMix;

	/// Whether the mixer is running on a separate thread.
	public bool IsThreaded => mThreaded;

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

	/// Enqueues a command to be executed on the mix thread before the next graph evaluation.
	/// If not threaded, the command is executed immediately.
	public void EnqueueCommand(delegate void() command)
	{
		if (!mThreaded)
		{
			command();
			delete command;
			return;
		}

		mCommandLock.Enter();
		mCommandQueue.Add(command);
		mCommandLock.Exit();
	}

	/// Drains all pending commands. Called at the start of each Mix().
	private void DrainCommands()
	{
		if (!mThreaded)
			return;

		// Swap under lock to minimize lock hold time
		mCommandLock.Enter();
		let temp = mCommandQueue;

		// Swap the lists so we drain from the filled one and the main thread enqueues to the empty one
		for (let cmd in temp)
			mDrainBuffer.Add(cmd);
		temp.Clear();

		mCommandLock.Exit();

		// Execute outside the lock
		for (let cmd in mDrainBuffer)
		{
			cmd();
			delete cmd;
		}
		mDrainBuffer.Clear();
	}

	/// Evaluates the audio graph into the mix buffer, then calls OutputMix().
	/// When threaded, this is called from the audio thread.
	public void Mix()
	{
		DrainCommands();

		let sampleCount = mFramesPerMix * 2;
		Internal.MemSet(mMixBuffer, 0, sampleCount * sizeof(float));

		mGraph.Evaluate(mMixBuffer, mFramesPerMix, mSampleRate);

		OutputMix(mMixBuffer, mFramesPerMix, mSampleRate);
	}

	/// Enables threaded mode. After this call, structural changes to the graph
	/// (node connections, bus create/destroy, source connect/disconnect) must
	/// go through EnqueueCommand(). Parameter updates (volume, pan, etc.)
	/// are safe without the queue (atomic single-word writes).
	public void EnableThreading()
	{
		mThreaded = true;
	}

	/// Platform-specific: push the mixed float32 stereo buffer to the audio device.
	protected abstract void OutputMix(float* buffer, int32 frameCount, int32 sampleRate);

	public virtual void Dispose()
	{
		mThreaded = false;

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
