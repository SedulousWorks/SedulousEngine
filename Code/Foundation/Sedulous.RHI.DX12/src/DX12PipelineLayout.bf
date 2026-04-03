namespace Sedulous.RHI.DX12;

using System;
using System.Collections;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// Tracks the root parameter index for a dynamic offset binding.
struct DynamicRootEntry
{
	public uint32 GroupIndex;
	public uint32 DynamicIndex; // Index within this group's dynamic bindings
	public int32 RootParamIndex;
	public D3D12_ROOT_PARAMETER_TYPE ParamType;
}

/// DX12 implementation of IPipelineLayout.
/// Wraps an ID3D12RootSignature created from bind group layouts and push constant ranges.
class DX12PipelineLayout : IPipelineLayout
{
	private ID3D12RootSignature* mRootSignature;

	/// Maps (groupIndex, isSampler) -> root parameter index for descriptor tables.
	/// Layout: [group0_cbvSrvUav, group0_sampler, group1_cbvSrvUav, group1_sampler, ...]
	/// -1 means no root parameter for that slot.
	private int32[] mRootParamMap;

	/// Maps (groupIndex, dynamicIndex) -> root parameter index for root descriptors.
	/// Dynamic offset bindings use root CBV/SRV/UAV instead of descriptor tables.
	private List<DynamicRootEntry> mDynamicRootEntries = new .() ~ delete _;

	/// Root parameter index where push constants start.
	private int32 mPushConstantRootIndex = -1;
	private uint32 mNumBindGroups;

	public this() { }

	public Result<void> Init(DX12Device device, PipelineLayoutDesc desc)
	{
		mNumBindGroups = (uint32)desc.BindGroupLayouts.Length;

		List<D3D12_ROOT_PARAMETER> rootParams = scope .();
		List<D3D12_DESCRIPTOR_RANGE[]> rangeStorage = scope .(); // Keep ranges alive

		mRootParamMap = new int32[desc.BindGroupLayouts.Length * 2];
		for (int i = 0; i < mRootParamMap.Count; i++)
			mRootParamMap[i] = -1;

		// For each bind group, create descriptor table parameters
		for (int groupIdx = 0; groupIdx < desc.BindGroupLayouts.Length; groupIdx++)
		{
			let layout = desc.BindGroupLayouts[groupIdx] as DX12BindGroupLayout;
			if (layout == null)
			{
				System.Diagnostics.Debug.WriteLine("DX12PipelineLayout: BindGroupLayout at index {} is not a DX12BindGroupLayout", groupIdx);
				return .Err;
			}

			// Collect CBV/SRV/UAV and sampler ranges (excluding dynamic offset bindings)
			List<D3D12_DESCRIPTOR_RANGE> cbvSrvUavRanges = scope .();
			List<D3D12_DESCRIPTOR_RANGE> samplerRanges = scope .();
			uint32 dynamicIdx = 0;

			for (let range in layout.Ranges)
			{
				// Dynamic offset bindings get their own root descriptors
				if (range.HasDynamicOffset)
				{
					D3D12_ROOT_PARAMETER_TYPE paramType;
					switch (range.Type)
					{
					case .UniformBuffer:
						paramType = .D3D12_ROOT_PARAMETER_TYPE_CBV;
					case .StorageBufferReadOnly:
						paramType = .D3D12_ROOT_PARAMETER_TYPE_SRV;
					case .StorageBufferReadWrite:
						paramType = .D3D12_ROOT_PARAMETER_TYPE_UAV;
					default:
						continue; // Only buffer types support dynamic offsets
					}

					D3D12_ROOT_PARAMETER param = default;
					param.ParameterType = paramType;
					param.ShaderVisibility = .D3D12_SHADER_VISIBILITY_ALL;
					param.Descriptor.ShaderRegister = range.Binding;
					param.Descriptor.RegisterSpace = (uint32)groupIdx;

					mDynamicRootEntries.Add(.()
					{
						GroupIndex = (uint32)groupIdx,
						DynamicIndex = dynamicIdx,
						RootParamIndex = (int32)rootParams.Count,
						ParamType = paramType
					});

					rootParams.Add(param);
					dynamicIdx++;
					continue;
				}

				D3D12_DESCRIPTOR_RANGE dxRange = .()
				{
					RangeType = DX12Conversions.ToDescriptorRangeType(range.Type),
					NumDescriptors = range.Count,
					BaseShaderRegister = range.Binding,
					RegisterSpace = (uint32)groupIdx,
					OffsetInDescriptorsFromTableStart = range.HeapOffset
				};

				if (range.IsSampler)
					samplerRanges.Add(dxRange);
				else
					cbvSrvUavRanges.Add(dxRange);
			}

			// Add CBV/SRV/UAV descriptor table
			if (cbvSrvUavRanges.Count > 0)
			{
				let ranges = new D3D12_DESCRIPTOR_RANGE[cbvSrvUavRanges.Count];
				cbvSrvUavRanges.CopyTo(ranges);
				rangeStorage.Add(ranges);

				D3D12_ROOT_PARAMETER param = default;
				param.ParameterType = .D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
				param.ShaderVisibility = .D3D12_SHADER_VISIBILITY_ALL;
				param.DescriptorTable.NumDescriptorRanges = (uint32)ranges.Count;
				param.DescriptorTable.pDescriptorRanges = ranges.CArray();

				mRootParamMap[groupIdx * 2] = (int32)rootParams.Count;
				rootParams.Add(param);
			}

			// Add Sampler descriptor table
			if (samplerRanges.Count > 0)
			{
				let ranges = new D3D12_DESCRIPTOR_RANGE[samplerRanges.Count];
				samplerRanges.CopyTo(ranges);
				rangeStorage.Add(ranges);

				D3D12_ROOT_PARAMETER param = default;
				param.ParameterType = .D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
				param.ShaderVisibility = .D3D12_SHADER_VISIBILITY_ALL;
				param.DescriptorTable.NumDescriptorRanges = (uint32)ranges.Count;
				param.DescriptorTable.pDescriptorRanges = ranges.CArray();

				mRootParamMap[groupIdx * 2 + 1] = (int32)rootParams.Count;
				rootParams.Add(param);
			}
		}

		// Push constants -> root constants
		for (let pushRange in desc.PushConstantRanges)
		{
			if (mPushConstantRootIndex < 0)
				mPushConstantRootIndex = (int32)rootParams.Count;

			D3D12_ROOT_PARAMETER param = default;
			param.ParameterType = .D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;
			param.ShaderVisibility = .D3D12_SHADER_VISIBILITY_ALL;
			param.Constants.ShaderRegister = pushRange.Offset / 4;
			param.Constants.RegisterSpace = mNumBindGroups; // Use space after all bind groups to avoid collisions
			param.Constants.Num32BitValues = pushRange.Size / 4;
			rootParams.Add(param);
		}

		// Create root signature
		D3D12_ROOT_SIGNATURE_FLAGS flags =
			.D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT;

		D3D12_ROOT_SIGNATURE_DESC rsDesc = .()
		{
			NumParameters = (uint32)rootParams.Count,
			pParameters = rootParams.Ptr,
			NumStaticSamplers = 0,
			pStaticSamplers = null,
			Flags = flags
		};

		ID3DBlob* signatureBlob = null;
		ID3DBlob* errorBlob = null;
		var rsDescRef = rsDesc;
		HRESULT hr = D3D12SerializeRootSignature(&rsDescRef, .D3D_ROOT_SIGNATURE_VERSION_1,
			&signatureBlob, &errorBlob);

		// Clean up range storage
		for (let ranges in rangeStorage)
			delete ranges;

		if (!SUCCEEDED(hr))
		{
			if (errorBlob != null)
			{
				let errMsg = StringView((char8*)errorBlob.GetBufferPointer(), (int)errorBlob.GetBufferSize());
				System.Diagnostics.Debug.WriteLine("D3D12SerializeRootSignature failed: {}", errMsg);
				errorBlob.Release();
			}
			if (signatureBlob != null) signatureBlob.Release();
			return .Err;
		}
		if (errorBlob != null) errorBlob.Release();

		hr = device.Handle.CreateRootSignature(0,
			signatureBlob.GetBufferPointer(), signatureBlob.GetBufferSize(),
			ID3D12RootSignature.IID, (void**)&mRootSignature);
		signatureBlob.Release();

		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine("CreateRootSignature failed: 0x{0:X}", (uint32)hr);
			return .Err;
		}
		return .Ok;
	}

	/// Gets the root parameter index for a bind group's CBV/SRV/UAV table.
	public int32 GetCbvSrvUavRootIndex(uint32 groupIndex)
	{
		let idx = groupIndex * 2;
		if (idx >= (uint32)mRootParamMap.Count) return -1;
		return mRootParamMap[(.)idx];
	}

	/// Gets the root parameter index for a bind group's sampler table.
	public int32 GetSamplerRootIndex(uint32 groupIndex)
	{
		let idx = groupIndex * 2 + 1;
		if (idx >= (uint32)mRootParamMap.Count) return -1;
		return mRootParamMap[(.)idx];
	}

	public void Cleanup(DX12Device device)
	{
		if (mRootSignature != null)
		{
			mRootSignature.Release();
			mRootSignature = null;
		}
		if (mRootParamMap != null)
		{
			delete mRootParamMap;
			mRootParamMap = null;
		}
	}

	// --- Internal ---
	public ID3D12RootSignature* Handle => mRootSignature;
	public int32 PushConstantRootIndex => mPushConstantRootIndex;
	public uint32 NumBindGroups => mNumBindGroups;
	public List<DynamicRootEntry> DynamicRootEntries => mDynamicRootEntries;
}
