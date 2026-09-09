using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Physics.Resource;

/// Registration for the physics resource types.
///
/// WHEN the serializable table is populated, and which factories a host wants, stay the
/// application's business, as everywhere else. Without the registration an instance writes
/// its primary fine and reads it back as null, which looks like a missing asset rather
/// than a missing call.
[SerializableRegistry]
static class PhysicsResources
{
	/// The manager does not take ownership, so the caller keeps the factories alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, CollisionShapeFactory shapes,
		PhysicalMaterialFactory materials)
	{
		manager.AddFactory(shapes);
		manager.AddFactory(materials);
	}
}
