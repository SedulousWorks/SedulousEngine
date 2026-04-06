namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Materials;

/// Depth prepass — renders opaque geometry to the depth buffer only.
/// Establishes early-Z for the forward pass to minimize overdraw.
/// Creates the SceneDepth transient resource.
class DepthPrepass : PipelinePass
{
	public override StringView Name => "DepthPrepass";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null)
			return;

		let opaqueBatch = data.GetSortedBatch(RenderCategories.Opaque);
		if (opaqueBatch.Length == 0)
			return;

		// Create SceneDepth as a transient depth texture
		let depthDesc = RGTextureDesc(.Depth24PlusStencil8)
		{
			Usage = .DepthStencil | .Sampled
		};
		let depthHandle = graph.CreateTransient("SceneDepth", depthDesc);

		graph.AddRenderPass("DepthPrepass", scope (builder) => {
			builder
				.SetDepthTarget(depthHandle, .Clear, .Store, 1.0f)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteDepthPrepass(encoder, view, pipeline);
				});
		});
	}

	private void ExecuteDepthPrepass(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		let cache = pipeline.PipelineStateCache;
		if (cache == null)
			return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		// Depth-only pipeline config: no color output, write depth
		var config = PipelineConfig();
		config.ShaderName = "depth_only";
		config.DepthMode = .ReadWrite;
		config.DepthCompare = .Less;
		config.DepthFormat = .Depth24PlusStencil8;
		config.CullMode = .Back;
		config.ColorTargetCount = 0;
		config.DepthOnly = true;

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let pipelineResult = cache.GetPipeline(config, vertexBuffers, null, .Undefined, .Depth24PlusStencil8);
		if (pipelineResult case .Err)
			return;

		let rhiPipeline = pipelineResult.Value;

		encoder.SetPipeline(rhiPipeline);

		let frame = pipeline.GetFrameResources(view.FrameIndex);
		if (frame.FrameBindGroup != null)
			encoder.SetBindGroup(BindGroupFrequency.Frame, frame.FrameBindGroup, default);

		let data = view.RenderData;
		let gpuResources = pipeline.GPUResources;
		let opaqueBatch = data.GetSortedBatch(RenderCategories.Opaque);

		for (int32 i = 0; i < (int32)opaqueBatch.Length; i++)
		{
			let mesh = ref data.GetMesh(RenderCategories.Opaque, i);
			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) continue;

			let subMesh = gpuMesh.SubMeshes[mesh.SubMeshIndex];

			// Upload object transform and bind with dynamic offset
			let objOffset = pipeline.WriteObjectUniforms(view.FrameIndex, mesh.WorldMatrix, mesh.PrevWorldMatrix);
			if (objOffset == uint32.MaxValue) continue;

			uint32[1] dynamicOffsets = .(objOffset);
			encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, dynamicOffsets);

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
	}
}
