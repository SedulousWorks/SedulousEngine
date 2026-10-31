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

	/// The cascade fade's width in world units and the clip space Y sign; zw unused.
	public Float4 ShadowParams = .(40.0f, 0, 0, 0);
	/// The first component is the semantic debug mode, nought being off; the rest spare.
	public Float4 DebugParams = .(0, 0, 0, 0);
	/// The diffuse and specular environment dimmers, then the wind's clock: this frame's time in
	/// seconds and the last frame's.
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
	/// The screen door fade, nought being solid: the forward pass's DITHER variant reads it on
	/// the single path, as the instanced one reads DataOffsets.W.
	public float Fade = 0.0f;
	/// Scalars, not a three wide vector: WGSL aligns a vec3 to sixteen bytes, which would move it.
	public uint32 FadePad0 = 0;
	public uint32 FadePad1 = 0;
	public uint32 FadePad2 = 0;

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

/// An instanced draw's set, cbuffer InstanceSet (instance_fade.hlsli), bound in set one beside
/// the instances in the forward, shadow and pick passes: its distance fade's window (an end at
/// or below nought is none), its instance count (each instance's rank in the fade is (index +
/// 0.5) over it), and the entity an instanced set picks as (index plus one and generation;
/// nought is each instance's own id).
[CRepr]
struct MeshInstanceSetData
{
	public float FadeStart = 0.0f;
	public float FadeEnd = 0.0f;
	public uint32 InstanceCount = 1;
	public uint32 Pad0 = 0;
	public uint32 PickIndex = 0;
	public uint32 PickGeneration = 0;
	public uint32 Pad1 = 0;
	public uint32 Pad2 = 0;

	public this() {}
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
	/// The forward pass's fade, as its float's bits (nought is solid).
	public uint32 W = 0;

	public this() {}

	public this(uint32 x, uint32 y, uint32 z, uint32 w)
	{
		X = x; Y = y; Z = z; W = w;
	}
}

/// The depth only pass's constants: the light's matrix and the wind clock.
[CRepr]
struct MeshShadowViewData
{
	public Float4x4 LightViewProj = .Identity();
	/// x is the time in seconds the WIND sway reads; yzw unused.
	public Float4 Wind = .(0, 0, 0, 0);
	/// The CAMERA's position: an instance fade is by camera distance, not the light's.
	public Float3 Camera = .(0, 0, 0);
	/// One when the pass couples to a camera, so a faded set fades; a pass with none draws every
	/// instance.
	public uint32 FadeFromCamera = 0;

	public this() {}

	public this(Float4x4 lightViewProj)
	{
		LightViewProj = lightViewProj;
	}
}

/// The pick pass's set nought view, the PickView block of pick_ids.vs: the cropped world to
/// clip, the WIND clock and the camera the instance fade measures from. An instanced set's own
/// id is its InstanceSet's. Shares the shadow view ring's slots.
[CRepr]
struct MeshPickViewData
{
	public Float4x4 ViewProj = .Identity();
	/// The time in seconds the WIND sway reads, so the pick follows the swayed card.
	public float WindTime = 0.0f;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;
	public float Pad2 = 0.0f;
	/// The camera's position, the instance fade's distance.
	public Float3 Camera = .(0, 0, 0);
	public float Pad3 = 0.0f;

	public this() {}
}
