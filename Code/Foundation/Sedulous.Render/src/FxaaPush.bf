using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// What the FXAA pass pushes, mirroring fxaa.ps.hlsl's FxaaPush.
[CRepr]
struct FxaaPush
{
	/// One over the whole target's size.
	public Float2 TexelSize = .(0, 0);
	/// The fullscreen uv to the view's sub rectangle.
	public Float2 UvScale = .(1, 1);
	public Float2 UvOffset = .(0, 0);
	public float SubpixelQuality = 0.75f;
	/// The relative edge threshold, and the absolute floor below which a difference is noise.
	public float EdgeThreshold = 0.166f;
	public float EdgeThresholdMin = 0.0312f;
	/// 1 when the source holds linear values (an sRGB or a float target).
	public float LinearInput = 0.0f;

	public this() {}
}
