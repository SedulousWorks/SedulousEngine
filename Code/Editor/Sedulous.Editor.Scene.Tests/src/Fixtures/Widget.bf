using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// A NON serializable component with reflected fields, so a remove undo goes through the
/// per field snapshot and a property edit through reflection.
[Component]
struct Widget
{
	public float Speed = 1.0f;
	public bool Spin = false;
	public Float3 Offset = .(0, 0, 0);
	public TestMode Mode = .Off;

	public this() {}
}
