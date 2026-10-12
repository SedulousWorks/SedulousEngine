using System;

namespace Sedulous.RHI;

/// One compiled shader blob, in whichever form the device's PreferredShaderFormat named.
interface IShaderModule
{
	/// The entry point the module was compiled for (ShaderModuleDesc.EntryPoint); empty for a
	/// module whose stages name their entries. Set by the device that creates it.
	StringView EntryPoint { get; }
}
