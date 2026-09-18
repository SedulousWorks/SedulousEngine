#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// The root signature: every bind group flattened into D3D12 root parameters.
///
/// A group becomes up to TWO descriptor tables, one for CBV/SRV/UAV and one for samplers,
/// because those come from different heaps. Bindings with dynamic offsets are lifted OUT of
/// the tables into root descriptors, since a root descriptor's address is set per draw and a
/// table's is not. Push constants become root 32 bit constants in the space just past the
/// last group.
///
/// The map from group index to root parameter is kept because nothing else can recover it:
/// a group with no CBV/SRV/UAV bindings contributes no table and the indices stop matching.
class DxPipelineLayout : IPipelineLayout
{
	private ID3D12RootSignature* mRootSig = null; // owned, released in Cleanup
	private List<int32> mRootParamMap = new .() ~ delete _;
	private List<DynamicRootEntry> mDynamicRootEntries = new .() ~ delete _;
	private int32 mPushConstantRootIndex = -1;
	private uint32 mNumBindGroups = 0;

	public ID3D12RootSignature* Handle => mRootSig;
	public int32 PushConstantRootIndex => mPushConstantRootIndex;
	public uint32 NumBindGroups => mNumBindGroups;
	public Span<DynamicRootEntry> DynamicRootEntries => mDynamicRootEntries;

	public int32 GetCbvSrvUavRootIndex(uint32 gi) =>
		((int)gi * 2 < mRootParamMap.Count) ? mRootParamMap[(int)gi * 2] : -1;

	public int32 GetSamplerRootIndex(uint32 gi) =>
		((int)gi * 2 + 1 < mRootParamMap.Count) ? mRootParamMap[(int)gi * 2 + 1] : -1;

	public Result<void> Initialize(ID3D12Device* device, PipelineLayoutDesc d)
	{
		mNumBindGroups = (uint32)d.BindGroupLayouts.Length;

		let rootParams = scope List<D3D12_ROOT_PARAMETER>();

		mRootParamMap.Clear();
		mRootParamMap.Resize(d.BindGroupLayouts.Length * 2, -1);

		for (int gi = 0; gi < d.BindGroupLayouts.Length; gi++)
		{
			let layout = d.BindGroupLayouts[gi] as DxBindGroupLayout;
			if (layout == null)
				return .Err;

			// METHOD scoped, not loop scoped. A root parameter points AT this memory and it
			// has to still be there when the signature is serialised below.
			let csvRanges = scope:: List<D3D12_DESCRIPTOR_RANGE>();
			let sampRanges = scope:: List<D3D12_DESCRIPTOR_RANGE>();
			uint32 dynIdx = 0;

			for (let r in layout.Ranges)
			{
				if (r.HasDynamicOffset)
				{
					D3D12_ROOT_PARAMETER_TYPE pt;
					switch (r.Type)
					{
					case .UniformBuffer:
						pt = .D3D12_ROOT_PARAMETER_TYPE_CBV;
					case .StorageBufferReadOnly:
						pt = .D3D12_ROOT_PARAMETER_TYPE_SRV;
					case .StorageBufferReadWrite:
						pt = .D3D12_ROOT_PARAMETER_TYPE_UAV;
					default:
						continue; // only buffers can be root descriptors
					}

					D3D12_ROOT_PARAMETER p = .();
					p.ParameterType = pt;
					p.ShaderVisibility = .D3D12_SHADER_VISIBILITY_ALL;
					p.Descriptor.ShaderRegister = r.Binding;
					p.Descriptor.RegisterSpace = (uint32)gi;

					DynamicRootEntry entry = .();
					entry.GroupIndex = (uint32)gi;
					entry.DynamicIndex = dynIdx;
					entry.RootParamIndex = (int32)rootParams.Count;
					entry.ParamType = pt;
					mDynamicRootEntries.Add(entry);

					rootParams.Add(p);
					dynIdx++;
					continue;
				}

				D3D12_DESCRIPTOR_RANGE dr = .();
				dr.RangeType = DxConversions.ToDescriptorRangeType(r.Type);
				dr.NumDescriptors = r.Count;
				dr.BaseShaderRegister = r.Binding;
				dr.RegisterSpace = (uint32)gi;
				dr.OffsetInDescriptorsFromTableStart = r.HeapOffset;

				if (r.IsSampler)
					sampRanges.Add(dr);
				else
					csvRanges.Add(dr);
			}

			if (!csvRanges.IsEmpty)
			{
				D3D12_ROOT_PARAMETER p = .();
				p.ParameterType = .D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
				p.ShaderVisibility = .D3D12_SHADER_VISIBILITY_ALL;
				p.DescriptorTable.NumDescriptorRanges = (uint32)csvRanges.Count;
				p.DescriptorTable.pDescriptorRanges = csvRanges.Ptr;
				mRootParamMap[gi * 2] = (int32)rootParams.Count;
				rootParams.Add(p);
			}

			if (!sampRanges.IsEmpty)
			{
				D3D12_ROOT_PARAMETER p = .();
				p.ParameterType = .D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
				p.ShaderVisibility = .D3D12_SHADER_VISIBILITY_ALL;
				p.DescriptorTable.NumDescriptorRanges = (uint32)sampRanges.Count;
				p.DescriptorTable.pDescriptorRanges = sampRanges.Ptr;
				mRootParamMap[gi * 2 + 1] = (int32)rootParams.Count;
				rootParams.Add(p);
			}
		}

		// Push constants become root 32 bit constants, in the register space just past the
		// last bind group so they cannot collide with one.
		for (let pc in d.PushConstantRanges)
		{
			if (mPushConstantRootIndex < 0)
				mPushConstantRootIndex = (int32)rootParams.Count;

			D3D12_ROOT_PARAMETER p = .();
			p.ParameterType = .D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;
			p.ShaderVisibility = .D3D12_SHADER_VISIBILITY_ALL;
			p.Constants.ShaderRegister = pc.Offset / 4;
			p.Constants.RegisterSpace = mNumBindGroups;
			p.Constants.Num32BitValues = pc.Size / 4;
			rootParams.Add(p);
		}

		D3D12_ROOT_SIGNATURE_DESC rsDesc = .();
		rsDesc.NumParameters = (uint32)rootParams.Count;
		rsDesc.pParameters = rootParams.Ptr;
		rsDesc.Flags = .D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT;

		ID3DBlob* sigBlob = null;
		ID3DBlob* errBlob = null;
		defer
		{
			if (sigBlob != null) sigBlob.Release();
			if (errBlob != null) errBlob.Release();
		}

		var hr = D3D12SerializeRootSignature(&rsDesc, .D3D_ROOT_SIGNATURE_VERSION_1, &sigBlob,
			&errBlob);
		if (FAILED(hr))
		{
			if (errBlob != null)
			{
				GlobalLog(.Error, "DxPipelineLayout: {0}",
					StringView((char8*)errBlob.GetBufferPointer()));
			}
			return .Err;
		}

		hr = device.CreateRootSignature(0, sigBlob.GetBufferPointer(), sigBlob.GetBufferSize(),
			ID3D12RootSignature.IID, (void**)&mRootSig);
		return SUCCEEDED(hr) ? .Ok : .Err;
	}

	public void Cleanup()
	{
		if (mRootSig != null)
		{
			mRootSig.Release();
			mRootSig = null;
		}
	}
}

#endif // BF_PLATFORM_WINDOWS
