using System;

namespace Sedulous.Render;

/// The debug blit's constants, laid out exactly as the shader reads them.
[CRepr]
struct DebugBlitPush
{
	public float UvScaleX = 1.0f;
	public float UvScaleY = 1.0f;
	public float UvOffsetX = 0.0f;
	public float UvOffsetY = 0.0f;
	public float SourceWidth = 1.0f;
	public float SourceHeight = 1.0f;
	public float RangeMin = 0.0f;
	public float RangeMax = 1.0f;
	public float NearZ = 0.1f;
	public float FarZ = 1000.0f;
	/// The channel select in the low three bits, and the depth linearisation at bit four.
	public uint32 Mode = 0;
	public uint32 Pad = 0;

	public this() {}
}
