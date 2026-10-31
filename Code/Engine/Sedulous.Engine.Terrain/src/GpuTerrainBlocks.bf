using System;
using Sedulous.Core;

namespace Sedulous.Engine.Terrain;

/// The terrain view block, mirroring terrain.ps.hlsl's TerrainView (terrain.vs.hlsl declares its
/// first four members by the same names, terrain_depth.vs.hlsl its first two): keep the field
/// order in lockstep.
[CRepr]
struct GpuTerrainView
{
	public Float4x4 ChunkToWorld;
	public Float4x4 ViewProj;
	public Float4x4 View;
	public Float4x4 PrevViewProj;
	/// One per shadow cascade (ShadowCascades.Count).
	public Float4x4[4] CascadeViewProj;
	/// The direction TO the light, normalised.
	public Float3 LightDir;
	public float Pad0;
	/// The camera in world space.
	public Float3 CameraPos;
	public float Pad1;
	/// This frame's jitter in the first two, last frame's in the last two.
	public Float4 Jitter;
	public Float4 CascadeSplitFar;
	public Float4 CascadeTexelSize;
	/// Nought: no directional caster this frame, so the pixel shader is fully lit.
	public float CascadeCount;
	/// The first cascade's layer in the shadow array.
	public float CascadeLayerBase;
	public float ShadowNormalBias;
	public float ShadowDepthBias;
	/// The far edge's fade width, in view depth.
	public float ShadowFarFade;
	public float ShadowUvYSign;
	/// The height blend's soft skirt width.
	public float HeightBlendContrast;
	/// One: a base or palette height map is bound (height blending on).
	public uint32 HeightMapsBound;
	public float PaletteCount;
	/// One: the splat weights, indices and palette are bound.
	public uint32 WeightsBound;
	/// The base maps' tile size, in terrain local units.
	public float BaseTileScale;
	/// One: a base albedo is bound.
	public uint32 BaseBound;
	/// One: a palette coverage mask array is bound.
	public uint32 MaskMapsBound;
	public float Pad2;
	public float Pad3;
	public float Pad4;
	/// The caster light's shadow strength, one being full.
	public float ShadowStrength;
	public float Pad5;
	public float Pad6;
	public float Pad7;
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

/// The pick pass's own view (cbuffer TerrainPickView, terrain_pick.vs.hlsl), written into the
/// slot the colour pass's TerrainView uses: the same two matrices first, then the id.
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
