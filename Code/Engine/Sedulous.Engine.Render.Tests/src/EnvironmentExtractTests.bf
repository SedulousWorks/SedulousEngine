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

		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractEnvironmentInto(scene, snapshot);
		Test.Assert(snapshot.HasTime);
		Test.Assert(Near(snapshot.TimeSeconds, 0.75f));
		Test.Assert(Near(snapshot.PrevTimeSeconds, 0.75f));

		// A scene without the system stamps none, and the frame's own clock stands in.
		let bare = scope Scene("bare");
		let none = scope ExtractedScene();
		RenderExtract.ExtractEnvironmentInto(bare, none);
		Test.Assert(!none.HasTime);
	}
}
