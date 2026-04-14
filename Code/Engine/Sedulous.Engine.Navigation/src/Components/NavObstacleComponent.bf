namespace Sedulous.Engine.Navigation;

using Sedulous.Scenes;

/// Component for a dynamic navigation obstacle.
/// The NavObstacleComponentManager creates obstacles in the TileCache,
/// updates positions from entity transforms, and rebuilds affected tiles.
class NavObstacleComponent : Component
{
	// --- Configuration ---

	/// Obstacle radius (cylinder shape).
	public float Radius = 1.0f;

	/// Obstacle height.
	public float Height = 2.0f;

	// --- Runtime state (managed by NavObstacleComponentManager) ---

	/// Obstacle ID in the NavWorld (-1 = not created).
	public int32 ObstacleId = -1;

	/// Whether this obstacle needs to be added to the TileCache.
	public bool NeedsCreation = true;
}
