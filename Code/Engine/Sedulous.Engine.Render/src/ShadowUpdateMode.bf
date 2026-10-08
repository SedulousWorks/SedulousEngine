using Sedulous.Core;

namespace Sedulous.Engine.Render;

/// How often a local light's shadow is re-rendered.
[Scriptable(.AllPublic)]
enum ShadowUpdateMode : uint32
{
	/// Re-rendered every frame.
	case Realtime = 0;
	/// Rendered into the cached atlas layer, and redrawn when the LIGHT moves or changes, and
	/// where a caster moves, appears or goes (a figure walking, a door swinging) within its
	/// reach. Cheap for scenes that mostly stand still.
	case Static = 1;
}
