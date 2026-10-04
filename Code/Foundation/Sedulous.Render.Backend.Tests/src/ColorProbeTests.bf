using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// The colour pipeline on a real device: what is entered is what is seen. Authored colours
/// are sRGB, the same encoding as an sRGB image, and every path decodes them once on the way
/// to the GPU.
///
/// A debug colour drawn into an sRGB target reads back as the bytes entered (the debug
/// shaders decode their vertex colours; the target encodes on write). A material colour
/// matches a texture of the same value: an unlit quad whose BaseColor is sRGB 0.5 over a white
/// texture, beside one whose texture is sRGB 128 under a white BaseColor, render the same
/// pixel (the material upload decodes its colours as the sampler decodes the texture).
class ColorProbeTests
{
	private const uint32 cSize = 64;

	/// An sRGB 2 x 2 texture of one grey byte value. The caller destroys both.
	private static void MakeGreyTexture(IDevice device, uint8 value, out ITexture texture, out ITextureView view)
	{
		var desc = TextureDesc();
		desc.Format = .RGBA8UnormSrgb;
		desc.Width = 2;
		desc.Height = 2;
		desc.Usage = .Sampled | .CopyDst;
		desc.Label = "probe.grey";
		texture = device.CreateTexture(desc).Value;
		uint8[2 * 2 * 4] pixels = .();
		for (int i < 4)
		{
			pixels[i * 4 + 0] = value;
			pixels[i * 4 + 1] = value;
			pixels[i * 4 + 2] = value;
			pixels[i * 4 + 3] = 255;
		}
		let queue = device.GetQueue(.Graphics);
		var batch = queue.CreateTransferBatch().Value;
		var layout = TextureDataLayout();
		layout.BytesPerRow = 2 * 4;
		layout.RowsPerImage = 2;
		batch.WriteTexture(texture, .(&pixels[0], pixels.Count), layout, .(2, 2, 1));
		Test.Assert(batch.Submit() case .Ok);
		queue.DestroyTransferBatch(ref batch);
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8UnormSrgb;
		view = device.CreateTextureView(texture, viewDesc).Value;
	}

	/// Renders `scene` into a fresh sRGB target and reads it back. Tonemapping runs as in any
	/// view; the probes compare like with like, or use the debug overlay, which draws after it.
	private static CapturedImage RenderProbe(IDevice device, RenderFrame frame, ExtractedScene scene)
	{
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 5), .(0, 0, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 0, 5);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8UnormSrgb;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "probe.target";
		var target = device.CreateTexture(textureDesc).Value;
		defer device.DestroyTexture(ref target);
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8UnormSrgb;
		var targetView = device.CreateTextureView(target, viewDesc).Value;
		defer device.DestroyTextureView(ref targetView);
		var pool = device.CreateCommandPool(.Graphics).Value;
		defer device.DestroyCommandPool(ref pool);
		var fence = device.CreateFence(0).Value;
		defer device.DestroyFence(ref fence);
		let queue = device.GetQueue(.Graphics);

		var settings = ViewSettings();
		settings.Clear = .(0.0f, 0.0f, 0.0f, 1.0f);
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.BloomEnabled = false;
		for (uint32 i < 2)
		{
			var encoder = pool.CreateEncoder().Value;
			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8UnormSrgb, cSize, cSize);
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

	[Test]
	public static void ADebugColourReadsBackFromAnSrgbTargetAsTheBytesEntered()
	{
		let fixture = scope BackendProbeFixture(.Vulkan);
		if (!fixture.Ready)
			return;
		let device = fixture.Device;
		let registry = scope RendererRegistry();
		let tonemap = scope TonemapPass(device, fixture.Shaders, 2);
		Test.Assert(tonemap.Initialize() case .Ok);
		let debugPass = scope DebugDrawPass(device, fixture.Shaders, 2);
		Test.Assert(debugPass.Initialize() case .Ok);
		let frame = scope RenderFrame(device, registry, 2, null, tonemap);

		// A filled overlay quad across the whole view, in an authored colour.
		let global = scope DebugDraw();
		global.DrawQuad(.(-5, -5, 0), .(5, -5, 0), .(5, 5, 0), .(-5, 5, 0), .(0.5f, 0.25f, 0.75f, 1.0f), true);
		frame.SetDebug(debugPass, global, null);

		let scene = scope ExtractedScene();
		let image = RenderProbe(device, frame, scene);
		defer delete image;
		Test.Assert(image.Valid);
		let p = image.At(cSize / 2, cSize / 2);
		// 0.5, 0.25, 0.75 as bytes: 128, 64, 191 (not 188, 137, 225, the value read as linear).
		Test.Assert(Math.Abs((int32)p[0] - 128) <= 2, scope $"red {p[0]}");
		Test.Assert(Math.Abs((int32)p[1] - 64) <= 2, scope $"green {p[1]}");
		Test.Assert(Math.Abs((int32)p[2] - 191) <= 2, scope $"blue {p[2]}");
	}

	[Test]
	public static void AMaterialColourRendersLikeATextureOfTheSameValue()
	{
		let fixture = scope BackendProbeFixture(.Vulkan);
		if (!fixture.Ready)
			return;
		let device = fixture.Device;
		let psoCache = scope PipelineStateCache(fixture.Shaders, device);
		let materials = scope MaterialSystem();
		Test.Assert(materials.Initialize(device) case .Ok);
		let meshRenderer = scope MeshRenderer(device, fixture.Shaders, psoCache, materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let tonemap = scope TonemapPass(device, fixture.Shaders, 2);
		Test.Assert(tonemap.Initialize() case .Ok);
		let frame = scope RenderFrame(device, registry, 2, null, tonemap);

		MakeGreyTexture(device, 128, var grey, var greyView);
		MakeGreyTexture(device, 255, var white, var whiteView);
		defer
		{
			device.WaitIdle();
			device.DestroyTextureView(ref greyView);
			device.DestroyTexture(ref grey);
			device.DestroyTextureView(ref whiteView);
			device.DestroyTexture(ref white);
		}

		// Left: the colour entered in the material (sRGB 0.502), over white. Right: white, over
		// a texture of byte 128. Unlit, so nothing but the colour reaches the pixel.
		let tinted = MaterialPresets.CreateUnlit("probe.tinted", .(128.0f / 255.0f, 128.0f / 255.0f, 128.0f / 255.0f, 1.0f));
		defer delete tinted;
		tinted.SetDefaultTexture("AlbedoMap", whiteView);
		let textured = MaterialPresets.CreateUnlit("probe.textured", .(1, 1, 1, 1));
		defer delete textured;
		textured.SetDefaultTexture("AlbedoMap", greyView);

		let quad = Primitives.Quad(2.0f, 2.0f);
		defer delete quad;
		let scene = scope ExtractedScene();
		void Add(float x, Material material)
		{
			let data = scene.Add<MeshRenderData>();
			data.World = Float4x4.Translation(.(x, 0.0f, 0.0f));
			data.WorldCenter = .(x, 0.0f, 0.0f);
			data.Mesh = quad;
			data.Material = material;
			data.Category = RenderCategories.Opaque;
		}
		Add(-1.2f, tinted);
		Add(1.2f, textured);

		let image = RenderProbe(device, frame, scene);
		defer delete image;
		Test.Assert(image.Valid);
		let left = image.At(cSize / 2 - 10, cSize / 2);
		let right = image.At(cSize / 2 + 10, cSize / 2);
		Test.Assert((left[0] > 10) && (right[0] > 10), scope $"both quads drew ({left[0]}, {right[0]})");
		Test.Assert(Math.Abs((int32)left[0] - (int32)right[0]) <= 2, scope $"left {left[0]}, right {right[0]}");
		Test.Assert(Math.Abs((int32)left[1] - (int32)right[1]) <= 2, scope $"left {left[1]}, right {right[1]}");
	}
}
