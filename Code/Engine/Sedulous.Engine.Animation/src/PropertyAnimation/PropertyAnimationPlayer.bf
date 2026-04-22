namespace Sedulous.Engine.Animation;

using System;
using Sedulous.Animation;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Core;

/// Evaluates a PropertyAnimationClip against an entity, applying sampled values
/// via the PropertyBinderRegistry.
public class PropertyAnimationPlayer
{
	private Scene mScene;
	private EntityHandle mEntity;
	private PropertyBinderRegistry mRegistry;
	private PropertyAnimationClip mClip;
	private float mCurrentTime;
	private float mSpeed = 1.0f;
	private PlaybackState mState = .Stopped;

	/// The scene this player operates on (borrowed).
	public Scene Scene => mScene;

	/// The entity being animated.
	public EntityHandle Entity => mEntity;

	/// The current animation clip (borrowed).
	public PropertyAnimationClip Clip => mClip;

	/// Current playback time in seconds.
	public float CurrentTime
	{
		get => mCurrentTime;
		set => mCurrentTime = value;
	}

	/// Playback speed multiplier.
	public float Speed
	{
		get => mSpeed;
		set => mSpeed = value;
	}

	/// Current playback state.
	public PlaybackState State => mState;

	public this(Scene scene, EntityHandle entity, PropertyBinderRegistry registry)
	{
		mScene = scene;
		mEntity = entity;
		mRegistry = registry;
	}

	/// Starts playing a clip from the beginning.
	public void Play(PropertyAnimationClip clip)
	{
		mClip = clip;
		mCurrentTime = 0;
		mState = .Playing;
	}

	/// Stops playback and resets time.
	public void Stop()
	{
		mState = .Stopped;
		mCurrentTime = 0;
	}

	/// Pauses playback at the current time.
	public void Pause()
	{
		if (mState == .Playing)
			mState = .Paused;
	}

	/// Resumes playback from the current time.
	public void Resume()
	{
		if (mState == .Paused)
			mState = .Playing;
	}

	/// Advances the animation by deltaTime and applies values to the entity.
	public void Update(float deltaTime)
	{
		if (mState != .Playing || mClip == null || mClip.Duration <= 0)
			return;

		mCurrentTime += deltaTime * mSpeed;

		if (mClip.IsLooping)
		{
			while (mCurrentTime >= mClip.Duration)
				mCurrentTime -= mClip.Duration;
			while (mCurrentTime < 0)
				mCurrentTime += mClip.Duration;
		}
		else
		{
			if (mCurrentTime >= mClip.Duration)
			{
				mCurrentTime = mClip.Duration;
				mState = .Stopped;
			}
			else if (mCurrentTime < 0)
			{
				mCurrentTime = 0;
				mState = .Stopped;
			}
		}

		Evaluate();
	}

	/// Evaluates all tracks at the current time and applies values.
	public void Evaluate()
	{
		if (mClip == null || mScene == null || mRegistry == null)
			return;

		// Float tracks
		for (let track in mClip.FloatTracks)
		{
			let setter = mRegistry.GetFloatSetter(track.PropertyPath);
			if (setter != null)
			{
				let value = PropertyAnimationSampler.SampleFloat(track, mCurrentTime);
				setter(mScene, mEntity, value);
			}
		}

		// Vector2 tracks
		for (let track in mClip.Vector2Tracks)
		{
			let setter = mRegistry.GetVector2Setter(track.PropertyPath);
			if (setter != null)
			{
				let value = PropertyAnimationSampler.SampleVector2(track, mCurrentTime);
				setter(mScene, mEntity, value);
			}
		}

		// Vector3 tracks
		for (let track in mClip.Vector3Tracks)
		{
			let setter = mRegistry.GetVector3Setter(track.PropertyPath);
			if (setter != null)
			{
				let value = PropertyAnimationSampler.SampleVector3(track, mCurrentTime);
				setter(mScene, mEntity, value);
			}
		}

		// Vector4 tracks
		for (let track in mClip.Vector4Tracks)
		{
			let setter = mRegistry.GetVector4Setter(track.PropertyPath);
			if (setter != null)
			{
				let value = PropertyAnimationSampler.SampleVector4(track, mCurrentTime);
				setter(mScene, mEntity, value);
			}
		}

		// Quaternion tracks
		for (let track in mClip.QuaternionTracks)
		{
			let setter = mRegistry.GetQuaternionSetter(track.PropertyPath);
			if (setter != null)
			{
				let value = PropertyAnimationSampler.SampleQuaternion(track, mCurrentTime);
				setter(mScene, mEntity, value);
			}
		}
	}
}
