namespace Sedulous.Particles;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Materials;
using Sedulous.Renderer;
using Sedulous.Shaders;

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

	/// Depth pass bind group layout (set 1) for soft particles.
	private IBindGroupLayout mDepthPassLayout;
	private ISampler mDepthSampler;

	/// Per-frame depth bind groups (rebuilt when depth view changes).
	private IBindGroup[MaxFramesInFlight] mDepthPassBindGroups;
	private ITextureView[MaxFramesInFlight] mLastDepthViews;

	/// Custom pipeline layout: Set 0 Frame, 1 DepthPass, 2 Material, 3 DrawCall.
	private IPipelineLayout mPipelineLayout;

	/// Cached render pipelines keyed by (shaderName + blendMode).
	private Dictionary<int, IRenderPipeline> mPipelineCache = new .() ~ delete _;

	/// Shader system reference for loading shaders.
	private ShaderSystem mShaderSystem;

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

	/// Depth pass bind group layout (for custom pipeline layout with depth at set 1).
	public IBindGroupLayout DepthPassLayout => mDepthPassLayout;

	/// Gets the depth pass bind group for the given frame.
	public IBindGroup GetDepthPassBindGroup(int32 frameIndex) => mDepthPassBindGroups[frameIndex % MaxFramesInFlight];

	/// Updates the depth bind group for the current frame with the scene depth view.
	/// Call before rendering particles. Skips rebuild if the view hasn't changed.
	public void UpdateDepthForFrame(int32 frameIndex, ITextureView depthView)
	{
		let slot = frameIndex % MaxFramesInFlight;
		if (mDepthPassBindGroups[slot] != null && mLastDepthViews[slot] == depthView)
			return;

		if (mDepthPassBindGroups[slot] != null)
			mDevice.DestroyBindGroup(ref mDepthPassBindGroups[slot]);

		mLastDepthViews[slot] = depthView;

		if (depthView == null || mDepthPassLayout == null || mDepthSampler == null)
			return;

		BindGroupEntry[2] entries = .(
			BindGroupEntry.Texture(depthView),
			BindGroupEntry.Sampler(mDepthSampler)
		);
		BindGroupDesc desc = .()
		{
			Label = "Particle Depth BindGroup",
			Layout = mDepthPassLayout,
			Entries = entries
		};
		if (mDevice.CreateBindGroup(desc) case .Ok(let bg))
			mDepthPassBindGroups[slot] = bg;
	}

	/// Custom pipeline layout for particle rendering (Frame + Depth + Material + DrawCall).
	public IPipelineLayout PipelineLayout => mPipelineLayout;

	/// Gets or creates a render pipeline for particles with the custom layout.
	/// Caches by shader name + blend mode combination.
	public Result<IRenderPipeline> GetOrCreatePipeline(
		StringView shaderName,
		BlendMode blendMode,
		Span<VertexBufferLayout> vertexBuffers,
		TextureFormat colorFormat,
		TextureFormat depthFormat)
	{
		// Simple hash key from shader name + blend mode
		int key = shaderName.GetHashCode() * 31 + (int)blendMode;
		key = key * 31 + (int)colorFormat;

		if (mPipelineCache.TryGetValue(key, let cached))
			return .Ok(cached);

		if (mPipelineLayout == null || mShaderSystem == null)
			return .Err;

		// Load shaders
		let vertResult = mShaderSystem.GetShader(shaderName, .Vertex, .None);
		if (vertResult case .Err) return .Err;
		let fragResult = mShaderSystem.GetShader(shaderName, .Fragment, .None);
		if (fragResult case .Err) return .Err;

		let vertShader = vertResult.Value;
		let fragShader = fragResult.Value;

		// Blend state
		BlendState blend;
		switch (blendMode)
		{
		case .Additive: blend = .Additive;
		case .AlphaBlend: blend = .AlphaBlend;
		case .PremultipliedAlpha: blend = .PremultipliedAlpha;
		default: blend = .AlphaBlend;
		}

		ColorTargetState[1] colorTargets = .(.(colorFormat, blend));

		RenderPipelineDesc rpDesc = .()
		{
			Label = "Particle Pipeline",
			Layout = mPipelineLayout,
			Vertex = .()
			{
				Shader = .(vertShader.Module, "main"),
				Buffers = vertexBuffers
			},
			Fragment = .()
			{
				Shader = .(fragShader.Module, "main"),
				Targets = .(&colorTargets[0], 1)
			},
			Primitive = .()
			{
				Topology = .TriangleList,
				CullMode = .None
			},
			DepthStencil = .()
			{
				Format = depthFormat,
				DepthWriteEnabled = false,
				DepthCompare = .LessEqual
			},
			Multisample = .() { Count = 1 }
		};

		if (mDevice.CreateRenderPipeline(rpDesc) case .Ok(let pipeline))
		{
			mPipelineCache[key] = pipeline;
			return .Ok(pipeline);
		}

		return .Err;
	}

	public Result<void> Initialize(IDevice device, MaterialSystem materialSystem, RenderContext renderContext = null)
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

		// --- Depth pass layout + sampler (set 1, for soft particles) ---
		BindGroupLayoutEntry[2] depthEntries = .(
			.SampledTexture(0, .Fragment, .Texture2D),
			.Sampler(0, .Fragment)
		);
		BindGroupLayoutDesc depthLayoutDesc = .()
		{
			Label = "Particle Depth Layout",
			Entries = depthEntries
		};
		if (device.CreateBindGroupLayout(depthLayoutDesc) case .Ok(let depthLayout))
			mDepthPassLayout = depthLayout;
		else
			return .Err;

		SamplerDesc depthSamplerDesc = .()
		{
			Label = "Particle Depth Sampler",
			MagFilter = .Nearest,
			MinFilter = .Nearest,
			AddressU = .ClampToEdge,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge
		};
		if (device.CreateSampler(depthSamplerDesc) case .Ok(let sampler))
			mDepthSampler = sampler;
		else
			return .Err;

		// Store shader system for lazy pipeline creation
		if (renderContext != null)
			mShaderSystem = renderContext.ShaderSystem;

		// --- Custom pipeline layout: Frame(0), DepthPass(1), Material(2), DrawCall(3) ---
		if (renderContext != null)
		{
			IBindGroupLayout[4] layouts = .(
				renderContext.FrameBindGroupLayout,
				mDepthPassLayout,
				mParticleMaterialLayout,
				renderContext.DrawCallBindGroupLayout
			);
			PipelineLayoutDesc pipeLayoutDesc = .()
			{
				BindGroupLayouts = .(&layouts[0], 4),
				Label = "Particle Pipeline Layout"
			};
			if (device.CreatePipelineLayout(pipeLayoutDesc) case .Ok(let pl))
				mPipelineLayout = pl;
			else
				return .Err;
		}

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
			if (mDepthPassBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mDepthPassBindGroups[i]);
		}
		for (let kv in mPipelineCache)
		{
			var pipeline = kv.value;
			mDevice.DestroyRenderPipeline(ref pipeline);
		}
		mPipelineCache.Clear();

		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mDepthPassLayout != null)
			mDevice.DestroyBindGroupLayout(ref mDepthPassLayout);
		if (mDepthSampler != null)
			mDevice.DestroySampler(ref mDepthSampler);
		// mParticleMaterialLayout is owned by MaterialSystem, do not destroy here.
	}
}
