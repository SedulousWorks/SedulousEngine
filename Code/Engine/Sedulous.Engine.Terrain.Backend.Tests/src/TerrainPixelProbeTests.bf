using System;
using Sedulous.Core;

namespace Sedulous.Engine.Terrain.Backend.Tests;

/// Terrain ground truth at the pixel level on a REAL device.
///
/// The null device suite proves the shaders COMPILE and the draws come out. These prove the
/// pixels are right: that a lit dome covers the view and actually shades, and that the
/// scene's own sun is what drives that shading rather than something baked in.
///
/// BOTH CURRENTLY FAIL, and they fail the same way: the terrain resolves all four of its
/// chunks into draws and the frame records them, yet not one pixel lands, with or without a
/// tone map in the chain. That is the same shape as the temporal resolve and the screen space
/// reflection each rendering black, so it is very likely the same cause, and Raptor's own
/// probe renders this dome lit on this machine.
///
/// The remaining eleven cases of Raptor's suite are left in the ledger rather than ported
/// blind: every one of them reads colours out of a rendered terrain, so with nothing landing
/// they could only be written unverified, and unverified assertions that happen to be red
/// look like coverage without being any.
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
}
