using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A descriptor set layout.
class VulkanBindGroupLayout : IBindGroupLayout
{
	/// What descriptor type a layout entry becomes.
	///
	/// A dynamic offset changes the TYPE, not a flag: Vulkan has separate descriptor types
	/// for the dynamic forms, and binding a plain one where the pipeline expects a dynamic
	/// one is invalid.
	public static VkDescriptorType ToVkDescriptorType(BindGroupLayoutEntry entry)
	{
		switch (entry.Type)
		{
		case .UniformBuffer:
			return entry.HasDynamicOffset ? .VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC
				: .VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
		case .StorageBufferReadOnly, .StorageBufferReadWrite:
			return entry.HasDynamicOffset ? .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC
				: .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
		case .SampledTexture, .BindlessTextures:
			return .VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
		case .StorageTextureReadOnly, .StorageTextureReadWrite, .BindlessStorageTextures:
			return .VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
		case .Sampler, .ComparisonSampler, .BindlessSamplers:
			return .VK_DESCRIPTOR_TYPE_SAMPLER;
		case .BindlessStorageBuffers:
			return .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
		case .AccelerationStructure:
			return .VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR;
		}
	}

	/// What an unbounded bindless array is sized at.
	///
	/// A concrete ceiling, because Vulkan needs a number even for a "runtime sized" array;
	/// the partially bound flag is what makes the unused ones cost nothing.
	public const uint32 BindlessCapacity = 1024 * 16;

	private VkDescriptorSetLayout mLayout;
	private List<BindGroupLayoutEntry> mEntries = new .() ~ delete _;
	private bool mHasBindless = false;
	private uint32 mBindlessCount = 0;

	public VkDescriptorSetLayout Handle => mLayout;
	public bool HasBindless => mHasBindless;
	public uint32 BindlessCount => mBindlessCount;
	public Span<BindGroupLayoutEntry> Entries => mEntries;

	public Result<void> Initialize(VkDevice device, BindGroupLayoutDesc desc, BindingShifts shifts)
	{
		mEntries.Clear();
		for (let entry in desc.Entries)
			mEntries.Add(entry);

		let count = desc.Entries.Length;
		let bindings = scope VkDescriptorSetLayoutBinding[count == 0 ? 1 : count];
		let bindingFlags = scope VkDescriptorBindingFlags[count == 0 ? 1 : count];

		for (int i < count)
		{
			let entry = desc.Entries[i];

			bindings[i] = default;
			// The SHIFTED binding, so it matches where DXC put the resource when it
			// compiled the shader.
			bindings[i].binding = shifts.Apply(entry.Type, entry.Binding);
			bindings[i].descriptorType = ToVkDescriptorType(entry);
			bindings[i].descriptorCount = entry.Count;
			bindings[i].stageFlags = VulkanConversions.ToVkShaderStageFlags(entry.Visibility);
			bindingFlags[i] = default;

			// A count of all ones means UNBOUNDED, which is how a bindless array is asked
			// for. It becomes a large fixed capacity that is partially bound, updatable
			// after binding, and variable sized at allocation.
			if (entry.Count == uint32.MaxValue)
			{
				bindings[i].descriptorCount = BindlessCapacity;
				mHasBindless = true;
				mBindlessCount = BindlessCapacity;
				bindingFlags[i] = .VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT
					| .VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT
					| .VK_DESCRIPTOR_BINDING_VARIABLE_DESCRIPTOR_COUNT_BIT;
			}
		}

		VkDescriptorSetLayoutBindingFlagsCreateInfo flagsInfo = .();
		flagsInfo.bindingCount = (uint32)count;
		flagsInfo.pBindingFlags = &bindingFlags[0];

		VkDescriptorSetLayoutCreateInfo createInfo = .();
		createInfo.bindingCount = (uint32)count;
		createInfo.pBindings = &bindings[0];

		// The flags chain is attached ONLY for a bindless layout: an update after bind pool
		// costs more, and asking for it where nothing needs it is waste.
		if (mHasBindless)
		{
			createInfo.flags |= .VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT;
			createInfo.pNext = &flagsInfo;
		}

		if (VulkanNative.vkCreateDescriptorSetLayout(device, &createInfo, null, &mLayout)
			!= .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mLayout != .Null)
		{
			VulkanNative.vkDestroyDescriptorSetLayout(device, mLayout, null);
			mLayout = .Null;
		}
	}
}
