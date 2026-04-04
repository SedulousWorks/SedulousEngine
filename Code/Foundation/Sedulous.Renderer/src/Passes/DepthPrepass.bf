namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;

/// Depth prepass — renders opaque geometry to the depth buffer only.
/// Establishes early-Z for subsequent passes to minimize overdraw.
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
		let maskedBatch = data.GetSortedBatch(RenderCategories.Masked);
		if (opaqueBatch.Length == 0 && maskedBatch.Length == 0)
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
				.NeverCull();

			builder.SetExecute(new [=] (encoder) => {
				ExecuteDepthPrepass(encoder, view, pipeline);
			});
		});
	}

	private void ExecuteDepthPrepass(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		let data = view.RenderData;
		let gpuResources = pipeline.GPUResources;
		let frame = pipeline.GetFrameResources(view.FrameIndex);

		// Bind frame bind group (set 0)
		if (frame.FrameBindGroup != null)
			encoder.SetBindGroup(0, frame.FrameBindGroup, default);

		// TODO: set depth-only pipeline (needs shader compilation)
		// For now, just the structure — actual drawing requires a pipeline state object

		// Draw opaque geometry (depth only, no color output)
		let opaqueBatch = data.GetSortedBatch(RenderCategories.Opaque);
		for (let entry in opaqueBatch)
		{
			let mesh = ref data.GetMesh(RenderCategories.Opaque, entry.Index);
			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) continue;

			let subMesh = gpuMesh.SubMeshes[mesh.SubMeshIndex];

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
