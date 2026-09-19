using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Script.Fixture;

[Scriptable]
class FixtureSystem : SceneSystem
{
	public int TickCount = 7;
	[Scriptable]
	public int Ticks => TickCount;
}
