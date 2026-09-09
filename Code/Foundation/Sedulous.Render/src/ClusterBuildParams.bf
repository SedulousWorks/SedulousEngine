using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// The build parameters, laid out exactly as the compute kernel's buffer reads them.
///
/// The scalars are grouped into whole vectors and the matrices follow, because the layout is
/// the shader's rather than ours: a field moved for tidiness would be read as another.
[CRepr]
struct ClusterBuildParams
{
	public uint32 GridX = 0;
	public uint32 GridY = 0;
	public uint32 SliceCount = 0;
	public uint32 TileSize = 0;

	public float NearZ = 0.0f;
	public float FarZ = 0.0f;
	public float LogScale = 0.0f;
	public float LogBias = 0.0f;

	public uint32 LightCount = 0;
	public uint32 LightOffset = 0;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;

	public Float4x4 ViewMatrix = .Identity();
	public Float4x4 InverseProjection = .Identity();

	public this() {}
}
