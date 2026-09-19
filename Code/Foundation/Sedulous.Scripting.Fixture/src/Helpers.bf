using Sedulous.Core;

namespace Sedulous.Scripting.Fixture;

static
{
	[Scriptable]
	public static float Lerp(float a, float b, float t) => a + (b - a) * t;

	public static float NotExposed(float a) => a;
}
