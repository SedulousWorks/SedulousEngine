using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// What a bind group is allowed to contain.
///
/// Bindings are declared SHIFTED, by the compact WebGPU profile, which is what the
/// compile side bakes into the SPIR-V for a WebGPU device. The bind group replays the
/// same rule when it fills the slots, so the two agree by construction rather than by
/// being kept in step.
///
/// Three things have no WebGPU shape and are refused rather than approximated: bindless
/// entries, acceleration structures, and binding ARRAYS, a count above one.
///
/// A sampled texture's sample type comes from the entry's EXPLICIT declaration, because
/// WebGPU validates it against the shader and a guess would fail there instead of here.
class WebGpuBindGroupLayout : IBindGroupLayout
{
	private WGPUBindGroupLayout mHandle;
	/// Owned. Entries serves it, and the bind group replays it to shift by the same rule.
	private List<BindGroupLayoutEntry> mEntries = new .() ~ delete _;

	public Span<BindGroupLayoutEntry> Entries => mEntries;
	public WGPUBindGroupLayout Handle => mHandle;

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuBindGroupLayoutRelease(mHandle);
			mHandle = null;
		}
	}

	public Result<void> Initialize(WGPUDevice device, BindGroupLayoutDesc desc)
	{
		mEntries.AddRange(desc.Entries);

		let wgpuEntries = scope List<WGPUBindGroupLayoutEntry>(mEntries.Count);

		for (let entry in mEntries)
		{
			if (entry.Count > 1)
				return .Err; // core WebGPU has no binding arrays

			WGPUBindGroupLayoutEntry wgpu = .();
			wgpu.binding = WebGpuConversions.ShiftedBinding(entry.Type, entry.Binding);
			wgpu.visibility = WebGpuConversions.ToWgpuShaderStage(entry.Visibility);

			switch (entry.Type)
			{
			case .UniformBuffer:
				wgpu.buffer.type = .WGPUBufferBindingType_Uniform;
				wgpu.buffer.hasDynamicOffset = entry.HasDynamicOffset ? 1 : 0;

			case .StorageBufferReadOnly:
				wgpu.buffer.type = .WGPUBufferBindingType_ReadOnlyStorage;
				wgpu.buffer.hasDynamicOffset = entry.HasDynamicOffset ? 1 : 0;

			case .StorageBufferReadWrite:
				wgpu.buffer.type = .WGPUBufferBindingType_Storage;
				wgpu.buffer.hasDynamicOffset = entry.HasDynamicOffset ? 1 : 0;

			case .SampledTexture:
				wgpu.texture.sampleType =
					WebGpuConversions.ToWgpuTextureSampleType(entry.TextureSampleType);
				wgpu.texture.viewDimension =
					WebGpuConversions.ToWgpuTextureViewDimension(entry.TextureDimension);
				wgpu.texture.multisampled = entry.TextureMultisampled ? 1 : 0;

			case .StorageTextureReadOnly:
				wgpu.storageTexture.access = .WGPUStorageTextureAccess_ReadOnly;
				wgpu.storageTexture.format =
					WebGpuConversions.ToWgpuTextureFormat(entry.StorageTextureFormat);
				wgpu.storageTexture.viewDimension =
					WebGpuConversions.ToWgpuTextureViewDimension(entry.TextureDimension);

			case .StorageTextureReadWrite:
				wgpu.storageTexture.access = .WGPUStorageTextureAccess_ReadWrite;
				wgpu.storageTexture.format =
					WebGpuConversions.ToWgpuTextureFormat(entry.StorageTextureFormat);
				wgpu.storageTexture.viewDimension =
					WebGpuConversions.ToWgpuTextureViewDimension(entry.TextureDimension);

			case .Sampler:
				wgpu.sampler.type = entry.SamplerNonFiltering
					? .WGPUSamplerBindingType_NonFiltering : .WGPUSamplerBindingType_Filtering;

			case .ComparisonSampler:
				wgpu.sampler.type = .WGPUSamplerBindingType_Comparison;

			default:
				return .Err; // bindless and acceleration structures
			}

			wgpuEntries.Add(wgpu);
		}

		WGPUBindGroupLayoutDescriptor wgpuDesc = .();
		wgpuDesc.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpuDesc.entryCount = (uint)wgpuEntries.Count;
		wgpuDesc.entries = wgpuEntries.Ptr;

		mHandle = wgpuDeviceCreateBindGroupLayout(device, &wgpuDesc);
		return (mHandle != null) ? .Ok : .Err;
	}
}
