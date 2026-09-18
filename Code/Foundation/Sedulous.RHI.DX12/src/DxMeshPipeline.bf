using System;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;

namespace Sedulous.RHI.DX12;

/// One mesh shading pipeline.
///
/// Mesh pipelines cannot be described by D3D12_GRAPHICS_PIPELINE_STATE_DESC, which has no room
/// for a mesh or amplification stage. They go through the STATE STREAM instead: a flat byte
/// buffer of tagged subobjects, each an eight byte aligned type tag followed by its value.
/// That is why this builds a buffer by hand rather than filling a struct.
///
/// The stream API lives on ID3D12Device2, so the device is queried for it.
class DxMeshPipeline : IMeshPipeline
{
	private ID3D12PipelineState* mPipelineState = null; // owned, released in Cleanup
	private DxPipelineLayout mLayout = null; // NOT owned

	public IPipelineLayout Layout => mLayout;
	public ID3D12PipelineState* Handle => mPipelineState;
	public DxPipelineLayout PipelineLayout => mLayout;

	public Result<void> Initialize(ID3D12Device* device, MeshPipelineDesc desc)
	{
		mLayout = desc.Layout as DxPipelineLayout;
		if (mLayout == null)
		{
			GlobalLog(.Error, "DxMeshPipeline: the pipeline layout is null");
			return .Err;
		}

		ID3D12Device2* device2 = null;
		let qiHr = device.QueryInterface(ID3D12Device2.IID, (void**)&device2);
		if (FAILED(qiHr) || (device2 == null))
		{
			GlobalLog(.Error,
				"DxMeshPipeline: QueryInterface for ID3D12Device2 failed (0x{0:X8})", (uint32)qiHr);
			return .Err;
		}
		defer device2.Release();

		// Subobjects packed in order: root signature, MS, optional AS, optional PS, blend,
		// sample mask, rasteriser, optional depth stencil and its format, RT formats, samples.
		uint8[2048] streamBuffer = .();
		int offset = 0;

		// The root signature is a POINTER subobject, so it cannot go through the generic
		// writer: what is stored is the pointer, not the object.
		{
			offset = (offset + 7) & ~7;
			var type = D3D12_PIPELINE_STATE_SUBOBJECT_TYPE.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_ROOT_SIGNATURE;
			Internal.MemCpy(&streamBuffer[offset], &type,
				sizeof(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE));
			offset += sizeof(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE);
			offset = (offset + 7) & ~7; // pointer align
			var rootSig = mLayout.Handle;
			Internal.MemCpy(&streamBuffer[offset], &rootSig, sizeof(ID3D12RootSignature*));
			offset += sizeof(ID3D12RootSignature*);
		}

		let msMod = desc.Mesh.Module as DxShaderModule;
		if (msMod == null)
		{
			GlobalLog(.Error, "DxMeshPipeline: the mesh shader module is null");
			return .Err;
		}

		{
			let msCode = msMod.Bytecode;
			D3D12_SHADER_BYTECODE msBC = .();
			msBC.pShaderBytecode = msCode.Ptr;
			msBC.BytecodeLength = (uint)msCode.Length;
			WriteSubobject(&streamBuffer[0], ref offset,
				.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_MS, msBC);
		}

		if (desc.Task.HasValue)
		{
			if (let asMod = desc.Task.Value.Module as DxShaderModule)
			{
				let asCode = asMod.Bytecode;
				D3D12_SHADER_BYTECODE asBC = .();
				asBC.pShaderBytecode = asCode.Ptr;
				asBC.BytecodeLength = (uint)asCode.Length;
				WriteSubobject(&streamBuffer[0], ref offset,
					.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_AS, asBC);
			}
		}

		if (desc.Fragment.HasValue)
		{
			if (let psMod = desc.Fragment.Value.Shader.Module as DxShaderModule)
			{
				let psCode = psMod.Bytecode;
				D3D12_SHADER_BYTECODE psBC = .();
				psBC.pShaderBytecode = psCode.Ptr;
				psBC.BytecodeLength = (uint)psCode.Length;
				WriteSubobject(&streamBuffer[0], ref offset,
					.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_PS, psBC);
			}
		}

		let colorTargets = desc.ColorTargets;

		D3D12_BLEND_DESC blendDesc = .();
		blendDesc.AlphaToCoverageEnable = desc.Multisample.AlphaToCoverageEnabled ? TRUE : FALSE;
		blendDesc.IndependentBlendEnable = (colorTargets.Length > 1) ? TRUE : FALSE;
		for (int i = 0; (i < colorTargets.Length) && (i < 8); i++)
		{
			let t = colorTargets[i];
			blendDesc.RenderTarget[i].RenderTargetWriteMask = (uint8)t.WriteMask;
			if (t.Blend.HasValue)
			{
				let blend = t.Blend.Value;
				blendDesc.RenderTarget[i].BlendEnable = TRUE;
				blendDesc.RenderTarget[i].SrcBlend = DxConversions.ToBlendFactor(blend.Color.SrcFactor);
				blendDesc.RenderTarget[i].DestBlend = DxConversions.ToBlendFactor(blend.Color.DstFactor);
				blendDesc.RenderTarget[i].BlendOp = DxConversions.ToBlendOp(blend.Color.Operation);
				blendDesc.RenderTarget[i].SrcBlendAlpha = DxConversions.ToBlendFactor(blend.Alpha.SrcFactor);
				blendDesc.RenderTarget[i].DestBlendAlpha = DxConversions.ToBlendFactor(blend.Alpha.DstFactor);
				blendDesc.RenderTarget[i].BlendOpAlpha = DxConversions.ToBlendOp(blend.Alpha.Operation);
			}
		}
		WriteSubobject(&streamBuffer[0], ref offset,
			.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_BLEND, blendDesc);

		uint32 sampleMask = (desc.Multisample.Mask != 0) ? desc.Multisample.Mask : uint32.MaxValue;
		WriteSubobject(&streamBuffer[0], ref offset,
			.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SAMPLE_MASK, sampleMask);

		D3D12_RASTERIZER_DESC rasterDesc = .();
		rasterDesc.FillMode = DxConversions.ToFillMode(desc.Primitive.FillMode);
		rasterDesc.CullMode = DxConversions.ToCullMode(desc.Primitive.CullMode);
		rasterDesc.FrontCounterClockwise = (desc.Primitive.FrontFace == .CCW) ? TRUE : FALSE;
		rasterDesc.DepthClipEnable = desc.Primitive.DepthClipEnabled ? TRUE : FALSE;
		rasterDesc.MultisampleEnable = (desc.Multisample.Count > 1) ? TRUE : FALSE;
		if (desc.DepthStencil.HasValue)
		{
			rasterDesc.DepthBias = desc.DepthStencil.Value.DepthBias;
			rasterDesc.DepthBiasClamp = desc.DepthStencil.Value.DepthBiasClamp;
			rasterDesc.SlopeScaledDepthBias = desc.DepthStencil.Value.DepthBiasSlopeScale;
		}
		WriteSubobject(&streamBuffer[0], ref offset,
			.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_RASTERIZER, rasterDesc);

		if (desc.DepthStencil.HasValue)
		{
			let ds = desc.DepthStencil.Value;

			D3D12_DEPTH_STENCIL_DESC dsDesc = .();
			dsDesc.DepthEnable = ds.DepthTestEnabled ? TRUE : FALSE;
			dsDesc.DepthWriteMask = ds.DepthWriteEnabled
				? .D3D12_DEPTH_WRITE_MASK_ALL
				: .D3D12_DEPTH_WRITE_MASK_ZERO;
			dsDesc.DepthFunc = DxConversions.ToComparisonFunc(ds.DepthCompare);
			dsDesc.StencilEnable = ds.StencilEnabled ? TRUE : FALSE;
			dsDesc.StencilReadMask = ds.StencilReadMask;
			dsDesc.StencilWriteMask = ds.StencilWriteMask;

			dsDesc.FrontFace.StencilFailOp = DxConversions.ToStencilOp(ds.StencilFront.FailOp);
			dsDesc.FrontFace.StencilDepthFailOp = DxConversions.ToStencilOp(ds.StencilFront.DepthFailOp);
			dsDesc.FrontFace.StencilPassOp = DxConversions.ToStencilOp(ds.StencilFront.PassOp);
			dsDesc.FrontFace.StencilFunc = DxConversions.ToComparisonFunc(ds.StencilFront.Compare);

			dsDesc.BackFace.StencilFailOp = DxConversions.ToStencilOp(ds.StencilBack.FailOp);
			dsDesc.BackFace.StencilDepthFailOp = DxConversions.ToStencilOp(ds.StencilBack.DepthFailOp);
			dsDesc.BackFace.StencilPassOp = DxConversions.ToStencilOp(ds.StencilBack.PassOp);
			dsDesc.BackFace.StencilFunc = DxConversions.ToComparisonFunc(ds.StencilBack.Compare);

			WriteSubobject(&streamBuffer[0], ref offset,
				.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL, dsDesc);

			var dsFormat = DxConversions.ToDxgiFormat(ds.Format);
			WriteSubobject(&streamBuffer[0], ref offset,
				.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL_FORMAT, dsFormat);
		}

		D3D12_RT_FORMAT_ARRAY rtFormats = .();
		rtFormats.NumRenderTargets = (uint32)Math.Min(colorTargets.Length, 8);
		for (int i = 0; (i < colorTargets.Length) && (i < 8); i++)
			rtFormats.RTFormats[i] = DxConversions.ToDxgiFormat(colorTargets[i].Format);
		WriteSubobject(&streamBuffer[0], ref offset,
			.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_RENDER_TARGET_FORMATS, rtFormats);

		DXGI_SAMPLE_DESC sampleDesc = .();
		sampleDesc.Count = Math.Max(desc.Multisample.Count, 1);
		sampleDesc.Quality = 0;
		WriteSubobject(&streamBuffer[0], ref offset,
			.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SAMPLE_DESC, sampleDesc);

		D3D12_PIPELINE_STATE_STREAM_DESC streamDesc = .();
		streamDesc.SizeInBytes = (uint)offset;
		streamDesc.pPipelineStateSubobjectStream = &streamBuffer[0];

		let hr = device2.CreatePipelineState(&streamDesc, ID3D12PipelineState.IID,
			(void**)&mPipelineState);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxMeshPipeline: CreatePipelineState failed (0x{0:X8})", (uint32)hr);
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

	/// One subobject: an eight byte aligned type tag, then the value at its own alignment.
	private static void WriteSubobject<T>(uint8* buffer, ref int offset,
		D3D12_PIPELINE_STATE_SUBOBJECT_TYPE type, T value) where T : struct
	{
		var type;
		var value;

		offset = (offset + 7) & ~7;
		Internal.MemCpy(&buffer[offset], &type, sizeof(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE));
		offset += sizeof(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE);

		let valueAlign = alignof(T);
		offset = (offset + valueAlign - 1) & ~(valueAlign - 1);
		Internal.MemCpy(&buffer[offset], &value, sizeof(T));
		offset += sizeof(T);
	}
}
