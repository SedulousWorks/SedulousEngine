namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Sedulous.RHI;

using static Sedulous.RHI.TextureFormatExt;

/// Pipeline state stream subobject wrapper.
/// Each subobject in the stream is: { D3D12_PIPELINE_STATE_SUBOBJECT_TYPE type; T value; }
/// with padding to align T naturally.
[CRepr]
struct PSSSubobject<T> where T : struct
{
	public D3D12_PIPELINE_STATE_SUBOBJECT_TYPE Type;
	public T Value;

	public this(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE type, T value)
	{
		Type = type;
		Value = value;
	}
}

/// DX12 implementation of IMeshPipeline.
/// Uses pipeline state stream (ID3D12Device2.CreatePipelineState) since
/// mesh shader pipelines cannot use the traditional D3D12_GRAPHICS_PIPELINE_STATE_DESC.
class DX12MeshPipeline : IMeshPipeline
{
	private ID3D12PipelineState* mPipelineState;
	private DX12PipelineLayout mLayout;

	public IPipelineLayout Layout => mLayout;

	public this() { }

	public Result<void> Init(DX12Device device, MeshPipelineDesc desc)
	{
		mLayout = desc.Layout as DX12PipelineLayout;
		if (mLayout == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12MeshPipeline: pipeline layout is null");
			return .Err;
		}

		// Query ID3D12Device2 for CreatePipelineState
		ID3D12Device2* device2 = null;
		HRESULT hr = device.Handle.QueryInterface(ID3D12Device2.IID, (void**)&device2);
		if (!SUCCEEDED(hr) || device2 == null)
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12MeshPipeline: QueryInterface for ID3D12Device2 failed (0x{hr:X})");
			return .Err;
		}
		defer device2.Release();

		// Build pipeline state stream as raw bytes
		// We pack subobjects sequentially: root sig, MS, [AS], [PS], blend, rasterizer, depth/stencil, RT formats, DS format, sample desc, sample mask

		// Calculate the stream inline to avoid issues with alignment
		uint8[2048] streamBuffer = default;
		int offset = 0;

		// Root signature (written manually since pointer types can't be used with WriteSubobject<T>)
		{
			offset = (offset + 7) & ~7;
			*(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE*)&streamBuffer[offset] = .D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_ROOT_SIGNATURE;
			offset += sizeof(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE);
			offset = (offset + 7) & ~7; // pointer-align
			*(ID3D12RootSignature**)&streamBuffer[offset] = mLayout.Handle;
			offset += sizeof(ID3D12RootSignature*);
		}

		// Mesh shader (required)
		if (let msMod = desc.Mesh.Module as DX12ShaderModule)
		{
			D3D12_SHADER_BYTECODE msBC = .()
			{
				pShaderBytecode = msMod.Bytecode.Ptr,
				BytecodeLength = (uint)msMod.Bytecode.Length
			};
			WriteSubobject<D3D12_SHADER_BYTECODE>(ref streamBuffer, ref offset,
				.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_MS, msBC);
		}
		else
		{
			System.Diagnostics.Debug.WriteLine("DX12MeshPipeline: mesh shader module is null");
			return .Err;
		}

		// Task/amplification shader (optional)
		if (desc.Task != null)
		{
			let task = desc.Task.Value;
			if (let asMod = task.Module as DX12ShaderModule)
			{
				D3D12_SHADER_BYTECODE asBC = .()
				{
					pShaderBytecode = asMod.Bytecode.Ptr,
					BytecodeLength = (uint)asMod.Bytecode.Length
				};
				WriteSubobject<D3D12_SHADER_BYTECODE>(ref streamBuffer, ref offset,
					.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_AS, asBC);
			}
		}

		// Fragment/pixel shader (optional)
		if (desc.Fragment != null)
		{
			let frag = desc.Fragment.Value;
			if (let psMod = frag.Module as DX12ShaderModule)
			{
				D3D12_SHADER_BYTECODE psBC = .()
				{
					pShaderBytecode = psMod.Bytecode.Ptr,
					BytecodeLength = (uint)psMod.Bytecode.Length
				};
				WriteSubobject<D3D12_SHADER_BYTECODE>(ref streamBuffer, ref offset,
					.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_PS, psBC);
			}
		}

		// Blend state
		let meshColorTargets = desc.ColorTargets;
		D3D12_BLEND_DESC blendDesc = default;
		blendDesc.AlphaToCoverageEnable = desc.Multisample.AlphaToCoverageEnabled ? 1 : 0;
		blendDesc.IndependentBlendEnable = (meshColorTargets.Length > 1) ? 1 : 0;

		for (int i = 0; i < meshColorTargets.Length && i < 8; i++)
		{
			let target = meshColorTargets[i];
			ref D3D12_RENDER_TARGET_BLEND_DESC rtBlend = ref blendDesc.RenderTarget[i];
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
		}
		WriteSubobject<D3D12_BLEND_DESC>(ref streamBuffer, ref offset,
			.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_BLEND, blendDesc);

		// Sample mask
		uint32 sampleMask = (desc.Multisample.Mask != 0) ? desc.Multisample.Mask : uint32.MaxValue;
		WriteSubobject<uint32>(ref streamBuffer, ref offset,
			.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SAMPLE_MASK, sampleMask);

		// Rasterizer state
		D3D12_RASTERIZER_DESC rasterDesc = default;
		rasterDesc.FillMode = DX12Conversions.ToFillMode(desc.Primitive.FillMode);
		rasterDesc.CullMode = DX12Conversions.ToCullMode(desc.Primitive.CullMode);
		rasterDesc.FrontCounterClockwise = (desc.Primitive.FrontFace == .CCW) ? 1 : 0;
		rasterDesc.DepthClipEnable = desc.Primitive.DepthClipEnabled ? 1 : 0;
		rasterDesc.MultisampleEnable = (desc.Multisample.Count > 1) ? 1 : 0;

		if (desc.DepthStencil != null)
		{
			let ds = desc.DepthStencil.Value;
			rasterDesc.DepthBias = ds.DepthBias;
			rasterDesc.DepthBiasClamp = ds.DepthBiasClamp;
			rasterDesc.SlopeScaledDepthBias = ds.DepthBiasSlopeScale;
		}

		WriteSubobject<D3D12_RASTERIZER_DESC>(ref streamBuffer, ref offset,
			.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_RASTERIZER, rasterDesc);

		// Depth/stencil state
		if (desc.DepthStencil != null)
		{
			let ds = desc.DepthStencil.Value;
			D3D12_DEPTH_STENCIL_DESC dsDesc = default;
			dsDesc.DepthEnable = ds.DepthTestEnabled ? 1 : 0;
			dsDesc.DepthWriteMask = ds.DepthWriteEnabled
				? .D3D12_DEPTH_WRITE_MASK_ALL
				: .D3D12_DEPTH_WRITE_MASK_ZERO;
			dsDesc.DepthFunc = DX12Conversions.ToComparisonFunc(ds.DepthCompare);
			dsDesc.StencilEnable = ds.StencilEnabled ? 1 : 0;
			dsDesc.StencilReadMask = ds.StencilReadMask;
			dsDesc.StencilWriteMask = ds.StencilWriteMask;

			dsDesc.FrontFace.StencilFailOp = DX12Conversions.ToStencilOp(ds.StencilFront.FailOp);
			dsDesc.FrontFace.StencilDepthFailOp = DX12Conversions.ToStencilOp(ds.StencilFront.DepthFailOp);
			dsDesc.FrontFace.StencilPassOp = DX12Conversions.ToStencilOp(ds.StencilFront.PassOp);
			dsDesc.FrontFace.StencilFunc = DX12Conversions.ToComparisonFunc(ds.StencilFront.Compare);

			dsDesc.BackFace.StencilFailOp = DX12Conversions.ToStencilOp(ds.StencilBack.FailOp);
			dsDesc.BackFace.StencilDepthFailOp = DX12Conversions.ToStencilOp(ds.StencilBack.DepthFailOp);
			dsDesc.BackFace.StencilPassOp = DX12Conversions.ToStencilOp(ds.StencilBack.PassOp);
			dsDesc.BackFace.StencilFunc = DX12Conversions.ToComparisonFunc(ds.StencilBack.Compare);

			WriteSubobject<D3D12_DEPTH_STENCIL_DESC>(ref streamBuffer, ref offset,
				.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL, dsDesc);

			// Depth/stencil format
			let dsFormat = DX12Conversions.ToDxgiFormat(ds.Format);
			WriteSubobject<DXGI_FORMAT>(ref streamBuffer, ref offset,
				.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL_FORMAT, dsFormat);
		}

		// Render target formats
		D3D12_RT_FORMAT_ARRAY rtFormats = default;
		rtFormats.NumRenderTargets = (uint32)Math.Min(meshColorTargets.Length, 8);
		for (int i = 0; i < meshColorTargets.Length && i < 8; i++)
			rtFormats.RTFormats[i] = DX12Conversions.ToDxgiFormat(meshColorTargets[i].Format);

		WriteSubobject<D3D12_RT_FORMAT_ARRAY>(ref streamBuffer, ref offset,
			.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_RENDER_TARGET_FORMATS, rtFormats);

		// Sample desc
		DXGI_SAMPLE_DESC sampleDesc = .()
		{
			Count = Math.Max(desc.Multisample.Count, 1),
			Quality = 0
		};
		WriteSubobject<DXGI_SAMPLE_DESC>(ref streamBuffer, ref offset,
			.D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SAMPLE_DESC, sampleDesc);

		// Create pipeline state
		D3D12_PIPELINE_STATE_STREAM_DESC streamDesc = .()
		{
			SizeInBytes = (uint)offset,
			pPipelineStateSubobjectStream = &streamBuffer[0]
		};

		hr = device2.CreatePipelineState(&streamDesc, ID3D12PipelineState.IID, (void**)&mPipelineState);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12MeshPipeline: CreatePipelineState failed (0x{hr:X})");
			return .Err;
		}

		return .Ok;
	}

	/// Writes a pipeline state stream subobject into the buffer.
	/// Each subobject is: { type (aligned to pointer size), value }
	private static void WriteSubobject<T>(ref uint8[2048] buffer, ref int offset,
		D3D12_PIPELINE_STATE_SUBOBJECT_TYPE type, T value) where T : struct
	{
		// Align to pointer size (8 bytes on 64-bit)
		offset = (offset + 7) & ~7;

		// Write type
		*(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE*)&buffer[offset] = type;
		offset += sizeof(D3D12_PIPELINE_STATE_SUBOBJECT_TYPE);

		// Pad to align value to its natural alignment within the subobject
		// (the outer subobject start is already 8-byte aligned; the inner value uses natural alignment)
		int valueAlign = alignof(T);
		offset = (offset + valueAlign - 1) & ~(valueAlign - 1);

		// Write value
		*(T*)&buffer[offset] = value;
		offset += sizeof(T);
	}

	public void Cleanup(DX12Device device)
	{
		if (mPipelineState != null)
		{
			mPipelineState.Release();
			mPipelineState = null;
		}
	}

	// --- Internal ---
	public ID3D12PipelineState* Handle => mPipelineState;
}
