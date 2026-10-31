using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// One decal's constants, laid out exactly as the shader reads them.
[CRepr]
struct DecalUniforms
{
	/// The box's world transform, whose scale is the box's size. It projects along its own
	/// forward axis.
	public Float4x4 World = .Identity();
	/// World into the box's own space, which is where the clip happens.
	public Float4x4 InvWorld = .Identity();
	/// Screen and depth back into world, for THIS view and its jitter.
	public Float4x4 InvViewProj = .Identity();
	public Float4 Color = .(1, 1, 1, 1);
	/// One over the full target's size.
	public Float2 InvTargetSize = .(0, 0);
	/// The cosine of the angle fade's start, and of its end.
	public float FadeStartCos = 1.0f;
	public float FadeEndCos = 0.0f;
	/// The vertical correction for the interpolant: one on Vulkan, minus one on a target that
	/// flips clip space.
	public float YFlip = 1.0f;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;
	public float Pad2 = 0.0f;

	public this() {}
}
