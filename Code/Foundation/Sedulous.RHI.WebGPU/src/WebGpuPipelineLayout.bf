using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// The bind group layouts a pipeline uses, and how its push constants get there.
///
/// Push constants take one of TWO shapes. Natively they are wgpu's immediates: the
/// layout declares a size and the encoders set them directly. In the fallback, which is
/// what a browser gets because Dawn has no immediates, and what can be forced for
/// testing, the block is bound as an ordinary uniform buffer at group, binding zero,
/// matching the WGSL cook. The layout synthesises that group's bind group layout here
/// and reports it; the pass encoders keep a CPU shadow of the block, upload it and bind
/// the group before each draw.
sealed class WebGpuPipelineLayout : IPipelineLayout
{
	private WGPUPipelineLayout mHandle;

	private WGPUBindGroupLayout mEmulatedLayout = null;
	private int32 mEmulatedGroup = -1;
	private uint32 mEmulatedBlockSize = 0;
	/// Empty layouts padding the groups before the emulated one, since a pipeline layout
	/// is positional and the block has to land at its declared index.
	private List<WGPUBindGroupLayout> mEmptyFillers = new .() ~ delete _;

	public WGPUPipelineLayout Handle => mHandle;

	/// The group the emulated block binds to, or -1 when this layout issues native
	/// immediates instead. At zero or above, the pass encoders shadow BlockSize bytes.
	public int32 EmulatedPushConstantGroup => mEmulatedGroup;
	public WGPUBindGroupLayout EmulatedPushConstantLayout => mEmulatedLayout;
	public uint32 EmulatedPushConstantBlockSize => mEmulatedBlockSize;

	public PushConstantEmulation EmulationInfo => .()
		{
			Group = mEmulatedGroup,
			Layout = mEmulatedLayout,
			BlockSize = mEmulatedBlockSize
		};

	public ~this()
	{
		if (mHandle != null)
			wgpuPipelineLayoutRelease(mHandle);

		if (mEmulatedLayout != null)
			wgpuBindGroupLayoutRelease(mEmulatedLayout);

		for (let filler in mEmptyFillers)
			wgpuBindGroupLayoutRelease(filler);
	}

	public Result<void> Initialize(WGPUDevice device, PipelineLayoutDesc desc,
		bool emulatePushConstants)
	{
		let layouts = scope List<WGPUBindGroupLayout>();

		for (let layout in desc.BindGroupLayouts)
		{
			let wgpuLayout = layout as WebGpuBindGroupLayout;
			if (wgpuLayout == null)
				return .Err;

			layouts.Add(wgpuLayout.Handle);
		}

		// Aggregate the block: its size is the furthest range end, its visibility the
		// union of the stages that touch it, and its group the one they all share,
		// every range being part of the same block.
		uint32 blockSize = 0;
		ShaderStage stages = .None;
		uint32 group = 0;
		var havePushConstants = false;

		for (let range in desc.PushConstantRanges)
		{
			let end = range.Offset + range.Size;
			if (end > blockSize)
				blockSize = end;

			stages |= range.Stages;
			group = range.BindGroupIndex;
			havePushConstants = true;
		}

		var immediateSize = blockSize;

		if (havePushConstants && emulatePushConstants)
		{
			if (SynthesiseEmulatedGroup(device, layouts, stages, group, blockSize) case .Err)
				return .Err;

			immediateSize = 0; // no immediates are declared in this mode
		}

		WGPUPipelineLayoutDescriptor wgpuDesc = .();
		wgpuDesc.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpuDesc.bindGroupLayoutCount = (uint)layouts.Count;
		wgpuDesc.bindGroupLayouts = layouts.Ptr;
		wgpuDesc.immediateSize = immediateSize;

		mHandle = wgpuDeviceCreatePipelineLayout(device, &wgpuDesc);
		return (mHandle != null) ? .Ok : .Err;
	}

	/// Builds the uniform buffer layout the WGSL expects and puts it at its declared
	/// index, padding any earlier unused groups with empty layouts.
	private Result<void> SynthesiseEmulatedGroup(WGPUDevice device,
		List<WGPUBindGroupLayout> layouts, ShaderStage stages, uint32 group, uint32 blockSize)
	{
		WGPUBindGroupLayoutEntry entry = .();
		entry.binding = 0; // the constant buffer shift is zero, so the block stays at 0
		entry.visibility = WebGpuConversions.ToWgpuShaderStage(stages);
		entry.buffer.type = .WGPUBufferBindingType_Uniform;
		entry.buffer.hasDynamicOffset = 0;

		WGPUBindGroupLayoutDescriptor bglDesc = .();
		bglDesc.entryCount = 1;
		bglDesc.entries = &entry;

		mEmulatedLayout = wgpuDeviceCreateBindGroupLayout(device, &bglDesc);
		if (mEmulatedLayout == null)
			return .Err;

		while ((uint32)layouts.Count < group)
		{
			WGPUBindGroupLayoutDescriptor emptyDesc = .();
			let empty = wgpuDeviceCreateBindGroupLayout(device, &emptyDesc);
			if (empty == null)
				return .Err;

			mEmptyFillers.Add(empty);
			layouts.Add(empty);
		}

		if (group < (uint32)layouts.Count)
			return .Err; // that slot already holds a real bind group

		layouts.Add(mEmulatedLayout); // which puts it at index `group`
		mEmulatedGroup = (int32)group;
		mEmulatedBlockSize = blockSize;
		return .Ok;
	}
}
