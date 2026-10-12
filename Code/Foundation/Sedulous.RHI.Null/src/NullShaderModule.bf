using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullShaderModule : IShaderModule
{
	private String mEntryPoint = new .() ~ delete _;

	public StringView EntryPoint => mEntryPoint;

	public this(StringView entryPoint)
	{
		mEntryPoint.Set(entryPoint);
	}
}
