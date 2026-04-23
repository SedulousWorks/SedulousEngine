namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Renderer.Debug;
using Sedulous.DebugFont;
using Sedulous.Profiler;
using Sedulous.Materials;

/// Debug line drawing - uploads accumulated line vertices from
/// RenderContext.DebugDraw and renders them with depth test (occluded lines
/// still draw but behind opaque geometry). Runs after the main forward passes
/// and before post-processing so the lines compose into the HDR scene color.
class DebugPass : PipelinePass
{
	public override StringView Name => "DebugLines";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let debugDraw = pipeline.RenderContext.DebugDraw;
		if (debugDraw == null || (debugDraw.LineVertexCount == 0 && debugDraw.OverlayLineVertexCount == 0))
			return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid)
			return;

		let depthHandle = graph.GetResource("SceneDepth");
		let hasDepth = depthHandle.IsValid;

		graph.AddRenderPass("DebugLines", scope (builder) => {
			builder.SetColorTarget(0, outputHandle, .Load, .Store);
			if (hasDepth)
				builder.SetDepthTarget(depthHandle, .Load, .Store, 1.0f);
			builder
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					Execute(encoder, view, pipeline, hasDepth);
				});
		});
	}

	private void Execute(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline, bool hasDepth)
	{
		using (Profiler.Begin("DebugLines"))
		{
		let renderContext = pipeline.RenderContext;
		let debugDraw = renderContext.DebugDraw;
		let debugSystem = renderContext.DebugDrawSystem;
		let cache = renderContext.PipelineStateCache;
		if (cache == null || debugSystem == null) return;

		// Upload both depth-tested and overlay line vertices into the same buffer
		// at different offsets (like the old renderer) to avoid overwriting in-flight data.
		let depthCount = debugDraw.LineVertexCount;
		let overlayCount = debugDraw.OverlayLineVertexCount;
		let totalCount = depthCount + overlayCount;
		if (totalCount == 0) return;

		let maxVerts = DebugDrawSystem.MaxLineVertices;
		let depthClamped = Math.Min((uint32)depthCount, maxVerts);
		let overlayMax = maxVerts - depthClamped;
		let overlayClamped = Math.Min((uint32)overlayCount, overlayMax);

		let vb = debugSystem.GetLineVertexBuffer(view.FrameIndex);

		// Upload depth-tested lines at offset 0, overlay lines immediately after
		if (depthClamped > 0)
			TransferHelper.WriteMappedBuffer(vb, 0,
				Span<uint8>((uint8*)debugDraw.LineVertices.Ptr, (int)(depthClamped * DebugVertex.SizeInBytes)));
		if (overlayClamped > 0)
			TransferHelper.WriteMappedBuffer(vb, (uint64)(depthClamped * DebugVertex.SizeInBytes),
				Span<uint8>((uint8*)debugDraw.OverlayLineVertices.Ptr, (int)(overlayClamped * DebugVertex.SizeInBytes)));

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		// Pipeline state - line list, depth test, no cull, alpha blend.
		var config = PipelineConfig();
		config.ShaderName = "debug_line";
		config.BlendMode = .AlphaBlend;
		config.CullMode = .None;
		config.ColorTargetCount = 1;
		config.Topology = .LineList;
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

		// Vertex layout for DebugVertex.
		VertexAttribute[2] attrs = .(
			.(.Float32x3, 0, 0),      // Position
			.(.Unorm8x4, 12, 1)        // Color (packed RGBA8)
		);
		VertexBufferLayout vertexLayout = .((uint32)DebugVertex.SizeInBytes, .(&attrs[0], 2));
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let frame = pipeline.GetFrameResources(view.FrameIndex);

		encoder.SetVertexBuffer(0, vb, 0);

		// Depth-tested lines
		if (depthClamped > 0)
		{
			let pipelineResult = cache.GetPipeline(config, vertexBuffers, null, pipeline.OutputFormat,
				hasDepth ? .Depth24PlusStencil8 : .Undefined);
			if (pipelineResult case .Ok(let depthPipeline))
			{
				encoder.SetPipeline(depthPipeline);
				pipeline.BindFrameGroup(encoder, frame);
				if (renderContext.DefaultMaterialBindGroup != null)
					encoder.SetBindGroup(BindGroupFrequency.Material, renderContext.DefaultMaterialBindGroup, default);
				if (frame.DrawCallBindGroup != null)
				{
					uint32[1] zeroOffset = .(0);
					encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, zeroOffset);
				}
				encoder.Draw(depthClamped, 1, 0, 0);
			}
		}

		// Overlay lines (no depth test)
		if (overlayClamped > 0)
		{
			var overlayConfig = config;
			overlayConfig.DepthMode = .Disabled;

			let overlayPipelineResult = cache.GetPipeline(overlayConfig, vertexBuffers, null, pipeline.OutputFormat,
				hasDepth ? .Depth24PlusStencil8 : .Undefined);
			if (overlayPipelineResult case .Ok(let overlayPipeline))
			{
				encoder.SetPipeline(overlayPipeline);
				pipeline.BindFrameGroup(encoder, frame);
				if (renderContext.DefaultMaterialBindGroup != null)
					encoder.SetBindGroup(BindGroupFrequency.Material, renderContext.DefaultMaterialBindGroup, default);
				if (frame.DrawCallBindGroup != null)
				{
					uint32[1] zeroOff = .(0);
					encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, zeroOff);
				}
				encoder.Draw((uint32)overlayClamped, 1, depthClamped, 0);
			}
		}

		} // scope
	}
}
