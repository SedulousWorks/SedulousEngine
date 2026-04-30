namespace Sedulous.Audio.Graph;

using System;

/// Audio graph node that applies stereo panning using constant-power law.
/// Pan range: -1.0 (full left) to 0.0 (center) to 1.0 (full right).
public class PanNode : AudioNode
{
	private float mPan = 0.0f;

	/// Stereo pan position (-1.0 = left, 0.0 = center, 1.0 = right).
	public float Pan
	{
		get => mPan;
		set => mPan = Math.Clamp(value, -1.0f, 1.0f);
	}

	protected override void ProcessAudio(float* buffer, int32 frameCount, int32 sampleRate)
	{
		AccumulateInputSamples(buffer, frameCount, sampleRate, LastMixVersion);

		if (mPan == 0.0f)
			return; // center = no change

		// Constant-power panning
		// angle maps pan [-1, +1] to [0, PI/2]
		let angle = (mPan + 1.0f) * Math.PI_f * 0.25f;
		let leftGain = Math.Cos(angle);
		let rightGain = Math.Sin(angle);

		for (int32 i = 0; i < frameCount; i++)
		{
			let li = i * 2;
			let ri = i * 2 + 1;

			// Mix both channels to mono, then re-pan
			let mono = (buffer[li] + buffer[ri]) * 0.5f;
			buffer[li] = mono * leftGain;
			buffer[ri] = mono * rightGain;
		}
	}
}
