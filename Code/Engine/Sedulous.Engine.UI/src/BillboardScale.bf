using Sedulous.Core;

namespace Sedulous.Engine.UI;

/// Whether a billboard shrinks with distance.
[Scriptable(.AllPublic)]
enum BillboardScale : uint8
{
	case Fixed = 0;
	case Distance;
}
