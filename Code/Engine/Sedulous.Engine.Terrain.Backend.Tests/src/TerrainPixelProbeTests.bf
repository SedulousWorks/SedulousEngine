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
	/// The ridge both CASTS into the cascade and RECEIVES from it, on EVERY backend.
	///
	/// Flat ground has one normal, so without shadows a low sun lights both sides of the
	/// ridge equally; with the cascade the ridge darkens the side away from the sun. Either
	/// half of cast or receive missing and the asymmetry never appears.
	///
	/// WebGPU is not along for symmetry. The cascade cast pass is where the live CSM bound
	/// while attached hazard lives: Vulkan tolerates the read and write bind, WebGPU rejects
	/// the pass outright. With that bug WebGPU silently drops the cast and receive work and
	/// the asymmetry vanishes, so running the same scene here is the regression net.
	[Test]
	public static void TheRidgeCastsACascadedShadowOntoTheGround()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu))
		{
			let fixture = scope:: TerrainProbeFixture(kind);
			if (!fixture.Ready)
				continue;

			let grid = TerrainFixtures.MakeRidge();
			defer:: delete grid;

			let config = scope:: TerrainProbeConfig();
			config.Terrain = grid;
			// Top down and far enough out to hold the whole ridge, under a LOW sun so the
			// shadow it throws is long across the ground rather than tucked under it.
			config.Eye = .(0.0f, 260.0f, 0.01f);
			config.Target = .(0.0f, 0.0f, 0.0f);
			config.Up = .(0.0f, 0.0f, 1.0f);
			config.ToLight = Normalized(Float3(0.9f, 0.42f, 0.0f));

			config.Shadows = false;
			let unshadowed = TerrainProbeRenderer.Render(fixture, config);
			defer:: delete unshadowed;
			if (!unshadowed.Valid)
				continue;

			config.Shadows = true;
			let shadowed = TerrainProbeRenderer.Render(fixture, config);
			defer:: delete shadowed;
			Test.Assert(shadowed.Valid, scope $"{kind}: the shadowed frame rendered");

			let unshadowedAsymmetry = Math.Abs(unshadowed.LeftGround - unshadowed.RightGround)
				/ (unshadowed.LeftGround + unshadowed.RightGround);
			let shadowedAsymmetry = Math.Abs(shadowed.LeftGround - shadowed.RightGround)
				/ (shadowed.LeftGround + shadowed.RightGround);

			Test.Assert(unshadowedAsymmetry < 0.06,
				scope $"{kind}: unshadowed, both sides are lit alike");
			Test.Assert(shadowedAsymmetry > 0.15, scope $"{kind}: the cast shadow darkens one side");
			Test.Assert(shadowed.Total < unshadowed.Total * 0.99,
				scope $"{kind}: and a shadow only removes light");
		}
	}

	/// Every backend must render the dome the SAME, with Vulkan as the reference.
	///
	/// This is where a shader cook divergence surfaces: the integer Load on the R16Uint height
	/// texture, which is the load bearing WGSL portability bet, the GBuffer MRT layout, or the
	/// normal and lit path differing between the SPIR-V and WGSL frontends. Asserting against
	/// Vulkan's numbers rather than against constants is what makes it a parity check; the
	/// constants would drift with any deliberate change to the terrain shading.
	[Test]
	public static void EveryBackendMatchesTheVulkanReference()
	{
		let reference = scope TerrainProbeFixture(.Vulkan);
		if (!reference.Ready)
			return;

		let grid = TerrainFixtures.MakeDome();
		defer delete grid;

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;

		let expected = TerrainProbeRenderer.Render(reference, config);
		defer delete expected;
		if (!expected.Valid)
			return;

		for (let kind in scope ProbeBackend[](.WebGpu))
		{
			let fixture = scope:: TerrainProbeFixture(kind);
			if (!fixture.Ready)
				continue;

			let probe = TerrainProbeRenderer.Render(fixture, config);
			defer:: delete probe;
			Test.Assert(probe.Valid, scope $"{kind}: the dome rendered");

			// It rendered terrain rather than a black or failed frame, THEN it matches.
			Test.Assert((double)probe.Filled > cPixels * 0.5, scope $"{kind}: the dome covers the view");
			Within(kind, "filled", (double)probe.Filled, (double)expected.Filled, 0.02);
			Within(kind, "total", probe.Total, expected.Total, 0.05);
			Within(kind, "left luma", probe.LeftLuma, expected.LeftLuma, 0.05);
			Within(kind, "bottom luma", probe.BottomLuma, expected.BottomLuma, 0.05);
		}
	}

	/// Relative comparison against the reference, which is what tolerates driver rounding
	/// while still catching a frontend that shades differently.
	private static void Within(ProbeBackend kind, StringView what, double actual, double expected,
		double epsilon)
	{
		let allowed = Math.Abs(expected) * epsilon;
		Test.Assert(Math.Abs(actual - expected) <= allowed,
			scope $"{kind}: {what} {actual} is not within {epsilon} of Vulkan's {expected}");
	}
}
