using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;

namespace Sedulous.Physics.Tests;

/// What every world test is built out of.
///
/// The descriptions are mixins so what they hand back lives in the CALLER'S scope: a body
/// description owns its shape list, and a helper that allocated one would hand the caller a
/// thing to free.
static class PhysicsFixture
{
	public const float Step = 1.0f / 60.0f;

	public static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// A wide static slab with its top face at y = nought.
	public static mixin FloorDesc()
	{
		let floor = scope:mixin BodyDesc();
		floor.Motion = .Static;
		floor.Layer = .Static;
		floor.Position = .(0.0f, -0.5f, 0.0f);

		var slab = ShapeDesc();
		slab.Kind = .Box;
		slab.HalfExtents = .(50.0f, 0.5f, 50.0f);
		floor.Shapes.Add(slab);
		floor
	}

	/// A unit box centred at a height.
	public static mixin BoxAt(float y, MotionKind motion = MotionKind.Dynamic)
	{
		// "box" is a keyword, so the local is named for what it describes instead.
		let desc = scope:mixin BodyDesc();
		desc.Motion = motion;
		desc.Layer = (motion == .Static) ? PhysicsLayer.Static : PhysicsLayer.Dynamic;
		desc.Position = .(0.0f, y, 0.0f);

		var cube = ShapeDesc();
		cube.Kind = .Box;
		cube.HalfExtents = .(0.5f, 0.5f, 0.5f);
		desc.Shapes.Add(cube);
		desc
	}

	/// A world with nothing but a floor in it.
	public static mixin FlatWorld()
	{
		let world = scope:mixin PhysicsWorld();
		world.CreateBody(FloorDesc!());
		world
	}

	/// Steps a number of times, which is what letting something settle means here.
	public static void Simulate(PhysicsWorld world, int steps)
	{
		for (int i < steps)
			world.Step(Step);
	}
}
