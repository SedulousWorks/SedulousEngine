using System;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Tests;

/// Shaders that name their entry points (the RHI samples'): a shader the RHI binds directly
/// names its entry points and model in its own comments, and a cook reads them, so a device
/// with no compiler gets the same modules the sample compiles as it runs.
class EntryShaderTests
{
	/// The `// entry:` and `// model:` lines name what is cooked.
	[Test]
	public static void TheEntryAndModelLinesNameWhatIsCooked()
	{
		let directives = scope ShaderEntryDirectives();
		let error = scope String();
		Test.Assert(ShaderPackCooker.ParseEntryDirectives(
			"// A shader.\n// entry: vertex VSMain\n  // entry: fragment   PSMain  \n// model: 6_5\nfloat4 PSMain() : SV_TARGET { return 1; }\n// entry: raygen",
			directives, error));
		Test.Assert(directives.Entries.Count == 3);
		Test.Assert(directives.Entries[0].Stage == .Vertex);
		Test.Assert(directives.Entries[0].Entry == "VSMain");
		Test.Assert(directives.Entries[1].Stage == .Fragment);
		Test.Assert(directives.Entries[1].Entry == "PSMain");
		Test.Assert(directives.Entries[2].Stage == .RayGen);
		Test.Assert(directives.Entries[2].Entry.IsEmpty); // a ray tracing library's entry has no name
		Test.Assert(directives.ShaderModel == "6_5");

		let none = scope ShaderEntryDirectives();
		Test.Assert(ShaderPackCooker.ParseEntryDirectives("float4 main() : SV_TARGET { return 1; }", none, error));
		Test.Assert(none.Entries.IsEmpty);
		Test.Assert(none.ShaderModel == "6_0");

		let bad = scope ShaderEntryDirectives();
		Test.Assert(!ShaderPackCooker.ParseEntryDirectives("// entry: geometry GSMain", bad, error));
		Test.Assert(error.Contains("geometry"));

		Test.Assert(ShaderPackCooker.EntryShaderName("Sample001_Triangle/Shader.hlsl", "VSMain", .. scope String())
			== "Sample001_Triangle/Shader.hlsl:VSMain");
	}

	/// One definition of how such a shader compiles: SPIR-V takes the standard shifts over four
	/// sets, at vulkan1.1 only for native WebGPU; DXIL takes none.
	[Test]
	public static void DirectOptionsFollowTheTarget()
	{
		let spirv = CompileOptions.Direct(.SPIRV, "6_5");
		Test.Assert(spirv.ShaderModel == "6_5");
		Test.Assert(spirv.OptimizationLevel == 3);
		Test.Assert(spirv.BindingShiftSets == 4);
		Test.Assert(spirv.BindingShifts.TextureShift == BindingShifts.Standard.TextureShift);
		Test.Assert(spirv.BindingShifts.SamplerShift == BindingShifts.Standard.SamplerShift);
		Test.Assert(spirv.BindingShifts.UavShift == BindingShifts.Standard.UavShift);
		Test.Assert(spirv.SpirvTargetEnvironment == "vulkan1.3");

		let webGpu = CompileOptions.Direct(.SPIRV, "6_0", true);
		Test.Assert(webGpu.SpirvTargetEnvironment == "vulkan1.1");

		let dxil = CompileOptions.Direct(.DXIL, "6_0", true);
		Test.Assert(dxil.BindingShiftSets == 1);
		Test.Assert(dxil.BindingShifts.TextureShift == 0);
		Test.Assert(dxil.SpirvTargetEnvironment == "vulkan1.3"); // WebGPU's environment is SPIR-V's alone
	}
}
