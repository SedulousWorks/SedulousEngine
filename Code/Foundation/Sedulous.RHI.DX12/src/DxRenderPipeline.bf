#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// One graphics pipeline state object.
///
/// D3D12 bakes rasteriser, blend, depth stencil, input layout and target formats into ONE
/// immutable object, so almost all of this is translating the RHI's description into that
/// single struct. The topology TYPE goes into the object, but the topology itself is set on
/// the command list, so both are kept.
///
/// Vertex strides are kept too: D3D12 names them when the vertex buffer is bound rather than
/// in the pipeline, so the encoder has to ask the pipeline for them.
class DxRenderPipeline : IRenderPipeline
{
	private ID3D12PipelineState* mPipelineState = null; // owned, released in Cleanup
	private DxPipelineLayout mLayout = null; // NOT owned
	private D3D_PRIMITIVE_TOPOLOGY mTopology = .D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
	private uint32[8] mVtxStrides = .();
	private uint32 mVtxBufCount = 0;

	public IPipelineLayout Layout => mLayout;
	public ID3D12PipelineState* Handle => mPipelineState;
	public D3D_PRIMITIVE_TOPOLOGY Topology => mTopology;
	public DxPipelineLayout PipelineLayout => mLayout;

	public uint32 GetVertexStride(uint32 slot) =>
		(slot < mVtxBufCount) ? mVtxStrides[(int)slot] : 0;

	public Result<void> Initialize(ID3D12Device* device, RenderPipelineDesc d)
	{
		mLayout = d.Layout as DxPipelineLayout;
		if (mLayout == null)
			return .Err;

		D3D12_GRAPHICS_PIPELINE_STATE_DESC pso = .();
		pso.pRootSignature = mLayout.Handle;

		let vsMod = d.Vertex.Shader.Module as DxShaderModule;
		if (vsMod == null)
			return .Err;
		let vsCode = vsMod.Bytecode;
		pso.VS.pShaderBytecode = vsCode.Ptr;
		pso.VS.BytecodeLength = (uint)vsCode.Length;

		if (d.Fragment.HasValue)
		{
			if (let psMod = d.Fragment.Value.Shader.Module as DxShaderModule)
			{
				let ps = psMod.Bytecode;
				pso.PS.pShaderBytecode = ps.Ptr;
				pso.PS.BytecodeLength = (uint)ps.Length;
			}
		}

		// The input layout points AT this list, which therefore has to outlive the create
		// call below. Method scoped, so it does.
		let elems = scope List<D3D12_INPUT_ELEMENT_DESC>();
		let bufs = d.Vertex.Buffers;
		mVtxBufCount = (uint32)Math.Min(bufs.Length, 8);

		for (int i = 0; i < bufs.Length; i++)
		{
			let buf = bufs[i];
			if (i < 8)
				mVtxStrides[i] = buf.Stride;

			for (let a in buf.Attributes)
			{
				D3D12_INPUT_ELEMENT_DESC e = .();
				// Everything is TEXCOORD<n>. The shader cook emits the same, so a semantic
				// name carries no meaning here and the location is the whole of the match.
				e.SemanticName = (uint8*)"TEXCOORD".CStr(); // a literal, so it outlives the create call
				e.SemanticIndex = a.ShaderLocation;
				e.Format = DxConversions.ToDxgiVertexFormat(a.Format);
				e.InputSlot = (uint32)i;
				e.AlignedByteOffset = a.Offset;
				e.InputSlotClass = (buf.StepMode == .Instance)
					? .D3D12_INPUT_CLASSIFICATION_PER_INSTANCE_DATA
					: .D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA;
				e.InstanceDataStepRate = (buf.StepMode == .Instance) ? 1 : 0;
				elems.Add(e);
			}
		}

		pso.InputLayout.pInputElementDescs = elems.Ptr;
		pso.InputLayout.NumElements = (uint32)elems.Count;

		pso.PrimitiveTopologyType = DxConversions.ToPrimitiveTopologyType(d.Primitive.Topology);
		mTopology = DxConversions.ToPrimitiveTopology(d.Primitive.Topology);

		pso.RasterizerState.FillMode = DxConversions.ToFillMode(d.Primitive.FillMode);
		pso.RasterizerState.CullMode = DxConversions.ToCullMode(d.Primitive.CullMode);
		pso.RasterizerState.FrontCounterClockwise = (d.Primitive.FrontFace == .CCW) ? TRUE : FALSE;
		pso.RasterizerState.DepthClipEnable = d.Primitive.DepthClipEnabled ? TRUE : FALSE;
		pso.RasterizerState.MultisampleEnable = (d.Multisample.Count > 1) ? TRUE : FALSE;

		if (d.DepthStencil.HasValue)
		{
			pso.RasterizerState.DepthBias = d.DepthStencil.Value.DepthBias;
			pso.RasterizerState.DepthBiasClamp = d.DepthStencil.Value.DepthBiasClamp;
			pso.RasterizerState.SlopeScaledDepthBias = d.DepthStencil.Value.DepthBiasSlopeScale;
		}

		Span<ColorTargetState> targets = d.Fragment.HasValue ? d.Fragment.Value.Targets : default;

		pso.BlendState.AlphaToCoverageEnable = d.Multisample.AlphaToCoverageEnabled ? TRUE : FALSE;
		pso.BlendState.IndependentBlendEnable = (targets.Length > 1) ? TRUE : FALSE;

		for (int i = 0; (i < targets.Length) && (i < 8); i++)
		{
			let t = targets[i];
			pso.BlendState.RenderTarget[i].RenderTargetWriteMask = (uint8)t.WriteMask;
			if (t.Blend.HasValue)
			{
				let blend = t.Blend.Value;
				pso.BlendState.RenderTarget[i].BlendEnable = TRUE;
				pso.BlendState.RenderTarget[i].SrcBlend =
					DxConversions.ToBlendFactor(blend.Color.SrcFactor);
				pso.BlendState.RenderTarget[i].DestBlend =
					DxConversions.ToBlendFactor(blend.Color.DstFactor);
				pso.BlendState.RenderTarget[i].BlendOp =
					DxConversions.ToBlendOp(blend.Color.Operation);
				pso.BlendState.RenderTarget[i].SrcBlendAlpha =
					DxConversions.ToBlendFactor(blend.Alpha.SrcFactor);
				pso.BlendState.RenderTarget[i].DestBlendAlpha =
					DxConversions.ToBlendFactor(blend.Alpha.DstFactor);
				pso.BlendState.RenderTarget[i].BlendOpAlpha =
					DxConversions.ToBlendOp(blend.Alpha.Operation);
			}
		}

		if (d.DepthStencil.HasValue)
		{
			let ds = d.DepthStencil.Value;
			pso.DepthStencilState.DepthEnable = ds.DepthTestEnabled ? TRUE : FALSE;
			pso.DepthStencilState.DepthWriteMask = ds.DepthWriteEnabled
				? .D3D12_DEPTH_WRITE_MASK_ALL
				: .D3D12_DEPTH_WRITE_MASK_ZERO;
			pso.DepthStencilState.DepthFunc = DxConversions.ToComparisonFunc(ds.DepthCompare);
			pso.DepthStencilState.StencilEnable = ds.StencilEnabled ? TRUE : FALSE;
			pso.DepthStencilState.StencilReadMask = ds.StencilReadMask;
			pso.DepthStencilState.StencilWriteMask = ds.StencilWriteMask;

			pso.DepthStencilState.FrontFace.StencilFailOp =
				DxConversions.ToStencilOp(ds.StencilFront.FailOp);
			pso.DepthStencilState.FrontFace.StencilDepthFailOp =
				DxConversions.ToStencilOp(ds.StencilFront.DepthFailOp);
			pso.DepthStencilState.FrontFace.StencilPassOp =
				DxConversions.ToStencilOp(ds.StencilFront.PassOp);
			pso.DepthStencilState.FrontFace.StencilFunc =
				DxConversions.ToComparisonFunc(ds.StencilFront.Compare);

			pso.DepthStencilState.BackFace.StencilFailOp =
				DxConversions.ToStencilOp(ds.StencilBack.FailOp);
			pso.DepthStencilState.BackFace.StencilDepthFailOp =
				DxConversions.ToStencilOp(ds.StencilBack.DepthFailOp);
			pso.DepthStencilState.BackFace.StencilPassOp =
				DxConversions.ToStencilOp(ds.StencilBack.PassOp);
			pso.DepthStencilState.BackFace.StencilFunc =
				DxConversions.ToComparisonFunc(ds.StencilBack.Compare);

			pso.DSVFormat = DxConversions.ToDxgiFormat(ds.Format);
		}

		pso.NumRenderTargets = (uint32)Math.Min(targets.Length, 8);
		for (int i = 0; (i < targets.Length) && (i < 8); i++)
			pso.RTVFormats[i] = DxConversions.ToDxgiFormat(targets[i].Format);

		pso.SampleDesc.Count = Math.Max(d.Multisample.Count, 1);
		pso.SampleMask = (d.Multisample.Mask != 0) ? d.Multisample.Mask : uint32.MaxValue;

		let hr = device.CreateGraphicsPipelineState(&pso, ID3D12PipelineState.IID,
			(void**)&mPipelineState);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxRenderPipeline: CreateGraphicsPipelineState failed (0x{0:X8})",
				(uint32)hr);
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup()
	{
		if (mPipelineState != null)
		{
			mPipelineState.Release();
			mPipelineState = null;
		}
	}
}

#endif // BF_PLATFORM_WINDOWS
