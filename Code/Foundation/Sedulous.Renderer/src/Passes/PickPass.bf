namespace Sedulous.Renderer.Passes;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;

/// GPU entity picking pass.
/// Renders each entity with its index encoded as an RGBA8 color,
/// copies the clicked pixel to a staging buffer for CPU readback.
///
/// Usage:
///   1. Call RequestPick(x, y) when the user clicks
///   2. The next frame renders the pick buffer and issues a copy
///   3. Two frames later, TryGetResult() returns the picked entity index
///
/// Added to the pipeline by the editor via Pipeline.AddPass().
/// No-op when no pick is pending.
class PickPass : PipelinePass
{
	// GPU resources (owned)
	private IDevice mDevice;
	private ITexture mPickTexture;
	private ITextureView mPickTextureView;
	private ITexture mPickDepth;
	private ITextureView mPickDepthView;
	private IBuffer mStagingBuffer;

	// Dimensions
	private uint32 mWidth;
	private uint32 mHeight;

	// State machine
	private enum PickState { Idle, PendingRender, WaitingReadback, ResultReady }
	private PickState mState = .Idle;

	// Pick coordinates
	private int32 mPickX;
	private int32 mPickY;

	// Readback timing (wait N frames for GPU to finish before reading staging buffer)
	private int32 mWaitFrames;

	// Result (decoded entity index, uint32.MaxValue = no entity / background)
	private uint32 mPickResult;

	/// Per-draw data written to the object UBO for the pick shader.
	/// Must match pick.vert.hlsl cbuffer ObjectUniforms layout.
	[CRepr]
	private struct PickDrawData
	{
		public Matrix WorldMatrix;
		public Matrix PrevWorldMatrix;
		public uint32 EntityIndex;
	}

	public override StringView Name => "EntityPick";

	/// Request a pick at viewport coordinates.
	/// Result available ~2 frames later via TryGetResult().
	public void RequestPick(int32 x, int32 y)
	{
		mPickX = x;
		mPickY = y;
		mState = .PendingRender;
	}

	/// Returns true if a pick result is ready. Resets state to Idle.
	/// entityIndex is uint32.MaxValue if no entity was hit (background).
	public bool TryGetResult(out uint32 entityIndex)
	{
		if (mState == .ResultReady)
		{
			entityIndex = mPickResult;
			mState = .Idle;
			return true;
		}
		entityIndex = uint32.MaxValue;
		return false;
	}

	/// Whether a pick is in flight.
	public bool IsPicking => mState != .Idle && mState != .ResultReady;

	// ==================== Lifecycle ====================

	public override Result<void> OnInitialize(Pipeline pipeline)
	{
		mDevice = pipeline.RenderContext.Device;

		// Staging buffer for 1-pixel readback (RGBA8 = 4 bytes).
		// 256 bytes minimum for alignment requirements.
		BufferDesc stagingDesc = .()
		{
			Label = "PickStagingBuffer",
			Size = 256,
			Usage = .CopyDst,
			Memory = .GpuToCpu
		};

		if (mDevice.CreateBuffer(stagingDesc) case .Ok(let buf))
			mStagingBuffer = buf;
		else
			return .Err;

		return .Ok;
	}

	public override void OnResize(uint32 width, uint32 height)
	{
		if (width == mWidth && height == mHeight)
			return;

		// Cancel pending picks - texture dimensions changed
		if (mState == .PendingRender || mState == .WaitingReadback)
			mState = .Idle;

		// Destroy old textures
		if (mPickTextureView != null) mDevice.DestroyTextureView(ref mPickTextureView);
		if (mPickTexture != null) mDevice.DestroyTexture(ref mPickTexture);
		if (mPickDepthView != null) mDevice.DestroyTextureView(ref mPickDepthView);
		if (mPickDepth != null) mDevice.DestroyTexture(ref mPickDepth);

		mWidth = width;
		mHeight = height;

		// Pick color texture (RGBA8Unorm for entity ID encoding)
		TextureDesc colorDesc = .()
		{
			Label = "PickColorTarget",
			Width = width,
			Height = height,
			Depth = 1,
			Format = .RGBA8Unorm,
			Usage = .RenderTarget | .CopySrc,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1
		};

		if (mDevice.CreateTexture(colorDesc) case .Ok(let tex))
			mPickTexture = tex;
		if (mPickTexture != null)
		{
			if (mDevice.CreateTextureView(mPickTexture, .() { Format = .RGBA8Unorm }) case .Ok(let view))
				mPickTextureView = view;
		}

		// Pick depth buffer
		TextureDesc depthDesc = .()
		{
			Label = "PickDepthTarget",
			Width = width,
			Height = height,
			Depth = 1,
			Format = .Depth32Float,
			Usage = .DepthStencil,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1
		};

		if (mDevice.CreateTexture(depthDesc) case .Ok(let depthTex))
			mPickDepth = depthTex;
		if (mPickDepth != null)
		{
			if (mDevice.CreateTextureView(mPickDepth, .() { Format = .Depth32Float }) case .Ok(let depthView))
				mPickDepthView = depthView;
		}
	}

	public override void OnShutdown()
	{
		if (mDevice == null) return;
		if (mPickTextureView != null) mDevice.DestroyTextureView(ref mPickTextureView);
		if (mPickTexture != null) mDevice.DestroyTexture(ref mPickTexture);
		if (mPickDepthView != null) mDevice.DestroyTextureView(ref mPickDepthView);
		if (mPickDepth != null) mDevice.DestroyTexture(ref mPickDepth);
		if (mStagingBuffer != null) mDevice.DestroyBuffer(ref mStagingBuffer);
	}

	// ==================== Render Graph Integration ====================

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		// Check for readback completion from a previous pick
		if (mState == .WaitingReadback)
		{
			mWaitFrames--;
			if (mWaitFrames <= 0)
				ReadbackResult();
		}

		// Only render when a pick is pending
		if (mState != .PendingRender)
			return;

		if (mPickTexture == null || mPickTextureView == null ||
			mPickDepth == null || mPickDepthView == null ||
			mStagingBuffer == null)
		{
			mState = .Idle;
			return;
		}

		// Validate coordinates
		if (mPickX < 0 || mPickY < 0 || (uint32)mPickX >= mWidth || (uint32)mPickY >= mHeight)
		{
			mPickResult = uint32.MaxValue;
			mState = .ResultReady;
			return;
		}

		// Import persistent resources into the render graph for this frame
		let pickHandle = graph.ImportTarget("PickTarget", mPickTexture, mPickTextureView);
		let pickDepthHandle = graph.ImportTarget("PickDepth", mPickDepth, mPickDepthView);
		let stagingHandle = graph.ImportBuffer("PickStaging", mStagingBuffer);

		// Render pass: draw all entities with entity ID color
		graph.AddRenderPass("EntityPick", scope (builder) => {
			builder
				.SetColorTarget(0, pickHandle, .Clear, .Store, ClearColor(0.0f, 0.0f, 0.0f, 0.0f))
				.SetDepthTarget(pickDepthHandle, .Clear, .Store, 1.0f)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecutePickRender(encoder, view, pipeline);
				});
		});

		// Copy pass: copy 1 pixel at pick coordinates to staging buffer
		let pickX = (uint32)mPickX;
		let pickY = (uint32)mPickY;

		graph.AddCopyPass("PickReadback", scope (builder) => {
			builder
				.CopySrc(pickHandle)
				.CopyDst(stagingHandle)
				.NeverCull()
				.SetCopyExecute(new [=] (encoder) => {
					BufferTextureCopyRegion region = .()
					{
						BufferOffset = 0,
						BytesPerRow = 4,
						RowsPerImage = 1,
						TextureMipLevel = 0,
						TextureArrayLayer = 0,
						TextureOrigin = .(pickX, pickY, 0),
						TextureExtent = .(1, 1, 1)
					};
					encoder.CopyTextureToBuffer(mPickTexture, mStagingBuffer, region);
				});
		});

		mState = .WaitingReadback;
		mWaitFrames = 2;
	}

	// ==================== Readback ====================

	/// Maps the staging buffer and decodes the entity index from RGBA8 bytes.
	private void ReadbackResult()
	{
		mPickResult = uint32.MaxValue;

		if (mStagingBuffer != null)
		{
			let ptr = mStagingBuffer.Map();
			if (ptr != null)
			{
				let bytes = (uint8*)ptr;
				// Decode RGBA8 → uint32 (pick shader wrote entityIndex + 1)
				uint32 encoded = (uint32)bytes[0] |
					((uint32)bytes[1] << 8) |
					((uint32)bytes[2] << 16) |
					((uint32)bytes[3] << 24);

				// 0 = background (no entity hit), otherwise subtract 1
				if (encoded > 0)
					mPickResult = encoded - 1;

				mStagingBuffer.Unmap();
			}
		}

		mState = .ResultReady;
	}

	// ==================== Pick Rendering ====================

	/// Renders all mesh entities individually with entity ID colors.
	private void ExecutePickRender(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		let renderContext = pipeline.RenderContext;
		let cache = renderContext.PipelineStateCache;
		let gpuResources = renderContext.GPUResources;
		let skinningSystem = renderContext.SkinningSystem;
		if (cache == null || gpuResources == null)
			return;

		encoder.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, mWidth, mHeight);

		// Pick pipeline config: RGBA8 output, depth write, pick shader
		var config = PipelineConfig();
		config.ShaderName = "pick";
		config.BlendMode = .Opaque;
		config.CullMode = .Back;
		config.DepthMode = .ReadWrite;
		config.DepthCompare = .Less;

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let pipelineResult = cache.GetPipeline(config, vertexBuffers, null, .RGBA8Unorm, .Depth32Float);
		if (pipelineResult case .Err)
			return;

		encoder.SetPipeline(pipelineResult.Value);

		let frame = pipeline.GetFrameResources(view.FrameIndex);
		pipeline.BindFrameGroup(encoder, frame);

		// Draw all mesh entities individually (no instancing - each needs unique entity ID)
		RenderDataCategory[3] categories = .(
			RenderCategories.Opaque,
			RenderCategories.Masked,
			RenderCategories.Transparent
		);

		for (let category in categories)
		{
			let batch = view.RenderData?.GetBatch(category);
			if (batch == null) continue;

			for (let entry in batch)
			{
				let mesh = entry as MeshRenderData;
				if (mesh == null) continue;

				let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
				if (gpuMesh == null) continue;

				let subMesh = gpuMesh.SubMeshes[mesh.SubMeshIndex];

				// Write world matrix + entity index to per-draw UBO
				PickDrawData pickData = .()
				{
					WorldMatrix = mesh.WorldMatrix,
					PrevWorldMatrix = mesh.PrevWorldMatrix,
					EntityIndex = mesh.EntityIndex
				};

				let offset = pipeline.WriteDrawCallBytes(view.FrameIndex,
					Span<uint8>((uint8*)&pickData, sizeof(PickDrawData)));
				if (offset == uint32.MaxValue) return;

				uint32[1] dynamicOffsets = .(offset);
				encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, dynamicOffsets);

				// Use compute-skinned vertex buffer if available
				IBuffer vertexBuffer = gpuMesh.VertexBuffer;
				if (mesh.IsSkinned && skinningSystem != null)
				{
					let key = SkinningKey() { MeshHandle = mesh.MeshHandle, EntityId = mesh.MaterialKey };
					let skinnedVB = skinningSystem.GetSkinnedVertexBuffer(key);
					if (skinnedVB != null)
						vertexBuffer = skinnedVB;
					else
						continue;
				}

				encoder.SetVertexBuffer(0, vertexBuffer, 0);

				if (gpuMesh.IndexBuffer != null)
				{
					encoder.SetIndexBuffer(gpuMesh.IndexBuffer, gpuMesh.IndexFormat);
					encoder.DrawIndexed(subMesh.IndexCount, 1, subMesh.IndexStart, subMesh.BaseVertex, 0);
				}
				else
				{
					let vertCount = subMesh.IndexCount > 0 ? subMesh.IndexCount : gpuMesh.VertexCount;
					encoder.Draw(vertCount, 1, 0, 0);
				}
			}
		}
	}
}
