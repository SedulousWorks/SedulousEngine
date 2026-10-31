using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// One reflection probe as the shading reads it.
///
/// Packed so that, per cluster, the forward can pick the probe, box project the reflection ray
/// against it, and index its slice of the cube array. As lighting.hlsli declares it, every
/// scalar by its name in sixty four bytes; Integration.ShaderBlocks checks the two agree.
[CRepr]
struct GpuProbe
{
	/// The capture centre in world space.
	public Float3 Center = .(0, 0, 0);
	/// The reflection's strength.
	public float Intensity = 1.0f;
	/// The influence box's lower corner.
	public Float3 BoxMin = .(0, 0, 0);
	/// The fade at the box's faces.
	public float BlendDistance = 1.0f;
	/// The box's upper corner.
	public Float3 BoxMax = .(0, 0, 0);
	/// The probe's cube in the array: a float, as the sampler takes it.
	public float Slice = 0.0f;
	/// The prefiltered levels.
	public float MipCount = 1.0f;
	public float Priority = 0.0f;
	/// One: box project the reflection ray.
	public float Parallax = 1.0f;
	public float Pad = 0.0f;

	public this() {}
}
