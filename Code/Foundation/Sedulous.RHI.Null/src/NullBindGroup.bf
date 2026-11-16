using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullBindGroup : IBindGroup
{
	private List<BindGroupEntry> mEntries = new .() ~ delete _;

	public IBindGroupLayout Layout => null;
	public void UpdateBindless(Span<BindlessUpdateEntry> entries) {}

	/// The entries the group was created with, so a test can see what a caller bound.
	public Span<BindGroupEntry> Entries => mEntries;

	public void Initialize(Span<BindGroupEntry> entries)
	{
		mEntries.AddRange(entries);
	}
}
