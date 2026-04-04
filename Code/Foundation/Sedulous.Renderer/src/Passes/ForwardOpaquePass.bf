namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;

/// Forward opaque pass — renders opaque geometry.
/// Writes to PipelineOutput.
class ForwardOpaquePass : PipelinePass
{
	private IDevice mDevice;
	private Sedulous.RHI.IRenderPipeline mUnlitPipeline;
	private IPipelineLayout mPipelineLayout;

	public override StringView Name => "ForwardOpaque";

	public override Result<void> OnInitialize(Pipeline pipeline)
	{
		mDevice = pipeline.Device;
		let device = mDevice;
		let shaderSystem = pipeline.ShaderSystem;
		if (shaderSystem == null)
			return .Ok; // No shaders available yet

		// Get unlit shader pair
		let shaderResult = shaderSystem.GetShaderPair("unlit");
		if (shaderResult case .Err)
			return .Ok; // Non-fatal

		let (vertModule, fragModule) = shaderResult.Value;

		// Pipeline layout: set 0 = frame uniforms only (for now)
		IBindGroupLayout[1] layouts = .(pipeline.FrameBindGroupLayout);
		PipelineLayoutDesc plDesc = .(layouts);

		if (device.CreatePipelineLayout(plDesc) case .Ok(let plLayout))
			mPipelineLayout = plLayout;
		else
			return .Err;

		// Vertex layout: float3 position + float4 color
		VertexAttribute[2] attrs = .(
			.() { Format = .Float3, Offset = 0, ShaderLocation = 0 },    // POSITION
			.() { Format = .Float4, Offset = 12, ShaderLocation = 1 }    // COLOR
		);

		VertexBufferLayout[1] vertexBuffers = .(
			.()
			{
				Stride = 28, // 12 + 16
				StepMode = .Vertex,
				Attributes = attrs
			}
		);

		ColorTargetState[1] colorTargets = .(.() { Format = pipeline.OutputFormat });

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "Unlit Pipeline",
			Layout = mPipelineLayout,
			Vertex = .()
			{
				Shader = .(vertModule.Module, "main"),
				Buffers = vertexBuffers
			},
			Fragment = .()
			{
				Shader = .(fragModule.Module, "main"),
				Targets = colorTargets
			},
			Primitive = .()
			{
				Topology = .TriangleList,
				FrontFace = .CCW,
				CullMode = .None
			},
			DepthStencil = null,
			Multisample = .()
			{
				Count = 1,
				Mask = uint32.MaxValue
			}
		};

		if (device.CreateRenderPipeline(pipelineDesc) case .Ok(let rp))
			mUnlitPipeline = rp;

		return .Ok;
	}

	public override void OnShutdown()
	{
		if (mDevice != null)
		{
			if (mUnlitPipeline != null) mDevice.DestroyRenderPipeline(ref mUnlitPipeline);
			if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		}
	}

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
		if (mUnlitPipeline == null)
			return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);
		encoder.SetPipeline(mUnlitPipeline);

		let data = view.RenderData;
		let gpuResources = pipeline.GPUResources;
		let frame = pipeline.GetFrameResources(view.FrameIndex);

		// Bind frame bind group (set 0)
		if (frame.FrameBindGroup != null)
			encoder.SetBindGroup(0, frame.FrameBindGroup, default);

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
