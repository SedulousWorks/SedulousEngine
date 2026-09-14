namespace Samples.AnimatedCrowd;

/// How a character picks its pose out of the shared palettes.
///
/// Random is a function of the flat index, which the renderer can compute itself. The rest are
/// LAYOUT AWARE: they depend on where in the grid a character stands, and the renderer cannot
/// see that, so the sample computes the index and hands it over explicitly.
enum PosePolicy : int32
{
	/// Hashed from the flat index, inside the renderer. No per instance array.
	Random,
	/// A diagonal phase gradient across the grid.
	Wave,
	/// A whole column shares a phase, which reads as a formation.
	Columns,
	/// Cells of four by four characters share a phase, hashed so neighbours differ.
	Clusters,
	/// A scheme authored in the sample itself rather than taken from a render helper, which is
	/// what shows that Explicit accepts ANY index the caller computes.
	Custom
}
