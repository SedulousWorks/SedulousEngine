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

/// Screen-space reflections and GI, proven at the pixel on real devices through the full
/// RenderFrame chain (structural assertions, no golden images).
///  - SSR reach: a mirror floor seen from low above it reflects the WHOLE of a tall pillar
///    twenty metres away, down to where it stands. A ray length tied to the pixel's own depth
///    cut the reflection off near the pillar's base (the reflected ray climbs only as steeply
///    as the view ray came down).
///  - SSGI occlusion: an inside corner under flat ambient darkens toward its edge, where the
///    rays hit the other wall instead of the sky the forward lit it with. A purely additive
///    composite lifted it instead (counting the sky twice).
///  - SSGI albedo: a blue wall beside a red one takes no red bounce (blue reflects none). A
///    unit albedo composite added the red light at full strength and washed the blue out.
class ScreenSpaceProbeTests
{
	private const uint32 cSize = 128;

	private struct Item
	{
		public StaticMesh Mesh = null;
		public Material Material = null;
		public Float4x4 World = Float4x4.Identity();
		public Float3 Center = .(0, 0, 0);
		public float Radius = 1.0f;

		public this() {}
	}

	/// A probe's scene: its items (owned, deleted with it), the camera and the effects asked for.
	private class ProbeScene
	{
		public List<Item> Items = new .() ~ delete _;
		public ViewCamera Camera;
		public Float3 Ambient = .(1.0f, 1.0f, 1.0f);
		public bool Ssr;
		public bool Ssgi;

		public ~this()
		{
			for (let item in Items)
			{
				delete item.Mesh;
				delete item.Material;
			}
		}
	}

	/// Renders `spec` through the frame chain (forward and tonemap, plus SSR or SSGI when asked;
	/// no TAA, no bloom) and reads the LDR pixels back.
	private static CapturedImage Render(BackendProbeFixture fixture, ProbeScene spec)
	{
		let device = fixture.Device;
		let shaders = fixture.Shaders;

		let psoCache = scope PipelineStateCache(shaders, device);
		let materials = scope MaterialSystem();
		if (materials.Initialize(device) case .Err)
			return null;

		let meshRenderer = scope MeshRenderer(device, shaders, psoCache, materials, 2);
		if (meshRenderer.Initialize() case .Err)
			return null;

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let tonemap = scope TonemapPass(device, shaders, 2);
		if (tonemap.Initialize() case .Err)
			return null;

		let ssr = scope SsrPass(device, shaders);
		if (ssr.Initialize() case .Err)
			return null;

		let ssgi = scope SsgiPass(device, shaders);
		if (ssgi.Initialize() case .Err)
			return null;

		let frame = scope RenderFrame(device, registry, 2, null, tonemap, null, null, null, null, null, null, null);
		if (spec.Ssr)
		{
			var parameters = SsrParams();
			parameters.Temporal = false; // one frame's trace, not an accumulation still settling
			frame.SetSsr(ssr);
			frame.SetSsrParams(true, parameters);
		}
		if (spec.Ssgi)
			frame.SetSsgi(ssgi);

		let scene = scope ExtractedScene();
		scene.SetAmbient(spec.Ambient);
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

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "screenspace.probe.target";
		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return null;
		defer device.DestroyTexture(ref target);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return null;
		defer device.DestroyTextureView(ref targetView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return null;
		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return null;
		defer device.DestroyFence(ref fence);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return null;

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.BloomEnabled = false;
		settings.Post.TaaEnabled = false;
		settings.Post.SsrEnabled = spec.Ssr;
		settings.Post.SsgiEnabled = spec.Ssgi;
		// The GI history reprojects by the motion vectors.
		settings.Post.NeedsMotion = spec.Ssgi;

		// SSGI's few noisy rays converge over its temporal accumulation on a still camera.
		let frames = spec.Ssgi ? 24 : 2;
		for (uint32 i = 0; i < (uint32)frames; i++)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return null;

			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;

			frame.Begin(encoder, i % 2);
			frame.AddView(scene, spec.Camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();

			let commandBuffer = encoder.Finish();
			if (commandBuffer == null)
			{
				pool.DestroyEncoder(ref encoder);
				return null;
			}

			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}

		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		device.WaitIdle();
		return image;
	}

	/// The pixel column a world point lands on. X only: the y convention differs per backend,
	/// which the orientation probe owns.
	private static uint32 PixelX(ViewCamera camera, Float3 world)
	{
		let clip = Float4(world.X, world.Y, world.Z, 1.0f) * (camera.View * camera.Projection);
		let ndcX = clip.X / clip.W;
		return (uint32)Math.Clamp((ndcX * 0.5f + 0.5f) * (float)cSize, 0.0f, (float)(cSize - 1));
	}

	private static bool Reddish(uint8* p) => (p[0] > 60) && (p[0] > p[1] * 2) && (p[0] > p[2] * 2);

	/// Red pixels down one column.
	private static uint32 RedInColumn(CapturedImage image, uint32 x)
	{
		var count = (uint32)0;
		for (uint32 y = 0; y < image.Height; y++)
		{
			if (Reddish(image.At(x, y)))
				count++;
		}
		return count;
	}

	/// A mirror floor, a camera half a metre above it looking along it, and a red pillar 8 m
	/// tall twenty metres away. The floor is dark, so what reads red below the pillar is its
	/// reflection.
	private static ProbeScene PillarOverMirror(bool ssr)
	{
		let spec = new ProbeScene();
		spec.Ssr = ssr;

		var floor = Item();
		floor.Mesh = Primitives.Plane(200.0f, 200.0f);
		floor.Material = MaterialPresets.CreatePbr("probe.mirror", .(0.02f, 0.02f, 0.02f, 1.0f), 0.0f, 0.02f);
		floor.Radius = 150.0f;
		spec.Items.Add(floor);

		var pillar = Item();
		pillar.Mesh = Primitives.Cube(1.0f);
		pillar.Material = MaterialPresets.CreatePbr("probe.pillar", .(1.0f, 0.05f, 0.05f, 1.0f), 0.0f, 0.9f);
		pillar.World = Float4x4.Scale(.(2.0f, 8.0f, 2.0f)) * Float4x4.Translation(.(0.0f, 4.0f, -20.0f));
		pillar.Center = .(0.0f, 4.0f, -20.0f);
		pillar.Radius = 5.0f;
		spec.Items.Add(pillar);

		spec.Camera.View = Float4x4.LookAtRH(.(0, 0.5f, 0), .(0, 0.5f, -1), .(0, 1, 0));
		spec.Camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 500.0f);
		spec.Camera.Position = .(0, 0.5f, 0);
		return spec;
	}

	/// Two big slabs meeting at a vertical edge (the corner of x >= 0, z >= 0), seen from inside
	/// the corner along its bisector: the edge stands at the screen's centre column, wall X (the
	/// x = 0 slab) to one side and wall Z (the z = 0 slab) to the other. Flat white ambient, no
	/// lights: each wall reads as its albedo, until SSGI.
	private static ProbeScene Corner(bool ssgi, Float4 wallX, Float4 wallZ)
	{
		let spec = new ProbeScene();
		spec.Ssgi = ssgi;

		var x = Item();
		x.Mesh = Primitives.Cube(1.0f);
		x.Material = MaterialPresets.CreatePbr("probe.wallX", wallX, 0.0f, 0.9f);
		x.World = Float4x4.Scale(.(0.1f, 8.0f, 8.0f)) * Float4x4.Translation(.(-0.05f, 0.0f, 4.0f));
		x.Center = .(0.0f, 0.0f, 4.0f);
		x.Radius = 6.0f;
		spec.Items.Add(x);

		var z = Item();
		z.Mesh = Primitives.Cube(1.0f);
		z.Material = MaterialPresets.CreatePbr("probe.wallZ", wallZ, 0.0f, 0.9f);
		z.World = Float4x4.Scale(.(8.0f, 8.0f, 0.1f)) * Float4x4.Translation(.(4.0f, 0.0f, -0.05f));
		z.Center = .(4.0f, 0.0f, 0.0f);
		z.Radius = 6.0f;
		spec.Items.Add(z);

		spec.Camera.Position = .(2.5f, 0.0f, 2.5f);
		spec.Camera.View = Float4x4.LookAtRH(spec.Camera.Position, .(0, 0, 0), .(0, 1, 0));
		spec.Camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		return spec;
	}

	/// The mean of one channel (or of r+g+b with channel 3) over columns [x0, x1), every row.
	private static float ColumnsMean(CapturedImage image, uint32 x0, uint32 x1, int channel)
	{
		double sum = 0.0;
		var count = (uint32)0;
		for (uint32 x = x0; x < x1; x++)
		{
			for (uint32 y = 0; y < image.Height; y++)
			{
				let p = image.At(x, y);
				sum += (channel < 3) ? p[channel] : ((int)p[0] + p[1] + p[2]);
				count++;
			}
		}
		return (count > 0) ? (float)(sum / count) : 0.0f;
	}

	/// The columns of one wall beside the edge: from a few pixels off the edge to a quarter
	/// screen.
	private static void WallColumns(ViewCamera camera, bool zWall, out uint32 x0, out uint32 x1)
	{
		let edge = PixelX(camera, .(0.0f, 0.0f, 0.0f));
		let onWall = PixelX(camera, zWall ? Float3(1.0f, 0.0f, 0.0f) : Float3(0.0f, 0.0f, 1.0f));
		if (onWall > edge)
		{
			x0 = edge + 3;
			x1 = edge + cSize / 4;
		}
		else
		{
			x0 = edge - cSize / 4;
			x1 = edge - 3;
		}
	}

	[Test]
	public static void AMirrorFloorSeenFromLowReflectsTheWholeOfATallPillar()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			SsrReachOn(kind);
	}

	private static void SsrReachOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let offScene = PillarOverMirror(false);
		defer delete offScene;
		let onScene = PillarOverMirror(true);
		defer delete onScene;

		let off = Render(fixture, offScene);
		defer delete off;
		let on = Render(fixture, onScene);
		defer delete on;
		Test.Assert((off != null) && off.Valid, scope $"{kind}: rendered without SSR");
		Test.Assert((on != null) && on.Valid, scope $"{kind}: rendered with SSR");

		let x = PixelX(offScene.Camera, .(0.0f, 4.0f, -20.0f));
		let pillar = RedInColumn(off, x);
		let withReflection = RedInColumn(on, x);
		Test.Assert(pillar > 10, scope $"{kind}: the pillar itself is on screen ({pillar} red)");
		// The reflection mirrors the pillar about the floor: as tall as the pillar on screen, so
		// the column holds about twice as much red (less the last rows Fresnel fades). A ray cut
		// at the pixel's depth added none; a fixed hit band let the far reflection break into a
		// dither; the start pixel read as a hit left a gap where the reflection meets the pillar.
		Test.Assert(withReflection >= pillar * 18 / 10,
			scope $"{kind}: red in the pillar's column, SSR off {pillar}, on {withReflection}");
	}

	[Test]
	public static void AnInsideCornerDarkensTowardItsEdgeWhereTheBounceReplacesTheSky()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			SsgiOcclusionOn(kind);
	}

	private static void SsgiOcclusionOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let grey = Float4(0.5f, 0.5f, 0.5f, 1.0f);
		let offScene = Corner(false, grey, grey);
		defer delete offScene;
		let onScene = Corner(true, grey, grey);
		defer delete onScene;

		let off = Render(fixture, offScene);
		defer delete off;
		let on = Render(fixture, onScene);
		defer delete on;
		Test.Assert((off != null) && off.Valid, scope $"{kind}: rendered without SSGI");
		Test.Assert((on != null) && on.Valid, scope $"{kind}: rendered with SSGI");

		let edge = PixelX(offScene.Camera, .(0.0f, 0.0f, 0.0f));
		let litOff = ColumnsMean(off, edge - 6, edge + 6, 3);
		let litOn = ColumnsMean(on, edge - 6, edge + 6, 3);
		// The rays near the edge hit the other wall (half as bright as the sky they hide): darker.
		Test.Assert(litOn < litOff * 0.97f, scope $"{kind}: corner luma, SSGI off {litOff}, on {litOn}");
	}

	[Test]
	public static void AWallTakesTheBounceTintedByItsOwnAlbedo()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			SsgiAlbedoOn(kind);
	}

	private static void SsgiAlbedoOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let red = Float4(0.9f, 0.05f, 0.05f, 1.0f);
		let blue = Float4(0.05f, 0.05f, 0.9f, 1.0f);
		let offScene = Corner(false, red, blue);
		defer delete offScene;
		let onScene = Corner(true, red, blue);
		defer delete onScene;

		let off = Render(fixture, offScene);
		defer delete off;
		let on = Render(fixture, onScene);
		defer delete on;
		Test.Assert((off != null) && off.Valid, scope $"{kind}: rendered without SSGI");
		Test.Assert((on != null) && on.Valid, scope $"{kind}: rendered with SSGI");

		WallColumns(offScene.Camera, true, let x0, let x1);
		let redOff = ColumnsMean(off, x0, x1, 0);
		let redOn = ColumnsMean(on, x0, x1, 0);
		let blueOff = ColumnsMean(off, x0, x1, 2);
		Test.Assert(blueOff > 100.0f, scope $"{kind}: the blue wall is where we look ({blueOff})");
		// Blue reflects almost no red: the red bounce must not tint it (unit albedo added it whole).
		Test.Assert(redOn <= redOff + 3.0f,
			scope $"{kind}: blue wall red channel, SSGI off {redOff}, on {redOn} (blue {blueOff})");
	}
}
