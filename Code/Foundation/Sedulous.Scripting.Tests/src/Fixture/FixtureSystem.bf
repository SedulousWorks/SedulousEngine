using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scripting.Tests.Fixture;

[Scriptable]
class FixtureSystem : SceneSystem
{
	public int TickCount = 7;
	[Scriptable]
	public int Ticks => TickCount;
}
