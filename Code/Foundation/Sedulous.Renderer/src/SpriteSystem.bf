namespace Sedulous.Renderer;

using System;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;

/// Per-instance data uploaded to the GPU for one sprite draw.
/// Matches the vertex input layout in sprite.vert.hlsl exactly.
/// Instance stride = 64 bytes.
[CRepr]
public struct SpriteInstance
{
	/// (world.x, world.y, world.z, size.x)
	public Vector4 PositionSize;

	/// (size.y, orientation_mode, reserved, reserved)
	public Vector4 SizeOrientation;

	/// (r, g, b, a) tint
	public Vector4 Tint;

	/// (u, v, uv_w, uv_h) sub-rectangle within the texture
	public Vector4 UVRect;

	public const int32 SizeInBytes = 64;
}

/// RenderContext-owned GPU resources for the sprite system.
///
/// Owns the shared sprite Material template, caches its bind group layout
/// (so SpriteRenderer can build a pipeline state), and owns per-frame
/// instance vertex buffers. The engine layer creates a MaterialInstance per
/// unique sprite texture from this template and goes through MaterialSystem
/// for bind group preparation.
public class SpriteSystem : IDisposable
{
	public const int32 MaxFramesInFlight = 2;
	public const uint32 MaxInstancesPerFrame = 16384;

	private IDevice mDevice;

	// Shared sprite Material template. Engine layer creates MaterialInstances
	// from this for each unique sprite texture.
	private Material mSpriteMaterial ~ delete _;

	// Bind group layout for the sprite material (resolved via MaterialSystem).
	private IBindGroupLayout mSpriteMaterialLayout;

	private IBuffer[MaxFramesInFlight] mInstanceBuffers;

	public Material SpriteMaterial => mSpriteMaterial;

	/// Bind group layout for sprite material instances (t0 texture + s0 sampler).
	/// Obtained from MaterialSystem so sprites share the layout-cache with any
	/// other material that happens to have the same property shape.
	public IBindGroupLayout SpriteMaterialLayout => mSpriteMaterialLayout;

	public IBuffer GetInstanceBuffer(int32 frameIndex) => mInstanceBuffers[frameIndex % MaxFramesInFlight];

	public Result<void> Initialize(IDevice device, MaterialSystem materialSystem)
	{
		mDevice = device;

		// --- Sprite material template ---
		// VertexLayout is .Custom — SpriteRenderer supplies a per-instance layout
		// at pipeline-creation time. The material config drives blend/cull/depth.
		mSpriteMaterial = scope MaterialBuilder("Sprite")
			.Shader("sprite")
			.VertexLayout(.Custom)
			.Transparent()
			.Cull(.None)
			.Texture("SpriteTexture")
			.Sampler("SpriteSampler")
			.Build();

		// Pre-build the bind group layout for the sprite material so SpriteRenderer
		// can reference it when creating the pipeline state (before any sprite
		// instance has been prepared).
		if (materialSystem.GetOrCreateLayout(mSpriteMaterial) case .Ok(let layout))
			mSpriteMaterialLayout = layout;
		else
			return .Err;

		// --- Per-frame instance vertex buffers ---
		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			BufferDesc desc = .()
			{
				Label = "Sprite Instances",
				Size = (uint64)(MaxInstancesPerFrame * SpriteInstance.SizeInBytes),
				Usage = .Vertex,
				Memory = .CpuToGpu
			};
			if (device.CreateBuffer(desc) case .Ok(let buf))
				mInstanceBuffers[i] = buf;
			else
				return .Err;
		}

		return .Ok;
	}

	public void Dispose()
	{
		if (mDevice == null) return;
		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			if (mInstanceBuffers[i] != null)
				mDevice.DestroyBuffer(ref mInstanceBuffers[i]);
		}
		// mSpriteMaterialLayout is owned by MaterialSystem, do not destroy here.
	}
}
