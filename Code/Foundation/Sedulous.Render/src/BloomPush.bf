using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// What a bloom pass pushes to its shader.
[CRepr]
struct BloomPush
{
	/// One texel of the SOURCE, so the filter's taps land between texels and get the
	/// hardware's bilinear filtering for nothing.
	public Float2 SrcTexel = .(0, 0);
	public float Threshold = 1.0f;
	public float Knee = 0.5f;
	/// Only the first downsample applies the threshold; the rest are already filtered.
	public int32 FirstPass = 0;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;
	public float Pad2 = 0.0f;

	public this() {}
}
