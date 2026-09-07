using System;

namespace Sedulous.RHI;

/// One programmable stage: a module, the function within it, and which stage it is.
struct ProgrammableStage
{
	public IShaderModule Module = null;
	public StringView EntryPoint = "main";
	public ShaderStage Stage = .None;

	public this() {}

	public this(IShaderModule module, StringView entryPoint, ShaderStage stage)
	{
		Module = module; EntryPoint = entryPoint; Stage = stage;
	}
}
