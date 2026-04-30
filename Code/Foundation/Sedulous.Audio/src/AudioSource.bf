using System;
using Sedulous.Core.Mathematics;
using Sedulous.Audio.Graph;

namespace Sedulous.Audio;

/// Default IAudioSource implementation using the audio node graph.
/// Each source owns a SourceNode -> PanNode chain that connects to a bus.
class AudioSource : IAudioSource
{
	private SourceNode mNode ~ { _.DisconnectAll(); _.Dispose(); delete _; };
	private PanNode mPanNode ~ { _.DisconnectAll(); _.Dispose(); delete _; };
	private AudioClip mCurrentClip;
	private AudioSourceState mState = .Stopped;
	private float mVolume = 1.0f;
	private float mPitch = 1.0f;
	private bool mLoop;
	private Vector3 mPosition = .Zero;
	private float mMinDistance = 1.0f;
	private float mMaxDistance = 100.0f;
	private bool m3DEnabled;
	private float mMasterVolume = 1.0f;
	private String mBusName = new .("SFX") ~ delete _;
	private Vector3 mDirection = .(0, 0, -1);
	private SoundAttenuator? mAttenuator;
	private Vector3 mPreviousPosition = .Zero;

	// 3D audio state
	private float mDistanceGain = 1.0f;
	private float mPan = 0.0f;  // -1 = left, 0 = center, +1 = right

	// Graph connection target - set by the system when routing to a bus
	private CombineNode mTargetBus;

	/// The underlying SourceNode in the audio graph.
	public SourceNode Node => mNode;

	/// Creates an audio source.
	/// SourceNode -> PanNode chain. The PanNode is what connects to the bus.
	public this()
	{
		mNode = new SourceNode();
		mPanNode = new PanNode();
		mPanNode.AddInput(mNode);
	}

	public AudioSourceState State => mState;

	public float Volume
	{
		get => mVolume;
		set => mVolume = Math.Clamp(value, 0.0f, 1.0f);
	}

	public float Pitch
	{
		get => mPitch;
		set => mPitch = Math.Max(value, 0.01f);
	}

	public bool Loop
	{
		get => mLoop;
		set
		{
			mLoop = value;
			mNode.Loop = value;
		}
	}

	public Vector3 Position
	{
		get => mPosition;
		set
		{
			mPosition = value;
			m3DEnabled = true;
		}
	}

	public float MinDistance
	{
		get => mMinDistance;
		set => mMinDistance = Math.Max(value, 0.01f);
	}

	public float MaxDistance
	{
		get => mMaxDistance;
		set => mMaxDistance = Math.Max(value, mMinDistance);
	}

	public StringView BusName
	{
		get => mBusName;
		set
		{
			mBusName.Set(value);
		}
	}

	public Vector3 Direction
	{
		get => mDirection;
		set => mDirection = value;
	}

	public SoundAttenuator? Attenuator
	{
		get => mAttenuator;
		set => mAttenuator = value;
	}

	public void Play(AudioClip clip)
	{
		mCurrentClip = clip;
		if (mCurrentClip == null || !mCurrentClip.IsLoaded)
			return;

		mNode.Clip = clip;
		mNode.Loop = mLoop;
		mNode.Volume = mVolume * mMasterVolume * mDistanceGain;
		mNode.Play();

		// Connect to target bus if set and not already connected
		if (mTargetBus != null)
			mTargetBus.AddInput(mPanNode);

		mState = .Playing;
	}

	public void Pause()
	{
		if (mState == .Playing)
			mState = .Paused;
	}

	public void Resume()
	{
		if (mState == .Paused)
			mState = .Playing;
	}

	public void Stop()
	{
		mNode.Stop();

		// Disconnect from bus
		if (mTargetBus != null)
			mTargetBus.RemoveInput(mPanNode);

		mState = .Stopped;
	}

	/// Sets which CombineNode this source routes into.
	public void SetTargetBus(CombineNode bus)
	{
		if (mTargetBus == bus)
			return;

		// Disconnect from old bus
		if (mTargetBus != null && mState != .Stopped)
			mTargetBus.RemoveInput(mPanNode);

		mTargetBus = bus;

		// Connect to new bus if playing
		if (mTargetBus != null && mState != .Stopped)
			mTargetBus.AddInput(mPanNode);
	}

	/// Sets the master volume from the audio system.
	public void SetMasterVolume(float masterVolume)
	{
		mMasterVolume = masterVolume;
	}

	/// Calculates 3D audio parameters (distance gain, cone, pan) from listener position.
	public void Update3D(AudioListener listener)
	{
		if (!m3DEnabled)
		{
			mDistanceGain = 1.0f;
			mPan = 0.0f;
			return;
		}

		let offset = mPosition - listener.Position;
		let distance = offset.Length();

		// Distance attenuation - use attenuator if available, else default linear
		if (mAttenuator.HasValue)
		{
			let att = mAttenuator.Value;
			mDistanceGain = att.CalculateGain(distance);

			// Cone attenuation
			if (att.ConeInnerAngle < 360.0f && distance > 0.001f)
			{
				let toListener = offset / distance;
				let dotProduct = Vector3.Dot(mDirection, toListener);
				let angleDeg = Math.Acos(Math.Clamp(dotProduct, -1.0f, 1.0f)) * (180.0f / Math.PI_f);
				mDistanceGain *= att.CalculateConeGain(angleDeg);
			}
		}
		else
		{
			// Default linear attenuation
			if (distance <= mMinDistance)
				mDistanceGain = 1.0f;
			else if (distance >= mMaxDistance)
				mDistanceGain = 0.0f;
			else
				mDistanceGain = 1.0f - (distance - mMinDistance) / (mMaxDistance - mMinDistance);
		}

		// Stereo pan from direction
		if (distance > 0.001f)
		{
			let direction = offset / distance;
			let right = Vector3.Normalize(Vector3.Cross(listener.Forward, listener.Up));
			mPan = Math.Clamp(Vector3.Dot(direction, right), -1.0f, 1.0f);
		}
		else
		{
			mPan = 0.0f;
		}

		mPreviousPosition = mPosition;
	}

	/// Syncs volume and state to the underlying SourceNode.
	/// Called each frame by the system before graph evaluation.
	public void UpdateState()
	{
		if (mState == .Playing)
		{
			// Apply volume and pan to graph nodes
			mNode.Volume = mVolume * mMasterVolume * mDistanceGain;
			mPanNode.Pan = mPan;
			mNode.Enabled = true;

			// Check if source node finished
			if (mNode.IsFinished)
			{
				mState = .Stopped;

				// Disconnect from bus
				if (mTargetBus != null)
					mTargetBus.RemoveInput(mPanNode);
			}
		}
		else if (mState == .Paused)
		{
			mNode.Enabled = false;
		}
	}

	/// Returns true if this is a one-shot source (managed by the system).
	public bool IsOneShot { get; set; }

	/// Returns true if this source has finished playing (for one-shot cleanup).
	public bool IsFinished => mState == .Stopped && (mNode == null || mNode.IsFinished || !mNode.IsPlaying);

	/// For one-shot sources, stores the 3D position for panning calculations.
	public Vector3 OneShotPosition { get; set; }
}
