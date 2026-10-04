using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.RHI.Null;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// What is entered is what is seen: every authored colour is sRGB, like an sRGB image, and the
/// renderer works in linear. Extraction is where the one decode happens.
class ColourExtractTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;
	private static bool Same(Color a, Color b) => NearlyEqual(a, b, 1.0e-4f);
	private static bool Same3(Float3 a, Color b) => Near(a.X, b.R) && Near(a.Y, b.G) && Near(a.Z, b.B);

	[Test]
	public static void AuthoredColoursReachRenderDataDecodedToLinear()
	{
		let authored = Color(0.5f, 0.25f, 0.75f, 0.5f);
		let linear = ToLinear(authored);

		let scene = scope Scene("colours");
		let sets = scene.AddSystem<InstancedMeshComponentManager>();
		let sprites = scene.AddSystem<SpriteComponentManager>();
		let decals = scene.AddSystem<DecalComponentManager>();
		let lights = scene.AddSystem<LightComponentManager>();
		let cameras = scene.AddSystem<CameraComponentManager>();
		let environment = scene.AddSystem<EnvironmentSystem>();
		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let builder = scope MaterialBuilder("lit");
		let material = builder..Shader("forward").Build();
		defer delete material;
		// Extraction only stores the view, so a bare null backed one is enough.
		let view = scope NullTextureView();

		let set = sets.Add(scene.CreateEntity("set"));
		set.Mesh.SetDirect(cube);
		set.Color = authored;
		set.Tints.Add(.(0.5f, 0.5f, 0.5f, 1.0f));
		set.SetInstances(.(set.Instances.Ptr, 1)); // a mutation, so the tints are read again
		let sprite = sprites.Add(scene.CreateEntity("sprite"));
		sprite.Texture = view;
		sprite.Tint = authored;
		let decal = decals.Add(scene.CreateEntity("decal"));
		decal.Texture = view;
		decal.Color = authored;
		let light = lights.Add(scene.CreateEntity("light"));
		light.Color = authored;
		let camera = cameras.Add(scene.CreateEntity("camera"));
		camera.ClearColor = authored;
		environment.Environment.AmbientColor = authored;
		environment.Environment.AmbientIntensity = 1.0f;
		environment.Environment.SkyHorizon = authored;
		environment.Environment.SkyZenith = authored;
		environment.Environment.SkyGround = authored;
		scene.UpdateTransforms();

		// A scene of its own for the plain mesh: ExtractSceneInto gathers several kinds of item.
		let meshScene = scope Scene("mesh");
		let mesh = meshScene.AddSystem<MeshComponentManager>().Add(meshScene.CreateEntity("mesh"));
		mesh.Mesh.SetDirect(cube);
		mesh.SetMaterial(material);
		mesh.Color = authored;
		meshScene.UpdateTransforms();
		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractSceneInto(meshScene, snapshot);
			Test.Assert(snapshot.Size == 1);
			Test.Assert(Same(((MeshRenderData)snapshot.Items[0]).Color, linear));
		}

		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
			Test.Assert(snapshot.Size == 1);
			let data = (MultiMeshRenderData)snapshot.Items[0];
			Test.Assert(Same(data.Color, linear));
			Test.Assert(data.Tints != null);
			Test.Assert(Near(data.Tints[0].R, SrgbToLinear(0.5f)), "per instance tints too");
			Test.Assert(Near(set.Tints[0].R, 0.5f), "the authored list is untouched");
		}

		{
			let snapshot = scope ExtractedScene();
			RenderExtract.ExtractSpritesInto(scene, snapshot, 1);
			Test.Assert(snapshot.Size == 1);
			Test.Assert(Same(((SpriteRenderData)snapshot.Items[0]).Tint, linear));
		}

		let rest = scope ExtractedScene();
		RenderExtract.ExtractDecalsInto(scene, rest);
		RenderExtract.ExtractLightsInto(scene, rest);
		RenderExtract.ExtractEnvironmentInto(scene, rest);
		Test.Assert(rest.Decals.Length == 1);
		Test.Assert(Same(rest.Decals[0].Color, linear));
		Test.Assert(rest.Lights.Length == 1);
		Test.Assert(Same3(rest.Lights[0].Color, linear));
		Test.Assert(Same3(rest.Ambient, linear));
		Test.Assert(Same3(rest.Sky.Horizon, linear));
		Test.Assert(Same3(rest.Sky.Zenith, linear));
		Test.Assert(Same3(rest.Sky.Ground, linear));

		var viewCamera = ViewCamera();
		Color clear = .();
		Test.Assert(RenderExtract.ExtractPrimaryCamera(scene, ref viewCamera, &clear));
		Test.Assert(Same(clear, linear));
	}

	/// The defaults were picked while colours were read raw; written in sRGB, they decode to
	/// the same linear values, so a new scene looks as it did.
	[Test]
	public static void TheDefaultEnvironmentColoursAreSrgbAndRenderAsTheyAlwaysHave()
	{
		let environment = EnvironmentSettings();
		bool DecodesTo(Color c, float r, float g, float b)
		{
			let l = ToLinear(c);
			return (Math.Abs(l.R - r) < 2e-3f) && (Math.Abs(l.G - g) < 2e-3f) && (Math.Abs(l.B - b) < 2e-3f);
		}
		Test.Assert(DecodesTo(environment.AmbientColor, 0.10f, 0.12f, 0.16f));
		Test.Assert(DecodesTo(environment.SkyHorizon, 0.52f, 0.60f, 0.70f));
		Test.Assert(DecodesTo(environment.SkyZenith, 0.20f, 0.36f, 0.58f));
		Test.Assert(DecodesTo(environment.SkyGround, 0.26f, 0.26f, 0.26f));
	}
}
