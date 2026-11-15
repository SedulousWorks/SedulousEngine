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

/// The static shadow atlas layer on a real device.
///
/// Two Static spot lights each cast a cube's shadow into their cached tiles; then a caster
/// moves inside the first light's reach only, so only that light's tile redraws, frame after
/// frame. The second light's shadow must stay: its tile is cached, not redrawn, and the pass
/// that redraws the first must not clear it. Checked with the tile clear and with the whole
/// layer fallback a renderer without the clear's shader takes.
class StaticShadowTileProbeTests
{
	private const uint32 cSize = 128;
	/// Every static tile drawn into both frame slots, then clean.
	private const uint32 cStillFrames = 4;
	/// The first light's tile redraws each frame.
	private const uint32 cMovingFrames = 4;

	/// Each light stands 1.5 to the left of its cube and 2 up, aiming right and down, so the
	/// cube's shadow falls on the plane just right of the cube: x in [ox + 0.5, ox + 2.5].
	private const float cLightA = -6.0f;
	private const float cLightB = 4.0f;

	private struct Readings
	{
		public double ShadowA;
		public double LitA;
		public double ShadowB;
		public double LitB;
	}

	/// A world point's pixel in the top down view.
	private static void Project(ViewCamera camera, Float3 p, out uint32 px, out uint32 py)
	{
		let vp = camera.View * camera.Projection;
		float[4] clip = .();
		for (int j < 4)
			clip[j] = p.X * vp.M[0][j] + p.Y * vp.M[1][j] + p.Z * vp.M[2][j] + vp.M[3][j];
		let nx = clip[0] / clip[3];
		let ny = clip[1] / clip[3];
		px = (uint32)((nx * 0.5f + 0.5f) * (float)cSize);
		py = (uint32)((0.5f - ny * 0.5f) * (float)cSize);
	}

	private static double BoxLuma(CapturedImage image, uint32 cx, uint32 cy)
	{
		double sum = 0.0;
		for (uint32 y = cy - 1; y <= cy + 1; y++)
		{
			for (uint32 x = cx - 1; x <= cx + 1; x++)
				sum += image.Luma(x, y);
		}
		return sum / 9.0;
	}

	private static void AddItem(ExtractedScene scene, StaticMesh mesh, Material material, Float3 at,
		float radius, ref uint64 nextId)
	{
		let data = scene.Add<MeshRenderData>();
		data.World = Float4x4.Translation(at);
		data.WorldCenter = at;
		data.WorldRadius = radius;
		data.Mesh = mesh;
		data.Material = material;
		data.Category = RenderCategories.Opaque;
		data.EntityId = nextId;
		nextId++;
	}

	private static Readings Render(BackendProbeFixture fixture, bool tileClear)
	{
		var readings = Readings();
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 20, 0.01f), .(0, 0, 0), .(0, 0, -1));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 20, 0.01f);
		camera.FarZ = 100.0f;

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
		shadows.SetShaderSystem(tileClear ? fixture.Shaders : null);
		// The mode under test.
		Test.Assert((shadows.TileClearPipeline() != null) == tileClear);
		let frame = scope RenderFrame(device, registry, 2, null, null, shadows);

		let planeMesh = Primitives.Plane(24.0f, 8.0f);
		defer delete planeMesh;
		let cubeMesh = Primitives.Cube(1.0f);
		defer delete cubeMesh;
		let moverMesh = Primitives.Cube(0.5f);
		defer delete moverMesh;
		let grey = MaterialPresets.CreatePbr("probe.grey", .(0.8f, 0.8f, 0.8f, 1), 0.0f, 0.9f);
		defer delete grey;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "statictileprobe.target";
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

		// ONE scene object, refilled each frame: a different scene would dirty every static
		// tile, which would hide what is under test.
		let scene = scope ExtractedScene();
		float[2] cubes = .(cLightA, cLightB);
		for (uint32 i < cStillFrames + cMovingFrames)
		{
			scene.Reset();
			scene.SetAmbient(.(0.02f, 0.02f, 0.02f));
			uint64 nextId = 1;
			AddItem(scene, planeMesh, grey, .(0, 0, 0), 13.0f, ref nextId);
			for (let ox in cubes)
				AddItem(scene, cubeMesh, grey, .(ox, 0.5f, 0), 0.9f, ref nextId);
			if (i >= cStillFrames)
			{
				// Inside the first light's reach (8 from it), far outside the second's, and a
				// little further along each frame, so the first light's tile redraws every frame.
				AddItem(scene, moverMesh, grey, .(cLightA - 4.5f, 0.25f, -3.0f + 0.2f * (float)i), 0.45f,
					ref nextId);
			}
			for (int l < 2)
			{
				let position = Float3(cubes[l] - 1.5f, 2.0f, 0.0f);
				let direction = Normalized(Float3(3.0f, -2.0f, 0.0f));
				var spot = GpuLight();
				spot.Type = 2.0f;
				spot.PositionWS = position;
				spot.DirectionWS = direction;
				spot.Range = 8.0f;
				spot.Intensity = 30.0f;
				spot.InnerCos = (float)Math.Cos(0.9);
				spot.OuterCos = (float)Math.Cos(1.1);
				// One tile each, in caster order.
				spot.ShadowIndex = (float)l;
				scene.AddLight(spot);
				var caster = LocalShadowCaster();
				caster.Type = 2;
				caster.PositionWS = position;
				caster.DirectionWS = direction;
				caster.Range = 8.0f;
				caster.OuterAngle = 1.1f;
				caster.IsStatic = true;
				scene.AddLocalShadowCaster(caster);
			}

			var encoder = pool.CreateEncoder().Value;
			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();
			let commandBuffer = encoder.Finish();
			Test.Assert(commandBuffer != null);
			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}
		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		defer delete image;
		Test.Assert(image.Valid);
		Project(camera, .(cLightA + 1.5f, 0, 0), var x, var y);
		readings.ShadowA = BoxLuma(image, x, y);
		Project(camera, .(cLightA + 1.5f, 0, 2.0f), out x, out y);
		readings.LitA = BoxLuma(image, x, y);
		Project(camera, .(cLightB + 1.5f, 0, 0), out x, out y);
		readings.ShadowB = BoxLuma(image, x, y);
		Project(camera, .(cLightB + 1.5f, 0, 2.0f), out x, out y);
		readings.LitB = BoxLuma(image, x, y);
		device.WaitIdle();
		return readings;
	}

	[Test]
	public static void ATileRedrawnBesideACachedOneLeavesTheCachedShadow()
	{
		let fixture = scope BackendProbeFixture(.Vulkan);
		if (!fixture.Ready)
			return;
		bool[2] modes = .(true, false);
		for (let tileClear in modes)
		{
			let readings = Render(fixture, tileClear);
			let mode = tileClear ? "tile clear" : "whole layer fallback";
			Test.Assert(readings.LitA > 60.0, scope $"{mode}: the first light lights the plane ({readings.LitA})");
			Test.Assert(readings.LitB > 60.0, scope $"{mode}: the second light lights the plane ({readings.LitB})");
			Test.Assert(readings.ShadowA < readings.LitA * 0.5,
				scope $"{mode}: the redrawn light keeps its shadow ({readings.ShadowA} against {readings.LitA})");
			Test.Assert(readings.ShadowB < readings.LitB * 0.5,
				scope $"{mode}: the cached light keeps its shadow ({readings.ShadowB} against {readings.LitB})");
		}
	}
}
