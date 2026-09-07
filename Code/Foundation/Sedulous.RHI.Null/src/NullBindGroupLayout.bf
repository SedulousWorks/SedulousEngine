using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullBindGroupLayout : IBindGroupLayout
{
	/// Empty: the null backend records no entries, so nothing can be validated against them
	/// here. The validation layer is where that checking lives.
	public Span<BindGroupLayoutEntry> Entries => default;
}
