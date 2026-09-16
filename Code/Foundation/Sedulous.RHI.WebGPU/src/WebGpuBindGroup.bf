using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// What a bind group actually holds.
///
/// The entries are POSITIONAL against the layout's, which is the RHI contract every
/// backend shares, and each resolves to the layout entry's SHIFTED binding number. The
/// shift is read back off the layout rather than recomputed from the group, so the two
/// cannot drift: whatever the layout declared is what gets filled.
class WebGpuBindGroup : IBindGroup
{
	private WGPUBindGroup mHandle;
	/// BORROWED, and outlives this by the RHI's ownership rules.
	private WebGpuBindGroupLayout mLayout;

	public IBindGroupLayout Layout => mLayout;
	public WGPUBindGroup Handle => mHandle;

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuBindGroupRelease(mHandle);
			mHandle = null;
		}
	}

	public Result<void> Initialize(WGPUDevice device, BindGroupDesc desc)
	{
		mLayout = desc.Layout as WebGpuBindGroupLayout;
		if (mLayout == null)
			return .Err;

		let layoutEntries = mLayout.Entries;
		if (desc.Entries.Length != layoutEntries.Length)
			return .Err; // the positional contract was not kept

		let wgpuEntries = scope List<WGPUBindGroupEntry>(desc.Entries.Length);

		for (int i = 0; i < desc.Entries.Length; i++)
		{
			let entry = desc.Entries[i];
			let layoutEntry = layoutEntries[i];

			WGPUBindGroupEntry wgpu = .();
			wgpu.binding = WebGpuConversions.ShiftedBinding(layoutEntry.Type, layoutEntry.Binding);

			if (let buffer = entry.Buffer as WebGpuBuffer)
			{
				wgpu.buffer = buffer.Handle;
				wgpu.offset = entry.BufferOffset;
				// Zero means the rest of the buffer, which WebGPU spells as its own
				// whole-size sentinel rather than as zero.
				wgpu.size = (entry.BufferSize != 0) ? entry.BufferSize : WGPU_WHOLE_SIZE;
			}
			else if (let view = entry.TextureView as WebGpuTextureView)
			{
				wgpu.textureView = view.Handle;
			}
			else if (let sampler = entry.Sampler as WebGpuSampler)
			{
				wgpu.sampler = sampler.Handle;
			}
			else
			{
				// An empty slot. An acceleration structure never reaches here, its
				// layout having failed creation already.
				return .Err;
			}

			wgpuEntries.Add(wgpu);
		}

		WGPUBindGroupDescriptor wgpuDesc = .();
		wgpuDesc.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpuDesc.layout = mLayout.Handle;
		wgpuDesc.entryCount = (uint)wgpuEntries.Count;
		wgpuDesc.entries = wgpuEntries.Ptr;

		mHandle = wgpuDeviceCreateBindGroup(device, &wgpuDesc);
		return (mHandle != null) ? .Ok : .Err;
	}

	/// Nothing to do: bindless never reaches WebGPU, a layout declaring it having
	/// failed creation.
	public void UpdateBindless(Span<BindlessUpdateEntry> entries)
	{
	}
}
