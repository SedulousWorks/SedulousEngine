using System;

namespace Sedulous.RHI;

struct BindGroupDesc
{
	public IBindGroupLayout Layout = null;
	public Span<BindGroupEntry> Entries = default;
	public StringView Label = default;

	public this() {}
}
