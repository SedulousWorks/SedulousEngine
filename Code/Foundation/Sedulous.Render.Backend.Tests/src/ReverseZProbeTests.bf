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

/// The depth convention (reverse-Z: Projection, Depth, depth.hlsli) proven at the pixel:
/// three scenes through the FULL RenderFrame chain on real devices, read back and asserted.
///  - ordering: a near cube over a far cube, the nearer wins the centre whatever the draw
///    order, and a pixel nothing touched keeps the clear (the far plane stays the far plane);
///  - precision: a red face 0.02 units in front of a grey wall NINE HUNDRED units away, with
///    a 0.1 near plane. Under standard-Z that gap is a fraction of a float ulp at depth ~1 and
///    the two z-fight into speckle; under reverse-Z it is thousands of ulps and the face is
///    solid red. This is the whole reason for the convention, so it is the test that must
///    never go green by accident;
///  - shadows: a sun over a cube on a plane; the cascade's ortho projection, the caster side
///    hardware bias (its sign flipped with the convention), the sampler compare and the
///    receiver side bias all have to agree for the plane to read lit beside the cube and dark
///    in its shadow.
class ReverseZProbeTests
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

	private class SceneSpec
	{
		public List<Item> Items = new .() ~ DeleteContainerAndItems!(_);
		public ViewCamera Camera = .();
		/// A shadow casting directional light, which needs the ShadowSystem.
		public bool Sun = false;
		public Float3 SunDirection = .(0, -1, 0);
	}

	/// Renders `spec` raw, no tonemap, no TAA, no AO, and reads the LDR pixels back.
	private static CapturedImage RenderScene(BackendProbeFixture fixture, SceneSpec spec)
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
		ShadowSystem shadows = null;
		if (spec.Sun)
		{
			shadows = new ShadowSystem(device, 2);
			if (shadows.Initialize() case .Err)
			{
				delete shadows;
				return null;
			}
		}
		defer { delete shadows; }
		let frame = scope RenderFrame(device, registry, 2, null, null, shadows);

		let scene = scope ExtractedScene();
		// Flat white ambient lights the unlit scenes; the sun scene keeps it dim so the lit
		// plane does not saturate and the shadow is readable as a ratio.
		scene.SetAmbient(spec.Sun ? Float3(0.05f, 0.05f, 0.05f) : Float3(1.0f, 1.0f, 1.0f));
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
		if (spec.Sun)
		{
			var sun = GpuLight();
			sun.Type = 0.0f; // directional
			sun.DirectionWS = Normalized(spec.SunDirection);
			sun.Color = .(1, 1, 1);
			sun.Intensity = 1.5f;
			sun.ShadowIndex = 0.0f; // shadowed, as the extraction marks it
			scene.AddLight(sun);
			var ds = DirectionalShadow();
			ds.Direction = sun.DirectionWS;
			ds.Valid = true;
			scene.SetDirectionalShadow(ds);
		}

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "reversez.target";
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
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;
		for (uint32 i = 0; i < 2; i++)
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

	private static Item Cube(float size, Float3 at, StringView name, Float4 color)
	{
		let item = new Item();
		item.Mesh = Primitives.Cube(size);
		item.Material = MaterialPresets.CreatePbr(name, color, 0.0f, 0.9f);
		item.World = Float4x4.Translation(at);
		item.Center = at;
		item.Radius = size;
		return item;
	}

	/// A plane, built in XZ facing +Y, rotated to face +Z, toward a camera looking down -Z.
	private static Item WallFacingCamera(float extent, Float3 at, StringView name, Float4 color)
	{
		let item = new Item();
		item.Mesh = Primitives.Plane(extent, extent);
		item.Material = MaterialPresets.CreatePbr(name, color, 0.0f, 0.9f);
		item.World = Float4x4.RotationX(1.57079633f) * Float4x4.Translation(at);
		item.Center = at;
		item.Radius = extent;
		return item;
	}

	private static Item Ground(float extent, float y, StringView name, Float4 color)
	{
		let item = new Item();
		item.Mesh = Primitives.Plane(extent, extent);
		item.Material = MaterialPresets.CreatePbr(name, color, 0.0f, 0.9f);
		item.World = Float4x4.Translation(.(0.0f, y, 0.0f));
		item.Center = .(0.0f, y, 0.0f);
		item.Radius = extent;
		return item;
	}

	/// The pixel column a world point lands on through the camera. X only: the y convention
	/// differs per backend, which the orientation probe owns; every probe here samples along
	/// one screen row.
	private static uint32 PixelX(ViewCamera camera, Float3 world)
	{
		let clip = Float4(world.X, world.Y, world.Z, 1.0f) * (camera.View * camera.Projection);
		let ndcX = clip.X / clip.W;
		return (uint32)Clamp((ndcX * 0.5f + 0.5f) * (float)cSize, 0.0f, (float)(cSize - 1));
	}

	private static bool RedDominant(uint8* p) => (p[0] > 100) && (p[0] > p[1] * 2) && (p[0] > p[2] * 2);
	private static bool BlueDominant(uint8* p) => (p[2] > 100) && (p[2] > p[0] * 2) && (p[2] > p[1] * 2);

	/// The fraction of the pixels in the centred square of `half` half extent that satisfy
	/// the predicate.
	private static double CentreFraction(CapturedImage image, uint32 half, delegate bool(uint8*) pred)
	{
		uint32 hits = 0, total = 0;
		for (uint32 y = cSize / 2 - half; y < cSize / 2 + half; y++)
		{
			for (uint32 x = cSize / 2 - half; x < cSize / 2 + half; x++)
			{
				total++;
				if (pred(image.At(x, y)))
					hits++;
			}
		}
		return (double)hits / (double)total;
	}

	// ---- the three scenes ----

	/// Near red cube, far blue cube, the far one ADDED after the near one: a renderer that
	/// lost its depth test, or compares the wrong way, shows blue at the centre.
	private static SceneSpec OrderingScene()
	{
		let spec = new SceneSpec();
		// Near cube 0.6 wide, front face 2.7 out: ~19% of the half height around the centre.
		// Far cube 3 wide, front face 6.5 out: ~40%, so a row 20 pixels off centre is far cube
		// only and the corners see nothing.
		spec.Items.Add(Cube(0.6f, .(0, 0, -3.0f), "rz.near", .(1.0f, 0.05f, 0.05f, 1)));
		spec.Items.Add(Cube(3.0f, .(0, 0, -8.0f), "rz.far", .(0.05f, 0.05f, 1.0f, 1)));
		spec.Camera.View = Float4x4.LookAtRH(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0));
		spec.Camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		spec.Camera.Position = .(0, 0, 0);
		spec.Camera.FarZ = 100.0f;
		return spec;
	}

	/// A grey wall 900 units out, a red cube whose FRONT face sits 0.02 units in front of it,
	/// the rest of the cube behind the wall. The centre of the view is that face.
	private static SceneSpec PrecisionScene()
	{
		let spec = new SceneSpec();
		const float cWallZ = -900.0f;
		const float cGap = 0.02f;
		const float cCube = 400.0f;
		spec.Items.Add(WallFacingCamera(4000.0f, .(0, 0, cWallZ), "rz.wall", .(0.6f, 0.6f, 0.6f, 1)));
		spec.Items.Add(Cube(cCube, .(0, 0, cWallZ + cGap - cCube * 0.5f), "rz.face", .(1.0f, 0.05f, 0.05f, 1)));
		spec.Camera.View = Float4x4.LookAtRH(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0));
		spec.Camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 2000.0f);
		spec.Camera.Position = .(0, 0, 0);
		spec.Camera.FarZ = 2000.0f;
		return spec;
	}

	/// A cube floating over a ground plane, lit by a sun slanting toward +X: the shadow falls
	/// on the plane beside the cube, x in [0.4, 3.6]; the plane at -x is lit.
	private static SceneSpec ShadowScene()
	{
		let spec = new SceneSpec();
		spec.Items.Add(Ground(40.0f, -1.0f, "rz.ground", .(0.8f, 0.8f, 0.8f, 1)));
		spec.Items.Add(Cube(1.6f, .(0, 1.0f, 0), "rz.caster", .(0.8f, 0.8f, 0.8f, 1)));
		spec.Sun = true;
		spec.SunDirection = .(1.0f, -1.0f, 0.0f);
		// Straight down from 12 units up; screen x follows world x.
		spec.Camera.View = Float4x4.LookAtRH(.(0, 12.0f, 0.001f), .(0, 0, 0), .(0, 0, -1));
		spec.Camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		spec.Camera.Position = .(0, 12.0f, 0.001f);
		spec.Camera.FarZ = 100.0f;
		return spec;
	}

	[Test]
	public static void NearerWinsDistanceKeepsItsPrecisionAndShadowsAgree()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			ProbeOn(kind);
	}

	private static void ProbeOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		// Ordering.
		{
			let spec = OrderingScene();
			defer delete spec;
			let image = RenderScene(fixture, spec);
			defer delete image;
			Test.Assert((image != null) && image.Valid, scope $"{kind}: the ordering scene rendered");
			let red = CentreFraction(image, 6, scope => RedDominant);
			let blue = CentreFraction(image, 6, scope => BlueDominant);
			Test.Assert(red > 0.99, scope $"{kind} ordering: the near cube wins the centre, red {red}");
			Test.Assert(blue == 0.0, scope $"{kind} ordering: no far cube at the centre, blue {blue}");
			// The far cube is bigger: it shows around the near one.
			Test.Assert(BlueDominant(image.At(cSize / 2, cSize / 2 - 20)), scope $"{kind}: the far cube above");
			Test.Assert(BlueDominant(image.At(cSize / 2, cSize / 2 + 20)), scope $"{kind}: the far cube below");
			// A corner nothing reached keeps the clear: the far plane is still the far plane.
			let corner = image.At(1, 1);
			Test.Assert((corner[0] + corner[1] + corner[2]) == 0, scope $"{kind}: the corner kept the clear");
		}

		// Precision at distance: solid red, no wall bleeding through the 0.02 gap.
		{
			let spec = PrecisionScene();
			defer delete spec;
			let image = RenderScene(fixture, spec);
			defer delete image;
			Test.Assert((image != null) && image.Valid, scope $"{kind}: the precision scene rendered");
			let red = CentreFraction(image, 16, scope => RedDominant);
			Test.Assert(red > 0.999, scope $"{kind} precision: the face 0.02 in front of a wall 900 out is solid red, got {red}");
		}

		// Shadows.
		{
			let spec = ShadowScene();
			defer delete spec;
			let image = RenderScene(fixture, spec);
			defer delete image;
			Test.Assert((image != null) && image.Valid, scope $"{kind}: the shadow scene rendered");
			let row = cSize / 2;
			let litX = PixelX(spec.Camera, .(-2.4f, -1.0f, 0.0f));
			let shadowX = PixelX(spec.Camera, .(2.4f, -1.0f, 0.0f));
			let lit = image.Luma(litX, row);
			let shadowed = image.Luma(shadowX, row);
			Test.Assert(lit > 150, scope $"{kind} shadows: the sun reaches the open plane, lit {lit} at x {litX}");
			Test.Assert(lit < 765, scope $"{kind} shadows: not saturated, so the ratio means something");
			Test.Assert(shadowed * 2 < lit, scope $"{kind} shadows: the plane in the cube's shadow gets ambient only, shadowed {shadowed} at x {shadowX} vs lit {lit}");
			// No acne: the lit side is uniformly lit along the row; a wrong bias sign speckles it.
			uint32 darkest = 765;
			for (uint32 x = litX - 6; x <= litX + 6; x++)
				darkest = Math.Min(darkest, image.Luma(x, row));
			Test.Assert(darkest * 10 > lit * 8, scope $"{kind} shadows: no acne on the lit side, darkest {darkest} vs lit {lit}");
		}
	}
}
