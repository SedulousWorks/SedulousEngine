namespace Sedulous.Shaders;

/// How HLSL register classes are pushed apart into Vulkan's single binding space.
///
/// HLSL counts `b`, `t`, `u` and `s` registers separately, so `b0` and `t0` are different
/// registers; SPIR-V has one binding number per descriptor set, so without a shift they
/// collide. DXC applies these when it compiles, and the RHI's descriptor set layouts must
/// apply the SAME numbers or the two disagree about where a resource lives.
struct BindingShifts
{
	/// Constant buffers, the HLSL `b` registers.
	public uint32 ConstantBufferShift = 0;
	/// Shader resource views, the `t` registers.
	public uint32 TextureShift = 0;
	/// Samplers, the `s` registers.
	public uint32 SamplerShift = 0;
	/// Unordered access views, the `u` registers.
	public uint32 UavShift = 0;

	public this() {}

	public this(uint32 constantBuffer, uint32 texture, uint32 sampler, uint32 uav)
	{
		ConstantBufferShift = constantBuffer;
		TextureShift = texture;
		SamplerShift = sampler;
		UavShift = uav;
	}

	/// THE engine wide table: CBV at 0, SRV at 100, UAV at 200, Sampler at 300.
	///
	/// Compact rather than spread by thousands because the same numbers serve WebGPU, whose
	/// maxBindingsPerBindGroup is 1000 in a browser and not negotiable. Vulkan constrains
	/// binding indices not at all, so one table serves both and one shader compilation
	/// serves both backends.
	///
	/// MUST equal Sedulous.RHI.Vulkan's BindingShifts.Standard. A test pins that.
	public static BindingShifts Standard => .(0, 100, 300, 200);
}
