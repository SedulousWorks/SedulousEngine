using System;
using Sedulous.Core;

namespace Sedulous.Scripting.Tests.Fixture;

/// A value type with the whole public data surface exposed, some marked methods, and a
/// public field hidden by hand.
[Scriptable(.AllPublic)]
[DisplayName("Vector 2")]
[Description("A two component vector.")]
struct Vec2
{
	public float X;
	[Range(0, 1, 0.1f)]
	public float Y;
	public static readonly Vec2 Zero = .(0, 0);
	[Hidden]
	public int Scratch;

	public float Length => 0.0f;
	public float Scale { get; set mut; }

	[Scriptable]
	public this(float x, float y)
	{
		X = x;
		Y = y;
		Scratch = 0;
		Scale = 1.0f;
	}

	[Scriptable]
	public static float Dot(Vec2 a, Vec2 b) => a.X * b.X + a.Y * b.Y;

	public Vec2 Normalized() => this;
}
