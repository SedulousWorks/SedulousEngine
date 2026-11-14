using System;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Scene;
using Sedulous.VFS;

namespace Sedulous.Engine.Render.Tests;

/// A quality level over what a scene asks for: an Off tier turns its effect off, the level sets
/// the MSAA count and the antialiasing, its shadows Off draws none and its cap shortens their
/// reach; no tier turns an effect on.
class QualityLevelTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void ALevelTurnsEffectsOffAndSetsTheMsaaAndAaNeverTurningOneOn()
	{
		// A scene that asks for everything.
		var scene = PostProcessSettings();
		scene.AoMode = .GTAO;
		scene.SsrEnabled = true;
		scene.SsgiEnabled = true;
		scene.BloomEnabled = true;
		scene.TaaBlendFactor = 0.9f;

		// The engine's own highest: every effect the scene asks for runs, at 4x MSAA, with no AA.
		{
			var config = ScenePost.Resolve(scene);
			QualityApply.Apply(ref config, scope RenderQualitySettings(), true);
			Test.Assert(config.AoMode == (uint32)AoMode.GTAO);
			Test.Assert(config.SsrEnabled && config.SsgiEnabled && config.BloomEnabled);
			Test.Assert(config.MsaaSamples == 4);
			Test.Assert(!config.TaaEnabled && !config.FxaaEnabled);
		}
		// A phone's level: each Off turns its effect off; MSAA off; TAA runs, with the scene's look.
		let phone = scope RenderQualitySettings();
		phone.MsaaSamples = 1;
		phone.Antialiasing = .TAA;
		phone.AmbientOcclusion = .Off;
		phone.Reflections = .Off;
		phone.GlobalIllumination = .Off;
		phone.Bloom = .Off;
		{
			var config = ScenePost.Resolve(scene);
			QualityApply.Apply(ref config, phone, true);
			Test.Assert(config.AoMode == 0);
			Test.Assert(!config.SsrEnabled && !config.SsgiEnabled && !config.BloomEnabled);
			Test.Assert(config.MsaaSamples == 1);
			Test.Assert(config.TaaEnabled && Near(config.TaaBlend, 0.9f));
			Test.Assert(config.NeedsMotion, "TAA reads motion vectors");
		}
		// FXAA: no motion. A level whose tiers are High turns nothing on that the scene left off.
		{
			var plain = PostProcessSettings();
			plain.BloomEnabled = false;
			let fxaa = scope RenderQualitySettings();
			fxaa.Antialiasing = .FXAA;
			var config = ScenePost.Resolve(plain);
			QualityApply.Apply(ref config, fxaa, true);
			Test.Assert(config.FxaaEnabled && !config.TaaEnabled && !config.NeedsMotion);
			Test.Assert(config.AoMode == 0);
			Test.Assert(!config.SsrEnabled && !config.SsgiEnabled && !config.BloomEnabled);
		}
		// Without `antialiasing` (a debug panel set its own), the view's AA stays as it was.
		{
			var config = ScenePost.Resolve(scene);
			config.FxaaEnabled = true;
			QualityApply.Apply(ref config, phone, false);
			Test.Assert(config.FxaaEnabled && !config.TaaEnabled);
			Test.Assert(config.MsaaSamples == 1, "the count is the level's either way");
		}
	}

	[Test]
	public static void ALevelsShadowsOffDrawsNoneAndItsCapShortensTheReach()
	{
		let extracted = scope ExtractedScene();
		var sun = GpuLight();
		sun.ShadowIndex = 0.0f; // the cascades
		extracted.AddLight(sun);
		var lamp = GpuLight();
		lamp.ShadowIndex = 2.0f; // an atlas tile
		extracted.AddLight(lamp);
		extracted.AddLocalShadowCaster(LocalShadowCaster());
		var shadow = DirectionalShadow();
		shadow.Valid = true;
		extracted.SetDirectionalShadow(shadow);
		extracted.SetShadowSettings(SceneShadowSettings(300.0f, 0.5f, 40.0f));

		// High, with no cap: the scene's shadows as extracted.
		QualityApply.Apply(extracted, scope RenderQualitySettings());
		Test.Assert(extracted.DirectionalShadowData.Valid);
		Test.Assert(extracted.LocalShadowCasters.Length == 1);
		Test.Assert(Near(extracted.ShadowSettings.Distance, 300.0f));

		// A cap shorter than the scene's reach takes its place; one longer leaves it.
		let capped = scope RenderQualitySettings();
		capped.ShadowDistanceMax = 60.0f;
		QualityApply.Apply(extracted, capped);
		Test.Assert(Near(extracted.ShadowSettings.Distance, 60.0f));
		Test.Assert(Near(extracted.ShadowSettings.CascadeSplit, 0.5f));
		capped.ShadowDistanceMax = 500.0f;
		QualityApply.Apply(extracted, capped);
		Test.Assert(Near(extracted.ShadowSettings.Distance, 60.0f));

		// Off: no sun cascades, no local tiles, and no light reads a shadow.
		let off = scope RenderQualitySettings();
		off.Shadows = .Off;
		QualityApply.Apply(extracted, off);
		Test.Assert(!extracted.DirectionalShadowData.Valid);
		Test.Assert(extracted.LocalShadowCasters.IsEmpty);
		Test.Assert(extracted.Lights.Length == 2);
		for (let light in extracted.Lights)
			Test.Assert(Near(light.ShadowIndex, -1.0f));
	}

	/// A game's level keeps the scene's own post settings (its profile's auto exposure, AO, SSR)
	/// in effect; the level sets the MSAA count and the AA. A Game tab plays at its game's level
	/// while the editor's own views keep the global one.
	[Test]
	public static void AViewDrawsAtItsViewportsLevelElseTheGlobalOneOverTheScenesPost()
	{
		let dataRoot = FindDataRoot(.. scope String());
		if (dataRoot.IsEmpty)
			return;
		let mount = scope NativeFileSystem(dataRoot);

		let backend = NullRhi.CreateBackend();
		defer { backend.Destroy(); delete backend; }
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		defer device.Destroy();

		let subsystem = scope RenderSubsystem(device, 2, mount);

		let scene = scope Scene("quality");
		let post = scene.AddSystem<PostProcessSystem>();
		post.Post.AutoExposure = true;
		post.Post.AoMode = .SSAO;
		post.Post.SsrEnabled = true;

		// Until a host sets one, the engine's own highest.
		Test.Assert(subsystem.Quality.MsaaSamples == 4);
		let game = scope RenderQualitySettings();
		game.MsaaSamples = 2;
		game.Antialiasing = .TAA;
		subsystem.SetQuality(game);
		game.MsaaSamples = 1; // a copy was taken
		let level = subsystem.ViewPost(scene);
		Test.Assert(level.MsaaSamples == 2);
		Test.Assert(level.TaaEnabled);
		Test.Assert(level.AutoExposure);
		Test.Assert(level.AoMode == (uint32)AoMode.SSAO);
		Test.Assert(level.SsrEnabled);

		// A viewport's own level, for its views alone, until cleared.
		int gameTab = 0;
		let phone = scope RenderQualitySettings();
		phone.MsaaSamples = 1;
		phone.Antialiasing = .FXAA;
		phone.AmbientOcclusion = .Off;
		subsystem.SetViewportQuality(&gameTab, phone);
		phone.MsaaSamples = 2;
		subsystem.SetViewportQuality(&gameTab, phone); // again: its own, replaced
		let tab = subsystem.ViewPost(scene, &gameTab);
		Test.Assert(tab.MsaaSamples == 2);
		Test.Assert(tab.FxaaEnabled);
		Test.Assert(tab.AoMode == 0);
		Test.Assert(subsystem.QualityFor(&gameTab).Antialiasing == .FXAA);
		Test.Assert(subsystem.ViewPost(scene).AoMode == (uint32)AoMode.SSAO, "other views keep the global level");
		subsystem.ClearViewportQuality(&gameTab);
		Test.Assert(subsystem.ViewPost(scene, &gameTab).AoMode == (uint32)AoMode.SSAO);
		Test.Assert(subsystem.QualityFor(&gameTab) === subsystem.Quality);

		// A sample's debug panel still overrides the scene's look and its AA, under the level's
		// MSAA.
		subsystem.Exposure = 2.0f;
		let overridden = subsystem.ViewPost(scene);
		Test.Assert(Near(overridden.Exposure, 2.0f));
		Test.Assert(!overridden.AutoExposure);
		Test.Assert(overridden.MsaaSamples == 2);
		Test.Assert(!overridden.TaaEnabled, "the panel's own TAA setting (off)");
	}
}
