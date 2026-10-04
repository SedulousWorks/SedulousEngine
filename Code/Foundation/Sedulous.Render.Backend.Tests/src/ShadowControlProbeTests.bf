using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// A light's shadow controls on a real device.
///
/// Acne: a wall the sun meets at a grazing angle (PaperKid's house walls and sun) reads
/// uniformly lit across a sweep of normal offsets and at the default. Strength: a cube's shadow
/// on a plane darkens fully at strength one, half as much at a half and not at all at nought,
/// so the per light value reaches the sampling.
class ShadowControlProbeTests
{
	private const uint32 cSize = 128;

	private class Item
	{
		public StaticMesh Mesh ~ delete _;
		public Material Material ~ delete _;
		public Float4x4 World = .Identity();
		public Float3 Center = .(0, 0, 0);
		public float Radius = 1.0f;
	}

	private class ShadowScene
	{
		public List<Item> Items = new .() ~ DeleteContainerAndItems!(_);
		public ViewCamera Camera = .();
		public Float3 SunDirection = .(0, -1, 0);
		/// The light's biases and strength.
		public DirectionalShadow Shadow = .();
	}

	/// Renders `spec` raw (no tonemap, TAA or AO) with a shadow casting sun, and reads it back.
	private static CapturedImage Render(BackendProbeFixture fixture, ShadowScene spec)
	{
		let device = fixture.Device;
		let psoCache = scope PipelineStateCache(fixture.Shaders, device);
		let materials = scope MaterialSystem();
		Test.Assert(materials.Initialize(device) case .Ok);
		let meshRenderer = scope MeshRenderer(device, fixture.Shaders, psoCache, materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let shadows = scope ShadowSystem(device, 2);
		Test.Assert(shadows.Initialize() case .Ok);
		let frame = scope RenderFrame(device, registry, 2, null, null, shadows);

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(0.05f, 0.05f, 0.05f));
		for (let item in spec.Items)
		{
			let data = scene.Add<MeshRenderData>();
			data.World = item.World;
			data.WorldCenter = item.Center;
			data.WorldRadius = item.Radius;
			data.Mesh = item.Mesh;
			data.Material = item.Material;
			data.Category = RenderCategories.Opaque;
		}
		var sun = GpuLight();
		sun.Type = 0.0f;
		sun.DirectionWS = Normalized(spec.SunDirection);
		sun.Intensity = 4.0f;
		sun.ShadowIndex = 0.0f;
		sun.ShadowStrength = spec.Shadow.Strength;
		scene.AddLight(sun);
		var shadow = spec.Shadow;
		shadow.Direction = sun.DirectionWS;
		shadow.Valid = true;
		scene.SetDirectionalShadow(shadow);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "shadowprobe.target";
		var target = device.CreateTexture(textureDesc).Value;
		defer device.DestroyTexture(ref target);
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		var targetView = device.CreateTextureView(target, viewDesc).Value;
		defer device.DestroyTextureView(ref targetView);
		var pool = device.CreateCommandPool(.Graphics).Value;
		defer device.DestroyCommandPool(ref pool);
		var fence = device.CreateFence(0).Value;
		defer device.DestroyFence(ref fence);
		let queue = device.GetQueue(.Graphics);

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;
		for (uint32 i < 2)
		{
			var encoder = pool.CreateEncoder().Value;
			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, spec.Camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();
			let commandBuffer = encoder.Finish();
			Test.Assert(commandBuffer != null);
			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}
		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		device.WaitIdle();
		return image;
	}

	private static Item Make(StaticMesh mesh, StringView name, Float4x4 world, Float3 center, float radius)
	{
		let item = new Item();
		item.Mesh = mesh;
		item.Material = MaterialPresets.CreatePbr(name, .(0.8f, 0.8f, 0.8f, 1), 0.0f, 0.9f);
		item.World = world;
		item.Center = center;
		item.Radius = radius;
		return item;
	}

	/// PaperKid's case: a house wall beside the street, facing it (+X), the camera at eye height
	/// looking down the street with its 300 m far plane (the cascades are fitted to it), and the
	/// game's sun, which meets that wall at an N.L of about 0.17.
	private static void GrazingWall(ShadowScene spec, float normalBias)
	{
		// The plane faces +Y; a quarter turn about Z faces it +X. Its 12 m run along -Z.
		let world = Float4x4.RotationY(1.57079633f) * Float4x4.RotationZ(-1.57079633f)
			* Float4x4.Translation(.(-3.0f, 2.5f, -9.0f));
		spec.Items.Add(Make(Primitives.Plane(12.0f, 5.0f), "probe.wall", world, .(-3.0f, 2.5f, -9.0f), 7.0f));
		spec.SunDirection = .(-0.171f, -0.867f, -0.467f); // PaperKid's sun's forward
		spec.Camera.View = Float4x4.LookAtRH(.(0, 1.6f, 0), .(0, 1.6f, -10.0f), .(0, 1, 0));
		spec.Camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 300.0f);
		spec.Camera.Position = .(0, 1.6f, 0);
		spec.Camera.FarZ = 300.0f;
		spec.Shadow.NormalBias = normalBias;
	}

	/// The share of the wall that reads darker than 85% of its median: false shadow. The wall
	/// is whatever the left half of the image drew (the rest is the black clear).
	private static double AcneFraction(CapturedImage image, out uint32 median)
	{
		let lumas = scope List<uint32>();
		for (uint32 y = 8; y < cSize - 8; y++)
		{
			for (uint32 x = 2; x < cSize / 2 - 4; x++)
			{
				let v = image.Luma(x, y);
				if (v > 12)
					lumas.Add(v);
			}
		}
		if (lumas.IsEmpty)
		{
			median = 0;
			return 0.0;
		}
		let sorted = scope List<uint32>()..AddRange(lumas);
		sorted.Sort();
		median = sorted[sorted.Count / 2];
		int dark = 0;
		for (let v in lumas)
		{
			if (v * 100 < median * 85)
				dark++;
		}
		return (double)dark / (double)lumas.Count;
	}

	private static void CubeOnPlane(ShadowScene spec, float strength)
	{
		spec.Items.Add(Make(Primitives.Plane(16.0f, 16.0f), "probe.plane", .Identity(), .(0, 0, 0), 12.0f));
		spec.Items.Add(Make(Primitives.Cube(2.0f), "probe.cube", Float4x4.Translation(.(0, 1, 0)), .(0, 1, 0), 2.0f));
		spec.SunDirection = .(1.0f, -1.0f, 0.0f); // the shadow falls toward +X
		spec.Camera.View = Float4x4.LookAtRH(.(0, 14, 0.01f), .(0, 0, 0), .(0, 0, -1));
		spec.Camera.Projection = Float4x4.PerspectiveFovRH(1.0f, 1.0f, 0.1f, 100.0f);
		spec.Camera.Position = .(0, 14, 0.01f);
		spec.Camera.FarZ = 100.0f;
		spec.Shadow.Strength = strength;
	}

	/// The average luma of a small box of the plane.
	private static double BoxLuma(CapturedImage image, uint32 cx, uint32 cy)
	{
		double sum = 0.0;
		for (uint32 y = cy - 2; y <= cy + 2; y++)
		{
			for (uint32 x = cx - 2; x <= cx + 2; x++)
				sum += image.Luma(x, y);
		}
		return sum / 25.0;
	}

	[Test]
	public static void AWallTheSunGrazesIsCleanAtTheDefaultNormalOffset()
	{
		let fixture = scope BackendProbeFixture(.Vulkan);
		if (!fixture.Ready)
			return;
		float[6] sweep = .(0.02f, 0.25f, 0.5f, 1.0f, 2.0f, ShadowBiasDefaults.NormalBias);
		for (let normalBias in sweep)
		{
			let spec = scope ShadowScene();
			GrazingWall(spec, normalBias);
			let image = Render(fixture, spec);
			defer delete image;
			Test.Assert(image.Valid);
			let acne = AcneFraction(image, let median);
			Test.Assert(median > 60, scope $"the wall is lit (median luma {median} at a normal offset of {normalBias})");
			Test.Assert(acne < 0.005, scope $"no false shadow: {acne * 100.0}% at a normal offset of {normalBias} texels");
		}
	}

	[Test]
	public static void ALightsStrengthSetsHowDarkItsShadowGets()
	{
		let fixture = scope BackendProbeFixture(.Vulkan);
		if (!fixture.Ready)
			return;
		// Top down: +X is to the right of the image, and the shadow falls there.
		let shadowX = cSize / 2 + 17; // x ~ 2: the shadow spans 1 to 3 (the cube is 2 high, the sun at 45 degrees)
		let openX = cSize / 2 - 30; // x ~ -3.6: open plane
		float[3] strengths = .(0.0f, 0.5f, 1.0f);
		double[3] shadowed = .();
		double[3] open = .();
		for (int i < 3)
		{
			let spec = scope ShadowScene();
			CubeOnPlane(spec, strengths[i]);
			let image = Render(fixture, spec);
			defer delete image;
			Test.Assert(image.Valid);
			open[i] = BoxLuma(image, openX, cSize / 2);
			shadowed[i] = BoxLuma(image, shadowX, cSize / 2);
		}
		let full = shadowed[0] - shadowed[2];
		let half = shadowed[0] - shadowed[1];
		Test.Assert(full > 60.0, scope $"strength one: a full shadow ({full})");
		Test.Assert(Math.Abs(half - full * 0.5) <= full * 0.05, scope $"strength a half: half as dark ({half} of {full})");
		Test.Assert(Math.Abs(open[0] - open[2]) <= open[2] * 0.01, scope $"the open plane is untouched ({open[0]}, {open[2]})");
	}
}
