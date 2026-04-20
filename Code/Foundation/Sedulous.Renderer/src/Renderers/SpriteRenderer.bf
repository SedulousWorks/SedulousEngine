namespace Sedulous.Renderer.Renderers;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Renderer;

/// Per-type drawer for SpriteRenderData.
///
/// Participates in the Transparent category. Iterates the sorted batch,
/// groups consecutive sprites that share a material bind group, packs their
/// data into the SpriteSystem's per-frame instance buffer, and issues one
/// DrawInstanced(6, groupSize) per group.
///
/// The vertex shader uses SV_VertexID (0..5) to build a unit quad in the
/// sprite's local plane and combines it with per-instance attributes.
public class SpriteRenderer : Renderer
{
	private RenderDataCategory[1] mCategories;
	private List<SpriteInstance> mScratch = new .() ~ delete _;

	public this()
	{
		mCategories = .(RenderCategories.Transparent);
	}

	public override Span<RenderDataCategory> GetSupportedCategories()
	{
		return .(&mCategories[0], 1);
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

		let spriteSystem = renderContext.SpriteSystem;
		let cache = renderContext.PipelineStateCache;
		if (spriteSystem == null || cache == null) return;
		if (spriteSystem.SpriteMaterialLayout == null) return;

		// Only the main Pipeline draws sprites (ShadowPipeline skips Transparent),
		// so the cast is safe for fetching output format + frame bind group.
		let mainPipeline = pipeline as Pipeline;
		if (mainPipeline == null) return;

		// 1. Build instance data for ALL sprites first (single upload), remembering
		//    material-change boundaries so we can emit one Draw per run.
		mScratch.Clear();

		// (runStart, runCount, runBindGroup) tuples - kept in parallel arrays.
		let runs = scope List<(int32 start, int32 count, IBindGroup bg)>();
		int32 curStart = 0;
		int32 curCount = 0;
		IBindGroup curBG = null;

		for (let entry in batch)
		{
			let sprite = entry as SpriteRenderData;
			if (sprite == null) continue;

			if (sprite.MaterialBindGroup != curBG)
			{
				if (curCount > 0)
					runs.Add((curStart, curCount, curBG));
				curStart = (int32)mScratch.Count;
				curCount = 0;
				curBG = sprite.MaterialBindGroup;
			}

			mScratch.Add(.()
			{
				PositionSize = .(sprite.Position.X, sprite.Position.Y, sprite.Position.Z, sprite.Size.X),
				SizeOrientation = .(sprite.Size.Y, (float)(int32)sprite.Orientation, 0, 0),
				Tint = sprite.Tint,
				UVRect = sprite.UVRect
			});
			curCount++;
		}
		if (curCount > 0)
			runs.Add((curStart, curCount, curBG));
		if (runs.Count == 0) return;

		// 2. Upload all instance data in one go.
		let instanceBuffer = spriteSystem.GetInstanceBuffer(view.FrameIndex);
		let totalBytes = (int)(mScratch.Count * SpriteInstance.SizeInBytes);
		TransferHelper.WriteMappedBuffer(instanceBuffer, 0,
			Span<uint8>((uint8*)mScratch.Ptr, totalBytes));

		// 3. Get the sprite pipeline state (cached).
		VertexAttribute[4] attrs = .(
			.(.Float32x4, 0,  0),
			.(.Float32x4, 16, 1),
			.(.Float32x4, 32, 2),
			.(.Float32x4, 48, 3)
		);
		VertexBufferLayout instanceLayout = .((uint32)SpriteInstance.SizeInBytes, .(&attrs[0], 4), .Instance);
		VertexBufferLayout[1] vertexBuffers = .(instanceLayout);

		var config = spriteSystem.SpriteMaterial.PipelineConfig;
		config.ShaderName = "sprite";
		config.ColorTargetCount = 1;
		config.Topology = .TriangleList;
		config.DepthFormat = .Depth24PlusStencil8; // matches main forward prepass

		let pipelineResult = cache.GetPipeline(config, vertexBuffers,
			spriteSystem.SpriteMaterialLayout,
			mainPipeline.OutputFormat,
			.Depth24PlusStencil8);
		if (pipelineResult case .Err)
			return;

		encoder.SetPipeline(pipelineResult.Value);
		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		mainPipeline.BindFrameGroup(encoder, frame);

		// DrawCall bind group (object uniforms) - sprites don't use object uniforms
		// but the pipeline layout expects the set to be bound. Default offset 0.
		if (frame.DrawCallBindGroup != null)
		{
			uint32[1] zeroOffset = .(0);
			encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, zeroOffset);
		}

		// 4. One DrawInstanced per material run, with a vertex-buffer offset to
		// the run's starting instance.
		for (let run in runs)
		{
			let mat = (run.bg != null) ? run.bg : renderContext.DefaultMaterialBindGroup;
			if (mat != null)
				encoder.SetBindGroup(BindGroupFrequency.Material, mat, default);

			let offsetBytes = (uint64)(run.start * SpriteInstance.SizeInBytes);
			encoder.SetVertexBuffer(0, instanceBuffer, offsetBytes);
			encoder.Draw(6, (uint32)run.count, 0, 0);
		}
	}
}
