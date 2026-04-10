namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Profiler;

/// Forward pass — renders opaque and masked geometry with PBR lighting.
/// Reads SceneDepth from DepthPrepass (depth test LessEqual, no depth write).
/// Masked geometry uses the same shader with AlphaCutoff for discard.
class ForwardOpaquePass : PipelinePass
{
	public override StringView Name => "ForwardOpaque";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null)
			return;

		let opaqueBatch = data.GetSortedBatch(RenderCategories.Opaque);
		let maskedBatch = data.GetSortedBatch(RenderCategories.Masked);
		if (opaqueBatch.Length == 0 && maskedBatch.Length == 0)
			return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid)
			return;

		// Read SceneDepth from DepthPrepass
		let depthHandle = graph.GetResource("SceneDepth");
		let hasDepth = depthHandle.IsValid;

		graph.AddRenderPass("ForwardOpaque", scope (builder) => {
			builder.SetColorTarget(0, outputHandle, .Clear, .Store, ClearColor(0.0f, 0.0f, 0.0f, 1.0f));

			if (hasDepth)
				builder.SetDepthTarget(depthHandle, .Load, .Store, 1.0f);

			builder
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteForwardOpaque(encoder, view, pipeline, hasDepth);
				});
		});
	}

	private void ExecuteForwardOpaque(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline, bool hasDepth)
	{
		using (Profiler.Begin("ForwardOpaque"))
		{
		let renderer = pipeline.RenderContext;
		let cache = renderer.PipelineStateCache;
		if (cache == null)
			return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		let data = view.RenderData;
		let gpuResources = renderer.GPUResources;
		let frame = pipeline.GetFrameResources(view.FrameIndex);

		// Build pipeline config
		var config = PipelineConfig();
		config.ShaderName = "forward";
		config.BlendMode = .Opaque;
		config.CullMode = .Back;
		config.ColorTargetCount = 1;

		if (hasDepth)
		{
			// Read from prepass depth — test only, no write
			config.DepthMode = .ReadOnly;
			config.DepthCompare = .LessEqual;
			config.DepthFormat = .Depth24PlusStencil8;
		}
		else
		{
			config.DepthMode = .Disabled;
		}

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let pipelineResult = cache.GetPipeline(config, vertexBuffers, null, pipeline.OutputFormat,
			hasDepth ? .Depth24PlusStencil8 : .Undefined);
		if (pipelineResult case .Err)
			return;

		let rhiPipeline = pipelineResult.Value;

		encoder.SetPipeline(rhiPipeline);

		if (frame.FrameBindGroup != null)
			encoder.SetBindGroup(BindGroupFrequency.Frame, frame.FrameBindGroup, default);

		if (renderer.DefaultMaterialBindGroup != null)
			encoder.SetBindGroup(BindGroupFrequency.Material, renderer.DefaultMaterialBindGroup, default);

		IBindGroup lastMaterialBindGroup = null;

		// Draw opaque geometry, then masked (same shader, same pipeline state)
		DrawBatch(encoder, data, RenderCategories.Opaque, gpuResources, renderer, pipeline, frame, view, ref lastMaterialBindGroup);
		DrawBatch(encoder, data, RenderCategories.Masked, gpuResources, renderer, pipeline, frame, view, ref lastMaterialBindGroup);

		} // ForwardOpaque scope
	}

	private void DrawBatch(IRenderPassEncoder encoder, ExtractedRenderData data, RenderDataCategory category,
		GPUResourceManager gpuResources, RenderContext renderContext, Pipeline pipeline, PerFrameResources frame,
		RenderView view, ref IBindGroup lastMaterialBindGroup)
	{
		let batch = data.GetSortedBatch(category);

		for (int32 i = 0; i < (int32)batch.Length; i++)
		{
			let mesh = ref data.GetMesh(category, i);
			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) continue;

			let subMesh = gpuMesh.SubMeshes[mesh.SubMeshIndex];

			let objOffset = pipeline.WriteObjectUniforms(view.FrameIndex, mesh.WorldMatrix, mesh.PrevWorldMatrix);
			if (objOffset == uint32.MaxValue) continue;

			uint32[1] dynamicOffsets = .(objOffset);
			encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, dynamicOffsets);

			let materialBg = (mesh.MaterialBindGroup != null) ? mesh.MaterialBindGroup : renderContext.DefaultMaterialBindGroup;
			if (materialBg != null && materialBg != lastMaterialBindGroup)
			{
				encoder.SetBindGroup(BindGroupFrequency.Material, materialBg, default);
				lastMaterialBindGroup = materialBg;
			}

			// Use skinned vertex buffer if available (compute skinning output)
			IBuffer vertexBuffer = gpuMesh.VertexBuffer;
			if (mesh.IsSkinned)
			{
				let skinningSystem = renderContext.SkinningSystem;
				if (skinningSystem != null)
				{
					let key = SkinningKey() { MeshHandle = mesh.MeshHandle, EntityId = mesh.MaterialKey };
					let skinnedVB = skinningSystem.GetSkinnedVertexBuffer(key);
					if (skinnedVB != null)
						vertexBuffer = skinnedVB;
				}
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
