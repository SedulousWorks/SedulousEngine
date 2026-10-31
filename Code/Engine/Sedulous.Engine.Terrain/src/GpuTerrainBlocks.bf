using System;
using Sedulous.Core;

namespace Sedulous.Engine.Terrain;

/// The terrain view block, mirroring terrain.ps.hlsl's TerrainView (the vertex and depth shaders
/// declare a prefix of it): keep the field order in lockstep.
[CRepr]
struct GpuTerrainView
{
	public Float4x4 ChunkToWorld;
	public Float4x4 ViewProj;
	public Float4x4 View;
	public Float4x4 PrevViewProj;
	/// One per shadow cascade (ShadowCascades.Count).
	public Float4x4[4] CascadeViewProj;
	public Float4 LightDir;
	public Float4 CameraPos;
	public Float4 Jitter;
	public Float4 CascadeSplitFar;
	public Float4 CascadeTexelSize;
	/// x the cascade count, y the layer base, z the normal bias, w the depth bias.
	public Float4 ShadowMeta;
	/// x the far fade width, y the uv y sign, z the height blend contrast, w whether a
	/// height map is bound.
	public Float4 ShadowParams;
	/// x the palette count, y whether weights are bound, z the base tile scale, w whether
	/// a base albedo is bound.
	public Float4 SplatParams;
	/// x whether a coverage mask array is bound; the rest spare.
	public Float4 SplatParams2;
	/// x the caster light's shadow strength (one is full); the rest spare. Last, so the
	/// vertex shader's shorter declaration of this block still lines up.
	public Float4 ShadowLight;
}

/// The terrain chunk block, mirroring the terrain shaders' TerrainChunk. Shared by the colour, the
/// depth and the pick passes.
[CRepr]
struct GpuTerrainChunk
{
	public Float2 OriginXZ;
	public Float2 SizeXZ;
	public Float2 TexelBase;
	public Float2 TexelSpan;
	public Float2 HeightRange;
	public Float2 GridSize;
	/// x the skirt depth in world units, y spare.
	public Float2 Skirt;
}

/// The pick pass's view slot: the placement and the cropped projection where the depth
/// pass reads them, then the terrain entity's id. Mirrors terrain_pick.vs's prefix.
[CRepr]
struct GpuTerrainPickView
{
	public Float4x4 ChunkToWorld;
	public Float4x4 ViewProj;
	/// The entity index plus one; nought is nothing.
	public uint32 PickIndex;
	public uint32 PickGeneration;
	public uint32 Pad0;
	public uint32 Pad1;
}
