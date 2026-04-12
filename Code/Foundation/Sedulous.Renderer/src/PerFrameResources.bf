namespace Sedulous.Renderer;

using System;
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

	/// Current write offset into SceneUniformBuffer (reset each frame).
	/// Pipeline.WriteSceneUniforms returns the slot offset before advancing this.
	public uint32 SceneBufferOffset;

	/// The scene UBO offset of the view currently being rendered.
	/// Set by Pipeline.Render before invoking passes; passes pass it to SetBindGroup
	/// as the dynamic offset for the Frame bind group.
	public uint32 CurrentSceneOffset;

	/// Alignment for object uniform entries (256 bytes — Vulkan minUniformBufferOffsetAlignment).
	public const uint32 ObjectAlignment = 256;

	/// Maximum number of objects per frame.
	public const uint32 MaxObjects = 4096;

	/// Alignment for scene uniform slots. 512 bytes is a comfortable upper bound for
	/// SceneUniforms (~432 bytes) and a multiple of 256 for Vulkan compatibility.
	public const uint32 SceneAlignment = 512;

	/// Maximum number of views per frame (main + shadow casters). Conservative.
	public const uint32 MaxScenes = 32;

	/// Frees GPU resources.
	public void Release(IDevice device)
	{
		device.DestroyBindGroup(ref FrameBindGroup);
		device.DestroyBindGroup(ref DrawCallBindGroup);
		device.DestroyBuffer(ref SceneUniformBuffer);
		device.DestroyBuffer(ref ObjectUniformBuffer);
	}
}
