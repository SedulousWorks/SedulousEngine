using System;

namespace Sedulous.RHI;

/// One slot of a bind group layout.
struct BindGroupLayoutEntry
{
	public uint32 Binding = 0;
	public ShaderStage Visibility = .None;
	public BindingType Type = .UniformBuffer;
	public TextureViewDimension TextureDimension = .Texture2D;
	public TextureSampleType TextureSampleType = .Float;

	/// WebGPU only: marks a Sampler slot as binding nearest only samplers, which is
	/// REQUIRED when the texture it pairs with is UnfilterableFloat, such as depth read as
	/// data. Vulkan and DX12 have no such distinction and ignore it.
	public bool SamplerNonFiltering = false;

	public bool TextureMultisampled = false;
	public TextureFormat StorageTextureFormat = .Undefined;
	public bool HasDynamicOffset = false;

	/// The HLSL element size when the shader declares a structured buffer. See the
	/// StorageBuffer factory: this is required on DX12 and ignored on Vulkan.
	public uint32 StorageBufferStride = 0;

	/// How many descriptors this slot holds. One for an ordinary binding.
	public uint32 Count = 1;
	public StringView Label = default;

	public this() {}

	public static BindGroupLayoutEntry UniformBuffer(uint32 binding, ShaderStage visibility)
	{
		var e = BindGroupLayoutEntry();
		e.Binding = binding;
		e.Visibility = visibility;
		e.Type = .UniformBuffer;
		return e;
	}

	public static BindGroupLayoutEntry SampledTexture(uint32 binding, ShaderStage visibility,
		TextureViewDimension dimension = .Texture2D)
	{
		var e = BindGroupLayoutEntry();
		e.Binding = binding;
		e.Visibility = visibility;
		e.Type = .SampledTexture;
		e.TextureDimension = dimension;
		return e;
	}

	public static BindGroupLayoutEntry Sampler(uint32 binding, ShaderStage visibility)
	{
		var e = BindGroupLayoutEntry();
		e.Binding = binding;
		e.Visibility = visibility;
		e.Type = .Sampler;
		return e;
	}

	/// A storage buffer slot.
	///
	/// `stride` is the HLSL element size when the shader declares a structured buffer, and
	/// it is REQUIRED on DX12: the descriptor is built structured with a stride, or raw
	/// with zero for a byte address buffer, and binding a raw descriptor to a structured
	/// shader is undefined behaviour there, reading garbage. Vulkan ignores it, its storage
	/// buffers being unstructured.
	public static BindGroupLayoutEntry StorageBuffer(uint32 binding, ShaderStage visibility,
		bool readOnly = false, uint32 stride = 0)
	{
		var e = BindGroupLayoutEntry();
		e.Binding = binding;
		e.Visibility = visibility;
		e.Type = readOnly ? .StorageBufferReadOnly : .StorageBufferReadWrite;
		e.StorageBufferStride = stride;
		return e;
	}
}
