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

	/// The eye in world space.
	public Float3 CameraPos = .(0, 0, 0);
	/// The DISPLAY ONLY background multiplier: the environment's own intensity is baked into
	/// the cube, so this never touches the lighting.
	public float BackgroundIntensity = 1.0f;
	/// The direction to the sun.
	public Float3 SunDirection = .(0, 1, 0);
	public float SunAngularSizeDegrees = 0.5f;
	public Float3 SunColor = .(1, 1, 1);
	public float SunIntensity = 1.0f;
	/// This frame's jitter and last frame's, which the reprojection undoes.
	public Float4 Jitter = .(0, 0, 0, 0);
	/// The sign the reconstructed ray's vertical axis is multiplied by: a backend that flips
	/// clip space presents the ray mirrored, and this mirrors it back.
	public Float4 SkyFlags = .(1, 0, 0, 0);

	public this() {}
}
