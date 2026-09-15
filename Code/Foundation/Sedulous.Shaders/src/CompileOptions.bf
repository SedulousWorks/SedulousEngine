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

	public this() {}
}
