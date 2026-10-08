using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// A material's glow on real devices, in a scene with no light at all: one whose EmissiveColor
/// is set and that has no emissive texture glows its colour (glTF: emission is factor times
/// texture, the texture white when absent), and one with the default black EmissiveColor stays
/// black. Three cards: plain, glowing orange, glowing orange at twice the intensity.
///
/// An unbound emissive map used to be black, so every glow authored as a colour alone (each
/// glTF emissive factor the importer copies into EmissiveColor) never showed.
class EmissiveProbeTests
{
	private const uint32 cSize = 96;

	/// A unit card in the XY plane facing plus Z, toward a camera looking down minus Z.
	///
	/// THE CALLER OWNS what comes back.
	private static StaticMesh Card()
	{
		let mesh = new StaticMesh();
		let white = 0xFFFFFFFF;
		let n = Float3(0, 0, 1);
		let t = Float4(1, 0, 0, 1);
		mesh.Vertices.Add(.(.(-0.5f, -0.5f, 0), n, .(0, 1), white, t));
		mesh.Vertices.Add(.(.(0.5f, -0.5f, 0), n, .(1, 1), white, t));
		mesh.Vertices.Add(.(.(0.5f, 0.5f, 0), n, .(1, 0), white, t));
		mesh.Vertices.Add(.(.(-0.5f, 0.5f, 0), n, .(0, 0), white, t));
		// The buffer appends through its own cursor within the count, so the count comes first.
		mesh.Indices.Resize(6);
		mesh.Indices.AddTriangle(0, 1, 2);
		mesh.Indices.AddTriangle(0, 2, 3);
		mesh.GenerateTangents();
		mesh.Bounds = AABB.FromCenterExtents(.(0, 0, 0), .(0.5f, 0.5f, 0.01f));
		mesh.SubMeshes.Add(.(0, 6, 0, .Triangles));
		return mesh;
	}

	[Test]
	public static void AColourAloneGlowsWithoutAnEmissiveTextureAndBlackStaysDark()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			ProbeOn(kind);
	}

	private static void ProbeOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;
		let device = fixture.Device;
		let shaders = fixture.Shaders;

		let psoCache = scope PipelineStateCache(shaders, device);
		let materials = scope MaterialSystem();
		Test.Assert(materials.Initialize(device) case .Ok, scope $"{kind}: materials");
		let meshRenderer = scope MeshRenderer(device, shaders, psoCache, materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok, scope $"{kind}: mesh renderer");
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(device, registry, 2);

		let card = Card();
		defer delete card;
		let plain = MaterialPresets.CreatePbr("emissive.plain", .(0.6f, 0.6f, 0.6f, 1), 0.0f, 0.9f);
		defer delete plain;
		let glow = MaterialPresets.CreatePbr("emissive.glow", .(0.6f, 0.6f, 0.6f, 1), 0.0f, 0.9f);
		defer delete glow;
		glow.SetDefaultColor("EmissiveColor", .(1.0f, 0.5f, 0.2f, 0.5f)); // sRGB, intensity in w
		let bright = MaterialPresets.CreatePbr("emissive.bright", .(0.6f, 0.6f, 0.6f, 1), 0.0f, 0.9f);
		defer delete bright;
		bright.SetDefaultColor("EmissiveColor", .(1.0f, 0.5f, 0.2f, 1.0f));

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(0.0f, 0.0f, 0.0f)); // no light: only what glows shows
		Material[3] cardMaterials = .(plain, glow, bright);
		for (int32 i = -1; i <= 1; i++)
		{
			let at = Float3(1.15f * (float)i, 0.0f, -3.0f);
			let material = cardMaterials[i + 1];
			let data = scene.Add<MeshRenderData>();
			data.World = Float4x4.Translation(at);
			data.Mesh = card;
			data.Material = material;
			data.RendererId = meshRenderer.RendererId;
			data.Category = RenderCategories.Opaque;
			data.SortBatchKey = SortKeys.BatchKey(Internal.UnsafeCastToPtr(card),
				Internal.UnsafeCastToPtr(material));
			data.WorldCenter = at;
			data.WorldRadius = 1.0f;
			data.EntityId = (uint64)(i + 2);
		}

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 0, 0);
		camera.FarZ = 100.0f;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "emissive.target";
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
		Test.Assert(queue != null, scope $"{kind}: a graphics queue");

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;

		for (uint32 i = 0; i < 2; i++)
		{
			var encoder = pool.CreateEncoder().Value;
			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();
			let commandBuffer = encoder.Finish();
			Test.Assert(commandBuffer != null, scope $"{kind}: the frame recorded");
			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}

		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		defer delete image;
		device.WaitIdle();
		Test.Assert((image != null) && image.Valid, scope $"{kind}: read back");

		// Lit pixels per third: none for the plain card, the glowing ones orange.
		uint32[3] lit = .(0, 0, 0);
		Float3[3] sum = .(.(0, 0, 0), .(0, 0, 0), .(0, 0, 0));
		for (uint32 y < cSize)
		{
			for (uint32 x < cSize)
			{
				let p = image.At(x, y);
				if ((uint32)p[0] + p[1] + p[2] <= 30)
					continue;
				let c = Math.Min(x * 3 / cSize, 2);
				lit[c]++;
				sum[c] = sum[c] + Float3((float)p[0], (float)p[1], (float)p[2]);
			}
		}
		let report = scope $"{kind}: lit thirds {lit[0]} {lit[1]} {lit[2]}";
		// A black EmissiveColor in the dark: nothing.
		Test.Assert(lit[0] == 0, report);
		// A glow authored as a colour alone shows.
		Test.Assert((lit[1] > 0) && (lit[2] > 0), report);
		let glowMean = sum[1] * (1.0f / (float)lit[1]);
		let brightMean = sum[2] * (1.0f / (float)lit[2]);
		let colours = scope $"{report}, glow mean ({glowMean.X}, {glowMean.Y}, {glowMean.Z}), bright red {brightMean.X}";
		// Its colour: orange.
		Test.Assert(glowMean.X > glowMean.Z * 2.0f, colours);
		// Twice the intensity, brighter.
		Test.Assert(brightMean.X > glowMean.X, colours);
	}
}
