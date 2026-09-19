using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scripting.Tests.Fixture;

[Scriptable]
class FixtureSystem : SceneSystem
{
	[Scriptable]
	public int Ticks => 0;
}
