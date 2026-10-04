using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render.Tests;

/// The scene's environment reaching the snapshot: the sky product's IDENTITY and shape, and
/// the lighting dimmers beside it.
class EnvironmentExtractTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void TheSkyTextureProductCarriesItsIdentityAndCubeFlag()
	{
		let scene = scope Scene("s");
		let system = scene.AddSystem<EnvironmentSystem>();
		system.Environment.SkyMode = .Cubemap;

		// A cube shaped product. No GPU objects are needed: the identity and the shape are
		// what extraction reads.
		let sky = scope Texture();
		sky.Adopt(null, null, null, null, 64, 64, .RGBA8Unorm, true);
		// A direct override; the picker and the serialized path bind by id instead.
		system.Environment.SkyTexture.SetDirect(sky);

		// The lighting dimmers ride the snapshot, one being full physical strength.
		system.Environment.IblDiffuseIntensity = 0.4f;
		system.Environment.IblSpecularIntensity = 0.7f;

		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractEnvironmentInto(scene, snapshot);
			let extracted = snapshot.Sky;
			Test.Assert(extracted.Mode == .Cubemap);
			Test.Assert(extracted.TextureUid == sky.Uid);
			Test.Assert(extracted.TextureUid != 0);
			Test.Assert(extracted.TextureIsCube);
			Test.Assert(Near(extracted.IblDiffuseIntensity, 0.4f));
			Test.Assert(Near(extracted.IblSpecularIntensity, 0.7f));
		}

		// No texture means NO identity, which leaves the lighting on its procedural source.
		system.Environment.SkyTexture = .(Guid());
		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractEnvironmentInto(scene, snapshot);
			Test.Assert(snapshot.Sky.TextureUid == 0);
		}
	}

	/// The scene's render clock: it adds the scene's OWN delta, holds still at nought, and
	/// rides the snapshot.
	[Test]
	public static void TheSceneClockAddsTheScenesOwnDeltaAndRidesTheSnapshot()
	{
		let scene = scope Scene("s");
		RenderScene.AddRenderSceneManagers(scene);
		let system = scene.GetSystem<EnvironmentSystem>();
		Test.Assert(system != null);
		scene.Start();
		Test.Assert(system.TimeSeconds == 0.0f);

		// The delta a scene is updated with is the one its manager composed, the context,
		// group and scene scales together: the clock adds exactly that, once a frame, keeping
		// last frame's value for the motion vectors.
		scene.Update(0.5f);
		Test.Assert(Near(system.TimeSeconds, 0.5f));
		Test.Assert(Near(system.PrevTimeSeconds, 0.0f));
		scene.Update(0.25f);
		Test.Assert(Near(system.TimeSeconds, 0.75f));
		Test.Assert(Near(system.PrevTimeSeconds, 0.5f));

		// A paused scene, whose scale takes the delta to nought, holds still.
		scene.Update(0.0f);
		Test.Assert(Near(system.TimeSeconds, 0.75f));
		Test.Assert(Near(system.PrevTimeSeconds, 0.75f));

		// The editor's editing scene ticks with simulation DISABLED, Simulate being what
		// enables it: the clock does not advance there, so a frozen world's grass stands still.
		scene.SetSimulationEnabled(false);
		scene.Update(0.5f);
		Test.Assert(Near(system.TimeSeconds, 0.75f));
		Test.Assert(Near(system.PrevTimeSeconds, 0.75f));
		scene.SetSimulationEnabled(true);
		scene.Update(0.5f);
		Test.Assert(Near(system.TimeSeconds, 1.25f));
		scene.SetSimulationEnabled(false);
		scene.Update(0.5f);

		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractEnvironmentInto(scene, snapshot);
		Test.Assert(snapshot.HasTime);
		Test.Assert(Near(snapshot.TimeSeconds, 1.25f));
		Test.Assert(Near(snapshot.PrevTimeSeconds, 0.75f));

		// A scene without the system stamps none, and the frame's own clock stands in.
		let bare = scope Scene("bare");
		let none = scope ExtractedScene();
		RenderExtract.ExtractEnvironmentInto(bare, none);
		Test.Assert(!none.HasTime);
	}

	/// The scene's shadow reach rides the snapshot, so two scenes in one frame keep their own;
	/// and a shorter reach gives the near cascade smaller texels, which is what sharpens a roof's
	/// shadow on a wall.
	[Test]
	public static void TheScenesShadowReachRidesTheSnapshot()
	{
		let scene = scope Scene("reach");
		let system = scene.AddSystem<EnvironmentSystem>();
		system.Environment.ShadowDistance = 60.0f;
		system.Environment.ShadowCascadeSplit = 0.7f;
		system.Environment.ShadowFadeDistance = 8.0f;
		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractEnvironmentInto(scene, snapshot);
		Test.Assert(snapshot.ShadowSettings.Distance == 60.0f);
		Test.Assert(snapshot.ShadowSettings.CascadeSplit == 0.7f);
		Test.Assert(snapshot.ShadowSettings.FadeDistance == 8.0f);

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 2, 0), .(0, 2, -10), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 16.0f / 9.0f, 0.1f, 400.0f);
		camera.FarZ = 400.0f;
		let sun = Normalized(Float3(-0.17f, -0.87f, -0.47f));
		let wide = ShadowMath.ComputeCascades(camera, sun, 300.0f, 1024);
		let near = ShadowMath.ComputeCascades(camera, sun, 60.0f, 1024);
		Test.Assert(near.TexelWorldSize[0] < wide.TexelWorldSize[0] * 0.5f);
		// ...and a split nearer one gives the camera's surroundings more of the map.
		let logarithmic = ShadowMath.ComputeCascades(camera, sun, 60.0f, 1024, 1.0f);
		Test.Assert(logarithmic.TexelWorldSize[0] < near.TexelWorldSize[0]);
	}
}
