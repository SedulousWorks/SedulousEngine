namespace Sedulous.Particles;

using System;
using Sedulous.RHI;
using Sedulous.Materials;
using Sedulous.Renderer;

/// RenderContext-owned GPU resources for the particle system.
///
/// Owns the shared particle Material template, caches its bind group layout,
/// and manages per-frame instance vertex buffers for CPU-simulated particles.
/// Mirrors SpriteSystem — one ParticleGPUResources per RenderContext.
public class ParticleGPUResources : IDisposable
{
	public const int32 MaxFramesInFlight = 2;
	public const uint32 MaxInstancesPerFrame = 32768;

	private IDevice mDevice;

	/// Shared particle material template. Engine layer creates MaterialInstances
	/// from this for each unique particle texture.
	private Material mParticleMaterial ~ delete _;

	/// Bind group layout for particle material instances.
	private IBindGroupLayout mParticleMaterialLayout;

	/// Per-frame instance vertex buffers (CpuToGpu for direct CPU writes).
	private IBuffer[MaxFramesInFlight] mInstanceBuffers;

	/// Per-frame trail vertex buffers.
	private IBuffer[MaxFramesInFlight] mTrailBuffers;
	public const uint32 MaxTrailVerticesPerFrame = 65536;

	/// Default MaterialInstance with white texture — used when no texture is set.
	private MaterialInstance mDefaultMaterialInstance ~ _?.ReleaseRef();

	/// The shared particle material template.
	public Material ParticleMaterial => mParticleMaterial;

	/// Bind group layout for particle material instances (texture + sampler).
	public IBindGroupLayout ParticleMaterialLayout => mParticleMaterialLayout;

	/// Default material bind group (white texture + default sampler).
	/// Used by ParticleRenderer when no material is assigned to a particle component.
	public IBindGroup DefaultBindGroup => mDefaultMaterialInstance?.BindGroup;

	/// Gets the instance buffer for the given frame index.
	public IBuffer GetInstanceBuffer(int32 frameIndex) => mInstanceBuffers[frameIndex % MaxFramesInFlight];

	/// Gets the trail vertex buffer for the given frame index.
	public IBuffer GetTrailBuffer(int32 frameIndex) => mTrailBuffers[frameIndex % MaxFramesInFlight];

	public Result<void> Initialize(IDevice device, MaterialSystem materialSystem)
	{
		mDevice = device;

		// --- Particle material template ---
		// VertexLayout is .Custom — ParticleRenderer supplies a per-instance layout
		// at pipeline-creation time. Blend mode defaults to Additive (most particles).
		mParticleMaterial = scope MaterialBuilder("Particle")
			.Shader("particle")
			.VertexLayout(.Custom)
			.Transparent()   // AlphaBlend + DepthReadOnly
			.Cull(.None)
			.Texture("ParticleTexture")
			.Sampler("ParticleSampler")
			.Build();

		// Pre-build the bind group layout so ParticleRenderer can reference it
		// when creating the pipeline state.
		if (materialSystem.GetOrCreateLayout(mParticleMaterial) case .Ok(let layout))
			mParticleMaterialLayout = layout;
		else
			return .Err;

		// --- Default material instance (white texture fallback) ---
		mDefaultMaterialInstance = new MaterialInstance(mParticleMaterial);
		mDefaultMaterialInstance.SetTexture("ParticleTexture", materialSystem.WhiteTexture);
		mDefaultMaterialInstance.SetSampler("ParticleSampler", materialSystem.DefaultSampler);
		materialSystem.PrepareInstance(mDefaultMaterialInstance);

		// --- Per-frame instance vertex buffers ---
		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			BufferDesc desc = .()
			{
				Label = "Particle Instances",
				Size = (uint64)(MaxInstancesPerFrame * ParticleVertex.SizeInBytes),
				Usage = .Vertex,
				Memory = .CpuToGpu
			};
			if (device.CreateBuffer(desc) case .Ok(let buf))
				mInstanceBuffers[i] = buf;
			else
				return .Err;
		}

		// --- Per-frame trail vertex buffers ---
		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			BufferDesc desc = .()
			{
				Label = "Particle Trails",
				Size = (uint64)(MaxTrailVerticesPerFrame * TrailVertex.SizeInBytes),
				Usage = .Vertex,
				Memory = .CpuToGpu
			};
			if (device.CreateBuffer(desc) case .Ok(let buf))
				mTrailBuffers[i] = buf;
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
			if (mTrailBuffers[i] != null)
				mDevice.DestroyBuffer(ref mTrailBuffers[i]);
		}
		// mParticleMaterialLayout is owned by MaterialSystem, do not destroy here.
	}
}
