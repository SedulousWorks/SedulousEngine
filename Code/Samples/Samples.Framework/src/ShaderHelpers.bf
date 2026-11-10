using System;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Samples.Framework;

/// Compiling HLSL straight to a shader module.
///
/// The samples have no shader system: an RHI sample's shaders are files under
/// Data/Samples/RHI (SampleShaders), and a sample wants a module back. This is the one call
/// that compiles one, and it is where the target is decided so no sample has to remember it;
/// the rest is CompileOptions.Direct, which a cooked pack of the same file takes too.
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

		// The options a cooked pack of the same file uses too (Sedulous.Tools.ShaderPack
		// --entries): only a SPIR-V target takes the shifts, DX12 having register spaces natively.
		var options = CompileOptions.Direct(target, shaderModel, device.Type == .WebGPU);
		options.SourceName = label;

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
		desc.EntryPoint = entryPoint;
		return device.CreateShaderModule(desc);
	}
}
