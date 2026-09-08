using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene.Resource.Tests;

/// One per scene settings block.
struct WorldSettings
{
	public float Gravity = -9.81f;
	public Float3 Wind = .(0, 0, 0);

	public this() {}
}
