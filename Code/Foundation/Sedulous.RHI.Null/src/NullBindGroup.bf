using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullBindGroup : IBindGroup
{
	public IBindGroupLayout Layout => null;
	public void UpdateBindless(Span<BindlessUpdateEntry> entries) {}
}
