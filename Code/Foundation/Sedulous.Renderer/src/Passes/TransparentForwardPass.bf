namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Profiler;

/// Transparent forward pass — renders transparent geometry with PBR lighting.
/// Reads SceneDepth (depth test, no write). Alpha blended, back-to-front sorted.
/// Same forward shader as opaque, different pipeline state.
class TransparentForwardPass : PipelinePass
{
	public override StringView Name => "TransparentForward";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null)
			return;

		let batch = data.GetSortedBatch(RenderCategories.Transparent);
		if (batch.Length == 0)
			return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid)
			return;

		let depthHandle = graph.GetResource("SceneDepth");
		let hasDepth = depthHandle.IsValid;

		graph.AddRenderPass("TransparentForward", scope (builder) => {
			builder.SetColorTarget(0, outputHandle, .Load, .Store);

			if (hasDepth)
				builder.SetDepthTarget(depthHandle, .Load, .Store, 1.0f);

			builder
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteTransparent(encoder, view, pipeline, hasDepth);
				});
		});
	}

	private void ExecuteTransparent(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline, bool hasDepth)
	{
		using (Profiler.Begin("TransparentForward"))
		{
		let renderer = pipeline.Renderer;
		let cache = renderer.PipelineStateCache;
		if (cache == null)
			return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		let data = view.RenderData;
		let gpuResources = renderer.GPUResources;
		let frame = pipeline.GetFrameResources(view.FrameIndex);

		// Transparent pipeline: same forward shader, alpha blend, depth read-only
		var config = PipelineConfig();
		config.ShaderName = "forward";
		config.BlendMode = .AlphaBlend;
		config.CullMode = .Back;
		config.ColorTargetCount = 1;

		if (hasDepth)
		{
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

		let batch = data.GetSortedBatch(RenderCategories.Transparent);
		IBindGroup lastMaterialBindGroup = null;

		// Back-to-front sorted by RenderCategories
		for (int32 i = 0; i < (int32)batch.Length; i++)
		{
			let mesh = ref data.GetMesh(RenderCategories.Transparent, i);
			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) continue;

			let subMesh = gpuMesh.SubMeshes[mesh.SubMeshIndex];

			let objOffset = pipeline.WriteObjectUniforms(view.FrameIndex, mesh.WorldMatrix, mesh.PrevWorldMatrix);
			if (objOffset == uint32.MaxValue) continue;

			uint32[1] dynamicOffsets = .(objOffset);
			encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, dynamicOffsets);

			let materialBg = (mesh.MaterialBindGroup != null) ? mesh.MaterialBindGroup : renderer.DefaultMaterialBindGroup;
			if (materialBg != null && materialBg != lastMaterialBindGroup)
			{
				encoder.SetBindGroup(BindGroupFrequency.Material, materialBg, default);
				lastMaterialBindGroup = materialBg;
			}

			encoder.SetVertexBuffer(0, gpuMesh.VertexBuffer, 0);
			if (gpuMesh.IndexBuffer != null)
			{
				encoder.SetIndexBuffer(gpuMesh.IndexBuffer, gpuMesh.IndexFormat);
				encoder.DrawIndexed(subMesh.IndexCount, 1, subMesh.IndexStart, subMesh.BaseVertex, 0);
			}
			else
			{
				encoder.Draw(subMesh.IndexCount, 1, 0, 0);
			}
		}
		} // TransparentForward scope
	}
}
