using System;

namespace Sedulous.RHI;

struct BindGroupLayoutDesc
{
	public Span<BindGroupLayoutEntry> Entries = default;
	public StringView Label = default;

	public this() {}
}
