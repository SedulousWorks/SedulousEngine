namespace Sedulous.Renderer.Passes;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Core.Mathematics;
using Sedulous.Renderer;
using Sedulous.Renderer.Debug;
using Sedulous.DebugFont;
using Sedulous.Profiler;
using Sedulous.Materials;

/// 2D overlay pass - renders accumulated screen-space text and filled rectangles
/// (plus screen-projected 3D text) using the DebugFont atlas.
///
/// No depth test. Runs last before the final post-process / blit so the overlay
/// sits on top of everything.
class DebugScreenPass : PipelinePass
{
	// CPU-side scratch buffer for building the quad geometry each frame.
	// Sized to match DebugDrawSystem.MaxOverlayVertices.
	private List<DebugTextVertex> mScratch = new .() ~ delete _;

	public override StringView Name => "Overlay";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		// Overlay commands come from both per-pipeline (scene-local in the editor's
		// multi-viewport case) and the global render-context stream. Mirrors the
		// DebugGeometryPass local+global merge so viewport-scoped overlays don't bleed into
		// other pipelines.
		let globalDraw = pipeline.RenderContext.DebugDraw;
		let localDraw = pipeline.DebugDraw;
		let globalEmpty = (globalDraw == null) || (globalDraw.Commands2D.Length == 0 && globalDraw.TextCommands3D.Length == 0);
		let localEmpty = (localDraw == null) || (localDraw.Commands2D.Length == 0 && localDraw.TextCommands3D.Length == 0);
		if (globalEmpty && localEmpty)
			return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid)
			return;

		graph.AddRenderPass("Overlay", scope (builder) => {
			builder
				.SetColorTarget(0, outputHandle, .Load, .Store)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					Execute(encoder, view, pipeline);
				});
		});
	}

	private void Execute(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		using (Profiler.Begin("Overlay"))
		{
		let renderContext = pipeline.RenderContext;
		let globalDraw = renderContext.DebugDraw;
		let localDraw = pipeline.DebugDraw;
		let debugSystem = renderContext.DebugDrawSystem;
		let cache = renderContext.PipelineStateCache;
		if (cache == null || debugSystem == null) return;

		// Build CPU scratch vertex list. Local (scene-scoped) first, global last so
		// global overlays draw on top of local ones - matches DebugGeometryPass ordering.
		mScratch.Clear();
		if (localDraw != null) BuildQuads(localDraw, view);
		if (globalDraw != null) BuildQuads(globalDraw, view);
		if (mScratch.Count == 0) return;

		let vertCount = Math.Min((uint32)mScratch.Count, DebugDrawSystem.MaxOverlayVertices);

		// Upload to GPU.
		let vb = debugSystem.GetOverlayVertexBuffer(view.FrameIndex);
		TransferHelper.WriteMappedBuffer(vb, 0,
			Span<uint8>((uint8*)mScratch.Ptr, (int)(vertCount * DebugTextVertex.SizeInBytes)));

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		// Pipeline state - textured quads, alpha blend, no depth, no cull.
		var config = PipelineConfig();
		config.ShaderName = "debug_screen";
		config.BlendMode = .AlphaBlend;
		config.CullMode = .None;
		config.ColorTargetCount = 1;
		config.Topology = .TriangleList;
		config.DepthMode = .Disabled;

		VertexAttribute[3] attrs = .(
			.(.Float32x3, 0, 0),       // Position (x,y pixels; z unused)
			.(.Float32x2, 12, 1),      // TexCoord
			.(.Unorm8x4, 20, 2)        // Color
		);
		VertexBufferLayout vertexLayout = .((uint32)DebugTextVertex.SizeInBytes, .(&attrs[0], 3));
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let pipelineResult = cache.GetPipeline(config, vertexBuffers,
			debugSystem.DebugBindGroupLayout, pipeline.OutputFormat, .Undefined);
		if (pipelineResult case .Err)
			return;

		encoder.SetPipeline(pipelineResult.Value);

		let frame = pipeline.GetFrameResources(view.FrameIndex);
		pipeline.BindFrameGroup(encoder, frame);

		// Material slot (2) holds the font atlas bind group.
		if (debugSystem.DebugBindGroup != null)
			encoder.SetBindGroup(BindGroupFrequency.Material, debugSystem.DebugBindGroup, default);
		if (frame.DrawCallBindGroup != null)
		{
			uint32[1] zeroOffset = .(0);
			encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, zeroOffset);
		}

		encoder.SetVertexBuffer(0, vb, 0);
		encoder.Draw(vertCount, 1, 0, 0);
		} // scope
	}

	// ==================== Quad generation ====================

	private void BuildQuads(DebugDraw debugDraw, RenderView view)
	{
		let chars = debugDraw.TextChars;
		let charW = (float)DebugFont.CharWidth;
		let charH = (float)DebugFont.CharHeight;

		// 2D commands.
		for (let cmd in debugDraw.Commands2D)
		{
			if (cmd.Kind == .Rect)
			{
				float u0, v0, u1, v1;
				DebugFont.GetSolidBlockUV(out u0, out v0, out u1, out v1);
				// Sample a single pixel inside the solid block to avoid filter bleed.
				let u = (u0 + u1) * 0.5f;
				let v = (v0 + v1) * 0.5f;
				EmitQuad(cmd.Position.X, cmd.Position.Y, cmd.Size.X, cmd.Size.Y,
					u, v, u, v, cmd.Color);
			}
			else // .Text
			{
				let scale = (cmd.Scale > 0) ? cmd.Scale : 1.0f;
				let scaledW = charW * scale;
				let scaledH = charH * scale;

				// Negative X signals right-aligned text
				float x;
				if (cmd.Position.X < 0)
				{
					let textWidth = (float)cmd.TextLength * scaledW;
					x = (float)view.Width + cmd.Position.X + 1 - textWidth;
				}
				else
					x = cmd.Position.X;

				let y = cmd.Position.Y;
				for (int32 i = 0; i < cmd.TextLength; i++)
				{
					let c = (char32)chars[cmd.TextStart + i];
					float u0, v0, u1, v1;
					if (DebugFont.GetCharUV(c, out u0, out v0, out u1, out v1))
						EmitQuad(x, y, scaledW, scaledH, u0, v0, u1, v1, cmd.Color);
					x += scaledW;
				}
			}
		}

		// 3D text - project to screen, then emit pixel-space quads.
		if (debugDraw.TextCommands3D.Length > 0)
		{
			let vp = view.ViewProjectionMatrix;

			for (let cmd in debugDraw.TextCommands3D)
			{
				let clip = Vector4.Transform(cmd.WorldPos, vp);
				if (clip.W <= 0.0f) continue;
				let ndcX = clip.X / clip.W;
				let ndcY = clip.Y / clip.W;
				// NDC -> pixel coordinates (top-left origin).
				let px = (ndcX * 0.5f + 0.5f) * (float)view.Width;
				let py = (1.0f - (ndcY * 0.5f + 0.5f)) * (float)view.Height;

				float x = px;
				let y = py;
				for (int32 i = 0; i < cmd.TextLength; i++)
				{
					let c = (char32)chars[cmd.TextStart + i];
					float u0, v0, u1, v1;
					if (DebugFont.GetCharUV(c, out u0, out v0, out u1, out v1))
						EmitQuad(x, y, charW, charH, u0, v0, u1, v1, cmd.Color);
					x += charW;
				}
			}
		}
	}

	private void EmitQuad(float x, float y, float w, float h, float u0, float v0, float u1, float v1, Color color)
	{
		// Triangle list, clockwise winding for DX convention.
		let p00 = Vector3(x,     y,     0);
		let p10 = Vector3(x + w, y,     0);
		let p01 = Vector3(x,     y + h, 0);
		let p11 = Vector3(x + w, y + h, 0);
		let uv00 = Vector2(u0, v0);
		let uv10 = Vector2(u1, v0);
		let uv01 = Vector2(u0, v1);
		let uv11 = Vector2(u1, v1);

		// Tri 1: 00, 10, 01
		mScratch.Add(.(p00, uv00, color));
		mScratch.Add(.(p10, uv10, color));
		mScratch.Add(.(p01, uv01, color));
		// Tri 2: 10, 11, 01
		mScratch.Add(.(p10, uv10, color));
		mScratch.Add(.(p11, uv11, color));
		mScratch.Add(.(p01, uv01, color));
	}
}
