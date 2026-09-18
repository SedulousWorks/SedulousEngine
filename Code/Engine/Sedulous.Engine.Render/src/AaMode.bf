using Sedulous.Core;

namespace Sedulous.Engine.Render;

/// The anti aliasing path, as ONE enum because the two are exclusive: a frame is smoothed
/// spatially or temporally, never both.
[Scriptable(.AllPublic)]
enum AaMode : uint32
{
	case Off = 0;
	/// Spatial, and cheap.
	case FXAA = 1;
	/// Temporal, which needs motion vectors and a history buffer.
	case TAA = 2;
}
