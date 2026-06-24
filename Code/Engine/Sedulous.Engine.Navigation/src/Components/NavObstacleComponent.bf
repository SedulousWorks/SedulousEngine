namespace Sedulous.Engine.Navigation;

using Sedulous.Engine.Core;
using Sedulous.Inspection;

/// Component for a dynamic navigation obstacle.
/// The NavObstacleComponentManager creates obstacles in the TileCache,
/// updates positions from entity transforms, and rebuilds affected tiles.
[Component]
class NavObstacleComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.Float("Radius", ref Radius);
		s.Float("Height", ref Height);
	}

	// --- Configuration ---

	/// Obstacle radius (cylinder shape).
	[Property(.Default, "Radius", "Radius")]
	public float Radius = 1.0f;

	/// Obstacle height.
	[Property(.Default, "Height", "Height")]
	public float Height = 2.0f;

	// --- Runtime state (managed by NavObstacleComponentManager) ---

	/// Obstacle ID in the NavWorld (-1 = not created).
	public int32 ObstacleId = -1;

	/// Whether this obstacle needs to be added to the TileCache.
	public bool NeedsCreation = true;
}
