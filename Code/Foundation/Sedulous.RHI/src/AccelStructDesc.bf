using System;

namespace Sedulous.RHI;

struct AccelStructDesc
{
	public AccelStructType Type = .BottomLevel;
	public AccelStructBuildFlags Flags = .PreferFastTrace;
	public StringView Label = default;

	public this() {}
}
