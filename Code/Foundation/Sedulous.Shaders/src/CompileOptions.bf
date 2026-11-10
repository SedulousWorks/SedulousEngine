using System;

namespace Sedulous.Shaders;

/// Everything about a compile except the source and what it is for.
struct CompileOptions
{
	public StringView ShaderModel = "6_0";
	/// The SPIR-V target environment, passed as -fspv-target-env.
	///
	/// vulkan1.3 for the Vulkan backend. WebGPU compiles must ask for vulkan1.1: naga's
	/// SPIR-V frontend rejects the 1.4 and later instructions DXC emits above 1.1,
	/// OpCopyLogical among them.
	public StringView SpirvTargetEnvironment = "vulkan1.3";
	public int32 OptimizationLevel = 3;
	public bool EnableDebugInfo = false;
	public bool RowMajorMatrices = false;
	public Span<ShaderDefine> Defines = default;
	/// Native include directories, passed as -I to the default disk handler. IGNORED when
	/// IncludeResolver is set.
	public Span<StringView> IncludePaths = default;
	/// Where `#include` is resolved from, when it is not the native filesystem. A mount, a
	/// pak or memory: the compiler asks this rather than opening a path.
	public IShaderIncludeResolver IncludeResolver = null;
	public BindingShifts BindingShifts = .();
	/// How many descriptor sets the shifts are applied to.
	///
	/// DXC takes a shift per set, so a shader using set 3 needs the shift declared for set 3
	/// or its bindings land unshifted.
	public uint32 BindingShiftSets = 1;

	/// SPIR-V only: keeps unused stage interface variables rather than stripping them, which
	/// is what makes a declared but unread input still occupy its location. Set from a stage's
	/// `// preserve-interface` directive.
	public bool PreserveInterface = false;

	/// The source's file name as its author knows it (`Toon.hlsl`): DXC's messages name it
	/// (`Toon.hlsl:12:5: error: ...`) instead of a placeholder. Empty is DXC's default.
	public StringView SourceName = default;

	public this() {}

	/// The options a shader the RHI binds directly takes for `target` (an RHI sample's):
	/// optimized, SPIR-V with the standard binding shifts over four sets, and, for native
	/// WebGPU, SPIR-V at vulkan1.1, which naga reads. One definition, so a sample compiled as it
	/// runs and the same sample's shader cooked into a pack are the same bytes.
	public static CompileOptions Direct(ShaderTarget target, StringView shaderModel, bool forWebGpu = false)
	{
		var options = CompileOptions();
		options.ShaderModel = shaderModel;
		options.OptimizationLevel = 3;
		if (target == .SPIRV)
		{
			options.BindingShifts = Sedulous.Shaders.BindingShifts.Standard;
			options.BindingShiftSets = 4;
			if (forWebGpu)
				options.SpirvTargetEnvironment = "vulkan1.1"; // naga rejects SPIR-V 1.4 and later
		}
		return options;
	}
}
