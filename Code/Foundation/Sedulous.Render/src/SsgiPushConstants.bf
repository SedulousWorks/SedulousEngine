using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// The trace's constants, laid out exactly as the shader reads them.
[CRepr]
struct SsgiPush
{
	public Float4x4 InvProj = .Identity();
	/// This view's sub rectangle, in texture coordinates: a split screen view traces in its
	/// own local space while sampling the whole texture.
	public Float2 VpMin = .(0, 0);
	public Float2 VpSize = .(1, 1);
	public Float2 Jitter = .(0, 0);
	public float ProjXX = 1.0f;
	public float ProjYY = 1.0f;
	public float Thickness = 0.6f;
	public float Radius = 3.0f;
	public int32 MaxSteps = 24;
	public int32 RayCount = 2;
	/// The sign of the vertical axis in the shader's coordinate conversions, which differs
	/// between the backends.
	public float YSign = -1.0f;
	/// Rotates the trace's noise, so a still camera converges under the temporal blend.
	public uint32 FrameIndex = 0;
	public float MaxRadiance = 4.0f;
	public float Pad0 = 0.0f;

	public this() {}
}

/// The radiance prefilter's constants.
[CRepr]
struct SsgiDownPush
{
	public Float2 SrcTexelSize = .(0, 0);
	public Float2 Pad0 = .(0, 0);

	public this() {}
}

/// The spatial denoise's constants.
[CRepr]
struct SsgiBlurPush
{
	public Float2 TexelSize = .(0, 0);
	public float DepthSigma = 0.05f;
	public float Pad0 = 0.0f;
	public Float4x4 InvProj = .Identity();
	public Float2 VpMin = .(0, 0);
	public Float2 VpSize = .(1, 1);
	public float YSign = -1.0f;
	public float Pad1 = 0.0f;

	public this() {}
}

/// The resolve's constants.
[CRepr]
struct SsgiResolvePush
{
	public Float2 VpMin = .(0, 0);
	public Float2 VpSize = .(1, 1);
	public Float2 TexelSize = .(0, 0);
	public float BlendFactor = 0.92f;
	public float HistoryValid = 0.0f;
	public float VarianceGamma = 1.5f;
	public float MotionScale = 24.0f;
	public int32 TemporalOn = 1;
	public int32 Debug = 0;
	public float GhostReject = 3.0f;
	public float Intensity = 1.0f;

	public this() {}
}
