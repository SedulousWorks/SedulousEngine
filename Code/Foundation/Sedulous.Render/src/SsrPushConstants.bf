using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// The trace's constants, laid out exactly as the shader reads them.
[CRepr]
struct SsrPush
{
	public Float4x4 InvProj = .Identity();
	/// This view's sub rectangle, in texture coordinates: a split screen view traces in its
	/// own local space while sampling the whole texture.
	public Float2 VpMin = .(0, 0);
	public Float2 VpSize = .(1, 1);
	public Float2 Jitter = .(0, 0);
	public float ProjXX = 1.0f;
	public float ProjYY = 1.0f;
	public float Thickness = 0.5f;
	public float Intensity = 1.0f;
	public float EdgeFade = 0.1f;
	public float RoughCutoff = 0.6f;
	public int32 MaxSteps = 96;
	/// The sign of the vertical axis in the shader's coordinate conversions, which differs
	/// between the backends.
	public float YSign = -1.0f;
	public int32 Debug = 0;
	public float Glossy = 1.0f;

	public this() {}
}

/// The resolve's constants.
[CRepr]
struct SsrResolvePush
{
	public Float2 VpMin = .(0, 0);
	public Float2 VpSize = .(1, 1);
	public Float2 TexelSize = .(0, 0);
	public float BlendFactor = 0.88f;
	public float HistoryValid = 0.0f;
	public float VarianceGamma = 1.0f;
	public float MotionScale = 24.0f;
	public int32 TemporalOn = 1;
	public int32 Debug = 0;
	public float GhostReject = 6.0f;

	public this() {}
}
