using System;

namespace Sedulous.Editor.Scene.Tests;

[Reflect(.Type | .NonStaticFields)]
struct WindSettings
{
	public float Speed = 1.0f;

	public this() {}
}
