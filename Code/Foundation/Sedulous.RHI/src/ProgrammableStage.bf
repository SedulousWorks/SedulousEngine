using System;

namespace Sedulous.RHI;

/// One programmable stage: a module, the function within it, and which stage it is. An empty
/// EntryPoint means the module's own (ShaderModuleDesc.EntryPoint); see ResolvedEntryPoint.
struct ProgrammableStage
{
	public IShaderModule Module = null;
	public StringView EntryPoint = default;
	public ShaderStage Stage = .None;

	public this() {}

	/// A stage that runs its module's own entry point, the one the module was compiled for.
	public this(IShaderModule module, ShaderStage stage)
	{
		Module = module; Stage = stage;
	}

	public this(IShaderModule module, StringView entryPoint, ShaderStage stage)
	{
		Module = module; EntryPoint = entryPoint; Stage = stage;
	}

	/// The entry point this stage runs: the one it names, else its module's own. Empty when
	/// neither says, which a backend refuses (a module of several entries needs the stage to
	/// choose).
	public StringView ResolvedEntryPoint
	{
		get
		{
			if (!EntryPoint.IsEmpty)
				return EntryPoint;
			return (Module != null) ? Module.EntryPoint : default;
		}
	}
}
