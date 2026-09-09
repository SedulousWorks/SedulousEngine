using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// The sub pixel jitter temporal antialiasing samples between.
static class TaaJitter
{
	/// One term of a low discrepancy sequence, which is what spreads the samples evenly
	/// rather than clumping them the way random ones do.
	public static float HaltonSeq(uint32 index, uint32 numberBase)
	{
		var fraction = 1.0f;
		var result = 0.0f;
		var i = index + 1;

		while (i > 0)
		{
			fraction /= (float)numberBase;
			result += fraction * (float)(i % numberBase);
			i /= numberBase;
		}
		return result;
	}

	/// This frame's jitter, in CLIP SPACE, centred about zero and scaled to a single texel.
	///
	/// Added to the projection's third row, which shifts clip space by a constant number of
	/// pixels. The two bases are coprime, so the sequence does not repeat itself in either
	/// axis for a long while.
	public static Float2 HaltonJitter(uint32 index, uint32 width, uint32 height)
	{
		let x = HaltonSeq(index, 2) - 0.5f;
		let y = HaltonSeq(index, 3) - 0.5f;

		return .(x * 2.0f / (float)Max(width, (uint32)1),
			y * 2.0f / (float)Max(height, (uint32)1));
	}
}
