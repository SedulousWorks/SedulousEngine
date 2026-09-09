using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// The ground truth estimator's constants.
[CRepr]
struct GtaoPush
{
	public Float4x4 InvProj = .Identity();
	public Float2 TexelSize = .(0, 0);
	public float Radius = 0.5f;
	public float Intensity = 1.0f;
	/// The projection's vertical scale, which turns a world radius into a screen one.
	public float ProjScaleY = 1.0f;
	/// The frame, wrapped, which rotates the sampling pattern so the noise moves and the
	/// temporal resolve can average it away.
	public int32 FrameMod = 0;
	public int32 DebugMode = 0;
	public int32 Pad = 0;

	public this() {}
}

/// The screen space estimator's constants.
[CRepr]
struct SsaoPush
{
	public Float4x4 InvProj = .Identity();
	public Float2 TexelSize = .(0, 0);
	/// The projection's own jitter, so the back projection matches the jittered depth it is
	/// reading rather than landing half a pixel off.
	public Float2 Jitter = .(0, 0);
	public float ProjXX = 1.0f;
	public float ProjYY = 1.0f;
	public float Radius = 0.5f;
	public float Intensity = 1.0f;
	public float Bias = 0.05f;
	public int32 SampleCount = 16;
	public int32 DebugMode = 0;

	public this() {}
}

/// The bilateral blur's constants: a direction, so the same shader runs across and then down.
[CRepr]
struct AoBlurPush
{
	public Float2 Direction = .(0, 0);
	public Float2 TexelSize = .(0, 0);
	/// How sharply the blur stops at a depth discontinuity, which is what keeps occlusion
	/// from bleeding across an edge.
	public float DepthSigma = 120.0f;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;
	public float Pad2 = 0.0f;

	public this() {}
}

/// The composite's constants.
[CRepr]
struct AoApplyPush
{
	public float Strength = 1.0f;
	/// One where the occlusion has to be sampled with its vertical coordinate flipped: the
	/// fullscreen passes store it mirrored against the scene on a backend that flips clip
	/// space.
	public float FlipAoY = 0.0f;
	public float Pad1 = 0.0f;
	public float Pad2 = 0.0f;

	public this() {}
}
