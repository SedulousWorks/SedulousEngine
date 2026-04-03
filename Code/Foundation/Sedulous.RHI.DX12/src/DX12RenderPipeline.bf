namespace Sedulous.RHI.DX12;

using System;
using System.Collections;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Sedulous.RHI;
using Win32.Graphics.Direct3D;

using static Sedulous.RHI.TextureFormatExt;

/// DX12 implementation of IRenderPipeline.
/// Wraps a D3D12 graphics pipeline state object.
class DX12RenderPipeline : IRenderPipeline
{
	private ID3D12PipelineState* mPipelineState;
	private DX12PipelineLayout mLayout;
	private D3D_PRIMITIVE_TOPOLOGY mTopology;
	private uint32[8] mVertexStrides;
	private int mVertexBufferCount;

	public IPipelineLayout Layout => mLayout;

	public this() { }

	public Result<void> Init(DX12Device device, RenderPipelineDesc desc)
	{
		mLayout = desc.Layout as DX12PipelineLayout;
		if (mLayout == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12RenderPipeline: pipeline layout is null");
			return .Err;
		}

		D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = default;
		psoDesc.pRootSignature = mLayout.Handle;

		// Shader stages
		if (let vsMod = desc.Vertex.Shader.Module as DX12ShaderModule)
		{
			psoDesc.VS.pShaderBytecode = vsMod.Bytecode.Ptr;
			psoDesc.VS.BytecodeLength = (uint)vsMod.Bytecode.Length;
		}
		else
		{
			System.Diagnostics.Debug.WriteLine("DX12RenderPipeline: vertex shader module is null");
			return .Err;
		}

		if (desc.Fragment != null)
		{
			let frag = desc.Fragment.Value;
			if (let psMod = frag.Shader.Module as DX12ShaderModule)
			{
				psoDesc.PS.pShaderBytecode = psMod.Bytecode.Ptr;
				psoDesc.PS.BytecodeLength = (uint)psMod.Bytecode.Length;
			}
		}

		// Input layout
		List<D3D12_INPUT_ELEMENT_DESC> inputElements = scope .();
		for (int i = 0; i < desc.Vertex.Buffers.Length; i++)
		{
			let buf = desc.Vertex.Buffers[i];
			for (let attr in buf.Attributes)
			{
				D3D12_INPUT_ELEMENT_DESC elem = default;
				// Use TEXCOORD as generic semantic for all attributes, indexed by location
				elem.SemanticName = (.)"TEXCOORD";
				elem.SemanticIndex = attr.ShaderLocation;
				elem.Format = DX12Conversions.ToDxgiVertexFormat(attr.Format);
				elem.InputSlot = (uint32)i;
				elem.AlignedByteOffset = attr.Offset;
				elem.InputSlotClass = (buf.StepMode == .Instance)
					? .D3D12_INPUT_CLASSIFICATION_PER_INSTANCE_DATA
					: .D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA;
				elem.InstanceDataStepRate = (buf.StepMode == .Instance) ? 1 : 0;
				inputElements.Add(elem);
			}
		}
		psoDesc.InputLayout.pInputElementDescs = inputElements.Ptr;
		psoDesc.InputLayout.NumElements = (uint32)inputElements.Count;

		// Store vertex buffer strides for SetVertexBuffer
		mVertexBufferCount = Math.Min(desc.Vertex.Buffers.Length, 8);
		for (int i = 0; i < mVertexBufferCount; i++)
			mVertexStrides[i] = desc.Vertex.Buffers[i].Stride;

		// Primitive topology type
		psoDesc.PrimitiveTopologyType = DX12Conversions.ToPrimitiveTopologyType(desc.Primitive.Topology);
		mTopology = ToD3DTopology(desc.Primitive.Topology);

		// Rasterizer state
		psoDesc.RasterizerState.FillMode = DX12Conversions.ToFillMode(desc.Primitive.FillMode);
		psoDesc.RasterizerState.CullMode = DX12Conversions.ToCullMode(desc.Primitive.CullMode);
		psoDesc.RasterizerState.FrontCounterClockwise = (desc.Primitive.FrontFace == .CCW) ? 1 : 0;
		psoDesc.RasterizerState.DepthClipEnable = desc.Primitive.DepthClipEnabled ? 1 : 0;
		psoDesc.RasterizerState.MultisampleEnable = (desc.Multisample.Count > 1) ? 1 : 0;

		if (desc.DepthStencil != null)
		{
			let ds = desc.DepthStencil.Value;
			psoDesc.RasterizerState.DepthBias = ds.DepthBias;
			psoDesc.RasterizerState.DepthBiasClamp = ds.DepthBiasClamp;
			psoDesc.RasterizerState.SlopeScaledDepthBias = ds.DepthBiasSlopeScale;
		}

		// Blend state
		let colorTargets = (desc.Fragment != null) ? desc.Fragment.Value.Targets : Span<ColorTargetState>();
		psoDesc.BlendState.AlphaToCoverageEnable = desc.Multisample.AlphaToCoverageEnabled ? 1 : 0;
		psoDesc.BlendState.IndependentBlendEnable = (colorTargets.Length > 1) ? 1 : 0;

		for (int i = 0; i < colorTargets.Length && i < 8; i++)
		{
			let target = colorTargets[i];
			ref D3D12_RENDER_TARGET_BLEND_DESC rtBlend = ref psoDesc.BlendState.RenderTarget[i];

			rtBlend.RenderTargetWriteMask = (uint8)target.WriteMask;

			if (target.Blend != null)
			{
				let blend = target.Blend.Value;
				rtBlend.BlendEnable = 1;
				rtBlend.SrcBlend = DX12Conversions.ToBlendFactor(blend.Color.SrcFactor);
				rtBlend.DestBlend = DX12Conversions.ToBlendFactor(blend.Color.DstFactor);
				rtBlend.BlendOp = DX12Conversions.ToBlendOp(blend.Color.Operation);
				rtBlend.SrcBlendAlpha = DX12Conversions.ToBlendFactor(blend.Alpha.SrcFactor);
				rtBlend.DestBlendAlpha = DX12Conversions.ToBlendFactor(blend.Alpha.DstFactor);
				rtBlend.BlendOpAlpha = DX12Conversions.ToBlendOp(blend.Alpha.Operation);
			}
			else
			{
				rtBlend.RenderTargetWriteMask = (uint8)target.WriteMask;
			}
		}

		// Depth/stencil state
		if (desc.DepthStencil != null)
		{
			let ds = desc.DepthStencil.Value;
			psoDesc.DepthStencilState.DepthEnable = ds.DepthTestEnabled ? 1 : 0;
			psoDesc.DepthStencilState.DepthWriteMask = ds.DepthWriteEnabled
				? .D3D12_DEPTH_WRITE_MASK_ALL
				: .D3D12_DEPTH_WRITE_MASK_ZERO;
			psoDesc.DepthStencilState.DepthFunc = DX12Conversions.ToComparisonFunc(ds.DepthCompare);
			psoDesc.DepthStencilState.StencilEnable = ds.StencilEnabled ? 1 : 0;
			psoDesc.DepthStencilState.StencilReadMask = ds.StencilReadMask;
			psoDesc.DepthStencilState.StencilWriteMask = ds.StencilWriteMask;

			psoDesc.DepthStencilState.FrontFace.StencilFailOp = DX12Conversions.ToStencilOp(ds.StencilFront.FailOp);
			psoDesc.DepthStencilState.FrontFace.StencilDepthFailOp = DX12Conversions.ToStencilOp(ds.StencilFront.DepthFailOp);
			psoDesc.DepthStencilState.FrontFace.StencilPassOp = DX12Conversions.ToStencilOp(ds.StencilFront.PassOp);
			psoDesc.DepthStencilState.FrontFace.StencilFunc = DX12Conversions.ToComparisonFunc(ds.StencilFront.Compare);

			psoDesc.DepthStencilState.BackFace.StencilFailOp = DX12Conversions.ToStencilOp(ds.StencilBack.FailOp);
			psoDesc.DepthStencilState.BackFace.StencilDepthFailOp = DX12Conversions.ToStencilOp(ds.StencilBack.DepthFailOp);
			psoDesc.DepthStencilState.BackFace.StencilPassOp = DX12Conversions.ToStencilOp(ds.StencilBack.PassOp);
			psoDesc.DepthStencilState.BackFace.StencilFunc = DX12Conversions.ToComparisonFunc(ds.StencilBack.Compare);

			psoDesc.DSVFormat = DX12Conversions.ToDxgiFormat(ds.Format);
		}

		// Render targets
		psoDesc.NumRenderTargets = (uint32)Math.Min(colorTargets.Length, 8);
		for (int i = 0; i < colorTargets.Length && i < 8; i++)
			psoDesc.RTVFormats[i] = DX12Conversions.ToDxgiFormat(colorTargets[i].Format);

		// Multisample (Count must be >= 1; default-initialized structs may have 0)
		psoDesc.SampleDesc.Count = Math.Max(desc.Multisample.Count, 1);
		psoDesc.SampleDesc.Quality = 0;
		psoDesc.SampleMask = (desc.Multisample.Mask != 0) ? desc.Multisample.Mask : uint32.MaxValue;

		// Try loading from pipeline library first, then create fresh
		let dxCache = desc.Cache as DX12PipelineCache;
		if (dxCache != null && dxCache.Handle != null && desc.Label.Length > 0)
		{
			let nameStr = scope String();
			nameStr.Append(desc.Label);
			let wideName = nameStr.ToScopedNativeWChar!();
			HRESULT hr = dxCache.Handle.LoadGraphicsPipeline(wideName, &psoDesc,
				ID3D12PipelineState.IID, (void**)&mPipelineState);
			if (SUCCEEDED(hr))
				return .Ok;
		}

		// Create PSO
		HRESULT hr = device.Handle.CreateGraphicsPipelineState(&psoDesc,
			ID3D12PipelineState.IID, (void**)&mPipelineState);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12RenderPipeline: CreateGraphicsPipelineState failed (0x{hr:X})");
			return .Err;
		}

		// Store in pipeline library for future loads
		if (dxCache != null && dxCache.Handle != null && desc.Label.Length > 0)
		{
			let nameStr = scope String();
			nameStr.Append(desc.Label);
			let wideName = nameStr.ToScopedNativeWChar!();
			dxCache.Handle.StorePipeline(wideName, mPipelineState);
		}

		return .Ok;
	}

	public void Cleanup(DX12Device device)
	{
		if (mPipelineState != null)
		{
			mPipelineState.Release();
			mPipelineState = null;
		}
	}

	private static D3D_PRIMITIVE_TOPOLOGY ToD3DTopology(PrimitiveTopology topology)
	{
		switch (topology)
		{
		case .PointList:     return .D3D_PRIMITIVE_TOPOLOGY_POINTLIST;
		case .LineList:      return .D3D_PRIMITIVE_TOPOLOGY_LINELIST;
		case .LineStrip:     return .D3D_PRIMITIVE_TOPOLOGY_LINESTRIP;
		case .TriangleList:  return .D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
		case .TriangleStrip: return .D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP;
		}
	}

	// --- Internal ---
	public ID3D12PipelineState* Handle => mPipelineState;
	public D3D_PRIMITIVE_TOPOLOGY Topology => mTopology;
	public uint32 GetVertexStride(uint32 slot) => (slot < (uint32)mVertexBufferCount) ? mVertexStrides[slot] : 0;
}
