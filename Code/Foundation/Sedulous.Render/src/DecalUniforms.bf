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
	/// The inverse of the full target's size in the first two, and the cosines of the fade's
	/// start and end angles in the last two.
	public Float4 Params = .(0, 0, 1, 0);
	/// The vertical correction for the interpolant in the first component; the rest spare.
	public Float4 Flip = .(1, 0, 0, 0);

	public this() {}
}
