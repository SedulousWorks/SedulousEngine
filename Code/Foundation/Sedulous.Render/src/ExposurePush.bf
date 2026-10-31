using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// What the exposure measure pushes, mirroring exposure_measure.ps.hlsl's ExposurePush.
[CRepr]
struct ExposurePush
{
	public Float2 UvScale = .(1, 1);
	public Float2 UvOffset = .(0, 0);
	/// The frame's time by the adaptation speed: how far the measure moves toward this frame's.
	public float DtSpeed = 0.0f;
	/// 1 once the previous measure holds a value.
	public float HistoryValid = 0.0f;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;

	public this() {}
}
