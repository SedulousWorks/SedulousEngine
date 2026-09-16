using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A render pipeline.
///
/// One honest narrowing: a wireframe fill has no WebGPU shape at all, polygon mode not
/// being in the API, so it is refused and a caller keeps its debug wireframe off this
/// backend. Depth bias rides the depth stencil state, which is where WebGPU puts it.
sealed class WebGpuRenderPipeline : IRenderPipeline
{
	private WGPURenderPipeline mHandle;
	private WebGpuPipelineLayout mLayout;
	/// Snapshotted off the layout so a pass encoder can resolve it on SetPipeline.
	private PushConstantEmulation mPushConstants;

	public IPipelineLayout Layout => mLayout;
	public WGPURenderPipeline Handle => mHandle;
	public PushConstantEmulation PushConstants => mPushConstants;

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuRenderPipelineRelease(mHandle);
			mHandle = null;
		}
	}

	public Result<void> Initialize(WGPUDevice device, RenderPipelineDesc desc)
	{
		mLayout = desc.Layout as WebGpuPipelineLayout;
		if ((mLayout == null) || (desc.Vertex.Shader.Module == null))
			return .Err;

		if (desc.Primitive.FillMode == .Wireframe)
			return .Err; // WebGPU has no polygon mode

		mPushConstants = mLayout.EmulationInfo;

		WGPURenderPipelineDescriptor wgpu = .();
		wgpu.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpu.layout = mLayout.Handle;

		// ---- the vertex stage and its buffers ----
		let vertexModule = desc.Vertex.Shader.Module as WebGpuShaderModule;
		if (vertexModule == null)
			return .Err;

		wgpu.vertex.module = vertexModule.Handle;
		wgpu.vertex.entryPoint = WebGpuConversions.ToWgpuStringView(desc.Vertex.Shader.EntryPoint);

		// The attribute arrays are pointed AT by the buffer layouts, so they have to
		// outlive this call and keep their addresses. One list per buffer, none of them
		// resized after a pointer into it is taken.
		let attributeStorage = scope List<List<WGPUVertexAttribute>>();
		defer { for (let list in attributeStorage) delete list; }

		let vertexBuffers = scope List<WGPUVertexBufferLayout>();

		for (let bufferLayout in desc.Vertex.Buffers)
		{
			let attributes = new List<WGPUVertexAttribute>(bufferLayout.Attributes.Length);
			attributeStorage.Add(attributes);

			for (let attribute in bufferLayout.Attributes)
			{
				WGPUVertexAttribute wgpuAttribute = .();
				wgpuAttribute.format = WebGpuConversions.ToWgpuVertexFormat(attribute.Format);
				wgpuAttribute.offset = attribute.Offset;
				wgpuAttribute.shaderLocation = attribute.ShaderLocation;
				attributes.Add(wgpuAttribute);
			}

			WGPUVertexBufferLayout wgpuLayout = .();
			wgpuLayout.stepMode = WebGpuConversions.ToWgpuVertexStepMode(bufferLayout.StepMode);
			wgpuLayout.arrayStride = bufferLayout.Stride;
			wgpuLayout.attributeCount = (uint)attributes.Count;
			wgpuLayout.attributes = attributes.Ptr;
			vertexBuffers.Add(wgpuLayout);
		}

		wgpu.vertex.bufferCount = (uint)vertexBuffers.Count;
		wgpu.vertex.buffers = vertexBuffers.Ptr;

		// ---- the primitive state ----
		wgpu.primitive.topology =
			WebGpuConversions.ToWgpuPrimitiveTopology(desc.Primitive.Topology);
		wgpu.primitive.frontFace = WebGpuConversions.ToWgpuFrontFace(desc.Primitive.FrontFace);
		wgpu.primitive.cullMode = WebGpuConversions.ToWgpuCullMode(desc.Primitive.CullMode);

		// A strip topology REQUIRES a strip index format and a list must leave it
		// undefined, which is the other way round from most state: setting it on a list
		// is the error, not omitting it on a strip. Uint32 is what the engine's index
		// buffers are.
		let isStrip = (desc.Primitive.Topology == .LineStrip)
			|| (desc.Primitive.Topology == .TriangleStrip);
		wgpu.primitive.stripIndexFormat = isStrip ? .WGPUIndexFormat_Uint32
			: .WGPUIndexFormat_Undefined;

		wgpu.primitive.unclippedDepth = desc.Primitive.DepthClipEnabled ? 0 : 1;

		// ---- the depth stencil state ----
		WGPUDepthStencilState depthStencil = .();
		if (desc.DepthStencil.HasValue)
		{
			let ds = desc.DepthStencil.Value;
			depthStencil.format = WebGpuConversions.ToWgpuTextureFormat(ds.Format);
			depthStencil.depthWriteEnabled = ds.DepthWriteEnabled ? .WGPUOptionalBool_True
				: .WGPUOptionalBool_False;
			// A disabled depth test is spelled as an Always compare rather than as a
			// flag, WebGPU having no separate enable.
			depthStencil.depthCompare = ds.DepthTestEnabled
				? WebGpuConversions.ToWgpuCompareFunction(ds.DepthCompare)
				: .WGPUCompareFunction_Always;
			// Likewise a disabled stencil is spelled as masks of zero.
			depthStencil.stencilReadMask = ds.StencilEnabled ? ds.StencilReadMask : 0;
			depthStencil.stencilWriteMask = ds.StencilEnabled ? ds.StencilWriteMask : 0;

			depthStencil.stencilFront.compare =
				WebGpuConversions.ToWgpuCompareFunction(ds.StencilFront.Compare);
			depthStencil.stencilFront.failOp =
				WebGpuConversions.ToWgpuStencilOperation(ds.StencilFront.FailOp);
			depthStencil.stencilFront.depthFailOp =
				WebGpuConversions.ToWgpuStencilOperation(ds.StencilFront.DepthFailOp);
			depthStencil.stencilFront.passOp =
				WebGpuConversions.ToWgpuStencilOperation(ds.StencilFront.PassOp);

			depthStencil.stencilBack.compare =
				WebGpuConversions.ToWgpuCompareFunction(ds.StencilBack.Compare);
			depthStencil.stencilBack.failOp =
				WebGpuConversions.ToWgpuStencilOperation(ds.StencilBack.FailOp);
			depthStencil.stencilBack.depthFailOp =
				WebGpuConversions.ToWgpuStencilOperation(ds.StencilBack.DepthFailOp);
			depthStencil.stencilBack.passOp =
				WebGpuConversions.ToWgpuStencilOperation(ds.StencilBack.PassOp);

			depthStencil.depthBias = ds.DepthBias;
			depthStencil.depthBiasSlopeScale = ds.DepthBiasSlopeScale;
			depthStencil.depthBiasClamp = ds.DepthBiasClamp;

			wgpu.depthStencil = &depthStencil;
		}

		// ---- multisample ----
		wgpu.multisample.count = desc.Multisample.Count;
		wgpu.multisample.mask = desc.Multisample.Mask;
		wgpu.multisample.alphaToCoverageEnabled = desc.Multisample.AlphaToCoverageEnabled ? 1 : 0;

		// ---- the fragment stage and its colour targets ----
		WGPUFragmentState fragment = .();
		let targets = scope List<WGPUColorTargetState>();
		// SIZED UP FRONT, never grown. Each target points at an element of this, so a
		// reallocation partway through would leave the earlier targets pointing at freed
		// blend states.
		let blendStorage = scope List<WGPUBlendState>(
			desc.Fragment.HasValue ? desc.Fragment.Value.Targets.Length : 0);

		if (desc.Fragment.HasValue)
		{
			let fs = desc.Fragment.Value;
			let fragmentModule = fs.Shader.Module as WebGpuShaderModule;
			if (fragmentModule == null)
				return .Err;

			fragment.module = fragmentModule.Handle;
			fragment.entryPoint = WebGpuConversions.ToWgpuStringView(fs.Shader.EntryPoint);

			for (let target in fs.Targets)
			{
				WGPUColorTargetState wgpuTarget = .();
				wgpuTarget.format = WebGpuConversions.ToWgpuTextureFormat(target.Format);
				wgpuTarget.writeMask = WebGpuConversions.ToWgpuColorWriteMask(target.WriteMask);

				if (target.Blend.HasValue)
				{
					let blend = target.Blend.Value;
					WGPUBlendState wgpuBlend = .();
					wgpuBlend.color.srcFactor =
						WebGpuConversions.ToWgpuBlendFactor(blend.Color.SrcFactor);
					wgpuBlend.color.dstFactor =
						WebGpuConversions.ToWgpuBlendFactor(blend.Color.DstFactor);
					wgpuBlend.color.operation =
						WebGpuConversions.ToWgpuBlendOperation(blend.Color.Operation);
					wgpuBlend.alpha.srcFactor =
						WebGpuConversions.ToWgpuBlendFactor(blend.Alpha.SrcFactor);
					wgpuBlend.alpha.dstFactor =
						WebGpuConversions.ToWgpuBlendFactor(blend.Alpha.DstFactor);
					wgpuBlend.alpha.operation =
						WebGpuConversions.ToWgpuBlendOperation(blend.Alpha.Operation);

					blendStorage.Add(wgpuBlend);
					wgpuTarget.blend = &blendStorage[blendStorage.Count - 1];
				}

				targets.Add(wgpuTarget);
			}

			fragment.targetCount = (uint)targets.Count;
			fragment.targets = targets.Ptr;
			wgpu.fragment = &fragment;
		}

		mHandle = wgpuDeviceCreateRenderPipeline(device, &wgpu);
		return (mHandle != null) ? .Ok : .Err;
	}
}
