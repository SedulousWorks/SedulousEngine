using System;
using Sedulous.Render;
using Sedulous.Resource;

namespace Sedulous.Engine.Render.Tests;

/// Turning an authored look into the renderer's per view configuration, and an editor
/// viewport's ephemeral overrides on top of it.
class ScenePostTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// Every enabled, so an override has something to strip.
	private static ViewPostConfig Base()
	{
		var config = ViewPostConfig();
		config.BloomEnabled = true;
		config.AoMode = 1;
		config.SsrEnabled = true;
		config.SsgiEnabled = true;
		config.TaaEnabled = true;
		config.FxaaEnabled = false;
		config.Exposure = 2.0f;
		config.AutoExposure = true;
		return config;
	}

	/// A DEFAULT block resolves to the renderer's historical globals, so authoring nothing
	/// looks exactly as it did before the settings existed.
	[Test]
	public static void ADefaultBlockResolvesToTheHistoricalGlobals()
	{
		let settings = PostProcessSettings();
		let config = ScenePost.Resolve(settings);

		// Two to the nought.
		Test.Assert(Near(config.Exposure, 1.0f));
		Test.Assert(config.BloomEnabled);
		Test.Assert(Near(config.BloomIntensity, 0.05f));
		Test.Assert(config.AoMode == 0);
		Test.Assert(Near(config.AoStrength, 0.6f));
	}

	/// Exposure is authored in STOPS and applied as a multiplier.
	[Test]
	public static void ExposureResolvesFromStopsToAMultiplier()
	{
		var brighter = PostProcessSettings();
		brighter.ExposureEV = 2.0f;
		Test.Assert(Near(ScenePost.Resolve(brighter).Exposure, 4.0f));

		var darker = PostProcessSettings();
		darker.ExposureEV = -1.0f;
		darker.AoMode = .SSAO;
		darker.BloomEnabled = false;
		let config = ScenePost.Resolve(darker);
		Test.Assert(Near(config.Exposure, 0.5f));
		Test.Assert(config.AoMode == 2);
		Test.Assert(!config.BloomEnabled);
	}

	/// One authored antialiasing mode becomes two EXCLUSIVE flags, and only the temporal one
	/// asks for motion vectors.
	[Test]
	public static void TheAntialiasingModeBecomesExclusiveFlags()
	{
		var temporal = PostProcessSettings();
		temporal.AaMode = .TAA;
		temporal.TaaBlendFactor = 0.9f;
		let taa = ScenePost.Resolve(temporal);
		Test.Assert(taa.TaaEnabled);
		Test.Assert(!taa.FxaaEnabled);
		Test.Assert(Near(taa.TaaBlend, 0.9f));
		Test.Assert(taa.NeedsMotion);

		var spatial = PostProcessSettings();
		spatial.AaMode = .FXAA;
		let fxaa = ScenePost.Resolve(spatial);
		Test.Assert(fxaa.FxaaEnabled);
		Test.Assert(!fxaa.TaaEnabled);
		// Post tonemap and spatial, so no motion.
		Test.Assert(!fxaa.NeedsMotion);
	}

	[Test]
	public static void TheTonemapOperatorAndReflectionsMapStraightThrough()
	{
		var clamped = PostProcessSettings();
		clamped.TonemapOperator = .Clamp;
		Test.Assert(!ScenePost.Resolve(clamped).AgxTonemap);

		var agx = PostProcessSettings();
		agx.TonemapOperator = .AgX;
		Test.Assert(ScenePost.Resolve(agx).AgxTonemap);

		var reflective = PostProcessSettings();
		reflective.SsrEnabled = true;
		reflective.SsrIntensity = 0.7f;
		let ssr = ScenePost.Resolve(reflective);
		Test.Assert(ssr.SsrEnabled);
		Test.Assert(Near(ssr.SsrIntensity, 0.7f));

		var bounced = PostProcessSettings();
		bounced.SsgiEnabled = true;
		bounced.SsgiIntensity = 2.0f;
		let ssgi = ScenePost.Resolve(bounced);
		Test.Assert(ssgi.SsgiEnabled);
		Test.Assert(Near(ssgi.SsgiIntensity, 2.0f));
	}

	/// The adaptation WINDOW is authored in relative stops; the configuration carries the
	/// linear clamps the tonemap compares against.
	[Test]
	public static void TheAutoExposureWindowResolvesStopsToLinearClamps()
	{
		// Off by default, and no grading: a default block stays what it was.
		let defaults = ScenePost.Resolve(PostProcessSettings());
		Test.Assert(!defaults.AutoExposure);
		Test.Assert(defaults.GradingLut == null);
		Test.Assert(Near(defaults.GradingLutSize, 0.0f));

		var settings = PostProcessSettings();
		settings.AutoExposure = true;
		settings.AutoExposureKey = 0.25f;
		settings.AutoExposureSpeed = 3.0f;
		settings.AutoExposureMinEV = -2.0f;
		settings.AutoExposureMaxEV = 3.0f;
		let config = ScenePost.Resolve(settings);
		Test.Assert(config.AutoExposure);
		Test.Assert(Near(config.AutoExposureKey, 0.25f));
		Test.Assert(Near(config.AutoExposureSpeed, 3.0f));
		Test.Assert(Near(config.AutoExposureMin, 0.25f));
		Test.Assert(Near(config.AutoExposureMax, 8.0f));
	}

	/// A grading reference with nothing behind it resolves to NO grading. The strip shape
	/// guard is only consulted on a live product.
	[Test]
	public static void AnUnresolvedGradingReferenceGradesNothing()
	{
		var settings = PostProcessSettings();
		settings.GradingLut.SetId(Guid(0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB));
		settings.GradingIntensity = 0.5f;

		let config = ScenePost.Resolve(settings);
		Test.Assert(config.GradingLut == null);
		Test.Assert(Near(config.GradingLutSize, 0.0f));
	}

	/// A single flag strips just its own effect, and leaves the adaptation alone.
	[Test]
	public static void OneOverrideFlagStripsOnlyItsEffect()
	{
		var config = Base();
		var over = ViewPostOverride();
		over.DisableBloom = true;
		ScenePost.ApplyOverride(ref config, over);
		Test.Assert(!config.BloomEnabled);
		Test.Assert(config.AoMode == 1);
		Test.Assert(config.AutoExposure);

		config = Base();
		over = .();
		over.DisableAo = true;
		ScenePost.ApplyOverride(ref config, over);
		Test.Assert(config.AoMode == 0);
		Test.Assert(config.BloomEnabled);

		config = Base();
		over = .();
		over.DisableSsr = true;
		ScenePost.ApplyOverride(ref config, over);
		Test.Assert(!config.SsrEnabled);

		config = Base();
		over = .();
		over.DisableAa = true;
		ScenePost.ApplyOverride(ref config, over);
		Test.Assert(!config.TaaEnabled);
		Test.Assert(!config.FxaaEnabled);
	}

	/// The master toggle strips the effects but KEEPS exposure and tone mapping, or the image
	/// would not be displayable at all, and it FREEZES the adaptation: an editing viewport
	/// must not shift brightness as the camera crosses between dark and bright regions.
	[Test]
	public static void TheMasterToggleStripsEffectsAndFreezesAdaptation()
	{
		var config = Base();
		var over = ViewPostOverride();
		over.DisablePost = true;
		ScenePost.ApplyOverride(ref config, over);

		Test.Assert(!config.BloomEnabled);
		Test.Assert(config.AoMode == 0);
		Test.Assert(!config.SsrEnabled);
		Test.Assert(!config.SsgiEnabled);
		Test.Assert(!config.TaaEnabled);
		Test.Assert(!config.AutoExposure);
		Test.Assert(Near(config.Exposure, 2.0f));
	}

	[Test]
	public static void AnEmptyOverrideChangesNothing()
	{
		var config = Base();
		ScenePost.ApplyOverride(ref config, ViewPostOverride());
		Test.Assert(config.BloomEnabled);
		Test.Assert(config.SsrEnabled);
		Test.Assert(config.TaaEnabled);
	}
}
