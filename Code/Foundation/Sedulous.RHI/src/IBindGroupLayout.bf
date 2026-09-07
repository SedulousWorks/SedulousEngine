using System;

namespace Sedulous.RHI;

/// The SHAPE of a bind group: which slots exist, of what type, visible to which stages.
///
/// Separate from the group itself because a layout is shared by every pipeline and group
/// that agrees on the shape, and building one is the expensive half.
interface IBindGroupLayout
{
	Span<BindGroupLayoutEntry> Entries { get; }
}
