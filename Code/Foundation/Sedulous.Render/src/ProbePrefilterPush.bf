using System;

namespace Sedulous.Render;

/// The probe prefilter's constants, laid out exactly as the shader reads them.
[CRepr]
struct ProbePrefilterPush
{
	public int32 FaceIndex = 0;
	public float Roughness = 0.0f;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;

	public this() {}
}
