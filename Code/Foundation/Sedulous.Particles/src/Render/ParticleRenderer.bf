namespace Sedulous.Particles;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Renderer;

/// Per-type drawer for ParticleBatchRenderData.
///
/// Participates in the Transparent category. Iterates the sorted batch,
/// packs all emitters' particle vertex data into a per-frame instance buffer,
/// groups by material bind group and blend mode, and issues one
/// DrawInstanced(6, count) per group with the correct pipeline state.
///
/// The vertex shader uses SV_VertexID (0..5) to build a billboard quad and
/// combines it with per-instance attributes (position, size, color, rotation, UV).
///
/// Owns ParticleGPUResources (instance buffers + material template), initialized
/// in OnRegistered when the renderer is added to RenderContext.
public class ParticleRenderer : Sedulous.Renderer.Renderer
{
	private RenderDataCategory[1] mCategories;
	private ParticleGPUResources mGPUResources ~ { if (_ != null) { _.Dispose(); delete _; } };

	public this()
	{
		mCategories = .(RenderCategories.Transparent);
	}

	/// ParticleGPUResources (instance buffers, material template, layout).
	public ParticleGPUResources GPUResources => mGPUResources;

	public override void OnRegistered(RenderContext context)
	{
		mGPUResources = new ParticleGPUResources();
		mGPUResources.Initialize(context.Device, context.MaterialSystem);
	}

	public override Span<RenderDataCategory> GetSupportedCategories()
	{
		return .(&mCategories[0], 1);
	}

	/// Maps ParticleBlendMode to Materials.BlendMode for pipeline creation.
	private static BlendMode ToMaterialBlendMode(ParticleBlendMode mode)
	{
		switch (mode)
		{
		case .Alpha:         return .AlphaBlend;
		case .Additive:      return .Additive;
		case .Premultiplied: return .PremultipliedAlpha;
		case .Multiply:      return .Multiply;
		}
	}

	public override void RenderBatch(
		IRenderPassEncoder encoder,
		List<RenderData> batch,
		RenderContext renderContext,
		IRenderingPipeline pipeline,
		PerFrameResources frame,
		RenderView view,
		RenderBatchFlags flags)
	{
		if (batch == null || batch.Count == 0) return;
		if (mGPUResources == null) return;

		let cache = renderContext.PipelineStateCache;
		if (cache == null) return;
		if (mGPUResources.ParticleMaterialLayout == null) return;

		let mainPipeline = pipeline as Pipeline;
		if (mainPipeline == null) return;

		// 1. Collect all particle vertices and track (material + blend mode) boundaries.
		let runs = scope List<(int32 start, int32 count, IBindGroup bg, ParticleBlendMode blend)>();
		int32 totalVertices = 0;
		int32 curStart = 0;
		int32 curCount = 0;
		IBindGroup curBG = null;
		ParticleBlendMode curBlend = .Alpha;

		for (let entry in batch)
		{
			let particle = entry as ParticleBatchRenderData;
			if (particle == null || particle.VertexCount == 0) continue;

			// Break run on material OR blend mode change
			if (particle.MaterialBindGroup != curBG || particle.BlendMode != curBlend)
			{
				if (curCount > 0)
					runs.Add((curStart, curCount, curBG, curBlend));
				curStart = totalVertices;
				curCount = 0;
				curBG = particle.MaterialBindGroup;
				curBlend = particle.BlendMode;
			}

			curCount += particle.VertexCount;
			totalVertices += particle.VertexCount;
		}
		if (curCount > 0)
			runs.Add((curStart, curCount, curBG, curBlend));
		if (runs.Count == 0 || totalVertices == 0) return;

		// Clamp to buffer capacity
		if (totalVertices > (int32)ParticleGPUResources.MaxInstancesPerFrame)
			totalVertices = (int32)ParticleGPUResources.MaxInstancesPerFrame;

		// 2. Upload all vertex data in one go.
		let instanceBuffer = mGPUResources.GetInstanceBuffer(view.FrameIndex);
		if (instanceBuffer == null) return;

		let scratchBytes = totalVertices * ParticleVertex.SizeInBytes;
		uint8* scratch = scope uint8[scratchBytes]*;
		int32 writeOffset = 0;

		for (let entry in batch)
		{
			let particle = entry as ParticleBatchRenderData;
			if (particle == null || particle.VertexCount == 0) continue;

			let copyCount = Math.Min(particle.VertexCount,
				(int32)ParticleGPUResources.MaxInstancesPerFrame - writeOffset);
			if (copyCount <= 0) break;

			Internal.MemCpy(
				scratch + writeOffset * ParticleVertex.SizeInBytes,
				particle.Vertices,
				copyCount * ParticleVertex.SizeInBytes);

			writeOffset += copyCount;
		}

		TransferHelper.WriteMappedBuffer(instanceBuffer, 0,
			Span<uint8>(scratch, writeOffset * ParticleVertex.SizeInBytes));

		// 3. Vertex layout (shared across all blend modes).
		VertexAttribute[6] attrs = .(
			.(.Float32x3, 0,  0),   // Position
			.(.Float32x2, 12, 1),   // Size
			.(.Unorm8x4,  20, 2),   // Color
			.(.Float32,   24, 3),   // Rotation
			.(.Float32x4, 28, 4),   // TexCoordOffset + TexCoordScale
			.(.Float32x2, 44, 5)    // Velocity2D
		);
		VertexBufferLayout instanceLayout = .((uint32)ParticleVertex.SizeInBytes, .(&attrs[0], 6), .Instance);
		VertexBufferLayout[1] vertexBuffers = .(instanceLayout);

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		mainPipeline.BindFrameGroup(encoder, frame);

		// DrawCall bind group — particles don't use object uniforms but the
		// pipeline layout expects the set to be bound.
		if (frame.DrawCallBindGroup != null)
		{
			uint32[1] zeroOffset = .(0);
			encoder.SetBindGroup(BindGroupFrequency.DrawCall, frame.DrawCallBindGroup, zeroOffset);
		}

		// 4. One draw per run, switching pipeline on blend mode change.
		ParticleBlendMode lastBlend = .Alpha;
		bool pipelineBound = false;

		for (let run in runs)
		{
			// Rebind pipeline if blend mode changed
			if (!pipelineBound || run.blend != lastBlend)
			{
				var config = mGPUResources.ParticleMaterial.PipelineConfig;
				config.ShaderName = "particle";
				config.ColorTargetCount = 1;
				config.Topology = .TriangleList;
				config.DepthFormat = .Depth24PlusStencil8;
				config.BlendMode = ToMaterialBlendMode(run.blend);

				let pipelineResult = cache.GetPipeline(config, vertexBuffers,
					mGPUResources.ParticleMaterialLayout,
					mainPipeline.OutputFormat,
					.Depth24PlusStencil8);
				if (pipelineResult case .Err)
					continue;

				encoder.SetPipeline(pipelineResult.Value);
				lastBlend = run.blend;
				pipelineBound = true;
			}

			let mat = (run.bg != null) ? run.bg : mGPUResources.DefaultBindGroup;
			if (mat != null)
				encoder.SetBindGroup(BindGroupFrequency.Material, mat, default);

			let offsetBytes = (uint64)(run.start * ParticleVertex.SizeInBytes);
			encoder.SetVertexBuffer(0, instanceBuffer, offsetBytes);
			encoder.Draw(6, (uint32)run.count, 0, 0);
		}

		// 5. Trail rendering — separate pass with different vertex layout and shader.
		RenderTrails(encoder, batch, cache, mainPipeline, frame, view);
	}

	/// Renders trail ribbon geometry for systems with RenderMode == .Trail.
	private void RenderTrails(
		IRenderPassEncoder encoder,
		List<RenderData> batch,
		PipelineStateCache cache,
		Pipeline mainPipeline,
		PerFrameResources frame,
		RenderView view)
	{
		// Collect trail vertices from all trail-mode systems
		int32 totalTrailVerts = 0;
		for (let entry in batch)
		{
			let particle = entry as ParticleBatchRenderData;
			if (particle == null || particle.RenderMode != .Trail || particle.TrailVertexCount == 0)
				continue;
			totalTrailVerts += particle.TrailVertexCount;
		}

		if (totalTrailVerts == 0) return;

		let trailBuffer = mGPUResources.GetTrailBuffer(view.FrameIndex);
		if (trailBuffer == null) return;

		// Clamp to buffer capacity
		if (totalTrailVerts > (int32)ParticleGPUResources.MaxTrailVerticesPerFrame)
			totalTrailVerts = (int32)ParticleGPUResources.MaxTrailVerticesPerFrame;

		// Upload trail vertex data
		let scratchBytes = totalTrailVerts * TrailVertex.SizeInBytes;
		uint8* scratch = scope uint8[scratchBytes]*;
		int32 writeOffset = 0;

		// Build runs grouped by material + blend mode
		let runs = scope List<(int32 start, int32 count, IBindGroup bg, ParticleBlendMode blend)>();
		int32 curStart = 0;
		int32 curCount = 0;
		IBindGroup curBG = null;
		ParticleBlendMode curBlend = .Alpha;

		for (let entry in batch)
		{
			let particle = entry as ParticleBatchRenderData;
			if (particle == null || particle.RenderMode != .Trail || particle.TrailVertexCount == 0)
				continue;

			let copyCount = Math.Min(particle.TrailVertexCount,
				(int32)ParticleGPUResources.MaxTrailVerticesPerFrame - writeOffset);
			if (copyCount <= 0) break;

			if (particle.MaterialBindGroup != curBG || particle.BlendMode != curBlend)
			{
				if (curCount > 0)
					runs.Add((curStart, curCount, curBG, curBlend));
				curStart = writeOffset;
				curCount = 0;
				curBG = particle.MaterialBindGroup;
				curBlend = particle.BlendMode;
			}

			Internal.MemCpy(
				scratch + writeOffset * TrailVertex.SizeInBytes,
				particle.TrailVertices,
				copyCount * TrailVertex.SizeInBytes);

			writeOffset += copyCount;
			curCount += copyCount;
		}
		if (curCount > 0)
			runs.Add((curStart, curCount, curBG, curBlend));
		if (runs.Count == 0) return;

		TransferHelper.WriteMappedBuffer(trailBuffer, 0,
			Span<uint8>(scratch, writeOffset * TrailVertex.SizeInBytes));

		// Trail vertex layout: Position(float3) + TexCoord(float2) + Color(unorm8x4)
		VertexAttribute[3] trailAttrs = .(
			.(.Float32x3, 0, 0),    // Position
			.(.Float32x2, 12, 1),   // TexCoord
			.(.Unorm8x4, 20, 2)     // Color
		);
		VertexBufferLayout trailLayout = .((uint32)TrailVertex.SizeInBytes, .(&trailAttrs[0], 3), .Vertex);
		VertexBufferLayout[1] trailBuffers = .(trailLayout);

		// Draw trail runs
		ParticleBlendMode lastBlend = .Alpha;
		bool pipelineBound = false;

		for (let run in runs)
		{
			if (!pipelineBound || run.blend != lastBlend)
			{
				var config = mGPUResources.ParticleMaterial.PipelineConfig;
				config.ShaderName = "particle_trail";
				config.ColorTargetCount = 1;
				config.Topology = .TriangleList;
				config.DepthFormat = .Depth24PlusStencil8;
				config.BlendMode = ToMaterialBlendMode(run.blend);

				let pipelineResult = cache.GetPipeline(config, trailBuffers,
					mGPUResources.ParticleMaterialLayout,
					mainPipeline.OutputFormat,
					.Depth24PlusStencil8);
				if (pipelineResult case .Err)
					continue;

				encoder.SetPipeline(pipelineResult.Value);
				lastBlend = run.blend;
				pipelineBound = true;
			}

			let mat = (run.bg != null) ? run.bg : mGPUResources.DefaultBindGroup;
			if (mat != null)
				encoder.SetBindGroup(BindGroupFrequency.Material, mat, default);

			let offsetBytes = (uint64)(run.start * TrailVertex.SizeInBytes);
			encoder.SetVertexBuffer(0, trailBuffer, offsetBytes);
			encoder.Draw((uint32)run.count, 1, 0, 0);
		}
	}
}
