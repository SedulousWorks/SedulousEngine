namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Materials;

/// Forward opaque pass — renders opaque geometry.
/// Uses PipelineStateCache to get GPU pipelines on demand from material config.
/// Writes to PipelineOutput.
class ForwardOpaquePass : PipelinePass
{
	public override StringView Name => "ForwardOpaque";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null)
			return;

		let opaqueBatch = data.GetSortedBatch(RenderCategories.Opaque);
		if (opaqueBatch.Length == 0)
			return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid)
			return;

		graph.AddRenderPass("ForwardOpaque", scope (builder) => {
			builder
				.SetColorTarget(0, outputHandle, .Load, .Store)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteForwardOpaque(encoder, view, pipeline);
				});
		});
	}

	private void ExecuteForwardOpaque(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		let cache = pipeline.PipelineStateCache;
		if (cache == null)
			return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		let data = view.RenderData;
		let gpuResources = pipeline.GPUResources;
		let frame = pipeline.GetFrameResources(view.FrameIndex);

		let opaqueBatch = data.GetSortedBatch(RenderCategories.Opaque);
		Sedulous.RHI.IRenderPipeline lastPipeline = null;

		for (let entry in opaqueBatch)
		{
			let mesh = ref data.GetMesh(RenderCategories.Opaque, entry.Index);
			let gpuMesh = gpuResources.GetMesh(mesh.MeshHandle);
			if (gpuMesh == null) continue;

			let subMesh = gpuMesh.SubMeshes[mesh.SubMeshIndex];

			// Build vertex layout from mesh
			VertexAttribute[2] attrs = .(
				.() { Format = .Float3, Offset = 0, ShaderLocation = 0 },
				.() { Format = .Float4, Offset = 12, ShaderLocation = 1 }
			);

			VertexBufferLayout[1] vertexBuffers = .(
				.() { Stride = gpuMesh.VertexStride, StepMode = .Vertex, Attributes = attrs }
			);

			// Get or create pipeline from cache
			var config = PipelineConfig();
			config.ShaderName = "unlit";
			config.BlendMode = .Opaque;
			config.DepthMode = .Disabled;
			config.CullMode = .None;
			config.ColorTargetCount = 1;

			if (cache.GetPipeline(config, vertexBuffers, null, pipeline.OutputFormat) case .Ok(let rhiPipeline))
			{
				if (rhiPipeline != lastPipeline)
				{
					encoder.SetPipeline(rhiPipeline);
					lastPipeline = rhiPipeline;

					// Bind frame bind group (set 0) after pipeline is set
					if (frame.FrameBindGroup != null)
						encoder.SetBindGroup(0, frame.FrameBindGroup, default);
				}
			}
			else
				continue;

			// Bind material (set 2) if available
			if (mesh.MaterialBindGroup != null)
				encoder.SetBindGroup(2, mesh.MaterialBindGroup, default);

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
