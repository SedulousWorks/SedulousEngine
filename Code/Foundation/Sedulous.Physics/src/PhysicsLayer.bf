using Sedulous.Core;

namespace Sedulous.Physics;

/// The FIXED semantic table, with a hard coded collision matrix on top of it.
///
/// The four ARE the topology and the addressing model. A designer collision group is
/// additive on top rather than a replacement, and the semantic rules below always win.
[Scriptable(.AllPublic)]
enum PhysicsLayer : uint8
{
	/// Immovable level geometry. Two statics never pair.
	case Static = 0;
	/// Simulated bodies.
	case Dynamic;
	/// Scene driven movers, such as a platform.
	case Kinematic;
	/// A sensor: overlap events, and no collision response.
	case Trigger;

	public const int Count = 4;
}
