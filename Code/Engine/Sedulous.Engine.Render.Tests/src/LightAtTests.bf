using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// RenderExtract.LightAt: how much light reaches a point. Every enabled light with the
/// renderer's falloff and cone, a shadow casting one stopped by what stands between (the
/// scene's ray query, faked here by a wall), plus the ambient. A game's light meter and a
/// guard's eye read it.
class LightAtTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	/// A wall across the plane x = WallX, answered as the scene's solid surface ray query (the
	/// seam physics fills in a running game). It remembers the group mask it was asked with.
	private class Wall : SceneSystem, ISceneRayQuery
	{
		public float WallX = 1.0f;
		public uint32 LastMask = 0;

		public override ISceneRayQuery AsRayQuery => this;

		public bool CastRay(Float3 origin, Float3 direction, float maxDistance, uint32 groupMask, out SceneRayHit outHit)
		{
			outHit = .();
			LastMask = groupMask;
			if (Math.Abs(direction.X) < 1.0e-6f)
				return false;
			let t = (WallX - origin.X) / direction.X;
			if ((t < 0.0f) || (t > maxDistance))
				return false;
			outHit.Distance = t;
			outHit.Position = origin + direction * t;
			return true;
		}
	}

	private static EntityHandle Place(Scene scene, Float3 at, Quaternion rotation = .Identity)
	{
		let entity = scene.CreateEntity();
		scene.SetLocalTransform(entity, .(at, rotation, .(1, 1, 1)));
		return entity;
	}

	[Test]
	public static void EachEnabledLightIsSummedByTheRenderersFalloffPlusTheAmbient()
	{
		let scene = scope Scene("lightAt");
		let lights = scene.AddSystem<LightComponentManager>();
		let environment = scene.AddSystem<EnvironmentSystem>();
		environment.Environment.AmbientColor = .(1.0f, 1.0f, 1.0f, 1.0f);
		environment.Environment.AmbientIntensity = 0.1f;
		let lamp = lights.Add(Place(scene, .(0.0f, 2.0f, 0.0f)));
		lamp.Type = .Point;
		lamp.Color = .(1.0f, 1.0f, 1.0f, 1.0f);
		lamp.Intensity = 4.0f;
		lamp.Range = 10.0f;
		scene.UpdateTransforms();

		// Two metres below a lamp of range ten: d = 0.2, window (1 - d^4)^2 = 0.99680256, over 4.
		let expected = 4.0f * 0.99680256f / (4.0f + 1e-4f) + 0.1f;
		let lit = RenderExtract.LightAt(scene, .(0.0f, 0.0f, 0.0f));
		Test.Assert(Near(lit.X, expected) && Near(lit.Y, expected) && Near(lit.Z, expected));
		// Past its range: the ambient alone.
		Test.Assert(Near(RenderExtract.LightAt(scene, .(0.0f, 2.0f, 12.0f)).X, 0.1f));
		// Switched off: the ambient alone.
		lamp.Enabled = false;
		Test.Assert(Near(RenderExtract.LightAt(scene, .(0.0f, 0.0f, 0.0f)).X, 0.1f));
	}

	[Test]
	public static void ASpotsConeIsFullInsideTheInnerAngleAndNothingPastTheOuter()
	{
		let scene = scope Scene("lightAt.spot");
		let lights = scene.AddSystem<LightComponentManager>();
		// Pointing straight down: forward is -Z, turned a quarter about X.
		let spot = lights.Add(Place(scene, .(0.0f, 0.0f, 0.0f), Quaternion.FromAxisAngle(.(1, 0, 0), -1.5707963f)));
		spot.Type = .Spot;
		spot.Intensity = 1.0f;
		spot.Range = 0.0f; // no range falloff: the cone alone
		spot.InnerAngle = 0.3f;
		spot.OuterAngle = 0.5f;
		scene.UpdateTransforms();

		Test.Assert(Near(RenderExtract.LightAt(scene, .(0.0f, -2.0f, 0.0f)).X, 1.0f), "on the axis");
		Test.Assert(Near(RenderExtract.LightAt(scene, .(2.0f * Math.Tan(0.7f), -2.0f, 0.0f)).X, 0.0f), "outside");
		let edge = RenderExtract.LightAt(scene, .(2.0f * Math.Tan(0.4f), -2.0f, 0.0f)).X;
		Test.Assert((edge > 0.1f) && (edge < 0.9f), "in the edge");
	}

	[Test]
	public static void AWallStopsAShadowCastingLightByItsStrengthAndOneWithoutShadowsShinesThrough()
	{
		let scene = scope Scene("lightAt.wall");
		let lights = scene.AddSystem<LightComponentManager>();
		let wall = scene.AddSystem<Wall>(); // across x = 1
		let lamp = lights.Add(Place(scene, .(2.0f, 0.0f, 0.0f)));
		lamp.Type = .Point;
		lamp.Range = 0.0f; // no range: the shader applies no falloff at all, so 4 arrives
		lamp.Intensity = 4.0f;
		scene.UpdateTransforms();
		let here = Float3(0.0f, 0.0f, 0.0f);

		// No shadows: the wall does not matter, as it does not on screen.
		Test.Assert(Near(RenderExtract.LightAt(scene, here).X, 4.0f));
		lamp.CastsShadows = true;
		Test.Assert(Near(RenderExtract.LightAt(scene, here).X, 0.0f));
		// A light shadow: three quarters still arrive.
		lamp.ShadowStrength = 0.25f;
		Test.Assert(Near(RenderExtract.LightAt(scene, here).X, 3.0f));
		// On the lamp's side of the wall nothing stands between.
		lamp.ShadowStrength = 1.0f;
		Test.Assert(RenderExtract.LightAt(scene, .(1.5f, 0.0f, 0.0f)).X > 1.0f);
		// The caller's collision groups reach the ray.
		RenderExtract.LightAt(scene, here, 0x5);
		Test.Assert(wall.LastMask == 0x5);
	}

	[Test]
	public static void ADirectionalLightReachesEverywhereUnlessSomethingStandsTowardIt()
	{
		let scene = scope Scene("lightAt.sun");
		let lights = scene.AddSystem<LightComponentManager>();
		let wall = scene.AddSystem<Wall>();
		// Shining along +X (forward -Z, turned a quarter about Y), so the way to it is -X.
		let sun = lights.Add(Place(scene, .(0.0f, 0.0f, 0.0f), Quaternion.FromAxisAngle(.(0, 1, 0), -1.5707963f)));
		sun.Type = .Directional;
		sun.Intensity = 0.5f;
		sun.CastsShadows = true;
		scene.UpdateTransforms();

		wall.WallX = 5.0f; // behind, along the light: no matter
		Test.Assert(Near(RenderExtract.LightAt(scene, .(0.0f, 0.0f, 0.0f)).X, 0.5f));
		wall.WallX = -5.0f; // between the point and the light
		Test.Assert(Near(RenderExtract.LightAt(scene, .(0.0f, 0.0f, 0.0f)).X, 0.0f));
	}

	/// GpuLight.FalloffAt against hand worked values of the forward shader's range window and
	/// spot cone.
	[Test]
	public static void TheFalloffMatchesTheForwardShadersRangeWindowAndSpotCone()
	{
		var point = GpuLight();
		point.Type = 1.0f;
		point.PositionWS = .(0.0f, 2.0f, 0.0f);
		point.Range = 10.0f;
		// d = 0.2 of the range: window (1 - d^4)^2 = 0.99680256, over dist^2 (+1e-4 as in the shader).
		Test.Assert(Near(point.FalloffAt(.(0, 0, 0)), 0.99680256f / 4.0001f));
		Test.Assert(Near(point.FalloffAt(.(0, 12.0f, 0)), 0.0f), "at the range: none");
		point.Range = 0.0f; // no range: the shader answers one, with no inverse square either
		Test.Assert(Near(point.FalloffAt(.(0, 0, 0)), 1.0f));

		var spot = GpuLight();
		spot.Type = 2.0f;
		spot.DirectionWS = .(0.0f, -1.0f, 0.0f);
		spot.InnerCos = Math.Cos(0.3f);
		spot.OuterCos = Math.Cos(0.5f);
		Test.Assert(Near(spot.FalloffAt(.(0, -2.0f, 0)), 1.0f), "the axis");
		Test.Assert(Near(spot.FalloffAt(.(2.0f * Math.Tan(0.7f), -2.0f, 0)), 0.0f), "outside");

		// Directional: everywhere alike.
		let sun = GpuLight();
		Test.Assert(Near(sun.FalloffAt(.(5, 5, 5)), 1.0f));
	}
}
