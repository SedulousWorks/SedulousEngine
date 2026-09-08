namespace Sedulous.Materials;

/// What a material instance calls back into, which in practice is the material system.
///
/// An INTERFACE so the edge runs one way: the instance knows nothing about the system, and
/// the system depends on the instance. Without it the two would depend on each other, which
/// is a cycle that has to be broken somewhere and this is the honest place.
interface IMaterialInstanceSink
{
	/// The instance just became dirty, having been clean. Called on the TRANSITION only,
	/// so the system's re-prep is proportional to what changed rather than to how many
	/// instances exist.
	void MarkInstanceDirty(MaterialInstance instance);

	/// The instance is going away and must be dropped from every list holding it.
	void ReleaseInstance(MaterialInstance instance);
}
