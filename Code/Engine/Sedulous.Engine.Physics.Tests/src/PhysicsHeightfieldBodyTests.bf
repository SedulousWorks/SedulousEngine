using System;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Heightfield;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// A heightfield body collides where its terrain is drawn: at its entity's scale, and on the rim
/// drawn around a hole.
class PhysicsHeightfieldBodyTests
{
	private static bool Near(float a, float b, float epsilon) => Math.Abs(a - b) <= epsilon;

	/// A flat 65x65 heightfield (1 m cells over 64 m, centred) at world Y = 2.
	private static void Flatten(Heightfield heightfield)
	{
		let flat = heightfield.WorldYToSample(2.0f);
		let samples = heightfield.Samples;
		for (int i < samples.Length)
			samples[i] = flat;
	}

	private static EntityHandle AddHeightfieldGround(PhysicsPlayScene play, Heightfield heightfield)
	{
		let ground = play.Scene.CreateEntity("heightfield");
		let body = play.Bodies.Add(ground);
		body.Motion = .Static;
		body.Layer = .Static;
		body.Shape = .Heightfield;
		body.Heightfield.SetDirect(heightfield);
		return ground;
	}

	private static bool GroundAt(PhysicsPlayScene play, float x, float z, out float y)
	{
		y = 0.0f;
		var hit = RayHit();
		if (!play.Physics.World.RayCast(.(x, 50.0f, z), .(0, -1, 0), 100.0f, out hit))
			return false;
		y = hit.Position.Y;
		return true;
	}

	/// Physics dropped every triangle at a cut sample, while the terrain draws a cell until all
	/// its samples are cut, shaping the rim at the bilinear mask's half: around one cut sample,
	/// ground was drawn where nothing collided.
	[Test]
	public static void AHolesDrawnRimCollidesAndTheCutItselfDoesNot()
	{
		let heightfield = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 4.0f);
		Flatten(heightfield);
		heightfield.SetHole(32, 32, true); // the sample at the origin
		let play = scope PhysicsPlayScene();
		AddHeightfieldGround(play, heightfield);
		play.Start();
		play.Step(1);

		// In each of the four cells around the cut, the corner away from it is drawn ground.
		float[4][2] corners = .(.(0.75f, 0.75f), .(-0.75f, 0.75f), .(0.75f, -0.75f), .(-0.75f, -0.75f));
		float y = 0.0f;
		for (let c in corners)
		{
			Test.Assert(GroundAt(play, c[0], c[1], out y), scope $"ground at {c[0]}, {c[1]}");
			Test.Assert(Near(y, 2.0f, 0.02f), scope $"at {c[0]}, {c[1]}: {y}");
		}
		// At the cut sample, and close to it (the mask above one half), there is nothing.
		Test.Assert(!GroundAt(play, 0.0f, 0.0f, out y), "nothing at the cut");
		Test.Assert(!GroundAt(play, 0.15f, 0.15f, out y), "nothing beside the cut");
		// Far from it, the heightfield as ever.
		Test.Assert(GroundAt(play, 10.0f, 10.0f, out y));
		Test.Assert(Near(y, 2.0f, 0.02f), scope $"far ground at {y}");
	}

	/// A terrain entity scaled up collided at its unscaled size.
	[Test]
	public static void AHeightfieldTakesItsEntitysScale()
	{
		let heightfield = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 4.0f);
		Flatten(heightfield);
		let play = scope PhysicsPlayScene();
		let ground = AddHeightfieldGround(play, heightfield);
		var transform = play.Scene.GetLocalTransform(ground);
		transform.Scale = .(2.0f, 3.0f, 2.0f);
		play.Scene.SetLocalTransform(ground, transform);
		play.Start();
		play.Step(1);

		// Past the unscaled 32 m half extent; a 2 m surface, three times as tall.
		float y = 0.0f;
		Test.Assert(GroundAt(play, 50.0f, 50.0f, out y), "ground past the unscaled extent");
		Test.Assert(Near(y, 6.0f, 0.06f), scope $"surface at {y}");
	}
}
