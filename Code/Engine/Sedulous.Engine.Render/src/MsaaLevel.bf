using System;

namespace Sedulous.Engine.Render;

/// One offerable scene pass multisampling level: the count, and what to call it.
struct MsaaLevel
{
	public uint32 Samples;
	public StringView Label;

	public this(uint32 samples, StringView label)
	{
		Samples = samples;
		Label = label;
	}
}
