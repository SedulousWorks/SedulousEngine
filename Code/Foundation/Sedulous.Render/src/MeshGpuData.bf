using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// The per view constants the mesh shaders read.
///
/// These five structs are the GPU LAYOUT CONTRACT: each mirrors a block the shader declares,
/// so a field reordered here and not there silently reads the wrong bytes. The tests pin
/// their sizes for that reason.
[CRepr]
struct MeshViewData
{
	public Float4x4 ViewProj = .Identity();
	/// View space depth, which the clustering and the cascade select both read.
	public Float4x4 View = .Identity();
	/// World into each cascade's light clip space.
	public Float4x4[ShadowCascades.Count] CascadeViewProj = .(.Identity(), .Identity(),
		.Identity(), .Identity());

	public Float3 CameraPos = .(0, 0, 0);
	/// As a float, mirroring the shader's own declaration.
	public float LightCount = 0.0f;

	public uint32 LightOffset = 0;
	public int32 ClusterViewportX = 0;
	public int32 ClusterViewportY = 0;
	/// Below nought means there is no environment, and the shading falls back to flat ambient.
	public float IblMaxLod = -1.0f;

	public uint32 ClusterGridX = 0;
	public uint32 ClusterGridY = 0;
	public uint32 ClusterSliceCount = 0;
	public uint32 ClusterTileSize = 0;

	public float ClusterNear = 0.0f;
	public float ClusterFar = 0.0f;
	public float ClusterLogScale = 0.0f;
	public float ClusterLogBias = 0.0f;

	public Float3 Ambient = .(0, 0, 0);
	public float ShadowCascadeCount = 0.0f;

	public Float4 CascadeSplitFar = .(0, 0, 0, 0);
	public Float4 CascadeTexelSize = .(0, 0, 0, 0);

	public float ShadowNormalBias = 0.0f;
	public float ShadowDepthBias = 0.0f;
	public float CascadeLayerBase = 0.0f;
	public uint32 LocalShadowBase = 0;

	/// Last frame's world into clip, for the motion vectors.
	public Float4x4 PrevViewProj = .Identity();
	/// This frame's jitter in the first two, last frame's in the last two.
	public Float4 Jitter = .(0, 0, 0, 0);

	/// The first component is this view's scene's base into the probe records, and the last
	/// is its count, which is the shader's loop bound.
	public Float4 ProbeCenter = .(0, 0, 0, 0);
	public Float4 ProbeBoxMin = .(0, 0, 0, 0);
	public Float4 ProbeBoxMax = .(0, 0, 0, 0);

	/// The first component is the cascade fade's width in world units; the rest spare.
	public Float4 ShadowParams = .(40.0f, 0, 0, 0);
	/// The first component is the semantic debug mode, nought being off; the rest spare.
	public Float4 DebugParams = .(0, 0, 0, 0);
	/// The diffuse and specular environment dimmers; the rest spare.
	public Float4 IblParams = .(1, 1, 0, 0);

	public this() {}
}

/// The per object constants, at a dynamic offset.
[CRepr]
struct MeshObjectData
{
	public Float4x4 World = .Identity();
	public Float4x4 PrevWorld = .Identity();
	public Color Tint = .(1, 1, 1, 1);
	public uint32 BoneBase = 0;
	public uint32 PrevBoneBase = 0;
	/// The pick pass alone reads these: the entity index plus one, nought being nothing, and
	/// the generation. The forward's layout has them as padding.
	public uint32 PickIndex = 0;
	public uint32 PickGeneration = 0;

	public this() {}
}

/// One element of the per instance structured buffer.
[CRepr]
struct MeshInstanceData
{
	public Float4x4 World = .Identity();
	public Float4x4 PrevWorld = .Identity();
	public Color Tint = .(1, 1, 1, 1);

	public this() {}

	public this(Float4x4 world, Float4x4 prevWorld, Color tint)
	{
		World = world;
		PrevWorld = prevWorld;
		Tint = tint;
	}
}

/// The instance stepped vertex attribute that addresses everything else.
///
/// The portable form of "which instance am I": a base and an offset in a vertex stream,
/// rather than the built in instance index, whose base differs between the backends.
[CRepr]
struct MeshDataOffsets
{
	/// The index into the instance buffer.
	public uint32 X = 0;
	/// The current bone base.
	public uint32 Y = 0;
	/// Last frame's bone base, for the motion vectors.
	public uint32 Z = 0;
	public uint32 W = 0;

	public this() {}

	public this(uint32 x, uint32 y, uint32 z, uint32 w)
	{
		X = x; Y = y; Z = z; W = w;
	}
}

/// The depth only pass's constants: just the light's matrix.
[CRepr]
struct MeshShadowViewData
{
	public Float4x4 LightViewProj = .Identity();

	public this() {}

	public this(Float4x4 lightViewProj)
	{
		LightViewProj = lightViewProj;
	}
}

/// The pick pass's set nought view, the PickView block of pick_ids.vs: the cropped world to
/// clip plus a per DRAW GROUP id override. An instanced set is one entity for all its
/// instances and its instance data is persistent, so its id rides the view slot instead;
/// nought means each draw carries its own. Shares the shadow view ring's slots.
[CRepr]
struct MeshPickViewData
{
	public Float4x4 ViewProj = .Identity();
	public uint32 PickIndex = 0;
	public uint32 PickGeneration = 0;
	public uint32 Pad0 = 0;
	public uint32 Pad1 = 0;

	public this() {}
}
