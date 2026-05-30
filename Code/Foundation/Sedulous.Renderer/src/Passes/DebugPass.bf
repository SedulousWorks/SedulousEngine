namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Renderer.Debug;
using Sedulous.DebugFont;
using Sedulous.Profiler;
using Sedulous.Materials;

/// Debug drawing pass - renders accumulated line and triangle vertices from
/// RenderContext.DebugDraw. Supports depth-tested and overlay modes for both
/// lines and filled triangles. Runs after main forward passes and before
/// post-processing so the primitives compose into the HDR scene color.
class DebugPass : PipelinePass
{
	public override StringView Name => "DebugLines";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let localDraw = pipeline.DebugDraw;
		let globalDraw = pipeline.RenderContext.DebugDraw;

		let localLineCount = (localDraw != null) ? localDraw.LineVertexCount + localDraw.OverlayLineVertexCount : 0;
		let globalLineCount = (globalDraw != null) ? globalDraw.LineVertexCount + globalDraw.OverlayLineVertexCount : 0;
		let localTriCount = (localDraw != null) ? localDraw.TriVertexCount + localDraw.OverlayTriVertexCount : 0;
		let globalTriCount = (globalDraw != null) ? globalDraw.TriVertexCount + globalDraw.OverlayTriVertexCount : 0;

		if (localLineCount == 0 && globalLineCount == 0 && localTriCount == 0 && globalTriCount == 0)
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
		let localDraw = pipeline.DebugDraw;
		let globalDraw = renderContext.DebugDraw;
		let debugSystem = renderContext.DebugDrawSystem;
		let cache = renderContext.PipelineStateCache;
		if (cache == null || debugSystem == null) return;

		// Count vertices from both local and global draws
		let localDepthLines = (localDraw != null) ? (uint32)localDraw.LineVertexCount : 0;
		let globalDepthLines = (globalDraw != null) ? (uint32)globalDraw.LineVertexCount : 0;
		let localOverlayLines = (localDraw != null) ? (uint32)localDraw.OverlayLineVertexCount : 0;
		let globalOverlayLines = (globalDraw != null) ? (uint32)globalDraw.OverlayLineVertexCount : 0;
		let localDepthTris = (localDraw != null) ? (uint32)localDraw.TriVertexCount : 0;
		let globalDepthTris = (globalDraw != null) ? (uint32)globalDraw.TriVertexCount : 0;
		let localOverlayTris = (localDraw != null) ? (uint32)localDraw.OverlayTriVertexCount : 0;
		let globalOverlayTris = (globalDraw != null) ? (uint32)globalDraw.OverlayTriVertexCount : 0;

		let totalDepthLines = localDepthLines + globalDepthLines;
		let totalOverlayLines = localOverlayLines + globalOverlayLines;
		let totalDepthTris = localDepthTris + globalDepthTris;
		let totalOverlayTris = localOverlayTris + globalOverlayTris;
		let totalVerts = totalDepthLines + totalOverlayLines + totalDepthTris + totalOverlayTris;

		if (totalVerts == 0) return;

		// Clamp to buffer capacity
		let maxVerts = DebugDrawSystem.MaxLineVertices;
		let clampedTotal = Math.Min(totalVerts, maxVerts);

		// Allocate budget: depth lines -> overlay lines -> depth tris -> overlay tris
		uint32 budget = clampedTotal;
		uint32 depthLinesClamped = Math.Min(totalDepthLines, budget);
		budget -= depthLinesClamped;
		uint32 overlayLinesClamped = Math.Min(totalOverlayLines, budget);
		budget -= overlayLinesClamped;
		uint32 depthTrisClamped = Math.Min(totalDepthTris, budget);
		budget -= depthTrisClamped;
		uint32 overlayTrisClamped = Math.Min(totalOverlayTris, budget);

		let vb = pipeline.GetLineVertexBuffer(view.FrameIndex);
		uint64 offset = 0;

		// Upload depth lines
		Span<DebugVertex> localLineSpan = (localDraw != null) ? localDraw.LineVertices : default;
		Span<DebugVertex> globalLineSpan = (globalDraw != null) ? globalDraw.LineVertices : default;
		let vertSize = (uint64)DebugVertex.SizeInBytes;

		offset = UploadVertices(vb, offset, localLineSpan, globalLineSpan, depthLinesClamped);
		let overlayLinesStart = (uint32)(offset / vertSize);

		// Upload overlay lines
		Span<DebugVertex> localOverlayLineSpan = (localDraw != null) ? localDraw.OverlayLineVertices : default;
		Span<DebugVertex> globalOverlayLineSpan = (globalDraw != null) ? globalDraw.OverlayLineVertices : default;
		offset = UploadVertices(vb, offset, localOverlayLineSpan, globalOverlayLineSpan, overlayLinesClamped);
		let depthTrisStart = (uint32)(offset / vertSize);

		// Upload depth triangles
		Span<DebugVertex> localTriSpan = (localDraw != null) ? localDraw.TriVertices : default;
		Span<DebugVertex> globalTriSpan = (globalDraw != null) ? globalDraw.TriVertices : default;
		offset = UploadVertices(vb, offset, localTriSpan, globalTriSpan, depthTrisClamped);
		let overlayTrisStart = (uint32)(offset / vertSize);

		// Upload overlay triangles
		Span<DebugVertex> localOverlayTriSpan = (localDraw != null) ? localDraw.OverlayTriVertices : default;
		Span<DebugVertex> globalOverlayTriSpan = (globalDraw != null) ? globalDraw.OverlayTriVertices : default;
		offset = UploadVertices(vb, offset, localOverlayTriSpan, globalOverlayTriSpan, overlayTrisClamped);

		// Setup shared state
		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		VertexAttribute[2] attrs = .(
			.(.Float32x3, 0, 0),
			.(.Unorm8x4, 12, 1)
		);
		VertexBufferLayout vertexLayout = .((uint32)DebugVertex.SizeInBytes, .(&attrs[0], 2));
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let frame = pipeline.GetFrameResources(view.FrameIndex);
		let depthFormat = hasDepth ? Pipeline.DepthFormat : TextureFormat.Undefined;

		var config = PipelineConfig();
		config.ShaderName = "debug_line";
		config.BlendMode = .AlphaBlend;
		config.CullMode = .None;
		config.ColorTargetCount = 1;
		config.DepthFormat = Pipeline.DepthFormat;

		// 1. Depth-tested lines
		if (depthLinesClamped > 0)
		{
			config.Topology = .LineList;
			config.DepthMode = hasDepth ? .ReadOnly : .Disabled;
			config.DepthCompare = .LessEqual;
			if (cache.GetPipeline(config, vertexBuffers, null, pipeline.OutputFormat, depthFormat) case .Ok(let p))
			{
				encoder.SetPipeline(p);
				encoder.SetVertexBuffer(0, vb, 0);
				pipeline.BindFrameGroup(encoder, frame);
				if (renderContext.DefaultMaterialBindGroup != null)
					encoder.SetBindGroup(BindGroupFrequency.Material, renderContext.DefaultMaterialBindGroup, default);
				if (frame.DrawCallBindGroup != null) { uint32[1] off = .(0); encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, off); }
				encoder.Draw(depthLinesClamped, 1, 0, 0);
			}
		}

		// 2. Overlay lines
		if (overlayLinesClamped > 0)
		{
			config.Topology = .LineList;
			config.DepthMode = .Disabled;
			if (cache.GetPipeline(config, vertexBuffers, null, pipeline.OutputFormat, depthFormat) case .Ok(let p))
			{
				encoder.SetPipeline(p);
				encoder.SetVertexBuffer(0, vb, 0);
				pipeline.BindFrameGroup(encoder, frame);
				if (renderContext.DefaultMaterialBindGroup != null)
					encoder.SetBindGroup(BindGroupFrequency.Material, renderContext.DefaultMaterialBindGroup, default);
				if (frame.DrawCallBindGroup != null) { uint32[1] off = .(0); encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, off); }
				encoder.Draw(overlayLinesClamped, 1, overlayLinesStart, 0);
			}
		}

		// 3. Depth-tested triangles
		if (depthTrisClamped > 0)
		{
			config.Topology = .TriangleList;
			config.DepthMode = hasDepth ? .ReadOnly : .Disabled;
			config.DepthCompare = .LessEqual;
			if (cache.GetPipeline(config, vertexBuffers, null, pipeline.OutputFormat, depthFormat) case .Ok(let p))
			{
				encoder.SetPipeline(p);
				encoder.SetVertexBuffer(0, vb, 0);
				pipeline.BindFrameGroup(encoder, frame);
				if (renderContext.DefaultMaterialBindGroup != null)
					encoder.SetBindGroup(BindGroupFrequency.Material, renderContext.DefaultMaterialBindGroup, default);
				if (frame.DrawCallBindGroup != null) { uint32[1] off = .(0); encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, off); }
				encoder.Draw(depthTrisClamped, 1, depthTrisStart, 0);
			}
		}

		// 4. Overlay triangles
		if (overlayTrisClamped > 0)
		{
			config.Topology = .TriangleList;
			config.DepthMode = .Disabled;
			if (cache.GetPipeline(config, vertexBuffers, null, pipeline.OutputFormat, depthFormat) case .Ok(let p))
			{
				encoder.SetPipeline(p);
				encoder.SetVertexBuffer(0, vb, 0);
				pipeline.BindFrameGroup(encoder, frame);
				if (renderContext.DefaultMaterialBindGroup != null)
					encoder.SetBindGroup(BindGroupFrequency.Material, renderContext.DefaultMaterialBindGroup, default);
				if (frame.DrawCallBindGroup != null) { uint32[1] off = .(0); encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, off); }
				encoder.Draw(overlayTrisClamped, 1, overlayTrisStart, 0);
			}
		}

		} // Profiler scope
	}

	/// Uploads local + global vertex spans into the buffer at the given offset.
	/// Returns the new offset after writing.
	private static uint64 UploadVertices(IBuffer vb, uint64 offset,
		Span<DebugVertex> localVerts, Span<DebugVertex> globalVerts, uint32 maxCount)
	{
		var offset;
		if (maxCount == 0) return offset;

		uint32 written = 0;

		let stride = (uint32)DebugVertex.SizeInBytes;

		// Local first
		if (localVerts.Length > 0)
		{
			let count = Math.Min((uint32)localVerts.Length, maxCount);
			let byteCount = (int)(count * stride);
			TransferHelper.WriteMappedBuffer(vb, offset,
				Span<uint8>((uint8*)localVerts.Ptr, byteCount));
			offset += (uint64)byteCount;
			written += count;
		}

		// Global
		if (globalVerts.Length > 0 && written < maxCount)
		{
			let remaining = maxCount - written;
			let count = Math.Min((uint32)globalVerts.Length, remaining);
			let byteCount = (int)(count * stride);
			TransferHelper.WriteMappedBuffer(vb, offset,
				Span<uint8>((uint8*)globalVerts.Ptr, byteCount));
			offset += (uint64)byteCount;
		}

		return offset;
	}
}
