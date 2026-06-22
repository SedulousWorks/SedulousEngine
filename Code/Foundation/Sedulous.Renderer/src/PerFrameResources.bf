namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;

/// GPU uniform data for per-frame scene constants (bind group set 0).
/// Layout must match the SceneUniforms cbuffer in all shaders that declare it.
[CRepr]
public struct SceneUniforms
{
	public Matrix ViewMatrix;
	public Matrix ProjectionMatrix;
	public Matrix ViewProjectionMatrix;
	public Matrix InvViewMatrix;
	public Matrix InvProjectionMatrix;
	public Matrix InvViewProjectionMatrix;
	/// Previous frame's combined view-projection matrix, used by the forward
	/// shader to compute per-pixel screen-space motion vectors for TAA / motion blur.
	public Matrix PrevViewProjectionMatrix;
	public Vector3 CameraPosition;
	public float NearPlane;
	public float FarPlane;
	public float Time;
	public float DeltaTime;
	public float _Pad0;
	public Vector2 ScreenSize;
	public Vector2 InvScreenSize;
	public Vector2 JitterOffset;
	public Vector2 PrevJitterOffset;
	/// Negative LOD bias applied to material texture samples when TAA is on so
	/// the rasterizer reads finer mips that TAA can reconstruct into a sharp
	/// stable image. 0 when TAA is off.
	public float MaterialLodBias;
	public float _Pad1;

	public const uint64 Size = sizeof(Self);
}

/// Per-frame GPU resources, double-buffered.
/// Each frame-in-flight has its own set to avoid write-while-GPU-reads.
class PerFrameResources
{
	/// Scene uniform ring buffer (set 0, binding 0, dynamic offset).
	/// Per-view scene uniforms are appended into this buffer; the dynamic offset
	/// selects the active view's slot when binding the frame group.
	public IBuffer SceneUniformBuffer;

	/// Frame-level bind group (set 0).
	public IBindGroup FrameBindGroup;

	/// Object uniform buffer for per-draw transforms (set 3, dynamic offsets).
	public IBuffer ObjectUniformBuffer;

	/// Draw call bind group (set 3) with dynamic offset into ObjectUniformBuffer.
	public IBindGroup DrawCallBindGroup;

	/// Current write offset into ObjectUniformBuffer (reset each frame).
	public uint32 ObjectBufferOffset;

	/// Per-frame instance buffer (StructuredBuffer<InstanceData>, bound at set 3 t0).
	/// Indexed by per-instance DataOffsets.x via the vertex attribute. Each entry =
	/// WorldMatrix + PrevWorldMatrix + InstanceColor = 144 bytes.
	public IBuffer InstanceBuffer;

	/// Per-frame DataOffsets vertex buffer (uint4 per instance, .Instance step rate).
	/// Bound as the second vertex buffer for instanced draws; the GPU vertex-pulling
	/// hardware delivers each instance's DataOffsets to the vertex shader, which
	/// uses .x to index into InstanceBuffer.
	public IBuffer InstanceOffsetsBuffer;

	/// Bind group for the instance data (set 3: t0 = StructuredBuffer<InstanceData>).
	public IBindGroup InstanceBindGroup;

	/// Current write offset into InstanceBuffer (in instances, not bytes).
	public int32 InstanceOffset;

	/// Current write offset into InstanceOffsetsBuffer (in uint4 entries, not bytes).
	public int32 InstanceOffsetsCount;

	/// Deferred bind group destruction list. Old frame bind groups are kept alive
	/// until BeginFrame to avoid invalidating in-flight command buffer references.
	public List<IBindGroup> StaleFrameBindGroups = new .() ~ delete _;

	/// Current write offset into SceneUniformBuffer (reset each frame).
	/// Pipeline.WriteSceneUniforms returns the slot offset before advancing this.
	public uint32 SceneBufferOffset;

	/// The scene UBO offset of the view currently being rendered.
	/// Set by Pipeline.Render before invoking passes; passes pass it to SetBindGroup
	/// as the dynamic offset for the Frame bind group.
	public uint32 CurrentSceneOffset;

	/// Alignment for object uniform entries (256 bytes - Vulkan minUniformBufferOffsetAlignment).
	public const uint32 ObjectAlignment = 256;

	/// Maximum number of objects per frame. Each draw consumes one slot.
	/// A skinned character with N submeshes drawn through depth + forward + 4
	/// shadow cascades uses N×6 slots, so a herd of 256 with 3-submesh
	/// characters exceeds the old 4096 cap and silently drops draws past the
	/// limit (rendering as black/zero-position meshes).
	public const uint32 MaxObjects = 65536;

	/// Maximum instances for batched instanced draws.
	public const int32 MaxInstances = 200000;

	/// Size of one instance entry in the StructuredBuffer (2 matrices + Color = 144 bytes).
	public const int32 InstanceStride = 144;

	/// Size of one DataOffsets entry (uint4 = 16 bytes).
	public const int32 DataOffsetsStride = 16;

	/// Alignment for scene uniform slots. 512 bytes is a comfortable upper bound for
	/// SceneUniforms (~432 bytes) and a multiple of 256 for Vulkan compatibility.
	public const uint32 SceneAlignment = 512;

	/// Maximum number of views per frame (main + shadow casters). Conservative.
	public const uint32 MaxScenes = 32;

	/// Frees GPU resources.
	public void Release(IDevice device)
	{
		// Flush deferred bind group destructions
		for (var bg in StaleFrameBindGroups)
			device.DestroyBindGroup(ref bg);
		StaleFrameBindGroups.Clear();

		device.DestroyBindGroup(ref FrameBindGroup);
		device.DestroyBindGroup(ref DrawCallBindGroup);
		if (InstanceBindGroup != null)
			device.DestroyBindGroup(ref InstanceBindGroup);
		device.DestroyBuffer(ref SceneUniformBuffer);
		device.DestroyBuffer(ref ObjectUniformBuffer);
		if (InstanceBuffer != null)
			device.DestroyBuffer(ref InstanceBuffer);
		if (InstanceOffsetsBuffer != null)
			device.DestroyBuffer(ref InstanceOffsetsBuffer);
	}
}
