using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// One local shadow entry, a spot or a single face of a point light, packed as the shader's
/// structured buffer reads it.
///
/// A light's shadow index selects one, and a point light takes six consecutive entries. Built
/// once the atlas layout is known, unlike the directional cascades, because the entry carries
/// the tile it was assigned.
[CRepr]
struct GpuLocalShadow
{
	/// World into the light's clip space, perspective.
	public Float4x4 ViewProjection = .Identity();
	/// Maps that clip space into the light's TILE of the shared atlas: scale then offset.
	public Float4 AtlasScaleBias = .(1, 1, 0, 0);

	/// The depth compare bias in NDC units, which the shader applies toward the light.
	public float DepthBias = ShadowBiasDefaults.LocalDepthBias;
	/// Which atlas layer: the realtime one or the cached static one.
	public float AtlasSelect = 0.0f;
	/// The light's normal offset as world units per unit of distance from the light: its texels
	/// times the tile's texel size at distance one (the shader multiplies by the distance).
	public float NormalBiasPerDistance = 0.0f;
	public float Pad2 = 0.0f;

	public this() {}

	public const int SizeInBytes = 96;
}
