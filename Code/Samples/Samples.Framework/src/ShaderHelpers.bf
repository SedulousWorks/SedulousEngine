using System;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Samples.Framework;

/// Compiling HLSL straight to a shader module.
///
/// The samples have no shader system and no cooked pack: each carries its own HLSL inline
/// and wants a module back. This is the one call that does it, and it is where the target
/// and the binding shifts are decided so no sample has to remember them.
static class ShaderHelpers
{
	/// Compiles HLSL and creates the module for it.
	///
	/// The TARGET follows the device: DXIL for DX12, SPIR-V everywhere else. A sample never
	/// states which, so the same source runs on either backend.
	public static Result<IShaderModule> CompileToModule(ShaderCompiler compiler, IDevice device,
		// QUALIFIED: Sedulous.RHI has its own ShaderStage, a bit field naming a SET of
		// stages, and a compile targets exactly one.
		StringView hlsl, Sedulous.Shaders.ShaderStage stage, StringView entryPoint,
		StringView label,
		StringView shaderModel = "6_0")
	{
		let isDX12 = device.Type == .DX12;
		let target = isDX12 ? ShaderTarget.DXIL : ShaderTarget.SPIRV;

		var options = CompileOptions();
		options.ShaderModel = shaderModel;
		options.OptimizationLevel = 3;

		// DX12 has register spaces natively, so only a SPIR-V target needs the shifts. One
		// engine wide table serves Vulkan and WebGPU alike.
		if (!isDX12)
		{
			options.BindingShifts = BindingShifts.Standard;
			options.BindingShiftSets = 4;
			if (device.Type == .WebGPU)
			{
				// naga rejects the SPIR-V 1.4 and later instructions a vulkan1.3 compile
				// emits.
				options.SpirvTargetEnvironment = "vulkan1.1";
			}
		}

		var compiled = compiler.Compile(.((uint8*)hlsl.Ptr, hlsl.Length), stage, entryPoint,
			target, options);
		defer compiled.Dispose();

		if (!compiled.Success)
		{
			Console.Error.WriteLine(scope $"Samples.Framework: shader compile failed ({label}): {compiled.Messages}");
			return .Err;
		}

		var desc = ShaderModuleDesc();
		desc.Code = compiled.Bytecode;
		desc.Label = label;
		return device.CreateShaderModule(desc);
	}
}
