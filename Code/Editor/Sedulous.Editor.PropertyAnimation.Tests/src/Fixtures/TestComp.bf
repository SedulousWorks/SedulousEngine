using System;
using Sedulous.Core;

namespace Sedulous.Editor.PropertyAnimation.Tests;

/// A nested reflected struct, the Light.Tint path.
[Reflect(.Type | .NonStaticFields)]
struct TestLight
{
	public Color Tint = .(1.0f, 1.0f, 1.0f, 1.0f);

	public this() {}
}

/// A component-like reflected struct: animatable leaves (Float3, Quat, float), a nested Color,
/// and a non-animatable int the collector must skip.
[Reflect(.Type | .NonStaticFields)]
struct TestComp
{
	public Float3 Position = .(0.0f, 0.0f, 0.0f);
	public Quaternion Rotation = .Identity;
	public float Intensity = 0.0f;
	public int32 Flags = 0;
	public TestLight Light = .();

	public this() {}
}
