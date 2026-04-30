namespace Sedulous.Audio.Effects;

using System;
using Sedulous.Audio;

/// Volume fade effect. Interpolates volume from current to target over a duration.
/// Holds at the target when complete.
public class FadeEffect : IAudioEffect
{
	public enum FadeCurve
	{
		Linear,
		EaseIn,
		EaseOut
	}

	private float mTargetVolume = 1.0f;
	private float mDuration = 1.0f;
	private FadeCurve mCurve = .Linear;
	private bool mEnabled = true;

	// Runtime state
	private float mCurrentVolume = 1.0f;
	private float mStartVolume = 1.0f;
	private float mElapsed;
	private bool mFading;

	public StringView Name => "Fade";

	public bool Enabled
	{
		get => mEnabled;
		set => mEnabled = value;
	}

	/// Target volume to fade to (0.0 to 1.0).
	public float TargetVolume => mTargetVolume;

	/// Duration of the fade in seconds.
	public float Duration => mDuration;

	/// Current interpolated volume.
	public float CurrentVolume => mCurrentVolume;

	/// Whether a fade is currently in progress.
	public bool IsFading => mFading;

	/// Starts a new fade from current volume to target over duration.
	public void StartFade(float targetVolume, float duration, FadeCurve curve = .Linear)
	{
		mStartVolume = mCurrentVolume;
		mTargetVolume = Math.Clamp(targetVolume, 0.0f, 1.0f);
		mDuration = Math.Max(duration, 0.001f);
		mCurve = curve;
		mElapsed = 0;
		mFading = true;
	}

	public void Process(float* buffer, int32 frameCount, int32 sampleRate)
	{
		let sampleCount = frameCount * 2;
		let timePerFrame = 1.0f / (float)sampleRate;

		for (int32 i = 0; i < frameCount; i++)
		{
			if (mFading)
			{
				mElapsed += timePerFrame;
				var t = Math.Clamp(mElapsed / mDuration, 0.0f, 1.0f);

				switch (mCurve)
				{
				case .Linear:
					break; // t is already linear
				case .EaseIn:
					t = t * t;
				case .EaseOut:
					t = 1.0f - (1.0f - t) * (1.0f - t);
				}

				mCurrentVolume = mStartVolume + (mTargetVolume - mStartVolume) * t;

				if (mElapsed >= mDuration)
				{
					mCurrentVolume = mTargetVolume;
					mFading = false;
				}
			}

			buffer[i * 2] *= mCurrentVolume;
			buffer[i * 2 + 1] *= mCurrentVolume;
		}
	}

	public void Reset()
	{
		mCurrentVolume = 1.0f;
		mStartVolume = 1.0f;
		mElapsed = 0;
		mFading = false;
	}

	public void Dispose() { }
}
