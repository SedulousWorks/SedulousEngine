using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// How HLSL register spaces map onto Vulkan descriptor bindings.
///
/// HLSL has four register CLASSES that each count from zero, so `b0`, `t0`, `u0` and `s0`
/// are four different registers. Vulkan has ONE binding number space per descriptor set,
/// so the classes must be pushed apart or they collide. DXC does that with its shift flags
/// when it compiles the shader, and the layout built here has to apply exactly the same
/// shifts or the two disagree about where a resource lives.
struct BindingShifts
{
	/// Constant buffers, the HLSL `b` registers.
	public uint32 CbvShift = 0;
	/// Shader resource views, the `t` registers.
	public uint32 SrvShift = 0;
	/// Unordered access views, the `u` registers.
	public uint32 UavShift = 0;
	/// Samplers, the `s` registers.
	public uint32 SamplerShift = 0;

	public this() {}

	public this(uint32 cbv, uint32 srv, uint32 uav, uint32 sampler)
	{
		CbvShift = cbv; SrvShift = srv; UavShift = uav; SamplerShift = sampler;
	}

	/// The engine wide layout.
	///
	/// Spaced a hundred apart rather than by something larger because the same numbers are
	/// used for WebGPU, whose maxBindingsPerBindGroup is a thousand. Vulkan does not
	/// constrain binding indices at all, so keeping to the compact table costs nothing here
	/// and lets one shader compilation serve both.
	public static BindingShifts Standard => .(0, 100, 200, 300);

	/// The Vulkan binding for an HLSL register of this type.
	public uint32 Apply(BindingType type, uint32 binding)
	{
		switch (type)
		{
		case .UniformBuffer:
			return binding + CbvShift;

		// A read only StructuredBuffer is an SRV in HLSL, a `t` register, so it takes the
		// SRV shift. An RWStructuredBuffer is a `u` register and takes the UAV shift
		// below. DXC shifts the SPIR-V binding by class, so the layout must classify it
		// the same way or the two point at different bindings.
		case .SampledTexture, .BindlessTextures, .AccelerationStructure,
			.StorageBufferReadOnly:
			return binding + SrvShift;

		case .StorageTextureReadOnly, .StorageTextureReadWrite, .BindlessStorageTextures,
			.StorageBufferReadWrite, .BindlessStorageBuffers:
			return binding + UavShift;

		case .Sampler, .ComparisonSampler, .BindlessSamplers:
			return binding + SamplerShift;
		}
	}
}
