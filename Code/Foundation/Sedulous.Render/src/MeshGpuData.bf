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

	/// This view's scene's first record in the probe records (scenes' records are
	/// concatenated per frame).
	public uint32 ProbeBase = 0;
	/// Its reflection probes, the shader's loop bound; nought is none, the global IBL alone.
	public uint32 ProbeCount = 0;
	public uint32 ProbePad0 = 0;
	public uint32 ProbePad1 = 0;

	/// The cascade fade's width in world units and the clip space Y sign; zw unused.
	public Float4 ShadowParams = .(40.0f, 0, 0, 0);
	/// The first component is the semantic debug mode, nought being off; the rest spare.
	public Float4 DebugParams = .(0, 0, 0, 0);
	/// The sky lighting dimmer (diffuse image lighting).
	public float IblDiffuse = 1.0f;
	/// The sky reflection dimmer (specular image lighting).
	public float IblSpecular = 1.0f;
	/// The view's scene clock in seconds: the WIND sway, a surface's Time().
	public float SceneTime = 0.0f;
	/// Last frame's, so the previous position sways with it for the motion vectors.
	public float PrevSceneTime = 0.0f;

	public this() {}
}

/// A single object's per draw block, cbuffer Object (object_block.hlsli; set one binding nought,
/// at a dynamic offset): one declaration the forward, shadow depth and pick vertex stages all
/// include, each pass writing and reading the fields it uses, by name.
[CRepr]
struct MeshObjectData
{
	public Float4x4 World = .Identity();
	public Float4x4 PrevWorld = .Identity();
	public Color Tint = .(1, 1, 1, 1);
	public uint32 BoneBase = 0;
	public uint32 PrevBoneBase = 0;
	/// The pick pass alone reads these: the entity index plus one, nought being nothing, and
	/// the generation.
	public uint32 PickIndex = 0;
	public uint32 PickGeneration = 0;
	/// The screen door fade, nought being solid: the forward pass's DITHER variant reads it on
	/// the single path, as the instanced one reads MeshDrawOffsets.Fade.
	public float Fade = 0.0f;
	/// Scalars, not a three wide vector: WGSL aligns a vec3 to sixteen bytes, which would move it.
	public uint32 ObjectPad0 = 0;
	public uint32 ObjectPad1 = 0;
	public uint32 ObjectPad2 = 0;

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

/// The instance stepped uint4 at location five an instanced draw binds beside its instances, one
/// entry per instance, in two layouts by pass. This is the forward's and the shadow depth's
/// (drawOffsets in forward_vs and shadow_depth_vs.hlsli): written by their instanced fills, the
/// shared MultiMesh ramp and a skinned set's per instance offsets. The fade is a float whose bits
/// travel in the uint4's w; the shader reads it with asfloat. A depth fill writes nought (a faded
/// run is never prepassed, so the forward reuses only solid ranges).
///
/// The portable form of "which instance am I": a base and an offset in a vertex stream,
/// rather than the built in instance index, whose base differs between the backends.
[CRepr]
struct MeshDrawOffsets
{
	/// Into the draw's Instances[].
	public uint32 InstanceIndex = 0;
	/// The instance's first bone matrix (skinned); nought otherwise.
	public uint32 BoneBase = 0;
	/// Last frame's bone base, for the motion vectors.
	public uint32 PrevBoneBase = 0;
	/// The screen door fade, nought being solid (the forward pass's DITHER variant).
	public float Fade = 0.0f;

	public this() {}

	public this(uint32 instanceIndex, uint32 boneBase, uint32 prevBoneBase, float fade)
	{
		InstanceIndex = instanceIndex;
		BoneBase = boneBase;
		PrevBoneBase = prevBoneBase;
		Fade = fade;
	}
}

/// The pick pass's instance stepped entry (pickOffsets in pick_ids_vs.hlsli): the instance and
/// bone base, then the entity's id. Its instanced fill writes them per draw; a MultiMesh set's
/// pick draw binds the pick ramp or the set's pick offsets, whose ids are nought (the set picks
/// as its InstanceSet's entity). The same sixteen bytes as MeshDrawOffsets: both passes' entries
/// share one ring's stride.
[CRepr]
struct MeshPickDrawOffsets
{
	/// Into the draw's Instances[].
	public uint32 InstanceIndex = 0;
	/// The instance's first bone matrix (skinned); nought otherwise.
	public uint32 BoneBase = 0;
	/// The entity's generation.
	public uint32 PickGeneration = 0;
	/// The entity's index plus one, nought being nothing.
	public uint32 PickIndex = 0;

	public this() {}

	public this(uint32 instanceIndex, uint32 boneBase, uint32 pickGeneration, uint32 pickIndex)
	{
		InstanceIndex = instanceIndex;
		BoneBase = boneBase;
		PickGeneration = pickGeneration;
		PickIndex = pickIndex;
	}
}

/// The depth only pass's constants: the light's matrix, the camera a faded set fades from, and
/// the scene clock.
[CRepr]
struct MeshShadowViewData
{
	public Float4x4 LightViewProj = .Identity();
	/// The CAMERA's position: an instance fade is by camera distance, not the light's.
	public Float3 Camera = .(0, 0, 0);
	/// One when the pass couples to a camera, so a faded set fades; a pass with none draws every
	/// instance.
	public uint32 FadeFromCamera = 0;
	/// The scene clock in seconds: the WIND sway, a surface's Time().
	public float SceneTime = 0.0f;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;
	public float Pad2 = 0.0f;

	public this() {}

	public this(Float4x4 lightViewProj)
	{
		LightViewProj = lightViewProj;
	}
}

/// The pick pass's set nought view, the PickView block of pick_ids.vs: the cropped world to
/// clip, the scene clock and the camera the instance fade measures from. An instanced set's own
/// id is its InstanceSet's. Shares the shadow view ring's slots.
[CRepr]
struct MeshPickViewData
{
	public Float4x4 ViewProj = .Identity();
	/// The scene clock in seconds: the WIND sway (the pick follows the swayed card), a
	/// surface's Time().
	public float SceneTime = 0.0f;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;
	public float Pad2 = 0.0f;
	/// The camera's position, the instance fade's distance.
	public Float3 Camera = .(0, 0, 0);
	public float Pad3 = 0.0f;

	public this() {}
}
