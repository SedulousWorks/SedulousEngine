using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// Fitting the shadow maps.
class ShadowMathTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static ViewCamera Camera(float farZ = 100.0f)
	{
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0f, 1.6f, 0.1f, farZ);
		camera.FarZ = farZ;
		return camera;
	}

	/// A round trip: a clip corner unprojected and projected again lands where it started.
	[Test]
	public static void UnprojectingInvertsTheProjection()
	{
		let camera = Camera();
		let viewProj = camera.ViewProjection;
		let inverse = Inverse(viewProj);

		let world = ShadowMath.UnprojectNDC(inverse, 0.5f, -0.25f, 0.5f);
		let backToClip = Float4(world.X, world.Y, world.Z, 1.0f) * viewProj;

		Test.Assert(Near(backToClip.X / backToClip.W, 0.5f, 0.001f));
		Test.Assert(Near(backToClip.Y / backToClip.W, -0.25f, 0.001f));
		Test.Assert(Near(backToClip.Z / backToClip.W, 0.5f, 0.001f));
	}

	/// The cascades cover the shadow distance, each ending further out than the last.
	[Test]
	public static void TheCascadeSplitsAscendToTheShadowDistance()
	{
		let cascades = ShadowMath.ComputeCascades(Camera(), .(0, -1, 0), 100.0f, 1024);

		Test.Assert(cascades.Valid);
		for (int i = 1; i < ShadowCascades.Count; i++)
			Test.Assert(cascades.SplitFar[i] > cascades.SplitFar[i - 1]);

		Test.Assert(Near(cascades.SplitFar[ShadowCascades.Count - 1], 100.0f, 0.5f),
			"the last one reaches the shadow distance");
	}

	/// The near cascades are TIGHTER, which is the whole reason for cascading: the texels
	/// near the camera cover less world.
	[Test]
	public static void TheNearCascadesAreTighter()
	{
		let cascades = ShadowMath.ComputeCascades(Camera(), .(0, -1, 0), 100.0f, 1024);

		for (int i = 1; i < ShadowCascades.Count; i++)
			Test.Assert(cascades.TexelWorldSize[i] > cascades.TexelWorldSize[i - 1]);
	}

	/// The split blends a logarithmic distribution with a uniform one, so the first cascade
	/// ends well short of an even quarter of the range.
	[Test]
	public static void TheSplitsAreBlendedRatherThanEven()
	{
		let cascades = ShadowMath.ComputeCascades(Camera(), .(0, -1, 0), 100.0f, 1024);

		let evenQuarter = 25.0f;
		Test.Assert(cascades.SplitFar[0] < evenQuarter, "nearer than an even split would be");
		Test.Assert(cascades.SplitFar[0] > 0.1f);
	}

	/// A cascade's extent is invariant under CAMERA ROTATION, which is what the bounding
	/// sphere fit buys: a box fit would resize as the camera turns and make the shadows swim.
	[Test]
	public static void RotatingTheCameraDoesNotResizeACascade()
	{
		let straight = ShadowMath.ComputeCascades(Camera(), .(0, -1, 0), 100.0f, 1024);

		var turned = Camera();
		turned.View = Float4x4.LookAtRH(.(0, 0, 0), .(0.7f, 0, -0.7f), .(0, 1, 0));
		let rotated = ShadowMath.ComputeCascades(turned, .(0, -1, 0), 100.0f, 1024);

		for (int i < ShadowCascades.Count)
		{
			Test.Assert(Near(straight.TexelWorldSize[i], rotated.TexelWorldSize[i], 0.001f),
				scope $"cascade {i} changed size when the camera turned");
		}
	}

	/// A LIGHT STRAIGHT DOWN still produces a usable frame: the up axis it looks with cannot
	/// be the axis it looks along.
	[Test]
	public static void ALightStraightDownStillFits()
	{
		let down = ShadowMath.ComputeCascades(Camera(), .(0, -1, 0), 100.0f, 1024);
		let up = ShadowMath.ComputeCascades(Camera(), .(0, 1, 0), 100.0f, 1024);

		for (int i < ShadowCascades.Count)
		{
			Test.Assert(down.TexelWorldSize[i] > 0.0f);
			Test.Assert(up.TexelWorldSize[i] > 0.0f);
			// A degenerate frame would leave the matrix full of nothing.
			Test.Assert(down.ViewProjection[i] != Float4x4());
		}
	}

	/// A shadow distance shorter than the near plane is clamped rather than inverting the
	/// range.
	[Test]
	public static void ADegenerateShadowDistanceIsClamped()
	{
		let cascades = ShadowMath.ComputeCascades(Camera(), .(0, -1, 0), 0.0f, 1024);

		Test.Assert(cascades.Valid);
		for (int i = 1; i < ShadowCascades.Count; i++)
			Test.Assert(cascades.SplitFar[i] >= cascades.SplitFar[i - 1]);
	}

	/// A higher resolution makes each texel cover LESS world, which is what sharpens the
	/// shadows.
	[Test]
	public static void MoreTexelsCoverLessWorldEach()
	{
		let coarse = ShadowMath.ComputeCascades(Camera(), .(0, -1, 0), 100.0f, 512);
		let fine = ShadowMath.ComputeCascades(Camera(), .(0, -1, 0), 100.0f, 2048);

		for (int i < ShadowCascades.Count)
			Test.Assert(fine.TexelWorldSize[i] < coarse.TexelWorldSize[i]);
	}

	// ---- the atlas ----

	/// The tiles walk across each row and then down.
	[Test]
	public static void TheTilesWalkTheAtlas()
	{
		Test.Assert(ShadowMath.AtlasTileRect(0, 2048, 512) == AtlasTile(0, 0, 512, 512));
		Test.Assert(ShadowMath.AtlasTileRect(1, 2048, 512) == AtlasTile(512, 0, 512, 512));
		Test.Assert(ShadowMath.AtlasTileRect(3, 2048, 512) == AtlasTile(1536, 0, 512, 512));
		Test.Assert(ShadowMath.AtlasTileRect(4, 2048, 512) == AtlasTile(0, 512, 512, 512),
			"and wrap onto the next row");
		Test.Assert(ShadowMath.AtlasTileRect(15, 2048, 512) == AtlasTile(1536, 1536, 512, 512));
	}

	/// A tile size of nothing does not divide by nothing.
	[Test]
	public static void ADegenerateTileSizeStillAnswers()
	{
		let tile = ShadowMath.AtlasTileRect(3, 2048, 0);
		Test.Assert(tile.Width == 0);
	}

	/// The scale and bias map a light's clip space into ITS tile, so the sample lands in the
	/// right part of the shared atlas.
	[Test]
	public static void TheEntryMapsIntoItsOwnTile()
	{
		let shadow = ShadowMath.MakeLocalShadow(Float4x4.Identity(), 10.0f, 1.0f, 5, 2048, 512);

		Test.Assert(Near(shadow.AtlasScaleBias.X, 0.25f));
		Test.Assert(Near(shadow.AtlasScaleBias.Y, 0.25f));
		Test.Assert(Near(shadow.AtlasScaleBias.Z, 0.25f), "the second column");
		Test.Assert(Near(shadow.AtlasScaleBias.W, 0.25f), "of the second row");
	}

	/// The near plane scales WITH the range: a fixed tiny near plane crams everything past a
	/// few units into the last thousandth of the depth buffer, and nothing casts at all.
	[Test]
	public static void TheNearPlaneScalesWithTheRange()
	{
		let near = ShadowMath.MakeLocalShadow(Float4x4.Identity(), 4.0f, 1.0f, 0, 2048, 512);
		let far = ShadowMath.MakeLocalShadow(Float4x4.Identity(), 400.0f, 1.0f, 0, 2048, 512);

		// A point midway along each light's range should sit at a comparable depth in both,
		// which it cannot if the near plane is fixed.
		let nearDepth = DepthOf(near.ViewProjection, 2.0f);
		let farDepth = DepthOf(far.ViewProjection, 200.0f);
		Test.Assert(Near(nearDepth, farDepth, 0.02f), scope $"{nearDepth} against {farDepth}");
	}

	private static float DepthOf(Float4x4 viewProj, float distance)
	{
		let clip = Float4(0, 0, -distance, 1.0f) * viewProj;
		return (Abs(clip.W) > 0.0001f) ? (clip.Z / clip.W) : 0.0f;
	}

	/// A spot's frame looks DOWN ITS CONE, and its field of view opens a little wider than
	/// the cone so the filter taps at the rim stay inside the tile.
	[Test]
	public static void ASpotLooksDownItsCone()
	{
		var caster = LocalShadowCaster();
		caster.Type = 2;
		caster.PositionWS = .(0, 10, 0);
		caster.DirectionWS = .(0, -1, 0);
		caster.Range = 20.0f;
		caster.OuterAngle = 0.5f;

		let shadow = ShadowMath.BuildSpotShadow(caster, 0, 2048, 512);

		// A point straight below the light is in front of it, so it lands within clip space.
		let clip = Float4(0, 0, 0, 1.0f) * shadow.ViewProjection;
		Test.Assert(clip.W > 0.0f, "in front of the light");
		Test.Assert(Abs(clip.X / clip.W) < 1.0f);
		Test.Assert(Abs(clip.Y / clip.W) < 1.0f);
	}

	/// Every cube face frames the axis it names, and a face index past the sixth falls back
	/// rather than reading past the table.
	[Test]
	public static void EachCubeFaceLooksDownItsAxis()
	{
		var caster = LocalShadowCaster();
		caster.Type = 1;
		caster.PositionWS = .(0, 0, 0);
		caster.Range = 20.0f;

		// A point on the positive X axis belongs to the first face.
		let face = ShadowMath.BuildPointShadowFace(caster, 0, 0, 2048, 512);
		let clip = Float4(5.0f, 0, 0, 1.0f) * face.ViewProjection;
		Test.Assert(clip.W > 0.0f);
		Test.Assert(Abs(clip.X / clip.W) < 0.5f, "and near the middle of it");

		let outOfRange = ShadowMath.BuildPointShadowFace(caster, 99, 0, 2048, 512);
		Test.Assert(outOfRange.ViewProjection == face.ViewProjection, "it falls back to the first");
	}

	/// The vertical faces cannot use an up axis of Y, since that is what they look along: a
	/// degenerate frame would leave the matrix full of nothing.
	[Test]
	public static void TheVerticalFacesUseAnotherUpAxis()
	{
		var caster = LocalShadowCaster();
		caster.PositionWS = .(0, 0, 0);
		caster.Range = 20.0f;

		for (uint32 face = 2; face <= 3; face++)
		{
			let built = ShadowMath.BuildPointShadowFace(caster, face, 0, 2048, 512);
			let clip = Float4(0, (face == 2) ? 5.0f : -5.0f, 0, 1.0f) * built.ViewProjection;
			Test.Assert(clip.W > 0.0f, scope $"face {face} does not frame its own axis");
		}
	}

	/// The faces open WIDER than a right angle, so a fragment on the exact boundary between
	/// two faces lands inside its tile rather than on the very edge where the filter taps
	/// would fall into the neighbouring one.
	[Test]
	public static void TheCubeFacesOverlapAtTheirBoundaries()
	{
		var caster = LocalShadowCaster();
		caster.PositionWS = .(0, 0, 0);
		caster.Range = 20.0f;

		let face = ShadowMath.BuildPointShadowFace(caster, 0, 0, 2048, 512);
		// Exactly on the boundary between the positive X and positive Z faces.
		let clip = Float4(5.0f, 0.0f, 5.0f, 1.0f) * face.ViewProjection;
		Test.Assert(clip.W > 0.0f);
		Test.Assert(Abs(clip.X / clip.W) < 0.99f, "pulled in off the edge");
	}

	/// A local light's own biases reach its atlas entries: the depth bias as it is, and the
	/// normal offset as world units per unit of distance, its texels times a tile texel's size at
	/// distance one.
	[Test]
	public static void ALocalLightsBiasesReachItsShadowEntries()
	{
		var caster = LocalShadowCaster();
		caster.Type = 2;
		caster.PositionWS = .(0, 5, 0);
		caster.DirectionWS = .(0, -1, 0);
		caster.Range = 20.0f;
		caster.OuterAngle = 0.5f;
		caster.NormalBias = 0.5f;
		caster.DepthBias = 0.004f;

		let spot = ShadowMath.BuildSpotShadow(caster, 0, 2048, 512);
		let fov = Min(caster.OuterAngle * 2.0f + 0.05f, 3.0f);
		Test.Assert(Abs(spot.NormalBiasPerDistance - 0.5f * 2.0f * Math.Tan(fov * 0.5f) / 512.0f) < 1e-6f);
		Test.Assert(spot.DepthBias == 0.004f);

		caster.Type = 1;
		let face = ShadowMath.BuildPointShadowFace(caster, 0, 1, 2048, 512);
		Test.Assert(Abs(face.NormalBiasPerDistance - 0.5f * 2.0f * Math.Tan(1.745f * 0.5f) / 512.0f) < 1e-6f);
		Test.Assert(face.DepthBias == 0.004f);

		// The defaults are today's values.
		let defaults = LocalShadowCaster();
		Test.Assert(defaults.NormalBias == ShadowBiasDefaults.NormalBias);
		Test.Assert(defaults.DepthBias == ShadowBiasDefaults.LocalDepthBias);
		Test.Assert(GpuLight().ShadowStrength == 1.0f, "a light shadows fully unless told otherwise");
	}

	/// A cached tile redraws while a moving caster is in it, and once after it leaves: last
	/// frame's sphere still reaches it, so the figure's shadow leaves the cache too.
	[Test]
	public static void ACachedTileRedrawsWhileAMovingCasterIsInItAndOnceAfterItLeaves()
	{
		let torch = Float3(0.0f, 1.5f, 0.0f);
		BoundingSphere[1] inside = .(.(.(2.0f, 0.9f, 0.0f), 1.0f));
		BoundingSphere[1] away = .(.(.(20.0f, 0.9f, 0.0f), 1.0f));
		BoundingSphere[1] grazing = .(.(.(6.5f, 0.9f, 0.0f), 1.0f)); // its sphere reaches the 6 m volume
		Test.Assert(ShadowMath.MovingCasterTouchesTile(torch, 6.0f, inside, .()));
		Test.Assert(ShadowMath.MovingCasterTouchesTile(torch, 6.0f, grazing, .()));
		Test.Assert(!ShadowMath.MovingCasterTouchesTile(torch, 6.0f, away, .()));
		// Walked out this frame: last frame's sphere still redraws the tile.
		Test.Assert(ShadowMath.MovingCasterTouchesTile(torch, 6.0f, away, inside));
		Test.Assert(!ShadowMath.MovingCasterTouchesTile(torch, 6.0f, away, away));
	}

	/// The cascades start at the camera's own near plane: a camera whose near plane is 2 m, with
	/// uniform splits (lambda nought) over a 60 m reach, ends its first cascade a quarter of the
	/// way from 2 m to 60 m, not from the 0.1 m once assumed.
	[Test]
	public static void TheCascadesStartAtTheCamerasOwnNearPlane()
	{
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 2, 0), .(0, 2, -10), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 16.0f / 9.0f, 2.0f, 400.0f);
		camera.FarZ = 400.0f;
		let sun = Normalized(Float3(-0.17f, -0.87f, -0.47f));
		let cascades = ShadowMath.ComputeCascades(camera, sun, 60.0f, 1024, 0.0f);
		Test.Assert(Near(cascades.SplitFar[0], 2.0f + 58.0f / 4.0f, 0.02f), scope $"{cascades.SplitFar[0]}");
	}

	/// A view's camera reads its kind, planes and height from its projection.
	[Test]
	public static void AViewsCameraReadsItsKindPlanesAndHeightFromItsProjection()
	{
		var camera = ViewCamera();
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 16.0f / 9.0f, 0.5f, 300.0f);
		Test.Assert(!camera.IsOrthographic);
		Test.Assert(Near(camera.NearPlane, 0.5f, 1.0e-3f) && Near(camera.FarPlane, 300.0f, 0.05f));
		Test.Assert(camera.OrthoHeight == 0.0f);

		camera.Projection = Float4x4.OrthographicRH(32.0f, 18.0f, 0.1f, 2000.0f);
		Test.Assert(camera.IsOrthographic);
		Test.Assert(Near(camera.NearPlane, 0.1f, 2.0e-3f) && Near(camera.FarPlane, 2000.0f, 0.2f));
		Test.Assert(Near(camera.OrthoHeight, 18.0f, 1.0e-3f));
	}

	/// An orthographic view's cascades cover its box from the near plane to the reach: a camera
	/// 30 m back and 20 m tall, a point anywhere across the view at any depth up to the reach,
	/// lands inside the cascade that covers its depth.
	[Test]
	public static void AnOrthographicViewsCascadesCoverItsBoxFromTheNearPlaneToTheReach()
	{
		var camera = ViewCamera();
		let eye = Float3(0, 5, 30);
		camera.View = Float4x4.LookAtRH(eye, .(0, 0, 0), .(0, 1, 0));
		camera.Projection = Float4x4.OrthographicRH(20.0f * 16.0f / 9.0f, 20.0f, 0.1f, 200.0f);
		camera.FarZ = 200.0f;
		let sun = Normalized(Float3(-0.17f, -0.87f, -0.47f));
		let cascades = ShadowMath.ComputeCascades(camera, sun, 60.0f, 1024);
		Test.Assert(cascades.Valid);
		let toWorld = Inverse(camera.View);
		let halfW = 10.0f * 16.0f / 9.0f * 0.95f;
		let halfH = 10.0f * 0.95f;
		for (let depth in scope float[](0.5f, 12.0f, 35.0f, 59.0f))
		{
			int c = 0;
			while ((c + 1 < ShadowCascades.Count) && (cascades.SplitFar[c] < depth))
				c++;
			for (let k in scope Float2[](.(-1, -1), .(1, -1), .(1, 1), .(-1, 1), .(0, 0)))
			{
				let world = TransformPoint(Float3(k.X * halfW, k.Y * halfH, -depth), toWorld);
				let lightClip = TransformPoint(world, cascades.ViewProjection[c]);
				Test.Assert((Abs(lightClip.X) <= 1.0f) && (Abs(lightClip.Y) <= 1.0f), scope $"depth {depth}, cascade {c}: {lightClip}");
				Test.Assert((lightClip.Z >= 0.0f) && (lightClip.Z <= 1.0f), scope $"depth {depth}, cascade {c}: {lightClip}");
			}
		}
	}

	/// An orthographic view's sky draws through a perspective stand-in; a perspective view's sky
	/// is the view's own.
	[Test]
	public static void AnOrthographicViewsSkyDrawsThroughAPerspectiveStandIn()
	{
		var camera = ViewCamera();
		let eye = Float3(0, 2, 10);
		camera.Position = eye;
		camera.View = Float4x4.LookAtRH(eye, .(0, 2, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0f, 16.0f / 9.0f, 0.1f, 500.0f);
		let perspectiveSky = SkyProjection.SkyViewProjection(camera);
		let perspectiveView = camera.ViewProjection;
		for (int r < 4)
			for (int c < 4)
				Test.Assert(perspectiveSky.M[r][c] == perspectiveView.M[r][c]);

		// An orthographic view's: a 60 degree perspective looking where the view looks.
		camera.Projection = Float4x4.OrthographicRH(16.0f, 9.0f, 0.1f, 500.0f);
		let sky = SkyProjection.SkyViewProjection(camera);
		// w carries depth again: the view-projection's w column is not nought (view.hlsli's test).
		Test.Assert(Abs(sky.M[0][3]) + Abs(sky.M[1][3]) + Abs(sky.M[2][3]) > 0.5f);
		let inverseSky = Inverse(sky);
		Float3 Ray(float x, float y)
		{
			let h = Float4(x, y, Projection.NdcDepthFar, 1.0f) * inverseSky;
			return Normalized(Float3(h.X / h.W, h.Y / h.W, h.Z / h.W) - eye);
		}
		let centre = Ray(0.0f, 0.0f);
		Test.Assert(Near(centre.Z, -1.0f, 1.0e-4f));
		let top = Ray(0.0f, 1.0f); // half of 60 degrees above the view
		Test.Assert(Near(Atan2(top.Y, -top.Z), 0.5235988f, 1.0e-3f));

		// A direction lands where it did for a still camera, and moves when the camera turns: the
		// sky's motion (a direction through an orthographic matrix has w nought, no motion at all).
		Float2 NdcOf(Float4x4 viewProj, Float3 direction)
		{
			let clip = Float4(direction.X, direction.Y, direction.Z, 0.0f) * viewProj;
			return .(clip.X / clip.W, clip.Y / clip.W);
		}
		let direction = Normalized(Float3(0.2f, 0.1f, -1.0f));
		let still = NdcOf(sky, direction);
		var turned = camera;
		turned.View = Float4x4.LookAtRH(eye, .(0.3f, 2, 0), .(0, 1, 0));
		let moved = NdcOf(SkyProjection.SkyViewProjection(turned), direction);
		Test.Assert(Abs(moved.X - still.X) > 0.01f);
		Test.Assert(moved.X == moved.X, "finite");
	}

	/// A view drawn from behind its eye reaches as far past the eye: the cascades start at the
	/// draw eye, so an orthographic editor view pulled back 40 m must reach 40 m further from
	/// there, or its shadows would end 40 m short of where they did.
	[Test]
	public static void AViewDrawnFromBehindItsEyeReachesAsFarPastTheEye()
	{
		var camera = ViewCamera();
		camera.FarZ = 1000.0f;
		Test.Assert(Math.Abs(ShadowMath.ShadowReach(camera, 120.0f) - 120.0f) < 1e-3f);
		Test.Assert(Math.Abs(ShadowMath.ShadowReach(camera, 0.0f) - 1.0f) < 1e-3f, "at least a metre");
		camera.PullBack = 40.0f;
		camera.FarZ = 1040.0f;
		Test.Assert(Math.Abs(ShadowMath.ShadowReach(camera, 120.0f) - 160.0f) < 1e-3f);
		Test.Assert(Math.Abs(ShadowMath.ShadowReach(camera, 5000.0f) - 1040.0f) < 1e-3f, "never past the far plane");
	}

	private static ViewCamera Looking(Float3 eye, Float3 at, Float3 up, float aspect)
	{
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(eye, at, up);
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, aspect, 0.1f, 250.0f);
		camera.FarZ = 250.0f;
		return camera;
	}

	/// A caster counts when its shadow can fall on what the view receives: the view's frustum
	/// cut at the shadow distance.
	[Test]
	public static void ACasterCountsWhenItsShadowCanFallOnWhatTheViewReceives()
	{
		// A camera at the origin looking down -Z (60 degrees, near 0.1, far 100), shadows to
		// 50 m, the sun straight down and carried 30 m.
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		let receivers = ShadowMath.ShadowReceiverFrustum(camera, 50.0f);
		let down = Float3(0, -1, 0);
		let reach = 30.0f;

		Test.Assert(ShadowMath.CasterShadowReachesView(receivers, down, reach, .(0, 0, -10, 1)), "in view");
		// Above the view, out of it, but its shadow falls through it.
		Test.Assert(ShadowMath.CasterShadowReachesView(receivers, down, reach, .(0, 20, -10, 1)), "above, shadowing it");
		// Higher than the light carries a shadow.
		Test.Assert(!ShadowMath.CasterShadowReachesView(receivers, down, reach, .(0, 40, -10, 1)), "beyond the reach");
		// Just within reach once its diameter counts: the shadow pass clamps a caster's depth,
		// so the part sticking out toward the light still casts.
		Test.Assert(ShadowMath.CasterShadowReachesView(receivers, down, reach, .(0, 37, -10, 1)), "its diameter counts");
		// Behind the camera, its shadow falling straight down behind it too.
		Test.Assert(!ShadowMath.CasterShadowReachesView(receivers, down, reach, .(0, 0, 20, 1)), "behind");
		// In front but past the shadow distance (inside the camera's far plane).
		Test.Assert(!ShadowMath.CasterShadowReachesView(receivers, down, reach, .(0, 0, -80, 1)), "past the cut");
		// Its radius counts: just beyond the cut, but large enough to reach back into it.
		Test.Assert(ShadowMath.CasterShadowReachesView(receivers, down, reach, .(0, 0, -55, 6)), "its radius counts");

		// The view turned to the sky from 2 m up: the forest below shadows nothing it sees.
		var sky = camera;
		sky.View = Float4x4.LookAtRH(.(0, 2, 0), .(0, 3, 0), .(0, 0, -1));
		let skyward = ShadowMath.ShadowReceiverFrustum(sky, 50.0f);
		for (float x = -40.0f; x <= 40.0f; x += 10.0f)
		{
			for (float z = -40.0f; z <= 40.0f; z += 10.0f)
				Test.Assert(!ShadowMath.CasterShadowReachesView(skyward, down, reach, .(x, 0.5f, z, 1.0f)), "below a skyward view");
		}
		// A caster up in the view (a branch overhead) still casts.
		Test.Assert(ShadowMath.CasterShadowReachesView(skyward, down, reach, .(0, 10, 0, 1)), "overhead");
	}

	/// CasterReach is the deepest cascade's depth: as far as any shadow is carried.
	[Test]
	public static void TheCasterReachIsTheDeepestCascadesDepth()
	{
		let camera = Looking(.(0, 2, 0), .(0, 2, -1), .(0, 1, 0), 16.0f / 9.0f);
		let resolution = (uint32)1024;
		let cascades = ShadowMath.ComputeCascades(camera, Normalized(Float3(0.3f, -1.0f, 0.2f)), 200.0f, resolution);
		// Each cascade's box is six radii deep along the light, its radius half its width.
		var deepest = 0.0f;
		for (int c < ShadowCascades.Count)
			deepest = Max(deepest, cascades.TexelWorldSize[c] * (float)resolution * 0.5f * 6.0f);
		Test.Assert(cascades.CasterReach > 0.0f);
		Test.Assert(Near(cascades.CasterReach, deepest, 0.01f));
	}

	/// Fitted to the scene, a cascade shrinks to what of its slice holds anything; one past the
	/// scene draws nothing.
	[Test]
	public static void AFittedCascadeShrinksToWhatOfItsSliceHoldsAnything()
	{
		// A view 2 m up looking down -Z over a scene 30 m tall that ends partway along it.
		let camera = Looking(.(0, 2, 0), .(0, 2, -1), .(0, 1, 0), 1.0f);
		let light = Normalized(Float3(0.3f, -1.0f, 0.2f));
		let resolution = (uint32)1024;
		let slices = ShadowMath.ComputeCascades(camera, light, 200.0f, resolution);
		// The scene ends just before the last cascade's slice begins.
		var scene = AABB(.(-50.0f, -13.0f, -(slices.SplitFar[2] - 1.0f)), .(50.0f, 17.0f, 10.0f));
		let fitted = ShadowMath.ComputeCascades(camera, light, 200.0f, resolution, 0.5f, &scene);

		// The near cascade's slice lies wholly in the scene: unchanged.
		Test.Assert(fitted.HasReceivers[0]);
		Test.Assert(Near(fitted.TexelWorldSize[0], slices.TexelWorldSize[0], 0.0001f));
		// The last slice is past the scene: nothing to shadow there.
		Test.Assert(!fitted.HasReceivers[3]);
		// The third slice spans far more height than the scene's 30 m: it shrinks to the
		// overlap, its texels finer, and still holds what of the scene is in it.
		Test.Assert(fitted.HasReceivers[2]);
		Test.Assert(fitted.TexelWorldSize[2] < slices.TexelWorldSize[2]);
		let mid = (slices.SplitFar[1] + slices.SplitFar[2]) * 0.5f;
		let fittedBox = BoundingFrustum(fitted.ViewProjection[2]);
		Float3[3] inScene = .(.(0, 0, -mid), .(-10, 15, -mid), .(10, -12, -mid));
		for (let p in inScene)
			Test.Assert(fittedBox.Contains(p) != .Disjoint);
		// A fitted box reaches no deeper than the slice's would.
		Test.Assert(fitted.CasterReach > 0.0f);
		Test.Assert(fitted.CasterReach <= slices.CasterReach + 0.001f);

		// No bounds (a scene that draws nothing) fits nothing: the boxes stay the slices'.
		var nothing = AABB.Empty();
		let none = ShadowMath.ComputeCascades(camera, light, 200.0f, resolution, 0.5f, &nothing);
		for (int c < ShadowCascades.Count)
		{
			Test.Assert(none.HasReceivers[c]);
			Test.Assert(Near(none.TexelWorldSize[c], slices.TexelWorldSize[c], 0.0001f));
		}
	}

	/// A cascade shades its slice and the blend band before it, where SampleCSM blends into it.
	[Test]
	public static void ACascadeShadesItsSliceAndTheBlendBandBeforeIt()
	{
		var cascades = ShadowCascades();
		cascades.SplitFar = .(10.0f, 30.0f, 60.0f, 100.0f);
		ShadowMath.CascadeReceiverDepths(cascades, 0.1f, 0, var nearDepth, var farDepth);
		Test.Assert(Near(nearDepth, 0.1f, 0.0001f), "the first starts at the view's near plane");
		Test.Assert(Near(farDepth, 10.0f, 0.0001f));
		ShadowMath.CascadeReceiverDepths(cascades, 0.1f, 1, out nearDepth, out farDepth);
		Test.Assert(Near(nearDepth, 10.0f - 10.0f * ShadowMath.CascadeBlendBand, 0.0001f));
		Test.Assert(Near(farDepth, 30.0f, 0.0001f));
		ShadowMath.CascadeReceiverDepths(cascades, 0.1f, 3, out nearDepth, out farDepth);
		Test.Assert(Near(nearDepth, 60.0f - 30.0f * ShadowMath.CascadeBlendBand, 0.0001f));
		Test.Assert(Near(farDepth, 100.0f, 0.0001f));

		// A slice of the view: a point between its depths is inside, one nearer or further is not.
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 250.0f);
		let slice = ShadowMath.ShadowSliceFrustum(camera, 30.0f, 60.0f);
		Test.Assert(slice.Contains(.(0, 0, -45)) != .Disjoint);
		Test.Assert(slice.Contains(.(0, 0, -20)) == .Disjoint);
		Test.Assert(slice.Contains(.(0, 0, -70)) == .Disjoint);
	}

	/// A shadow runs along the light no further than the scene's bounds.
	[Test]
	public static void AShadowRunsAlongTheLightNoFurtherThanTheScenesBounds()
	{
		// A forest 200 m across, from the ground (0) to the treetops (20 m).
		let scene = AABB(.(-100.0f, 0.0f, -100.0f), .(100.0f, 20.0f, 100.0f));
		let reach = 480.0f; // what the cascades alone would allow
		// Straight down from 10 m up (radius 1): to the ground, and its own radius past it.
		Test.Assert(Near(ShadowMath.ShadowSweepLength(.(0, 10, 0, 1), .(0, -1, 0), reach, scene), 11.0f, 0.001f));
		// Sideways from the middle: to the far side of the scene, not the cascades' whole reach.
		Test.Assert(Near(ShadowMath.ShadowSweepLength(.(0, 10, 0, 1), .(1, 0, 0), reach, scene), 101.0f, 0.001f));
		// A low sun: whichever bound the sweep meets first.
		let low = Normalized(Float3(1.0f, -0.5f, 0.0f));
		let expected = 11.0f / 0.5f * Length(Float3(1.0f, -0.5f, 0.0f));
		Test.Assert(Near(ShadowMath.ShadowSweepLength(.(0, 10, 0, 1), low, reach, scene), expected, expected * 0.001f));
		// Already past the scene along the light: nothing left for its shadow to land on.
		Test.Assert(Near(ShadowMath.ShadowSweepLength(.(0, -50, 0, 1), .(0, -1, 0), reach, scene), 0.0f, 0.0001f));
		// A scene with no bounds leaves the cascades' reach.
		Test.Assert(Near(ShadowMath.ShadowSweepLength(.(0, 10, 0, 1), .(0, -1, 0), reach, AABB.Empty()), reach, 0.0001f));
	}
}
