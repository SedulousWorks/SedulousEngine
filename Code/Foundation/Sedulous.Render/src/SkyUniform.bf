using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// What the sky shader reads: enough to rebuild the world ray through each pixel, and the sun
/// to draw on it.
[CRepr]
struct SkyUniform
{
	public Float4x4 InvViewProj = .Identity();
	/// Last frame's, which the camera motion vectors are the difference against.
	public Float4x4 PrevViewProj = .Identity();

	/// The eye, with the DISPLAY ONLY background multiplier in its fourth component: the
	/// environment's own intensity is baked into the cube, so this never touches the lighting.
	public Float4 CamPosIntensity = .(0, 0, 0, 1);
	/// The direction to the sun, with its angular size.
	public Float4 SunDir = .(0, 1, 0, 0.5f);
	public Float4 SunColor = .(1, 1, 1, 1);
	/// This frame's jitter and last frame's, which the reprojection undoes.
	public Float4 Jitter = .(0, 0, 0, 0);
	/// The sign the reconstructed ray's vertical axis is multiplied by: a backend that flips
	/// clip space presents the ray mirrored, and this mirrors it back.
	public Float4 SkyFlags = .(1, 0, 0, 0);

	public this() {}
}
