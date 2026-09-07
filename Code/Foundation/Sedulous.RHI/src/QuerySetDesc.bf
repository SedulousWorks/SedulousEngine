using System;

namespace Sedulous.RHI;

struct QuerySetDesc
{
	public QueryType Type = .Timestamp;
	public uint32 Count = 0;
	public StringView Label = default;

	public this() {}
}
