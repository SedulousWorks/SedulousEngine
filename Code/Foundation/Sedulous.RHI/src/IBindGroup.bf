using System;

namespace Sedulous.RHI;

/// Actual resources filled into a layout's slots, bound to a pipeline as a unit.
interface IBindGroup
{
	IBindGroupLayout Layout { get; }

	/// Rewrites individual slots of a BINDLESS group in place.
	///
	/// Bindless arrays are unbounded and written as they change rather than rebuilt, which
	/// is the point of them: a group holding every texture in the scene cannot be recreated
	/// each time one is streamed in.
	void UpdateBindless(Span<BindlessUpdateEntry> entries);
}
