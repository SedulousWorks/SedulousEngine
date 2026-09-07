using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A descriptor set filled from a bind group descriptor.
class VulkanBindGroup : IBindGroup
{
	private VkDevice mDevice;
	private VulkanBindGroupLayout mLayout;
	private VkDescriptorPool mPool;
	private VkDescriptorSet mSet;
	private BindingShifts mShifts;

	public IBindGroupLayout Layout => mLayout;
	public VkDescriptorSet Handle => mSet;

	public Result<void> Initialize(VkDevice device, VulkanDescriptorPoolManager pools,
		BindGroupDesc desc, BindingShifts shifts)
	{
		mDevice = device;
		mShifts = shifts;
		mLayout = desc.Layout as VulkanBindGroupLayout;
		if (mLayout == null)
			return .Err;

		// A bindless layout needs an update-after-bind pool and a variable count, so both
		// travel with the request rather than being decided by the pool.
		if (!(pools.Allocate(mLayout.Handle, mLayout.HasBindless, mLayout.BindlessCount)
			case .Ok(let pool)))
			return .Err;

		mPool = pool;
		mSet = pools.LastAllocatedSet;
		WriteDescriptors(desc);
		return .Ok;
	}

	public void Cleanup(VulkanDescriptorPoolManager pools)
	{
		if ((mSet != .Null) && (mPool != .Null))
		{
			pools.Free(mPool, mSet);
			mSet = .Null;
			mPool = .Null;
		}
	}

	/// Fills the set from the descriptor.
	///
	/// The entries are POSITIONAL against the layout's non bindless slots, so the layout is
	/// walked and the bindless ones skipped: an entry lines up with the next slot that
	/// takes one, not with the slot at the same index.
	private void WriteDescriptors(BindGroupDesc desc)
	{
		if (desc.Entries.IsEmpty)
			return;

		let layoutEntries = mLayout.Entries;
		let capacity = desc.Entries.Length;

		// Sized ONCE, up front. The write structures point INTO these, so anything that
		// moved them would leave the driver reading freed memory.
		let writes = scope List<VkWriteDescriptorSet>();
		let bufferInfos = scope VkDescriptorBufferInfo[capacity];
		let imageInfos = scope VkDescriptorImageInfo[capacity];
		let accelInfos = scope VkWriteDescriptorSetAccelerationStructureKHR[capacity];
		let accelHandles = scope VkAccelerationStructureKHR[capacity];
		int bufferCount = 0, imageCount = 0, accelCount = 0;

		int entryIndex = 0;
		for (int i < layoutEntries.Length)
		{
			let layoutEntry = layoutEntries[i];

			// Bindless slots are not filled here: their contents are written later through
			// UpdateBindless, which is the point of them.
			switch (layoutEntry.Type)
			{
			case .BindlessTextures, .BindlessSamplers, .BindlessStorageBuffers,
				.BindlessStorageTextures:
				continue;
			default:
			}

			if (entryIndex >= desc.Entries.Length)
				break;
			let entry = desc.Entries[entryIndex];
			entryIndex++;

			VkWriteDescriptorSet write = .();
			write.dstSet = mSet;
			write.dstBinding = mShifts.Apply(layoutEntry.Type, layoutEntry.Binding);
			write.dstArrayElement = 0;
			write.descriptorCount = 1;
			write.descriptorType = VulkanBindGroupLayout.ToVkDescriptorType(layoutEntry);

			switch (layoutEntry.Type)
			{
			case .UniformBuffer, .StorageBufferReadOnly, .StorageBufferReadWrite:
				let buffer = entry.Buffer as VulkanBuffer;
				if (buffer == null)
					continue;
				bufferInfos[bufferCount] = .()
					{
						buffer = buffer.Handle,
						offset = entry.BufferOffset,
						// Zero means the rest of the buffer, which is what binding a whole
						// buffer asks for without having to restate its size.
						range = (entry.BufferSize > 0) ? entry.BufferSize : VulkanNative.VK_WHOLE_SIZE
					};
				write.pBufferInfo = &bufferInfos[bufferCount];
				bufferCount++;

			case .SampledTexture, .StorageTextureReadOnly, .StorageTextureReadWrite:
				let view = entry.TextureView as VulkanTextureView;
				if (view == null)
					continue;

				VkImageLayout layout;
				if (layoutEntry.Type == .SampledTexture)
				{
					// A sampled depth texture is read in the DEPTH_STENCIL read only
					// layout; the shader read only layout is for colour alone.
					let texture = view.Texture as VulkanTexture;
					layout = ((texture != null) && TextureFormats.IsDepthFormat(texture.Desc.Format))
						? .VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL
						: .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
				}
				else
				{
					// A storage image is written as well as read, and only GENERAL allows
					// both.
					layout = .VK_IMAGE_LAYOUT_GENERAL;
				}

				imageInfos[imageCount] = .() { imageView = view.Handle, imageLayout = layout };
				write.pImageInfo = &imageInfos[imageCount];
				imageCount++;

			case .Sampler, .ComparisonSampler:
				let sampler = entry.Sampler as VulkanSampler;
				if (sampler == null)
					continue;
				imageInfos[imageCount] = .() { sampler = sampler.Handle };
				write.pImageInfo = &imageInfos[imageCount];
				imageCount++;

			case .AccelerationStructure:
				let accelStruct = entry.AccelStruct as VulkanAccelStruct;
				if (accelStruct == null)
					continue;
				accelHandles[accelCount] = accelStruct.Handle;
				accelInfos[accelCount] = .()
					{
						accelerationStructureCount = 1,
						pAccelerationStructures = &accelHandles[accelCount]
					};
				// An acceleration structure is written through the pNext chain rather than
				// a buffer or image info, since it is neither.
				write.pNext = &accelInfos[accelCount];
				accelCount++;

			default:
				continue;
			}

			writes.Add(write);
		}

		if (!writes.IsEmpty)
			VulkanNative.vkUpdateDescriptorSets(mDevice, (uint32)writes.Count, writes.Ptr, 0, null);
	}

	/// Rewrites individual slots of a bindless array in place.
	///
	/// The point of a bindless group: it holds thousands of descriptors and is written as
	/// its contents change, rather than being rebuilt each time something is streamed in.
	public void UpdateBindless(Span<BindlessUpdateEntry> entries)
	{
		if (entries.IsEmpty)
			return;

		let layoutEntries = mLayout.Entries;
		let capacity = entries.Length;

		let writes = scope List<VkWriteDescriptorSet>();
		let bufferInfos = scope VkDescriptorBufferInfo[capacity];
		let imageInfos = scope VkDescriptorImageInfo[capacity];
		int bufferCount = 0, imageCount = 0;

		for (int i < entries.Length)
		{
			let entry = entries[i];
			if (entry.LayoutIndex >= (uint32)layoutEntries.Length)
				continue;
			let layoutEntry = layoutEntries[entry.LayoutIndex];

			VkWriteDescriptorSet write = .();
			write.dstSet = mSet;
			write.dstBinding = mShifts.Apply(layoutEntry.Type, layoutEntry.Binding);
			// The slot WITHIN the array, which is the index a shader will use.
			write.dstArrayElement = entry.ArrayIndex;
			write.descriptorCount = 1;
			write.descriptorType = VulkanBindGroupLayout.ToVkDescriptorType(layoutEntry);

			switch (layoutEntry.Type)
			{
			case .BindlessStorageBuffers:
				let buffer = entry.Buffer as VulkanBuffer;
				if (buffer == null)
					continue;
				bufferInfos[bufferCount] = .()
					{
						buffer = buffer.Handle,
						offset = entry.BufferOffset,
						range = (entry.BufferSize > 0) ? entry.BufferSize : VulkanNative.VK_WHOLE_SIZE
					};
				write.pBufferInfo = &bufferInfos[bufferCount];
				bufferCount++;

			case .BindlessTextures, .BindlessStorageTextures:
				let view = entry.TextureView as VulkanTextureView;
				if (view == null)
					continue;
				imageInfos[imageCount] = .()
					{
						imageView = view.Handle,
						imageLayout = (layoutEntry.Type == .BindlessTextures)
							? .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
							: .VK_IMAGE_LAYOUT_GENERAL
					};
				write.pImageInfo = &imageInfos[imageCount];
				imageCount++;

			case .BindlessSamplers:
				let sampler = entry.Sampler as VulkanSampler;
				if (sampler == null)
					continue;
				imageInfos[imageCount] = .() { sampler = sampler.Handle };
				write.pImageInfo = &imageInfos[imageCount];
				imageCount++;

			default:
				continue;
			}

			writes.Add(write);
		}

		if (!writes.IsEmpty)
			VulkanNative.vkUpdateDescriptorSets(mDevice, (uint32)writes.Count, writes.Ptr, 0, null);
	}
}
