namespace Sedulous.Audio.Graph;

using System;

/// Audio graph node that applies a volume multiplier with smooth interpolation.
/// Used in bus chains for bus-level volume control.
public class VolumeNode : AudioNode
{
	private float mTargetVolume = 1.0f;
	private float mCurrentVolume = 1.0f;

	/// Target volume. Changes are interpolated smoothly over the next buffer.
	public float Volume
	{
		get => mTargetVolume;
		set => mTargetVolume = Math.Clamp(value, 0.0f, 10.0f);
	}

	/// Current interpolated volume (read-only, for debugging).
	public float CurrentVolume => mCurrentVolume;

	protected override void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate)
	{
		AccumulateInputSamples(buffer, frameCount, sampleRate, LastMixVersion);

		let sampleCount = frameCount * 2;

		if (mCurrentVolume == mTargetVolume)
		{
			// No interpolation needed
			if (mCurrentVolume == 1.0f)
				return; // passthrough

			for (int i = 0; i < sampleCount; i++)
				buffer[i] *= mCurrentVolume;
		}
		else
		{
			// Interpolate volume per sample for smooth transitions
			let volumeStep = (mTargetVolume - mCurrentVolume) / (float)frameCount;
			var vol = mCurrentVolume;

			for (int i = 0; i < frameCount; i++)
			{
				vol += volumeStep;
				buffer[i * 2] *= vol;
				buffer[i * 2 + 1] *= vol;
			}

			mCurrentVolume = mTargetVolume;
		}
	}
}
