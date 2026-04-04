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

	/// Frees GPU resources.
	public void Release(IDevice device)
	{
		device.DestroyBindGroup(ref FrameBindGroup);
		device.DestroyBuffer(ref SceneUniformBuffer);
		device.DestroyBuffer(ref ObjectUniformBuffer);
	}
}
