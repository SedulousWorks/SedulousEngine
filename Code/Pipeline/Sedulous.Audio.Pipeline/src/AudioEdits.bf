using System;

namespace Sedulous.Audio.Pipeline;

/// The cook's destructive edits' numbers, which the import window's notes say beforehand: what the
/// trim keeps and what the normalize scales by, counted by these for both, so what a note says is
/// what the cook does.
static class AudioEdits
{
	/// About -60 dBFS: a sample no louder is silence to the trim.
	public const int16 cSilenceThreshold = 33;
	/// Normalize brings the peak to -1 dBFS.
	public const float cNormalizeTarget = 0.891f * 32767.0f;

	/// The frames the trim keeps: up to the last audible one, and a 10 ms pad so nothing clicks.
	public static int AudibleFrames(Span<int16> samples, uint32 channels, uint32 sampleRate)
	{
		if (channels == 0)
			return 0;
		let frameCount = samples.Length / (int)channels;
		var lastAudibleFrame = 0;
		for (int frame = frameCount; (frame > 0) && (lastAudibleFrame == 0); --frame)
		{
			for (uint32 channel < channels)
			{
				if (Math.Abs((int)samples[(frame - 1) * (int)channels + (int)channel]) > cSilenceThreshold)
				{
					lastAudibleFrame = frame;
					break;
				}
			}
		}
		return Math.Min(lastAudibleFrame + (int)sampleRate / 100, frameCount);
	}

	/// The loudest sample's magnitude, of 32767.
	public static int32 Peak(Span<int16> samples)
	{
		int32 peak = 0;
		for (let sample in samples)
			peak = Math.Max(peak, Math.Abs((int32)sample));
		return peak;
	}
}
