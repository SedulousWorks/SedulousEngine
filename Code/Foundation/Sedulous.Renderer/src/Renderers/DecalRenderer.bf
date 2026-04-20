namespace Sedulous.Renderer.Renderers;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Shaders;
using Sedulous.Renderer;

/// Per-decal uniform data written to the per-frame draw-call ring buffer.
/// Layout must match decal.frag/vert.hlsl `DecalUniforms` cbuffer - 160 bytes.
[CRepr]
public struct DecalUniforms
{
	public Matrix World;
	public Matrix InvWorld;
	public Vector4 Color;
	public float AngleFadeStart;
	public float AngleFadeEnd;
	public float _Pad0;
	public float _Pad1;

	public const int32 Size = 160;
}

/// Per-type drawer for DecalRenderData.
///
/// Participates in RenderCategories.Decal. Each decal renders a unit cube
/// (36 verts generated from SV_VertexID) with culling disabled and depth test
/// off. The fragment shader samples SceneDepth to reconstruct world positions
/// and clips fragments outside the decal volume.
///
/// Owns its own 4-set pipeline layout (no shadow set) and pipeline state.
/// Uses the Pipeline's per-frame draw-call ring buffer for per-decal uniforms.
public class DecalRenderer : Renderer
{
	public const int32 MaxFramesInFlight = 2;

	private RenderDataCategory[1] mCategories;
	private IDevice mDevice;
	private RenderContext mRenderContext;

	// Shared decal material template - managed by MaterialSystem.
	private Material mDecalMaterial ~ delete _;
	private IBindGroupLayout mDecalMaterialLayout; // owned by MaterialSystem

	/// Shared decal Material template. Used by the engine layer to create
	/// MaterialInstances per unique decal texture.
	public Material DecalMaterial => mDecalMaterial;

	// Render-pass bind group layout (set 1) holding the scene depth input.
	private IBindGroupLayout mDecalPassLayout;
	private ISampler mDepthSampler;

	// Per-frame-in-flight decal-pass bind groups. Rebuilt each frame with the
	// current SceneDepth view; safe to destroy the old one per slot because
	// the submission that last used slot N has been fence-waited by the time
	// we reach UpdateForFrame(N) again.
	private IBindGroup[MaxFramesInFlight] mDecalPassBindGroups;
	private ITextureView[MaxFramesInFlight] mLastDepthViews;

	// Custom pipeline layout + pipeline state for decals. 4 sets:
	//   0 Frame, 1 DecalPass (depth), 2 Material, 3 DrawCall
	private IPipelineLayout mPipelineLayout;
	private Sedulous.RHI.IRenderPipeline mPipelineState;

	public this()
	{
		mCategories = .(RenderCategories.Decal);
	}

	public ~this()
	{
		if (mDevice != null)
		{
			if (mPipelineState != null) mDevice.DestroyRenderPipeline(ref mPipelineState);
			if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
			for (int i = 0; i < MaxFramesInFlight; i++)
			{
				if (mDecalPassBindGroups[i] != null)
					mDevice.DestroyBindGroup(ref mDecalPassBindGroups[i]);
			}
			if (mDecalPassLayout != null) mDevice.DestroyBindGroupLayout(ref mDecalPassLayout);
			if (mDepthSampler != null) mDevice.DestroySampler(ref mDepthSampler);
		}
	}

	public override Span<RenderDataCategory> GetSupportedCategories()
	{
		return .(&mCategories[0], 1);
	}

	/// Called by DecalPass before dispatching the Decal category. Rebuilds the
	/// per-frame-slot decal-pass bind group with the current SceneDepth view,
	/// skipping the rebuild if the view for this slot hasn't changed.
	public void UpdateForFrame(int32 frameIndex, ITextureView depthView)
	{
		let slot = frameIndex % MaxFramesInFlight;
		if (mDecalPassBindGroups[slot] != null && mLastDepthViews[slot] == depthView)
			return;

		// Old bind group for this slot is safe to destroy: the fence wait on
		// this frame slot has already completed before we got here.
		if (mDecalPassBindGroups[slot] != null)
			mDevice.DestroyBindGroup(ref mDecalPassBindGroups[slot]);

		mLastDepthViews[slot] = depthView;

		if (depthView == null || mDecalPassLayout == null || mDepthSampler == null)
			return;

		BindGroupEntry[2] entries = .(
			BindGroupEntry.Texture(depthView),
			BindGroupEntry.Sampler(mDepthSampler)
		);
		BindGroupDesc desc = .()
		{
			Label = "Decal Pass BindGroup",
			Layout = mDecalPassLayout,
			Entries = entries
		};
		if (mDevice.CreateBindGroup(desc) case .Ok(let bg))
			mDecalPassBindGroups[slot] = bg;
	}

	/// Gets the decal-pass bind group for the given frame slot. Called by
	/// RenderBatch.
	public IBindGroup GetDecalPassBindGroup(int32 frameIndex) => mDecalPassBindGroups[frameIndex % MaxFramesInFlight];

	public override void OnRegistered(RenderContext context)
	{
		mRenderContext = context;
		mDevice = context.Device;

		// --- 1. Decal Material template via MaterialBuilder ---
		mDecalMaterial = scope MaterialBuilder("Decal")
			.Shader("decal")
			.VertexLayout(.None)       // decal shader generates its own verts via SV_VertexID
			.Transparent()
			.Cull(.None)
			.Texture("DecalTexture")
			.Sampler("DecalSampler")
			.Build();

		if (context.MaterialSystem.GetOrCreateLayout(mDecalMaterial) case .Ok(let layout))
			mDecalMaterialLayout = layout;
		else
			return;

		// --- 2. Decal-pass bind group layout (set 1) - depth texture + sampler ---
		BindGroupLayoutEntry[2] passEntries = .(
			.SampledTexture(0, .Fragment, .Texture2D),
			.Sampler(0, .Fragment)
		);
		BindGroupLayoutDesc passLayoutDesc = .()
		{
			Label = "Decal Pass BindGroup Layout",
			Entries = passEntries
		};
		if (mDevice.CreateBindGroupLayout(passLayoutDesc) case .Ok(let passBgl))
			mDecalPassLayout = passBgl;
		else
			return;

		SamplerDesc samplerDesc = .()
		{
			Label = "Decal Depth Sampler",
			MinFilter = .Nearest,
			MagFilter = .Nearest,
			AddressU = .ClampToEdge,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge
		};
		if (mDevice.CreateSampler(samplerDesc) case .Ok(let sampler))
			mDepthSampler = sampler;
		else
			return;

		// --- 3. Custom pipeline layout ---
		// Set 0 Frame, 1 DecalPass, 2 Material, 3 DrawCall - no shadow set needed.
		IBindGroupLayout[4] layouts = .(
			context.FrameBindGroupLayout,
			mDecalPassLayout,
			mDecalMaterialLayout,
			context.DrawCallBindGroupLayout
		);
		PipelineLayoutDesc pipeDesc = .()
		{
			BindGroupLayouts = .(&layouts[0], 4),
			Label = "Decal Pipeline Layout"
		};
		if (mDevice.CreatePipelineLayout(pipeDesc) case .Ok(let pl))
			mPipelineLayout = pl;
		else
			return;

		// --- 4. Pipeline state (decal shader, depth off, cull none, alpha blend) ---
		let shaderResult = context.ShaderSystem?.GetShaderPair("decal", .None);
		if (shaderResult == null || shaderResult.Value case .Err) return;
		let (vertShader, fragShader) = shaderResult.Value.Value;

		ColorTargetState[1] colorTargets = .(.(TextureFormat.RGBA16Float, BlendState.AlphaBlend));

		RenderPipelineDesc rpDesc = .()
		{
			Label = "Decal Pipeline",
			Layout = mPipelineLayout,
			Vertex = .()
			{
				Shader = .(vertShader.Module, "main"),
				Buffers = .()  // no vertex buffer - SV_VertexID generates positions
			},
			Fragment = .()
			{
				Shader = .(fragShader.Module, "main"),
				Targets = .(&colorTargets[0], 1)
			},
			Primitive = .()
			{
				Topology = .TriangleList,
				FrontFace = .CCW,
				// Cull the near face (front-facing) of the cube, keeping the far
				// (back-facing) face. This gives 1 fragment per on-screen pixel of
				// the cube projection AND correctly handles the camera-inside-box
				// case: when the camera is inside, the "near" face is actually
				// behind the camera so the back face is what's visible.
				CullMode = .Front
			},
			DepthStencil = null, // depth disabled
			Multisample = .() { Count = 1, Mask = uint32.MaxValue }
		};

		if (mDevice.CreateRenderPipeline(rpDesc) case .Ok(let pso))
			mPipelineState = pso;
	}

	public override void RenderBatch(
		IRenderPassEncoder encoder,
		List<RenderData> batch,
		RenderContext renderContext,
		IRenderingPipeline pipeline,
		PerFrameResources frame,
		RenderView view,
		RenderBatchFlags flags,
		PipelineConfig passConfig)
	{
		if (batch == null || batch.Count == 0) return;
		if (mPipelineState == null) return;

		let passBindGroup = GetDecalPassBindGroup(view.FrameIndex);
		if (passBindGroup == null) return;

		let mainPipeline = pipeline as Pipeline;
		if (mainPipeline == null) return;

		encoder.SetPipeline(mPipelineState);
		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		mainPipeline.BindFrameGroup(encoder, frame);

		// Set 1 - decal pass bind group (scene depth)
		encoder.SetBindGroup(BindGroupFrequency.RenderPass, passBindGroup, default);

		IBindGroup lastMaterial = null;

		for (let entry in batch)
		{
			let decal = entry as DecalRenderData;
			if (decal == null) continue;
			if (decal.MaterialBindGroup == null) continue;

			// Per-decal uniforms -> ring buffer slot.
			DecalUniforms uniforms = .()
			{
				World = decal.WorldMatrix,
				InvWorld = decal.InvWorldMatrix,
				Color = decal.Color,
				AngleFadeStart = decal.AngleFadeStart,
				AngleFadeEnd = decal.AngleFadeEnd
			};
			let offset = mainPipeline.WriteDrawCallBytes(view.FrameIndex,
				Span<uint8>((uint8*)&uniforms, DecalUniforms.Size));
			if (offset == uint32.MaxValue) continue;

			uint32[1] dynamicOffsets = .(offset);
			encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, dynamicOffsets);

			if (decal.MaterialBindGroup != lastMaterial)
			{
				encoder.SetBindGroup(BindGroupFrequency.Material, decal.MaterialBindGroup, default);
				lastMaterial = decal.MaterialBindGroup;
			}

			encoder.Draw(36, 1, 0, 0);
		}
	}
}
