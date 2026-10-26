using Sedulous.Core;

namespace Sedulous.Engine.GUI;

/// What frame a billboard's offset is measured in.
[Scriptable(.AllPublic)]
enum GuiBillboardOrientation : uint8
{
	/// The entity's own space, so the offset turns with the entity.
	case Screen = 0;
	/// World space, so the offset is a fixed lift above the entity however it turns.
	case Cylindrical;
}
