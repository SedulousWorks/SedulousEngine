using Sedulous.Core.Serialization;

using Sedulous.Core;

namespace Sedulous.Engine.Navigation;

/// The per scene navigation settings, which is what the debug overlay is gated on.
///
/// Both overlays work in an editor AND in a player, following the physics debugging
/// precedent: gated here, drawn by the runtime subsystem.
[DisplayName("Navigation Settings")]
[Category("Navigation")]
[Scriptable]
struct NavigationSceneSettings : ISerializable
{
	/// Draws the LOADED navmesh surface, which is what agents actually path on.
	[Scriptable]
	public bool DebugDraw = false;
	/// Adds each agent's target line and its crowd state.
	[Scriptable]
	public bool DebugDrawPaths = false;
	/// The last bake's intermediate data, the walkable spans and the region contours: HOW the
	/// bake arrived at the mesh. Cleared per bake; the live mesh above stays the ground truth
	/// for what a query sees.
	[Scriptable]
	public bool DebugDrawBakeStages = false;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "debugDraw", ref DebugDraw);
		SerializeValue(ar, "debugDrawPaths", ref DebugDrawPaths);
		SerializeValue(ar, "debugDrawBakeStages", ref DebugDrawBakeStages);
	}
}
