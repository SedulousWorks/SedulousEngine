namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IBindGroupLayout.
class VulkanBindGroupLayout : IBindGroupLayout
{
	private VkDescriptorSetLayout mLayout;
	private List<BindGroupLayoutEntry> mEntries = new .() ~ delete _;
	private bool mHasBindless;
	private uint32 mBindlessDescriptorCount;

	public this() { }

	public Result<void> Init(VulkanDevice device, BindGroupLayoutDesc desc)
	{
		let shifts = device.BindingShifts;

		// Store entries for later use
		for (let entry in desc.Entries)
			mEntries.Add(entry);

		VkDescriptorSetLayoutBinding[] bindings = scope VkDescriptorSetLayoutBinding[desc.Entries.Length];
		VkDescriptorBindingFlags[] bindingFlags = scope VkDescriptorBindingFlags[desc.Entries.Length];

		for (int i = 0; i < desc.Entries.Length; i++)
		{
			let entry = desc.Entries[i];

			bindings[i] = .();
			bindings[i].binding = shifts.Apply(entry.Type, entry.Binding);
			bindings[i].descriptorType = ToVkDescriptorType(entry);
			bindings[i].descriptorCount = entry.Count;
			if (entry.Count == uint32.MaxValue)
			{
				// Bindless - use a large but finite count for the layout
				bindings[i].descriptorCount = 1024 * 16;
				mHasBindless = true;
				mBindlessDescriptorCount = bindings[i].descriptorCount;
			}
			bindings[i].stageFlags = ToVkShaderStageFlags(entry.Visibility);
			bindings[i].pImmutableSamplers = null;

			// Set binding flags
			bindingFlags[i] = .None;
			if (entry.Count == uint32.MaxValue)
			{
				bindingFlags[i] =
					.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT |
					.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT |
					.VK_DESCRIPTOR_BINDING_VARIABLE_DESCRIPTOR_COUNT_BIT;
			}
		}

		VkDescriptorSetLayoutCreateInfo layoutInfo = .();
		layoutInfo.bindingCount = (uint32)desc.Entries.Length;
		layoutInfo.pBindings = bindings.CArray();

		// Bindless flags
		VkDescriptorSetLayoutBindingFlagsCreateInfo flagsInfo = .();
		if (mHasBindless)
		{
			layoutInfo.flags |= .VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT;

			flagsInfo.bindingCount = (uint32)desc.Entries.Length;
			flagsInfo.pBindingFlags = bindingFlags.CArray();
			layoutInfo.pNext = &flagsInfo;
		}

		let result = VulkanNative.vkCreateDescriptorSetLayout(device.Handle, &layoutInfo, null, &mLayout);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanBindGroupLayout: vkCreateDescriptorSetLayout failed ({result})");
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mLayout.Handle != 0)
		{
			VulkanNative.vkDestroyDescriptorSetLayout(device.Handle, mLayout, null);
			mLayout = .Null;
		}
	}

	public VkDescriptorSetLayout Handle => mLayout;
	public List<BindGroupLayoutEntry> Entries => mEntries;
	public bool HasBindless => mHasBindless;
	public uint32 BindlessDescriptorCount => mBindlessDescriptorCount;

	public static VkDescriptorType ToVkDescriptorType(BindGroupLayoutEntry entry)
	{
		switch (entry.Type)
		{
		case .UniformBuffer:
			return entry.HasDynamicOffset ? .VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC : .VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
		case .StorageBufferReadOnly, .StorageBufferReadWrite:
			return entry.HasDynamicOffset ? .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC : .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
		case .SampledTexture:
			return .VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
		case .StorageTextureReadOnly, .StorageTextureReadWrite:
			return .VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
		case .Sampler, .ComparisonSampler:
			return .VK_DESCRIPTOR_TYPE_SAMPLER;
		case .BindlessTextures:
			return .VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
		case .BindlessSamplers:
			return .VK_DESCRIPTOR_TYPE_SAMPLER;
		case .BindlessStorageBuffers:
			return .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
		case .BindlessStorageTextures:
			return .VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
		case .AccelerationStructure:
			return .VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR;
		}
	}

	public static VkShaderStageFlags ToVkShaderStageFlags(ShaderStage stages)
	{
		VkShaderStageFlags flags = .None;
		if (stages.HasFlag(.Vertex))    flags |= .VK_SHADER_STAGE_VERTEX_BIT;
		if (stages.HasFlag(.Fragment))  flags |= .VK_SHADER_STAGE_FRAGMENT_BIT;
		if (stages.HasFlag(.Compute))   flags |= .VK_SHADER_STAGE_COMPUTE_BIT;
		if (stages.HasFlag(.Mesh))      flags |= .VK_SHADER_STAGE_MESH_BIT_EXT;
		if (stages.HasFlag(.Task))      flags |= .VK_SHADER_STAGE_TASK_BIT_EXT;
		if (stages.HasFlag(.RayGen))    flags |= .VK_SHADER_STAGE_RAYGEN_BIT_KHR;
		if (stages.HasFlag(.ClosestHit))flags |= .VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR;
		if (stages.HasFlag(.Miss))      flags |= .VK_SHADER_STAGE_MISS_BIT_KHR;
		if (stages.HasFlag(.AnyHit))    flags |= .VK_SHADER_STAGE_ANY_HIT_BIT_KHR;
		if (stages.HasFlag(.Intersection)) flags |= .VK_SHADER_STAGE_INTERSECTION_BIT_KHR;
		return flags;
	}
}
