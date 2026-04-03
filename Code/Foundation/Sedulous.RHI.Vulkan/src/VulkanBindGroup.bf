namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;
using static Sedulous.RHI.TextureFormatExt;

/// Vulkan implementation of IBindGroup.
class VulkanBindGroup : IBindGroup
{
	private VkDescriptorSet mDescriptorSet;
	private VkDescriptorPool mPool;
	private VulkanDevice mDevice;
	private VulkanBindGroupLayout mLayout;

	public IBindGroupLayout Layout => mLayout;

	public this() { }

	public Result<void> Init(VulkanDevice device, VulkanDescriptorPoolManager poolManager, BindGroupDesc desc)
	{
		mDevice = device;
		mLayout = desc.Layout as VulkanBindGroupLayout;
		if (mLayout == null)
		{
			System.Diagnostics.Debug.WriteLine("VulkanBindGroup: layout is not a VulkanBindGroupLayout");
			return .Err;
		}

		// Allocate descriptor set
		VkDescriptorPool allocPool;
		if (poolManager.Allocate(mLayout.Handle, out allocPool, mLayout.HasBindless, mLayout.BindlessDescriptorCount) case .Ok(let set))
		{
			mDescriptorSet = set;
			mPool = allocPool;
		}
		else
		{
			System.Diagnostics.Debug.WriteLine("VulkanBindGroup: descriptor set allocation failed");
			return .Err;
		}

		// Write descriptor updates
		WriteDescriptors(device, desc);
		return .Ok;
	}

	private void WriteDescriptors(VulkanDevice device, BindGroupDesc desc)
	{
		if (desc.Entries.Length == 0) return;

		let shifts = device.BindingShifts;

		List<VkWriteDescriptorSet> writes = scope .();
		List<VkDescriptorBufferInfo> bufferInfos = scope .();
		List<VkDescriptorImageInfo> imageInfos = scope .();
		List<VkWriteDescriptorSetAccelerationStructureKHR> accelWriteInfos = scope .();
		List<VkAccelerationStructureKHR> accelStructHandles = scope .();

		// Pre-allocate to stabilize pointers
		bufferInfos.Reserve(desc.Entries.Length);
		imageInfos.Reserve(desc.Entries.Length);
		accelWriteInfos.Reserve(desc.Entries.Length);
		accelStructHandles.Reserve(desc.Entries.Length);

		// Entries are positional: entry[j] provides the resource for the j-th non-bindless layout entry.
		// Bindless entries are skipped — they are populated via UpdateBindless().
		int entryIdx = 0;
		for (int i = 0; i < mLayout.Entries.Count; i++)
		{
			let layoutEntry = mLayout.Entries[i];

			// Skip bindless layout entries
			switch (layoutEntry.Type)
			{
			case .BindlessTextures, .BindlessSamplers, .BindlessStorageBuffers, .BindlessStorageTextures:
				continue;
			default:
			}

			if (entryIdx >= desc.Entries.Length) break;
			let entry = desc.Entries[entryIdx];
			entryIdx++;

			VkWriteDescriptorSet write = .();
			write.dstSet = mDescriptorSet;
			write.dstBinding = shifts.Apply(layoutEntry.Type, layoutEntry.Binding);
			write.dstArrayElement = 0;
			write.descriptorCount = 1;
			write.descriptorType = VulkanBindGroupLayout.ToVkDescriptorType(layoutEntry);

			switch (layoutEntry.Type)
			{
			case .UniformBuffer, .StorageBufferReadOnly, .StorageBufferReadWrite:
				if (let vkBuf = entry.Buffer as VulkanBuffer)
				{
					VkDescriptorBufferInfo bufInfo = .();
					bufInfo.buffer = vkBuf.Handle;
					bufInfo.offset = entry.BufferOffset;
					bufInfo.range = (entry.BufferSize > 0) ? entry.BufferSize : VulkanNative.VK_WHOLE_SIZE;
					bufferInfos.Add(bufInfo);
					write.pBufferInfo = &bufferInfos.Back;
				}
				else continue;

			case .SampledTexture, .StorageTextureReadOnly, .StorageTextureReadWrite:
				if (let vkView = entry.TextureView as VulkanTextureView)
				{
					VkDescriptorImageInfo imgInfo = .();
					imgInfo.imageView = vkView.Handle;
					if (layoutEntry.Type == .SampledTexture)
					{
						// Use the texture's tracked layout — depth textures in DepthStencilReadOnly
						// can be sampled with that layout (concurrent depth test + shader read).
						let vkTex = vkView.Texture as VulkanTexture;
						VkImageLayout currentLayout = (vkTex != null) ? vkTex.CurrentLayout : .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
						imgInfo.imageLayout = (currentLayout == .VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL)
							? .VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL
							: .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
					}
					else
						imgInfo.imageLayout = .VK_IMAGE_LAYOUT_GENERAL;
					imageInfos.Add(imgInfo);
					write.pImageInfo = &imageInfos.Back;
				}
				else continue;

			case .Sampler, .ComparisonSampler:
				if (let vkSampler = entry.Sampler as VulkanSampler)
				{
					VkDescriptorImageInfo imgInfo = .();
					imgInfo.sampler = vkSampler.Handle;
					imageInfos.Add(imgInfo);
					write.pImageInfo = &imageInfos.Back;
				}
				else continue;

			case .AccelerationStructure:
				if (let vkAs = entry.AccelStruct as VulkanAccelStruct)
				{
					var handle = vkAs.Handle;
					accelStructHandles.Add(handle);
					VkWriteDescriptorSetAccelerationStructureKHR accelInfo = .();
					accelInfo.accelerationStructureCount = 1;
					accelInfo.pAccelerationStructures = &accelStructHandles.Back;
					accelWriteInfos.Add(accelInfo);
					write.pNext = &accelWriteInfos.Back;
				}
				else continue;

			default:
				continue;
			}

			writes.Add(write);
		}

		if (writes.Count > 0)
			VulkanNative.vkUpdateDescriptorSets(device.Handle, (uint32)writes.Count, writes.Ptr, 0, null);
	}

	public void UpdateBindless(Span<BindlessUpdateEntry> entries)
	{
		if (entries.Length == 0) return;

		let shifts = mDevice.BindingShifts;

		List<VkWriteDescriptorSet> writes = scope .();
		List<VkDescriptorBufferInfo> bufferInfos = scope .();
		List<VkDescriptorImageInfo> imageInfos = scope .();

		bufferInfos.Reserve(entries.Length);
		imageInfos.Reserve(entries.Length);

		for (let entry in entries)
		{
			if ((int)entry.LayoutIndex >= mLayout.Entries.Count) continue;
			let layoutEntry = mLayout.Entries[(int)entry.LayoutIndex];

			VkWriteDescriptorSet write = .();
			write.dstSet = mDescriptorSet;
			write.dstBinding = shifts.Apply(layoutEntry.Type, layoutEntry.Binding);
			write.dstArrayElement = entry.ArrayIndex;
			write.descriptorCount = 1;
			write.descriptorType = VulkanBindGroupLayout.ToVkDescriptorType(layoutEntry);

			switch (layoutEntry.Type)
			{
			case .BindlessStorageBuffers:
				if (let vkBuf = entry.Buffer as VulkanBuffer)
				{
					VkDescriptorBufferInfo bufInfo = .();
					bufInfo.buffer = vkBuf.Handle;
					bufInfo.offset = entry.BufferOffset;
					bufInfo.range = (entry.BufferSize > 0) ? entry.BufferSize : VulkanNative.VK_WHOLE_SIZE;
					bufferInfos.Add(bufInfo);
					write.pBufferInfo = &bufferInfos.Back;
				}
				else continue;

			case .BindlessTextures, .BindlessStorageTextures:
				if (let vkView = entry.TextureView as VulkanTextureView)
				{
					VkDescriptorImageInfo imgInfo = .();
					imgInfo.imageView = vkView.Handle;
					imgInfo.imageLayout = (layoutEntry.Type == .BindlessTextures)
						? .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
						: .VK_IMAGE_LAYOUT_GENERAL;
					imageInfos.Add(imgInfo);
					write.pImageInfo = &imageInfos.Back;
				}
				else continue;

			case .BindlessSamplers:
				if (let vkSampler = entry.Sampler as VulkanSampler)
				{
					VkDescriptorImageInfo imgInfo = .();
					imgInfo.sampler = vkSampler.Handle;
					imageInfos.Add(imgInfo);
					write.pImageInfo = &imageInfos.Back;
				}
				else continue;

			default:
				continue;
			}

			writes.Add(write);
		}

		if (writes.Count > 0)
			VulkanNative.vkUpdateDescriptorSets(mDevice.Handle, (uint32)writes.Count, writes.Ptr, 0, null);
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mDescriptorSet.Handle != 0 && mPool.Handle != 0)
		{
			device.DescriptorPoolManager.Free(mPool, mDescriptorSet);
			mDescriptorSet = .Null;
			mPool = .Null;
		}
	}

	public VkDescriptorSet Handle => mDescriptorSet;
}
