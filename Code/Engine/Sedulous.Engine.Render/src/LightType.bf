using Sedulous.Core;

namespace Sedulous.Engine.Render;

/// What a light is, which decides what its entity transform MEANS.
///
/// Directional reads the entity's forward, which is -Z; point and spot read its world
/// position, and a range with it.
[Scriptable(.AllPublic)]
enum LightType : uint32
{
	case Directional = 0;
	case Point = 1;
	case Spot = 2;
}
