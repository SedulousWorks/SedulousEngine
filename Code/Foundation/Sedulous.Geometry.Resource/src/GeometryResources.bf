using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Geometry;

/// Registration for the geometry resource types.
///
/// Calling this stays the application's business, the same as everywhere else: WHEN the
/// serializable table is populated and which factories a host wants are not decisions this
/// project should make for it.
[SerializableRegistry]
static class GeometryResources
{
	/// Registers the mesh factories with a manager. The manager does not take ownership,
	/// so the caller keeps the factories alive for as long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, StaticMeshFactory staticMeshes,
		SkinnedMeshFactory skinnedMeshes)
	{
		manager.AddFactory(staticMeshes);
		manager.AddFactory(skinnedMeshes);
	}
}
