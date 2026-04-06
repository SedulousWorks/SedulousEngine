namespace Sedulous.Renderer;

using System;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;

/// GPU uniform data for per-frame scene constants (bind group set 0).
/// Layout must match scene_uniforms.hlsl.
[CRepr]
public struct SceneUniforms
{
	public Matrix ViewMatrix;
	public Matrix ProjectionMatrix;
	public Matrix ViewProjectionMatrix;
	public Matrix InvViewMatrix;
	public Matrix InvProjectionMatrix;
	public Matrix InvViewProjectionMatrix;
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
	/// Scene uniform buffer (set 0, binding 0).
	public IBuffer SceneUniformBuffer;

	/// Frame-level bind group (set 0).
	public IBindGroup FrameBindGroup;

	/// Object uniform buffer for per-draw transforms (set 3, dynamic offsets).
	public IBuffer ObjectUniformBuffer;

	/// Draw call bind group (set 3) with dynamic offset into ObjectUniformBuffer.
	public IBindGroup DrawCallBindGroup;

	/// Current write offset into ObjectUniformBuffer (reset each frame).
	public uint32 ObjectBufferOffset;

	/// Alignment for object uniform entries (256 bytes — Vulkan minUniformBufferOffsetAlignment).
	public const uint32 ObjectAlignment = 256;

	/// Maximum number of objects per frame.
	public const uint32 MaxObjects = 4096;

	/// Frees GPU resources.
	public void Release(IDevice device)
	{
		device.DestroyBindGroup(ref FrameBindGroup);
		device.DestroyBindGroup(ref DrawCallBindGroup);
		device.DestroyBuffer(ref SceneUniformBuffer);
		device.DestroyBuffer(ref ObjectUniformBuffer);
	}
}
