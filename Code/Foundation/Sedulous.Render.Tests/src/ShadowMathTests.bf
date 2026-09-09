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
}
