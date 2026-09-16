using System;
using Sedulous.Core;

namespace Sedulous.Engine.Terrain.Backend.Tests;

/// Terrain ground truth at the pixel level on a REAL device.
///
/// The null device suite proves the shaders COMPILE and the draws come out. These prove the
/// pixels are right: that a lit dome covers the view and actually shades, and that the
/// scene's own sun is what drives that shading rather than something baked in.
///
/// The material cases live beside this in TerrainSplatProbeTests.
class TerrainPixelProbeTests
{
	private const double cPixels = (double)TerrainProbeRenderer.Size * TerrainProbeRenderer.Size;

	[Test]
	public static void ALitDomeRendersAndShades()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let grid = TerrainFixtures.MakeDome();
		defer delete grid;

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;

		let probe = TerrainProbeRenderer.Render(fixture, config);
		defer delete probe;
		Test.Assert(probe.Valid, "the dome rendered");

		// It rendered AND it covers the view.
		Test.Assert((double)probe.Filled > cPixels * 0.5, "the dome covers the view");

		// And it SHADES: a flat fill would be symmetric about both axes.
		let asymmetry = Math.Abs(probe.LeftLuma - probe.RightLuma)
			+ Math.Abs(probe.TopLuma - probe.BottomLuma);
		Test.Assert(asymmetry > probe.Total * 0.02, "and shades rather than filling flat");
	}

	[Test]
	public static void TheScenesSunDrivesTheShading()
	{
		// The same dome under a sun from one side and then the other. If the scene's light is
		// what shades it, the asymmetry INVERTS; if the shading were baked into the shader,
		// both would come out the same way round.
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let grid = TerrainFixtures.MakeDome();
		defer delete grid;

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;

		config.ToLight = Normalized(Float3(0.85f, 0.5f, 0.0f));
		let fromPlusX = TerrainProbeRenderer.Render(fixture, config);
		defer delete fromPlusX;

		config.ToLight = Normalized(Float3(-0.85f, 0.5f, 0.0f));
		let fromMinusX = TerrainProbeRenderer.Render(fixture, config);
		defer delete fromMinusX;

		Test.Assert(fromPlusX.Valid && fromMinusX.Valid, "both rendered");

		let deltaA = fromPlusX.LeftLuma - fromPlusX.RightLuma;
		let deltaB = fromMinusX.LeftLuma - fromMinusX.RightLuma;

		Test.Assert(deltaA * deltaB < 0.0, "the asymmetry inverted with the sun");
		Test.Assert(Math.Abs(deltaA) > fromPlusX.Total * 0.02, "and it is a real asymmetry");
		Test.Assert(Math.Abs(deltaB) > fromMinusX.Total * 0.02, "both ways round");
	}
	/// The ridge both CASTS into the cascade and RECEIVES from it.
	///
	/// Flat ground has one normal, so without shadows a low sun lights both sides of the
	/// ridge equally; with the cascade the ridge darkens the side away from the sun. Either
	/// half of cast or receive missing and the asymmetry never appears.
	[Test]
	public static void TheRidgeCastsACascadedShadowOntoTheGround()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let grid = TerrainFixtures.MakeRidge();
		defer delete grid;

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;
		// Top down and far enough out to hold the whole ridge, under a LOW sun so the shadow
		// it throws is long across the ground rather than tucked under it.
		config.Eye = .(0.0f, 260.0f, 0.01f);
		config.Target = .(0.0f, 0.0f, 0.0f);
		config.Up = .(0.0f, 0.0f, 1.0f);
		config.ToLight = Normalized(Float3(0.9f, 0.42f, 0.0f));

		config.Shadows = false;
		let unshadowed = TerrainProbeRenderer.Render(fixture, config);
		defer delete unshadowed;
		if (!unshadowed.Valid)
			return;

		config.Shadows = true;
		let shadowed = TerrainProbeRenderer.Render(fixture, config);
		defer delete shadowed;
		Test.Assert(shadowed.Valid, "the shadowed frame rendered");

		let unshadowedAsymmetry = Math.Abs(unshadowed.LeftGround - unshadowed.RightGround)
			/ (unshadowed.LeftGround + unshadowed.RightGround);
		let shadowedAsymmetry = Math.Abs(shadowed.LeftGround - shadowed.RightGround)
			/ (shadowed.LeftGround + shadowed.RightGround);

		Test.Assert(unshadowedAsymmetry < 0.06, "unshadowed, both sides are lit alike");
		Test.Assert(shadowedAsymmetry > 0.15, "the cast shadow darkens one side");
		Test.Assert(shadowed.Total < unshadowed.Total * 0.99, "and a shadow only removes light");
	}
}
