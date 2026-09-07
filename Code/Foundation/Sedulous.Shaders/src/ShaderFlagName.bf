using System;

namespace Sedulous.Shaders;

/// One flag and the `#define` it emits.
struct ShaderFlagName
{
	public ShaderFlags Flag;
	public StringView Define;

	public this(ShaderFlags flag, StringView define)
	{
		Flag = flag;
		Define = define;
	}
}
