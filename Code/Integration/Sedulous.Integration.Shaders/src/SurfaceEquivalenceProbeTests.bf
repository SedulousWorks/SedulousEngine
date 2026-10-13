using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.RHI.Vulkan;
using Sedulous.RHI.WebGPU;
#if BF_PLATFORM_WINDOWS
using Sedulous.RHI.DX12;
#endif
using Sedulous.Shaders;
using Sedulous.Shaders.Pipeline;
using Sedulous.Shaders.Resource;
using Sedulous.VFS;

namespace Sedulous.Integration.Shaders;

/// A surface shader renders as the engine's own does: the built-in PBR written as a lit surface
/// shader (Data/Assets/shaders/surface_pbr), cooked by the shader pipeline into its forward, depth
/// and pick programs, draws a lit, windy sphere on a ground the same as `forward` draws them, on
/// REAL GPU backends. The test allows a rounding step, since the two programs compute the same
/// lighting in a different order (the surface samples every texture before the cut-out test) and
/// another driver may round the last bit differently, nothing more.
class SurfaceEquivalenceProbeTests
{
	private const uint32 cSize = 160;
	private const String cSurfaceName = "surface_pbr";

	private enum Backend { Vulkan, WebGpu, Dx12 }

	/// The surface PBR's programs, checked as the shader cook proves them: every variant.
	private static ShaderCheck CookSurfacePbr(String library)
	{
		let dataRoot = FindDataRoot(.. scope String());
		Test.Assert(!dataRoot.IsEmpty);
		DataPath(dataRoot, "Shaders", library);
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(DataPath(dataRoot, "Assets/shaders/surface_pbr/surface_pbr.hlsl", .. scope .()), text) case .Ok);
		var options = ShaderCheckOptions();
		options.ShaderLibrary = library;
		let check = new ShaderCheck();
		check.Run(text, "surface_pbr.hlsl", options);
		let errors = scope String();
		for (let error in check.Errors)
			error.Format(errors..Append('\n'));
		Test.Assert(check.IsOk, errors);
		Test.Assert(check.HasVertex, "forward's wind");
		return check;
	}

	/// The forward PBR material the scene uses, or the same values on the surface PBR (its
	/// properties are forward's, in forward's layout, so the material is the same but its
	/// shader). THE CALLER OWNS it.
	private static Material PbrMaterial(StringView name, Float4 color, float metallic, float roughness, bool surface)
	{
		let material = MaterialPresets.CreatePbr(name, color, metallic, roughness);
		material.SetDefaultFloat("WindStrength", 0.15f);
		material.SetDefaultFloat("WindSpeed", 1.0f);
		material.SetDefaultFloat("WindHeight", 0.5f);
		if (surface)
		{
			material.ShaderName.Set(cSurfaceName);
			material.Pipeline.ShaderName = material.ShaderName;
			material.DepthShaderName..Set(cSurfaceName).Append(ShaderSource.cDepthProgramSuffix);
			material.PickShaderName..Set(cSurfaceName).Append(ShaderSource.cPickProgramSuffix);
		}
		return material;
	}

	/// The scene drawn twice at one time (the second frame's previous time equals its own) and
	/// read back. Empty when the frame could not be built.
	private static void RenderScene(IDevice device, ShaderCheck cooked, bool surface, List<uint8> outPixels)
	{
		let dataMount = scope NativeFileSystem(FindDataRoot(.. scope String()));
		let host = scope ShaderSystemHost();
		if (host.Initialize(device, dataMount) case .Err)
			return;
		defer host.Shutdown();
		let shaders = host.System;
		for (let program in cooked.Programs)
		{
			let name = scope String(cSurfaceName)..Append(program.Suffix);
			shaders.RegisterSource(name, .Vertex, program.Text, program.VertexEntryPoint, program.VertexMask);
			shaders.RegisterSource(name, .Fragment, program.Text, program.FragmentEntryPoint, program.FragmentMask);
		}
		if (surface)
		{
			// The surface programs resolve: the draws below are the surface shader's, not a
			// fallback (a missing program would skip the draw, and the images would differ).
			Test.Assert(shaders.GetVariant(cSurfaceName, .Fragment, .GBuffer) != null);
			Test.Assert(shaders.GetVariant("surface_pbr.depth", .Vertex, .None) != null);
		}

		let psoCache = scope PipelineStateCache(shaders, device);
		let materials = scope MaterialSystem();
		if (materials.Initialize(device) case .Err)
			return;
		let meshRenderer = scope MeshRenderer(device, shaders, psoCache, materials, 2);
		if (meshRenderer.Initialize() case .Err)
			return;
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(device, registry, 2);

		let sphere = Primitives.Sphere(1.0f, 48, 24);
		defer delete sphere;
		let ground = Primitives.Plane(8.0f, 8.0f);
		defer delete ground;
		let ball = PbrMaterial("ball", .(0.8f, 0.3f, 0.2f, 1.0f), 0.2f, 0.4f, surface);
		defer delete ball;
		let floor = PbrMaterial("floor", .(0.7f, 0.7f, 0.7f, 1.0f), 0.0f, 0.8f, surface);
		defer delete floor;
		floor.SetDefaultFloat("WindStrength", 0.0f); // the ground stays put
		ball.SetDefaultFloat4("EmissiveColor", .(0.05f, 0.02f, 0.0f, 1.0f));

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(0.15f, 0.15f, 0.18f));
		let b = scene.Add<MeshRenderData>();
		b.World = Float4x4.Translation(.(0.0f, 1.3f, -6.0f));
		b.WorldCenter = .(0.0f, 1.3f, -6.0f);
		b.WorldRadius = 1.5f;
		b.Mesh = sphere;
		b.Material = ball;
		b.Category = RenderCategories.Opaque;
		let g = scene.Add<MeshRenderData>();
		g.World = Float4x4.Translation(.(0.0f, 0.0f, -6.0f));
		g.WorldCenter = .(0.0f, 0.0f, -6.0f);
		g.WorldRadius = 6.0f;
		g.Mesh = ground;
		g.Material = floor;
		g.Category = RenderCategories.Opaque;
		var sun = GpuLight();
		sun.Type = 0.0f;
		sun.DirectionWS = Normalized(Float3(0.4f, -1.0f, -0.3f));
		sun.Intensity = 3.0f;
		sun.ShadowIndex = 0.0f;
		sun.ShadowStrength = 1.0f;
		scene.AddLight(sun);
		var shadow = DirectionalShadow();
		shadow.Direction = sun.DirectionWS;
		shadow.Valid = true;
		scene.SetDirectionalShadow(shadow);

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 2.5f, 0), .(0, 0.8f, -6), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 2.5f, 0);
		camera.FarZ = 100.0f;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "surface.target";
		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return;
		defer device.DestroyTexture(ref target);
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return;
		defer device.DestroyTextureView(ref targetView);
		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return;
		defer device.DestroyCommandPool(ref pool);
		if (!(device.CreateFence(0) case .Ok(var fence)))
			return;
		defer device.DestroyFence(ref fence);
		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return;

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;
		for (uint32 i = 0; i < 2; i++)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return;
			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.SetTime(1.25f); // mid-sway: the sphere's top has moved
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();
			let commandBuffer = encoder.Finish();
			if (commandBuffer == null)
			{
				pool.DestroyEncoder(ref encoder);
				return;
			}
			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}

		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		defer delete image;
		device.WaitIdle();
		if ((image != null) && image.Valid)
			outPixels.AddRange(image.Rgba);
	}

	private static void Probe(IDevice device, ShaderCheck cooked, Backend kind)
	{
		let forward = scope List<uint8>();
		RenderScene(device, cooked, false, forward);
		let surface = scope List<uint8>();
		RenderScene(device, cooked, true, surface);
		Test.Assert(forward.Count == cSize * cSize * 4, scope $"{kind}: forward rendered");
		Test.Assert(surface.Count == forward.Count, scope $"{kind}: the surface rendered");

		uint32 lit = 0; // pixels the scene covers (not the black clear)
		uint32 worst = 0; // the largest channel difference
		uint32 differing = 0; // pixels off by more than rounding
		for (int i = 0; i < forward.Count; i += 4)
		{
			let luma = (uint32)forward[i] + forward[i + 1] + forward[i + 2];
			if (luma > 15)
				lit++;
			uint32 d = 0;
			for (int c < 3)
				d = Math.Max(d, (uint32)Math.Abs((int32)forward[i + c] - (int32)surface[i + c]));
			worst = Math.Max(worst, d);
			if (d > 2)
				differing++;
		}
		Console.WriteLine(scope $"{kind}: lit pixels {lit}, worst channel difference {worst}, pixels off by more than 2: {differing}");
		Test.Assert(lit > cSize * cSize / 4, scope $"{kind}: the scene fills the frame");
		Test.Assert(worst <= 3, scope $"{kind}: rounding, not a different picture ({worst})");
		Test.Assert(differing <= cSize * cSize / 200, scope $"{kind}: {differing} pixels differ");
	}

	[Test]
	public static void TheBuiltInPbrAsASurfaceRendersAsForwardDoesWindAndShadowIncluded()
	{
		{
			let compiler = scope ShaderCompiler();
			if (compiler.Initialize() case .Err) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		}
		let cooked = CookSurfacePbr(scope .());
		defer delete cooked;
		for (let kind in scope Backend[](.Vulkan, .WebGpu, .Dx12))
		{
			IBackend backend = null;
			switch (kind)
			{
			case .Vulkan:
				if (VulkanRhi.CreateBackend(false) case .Ok(let created))
					backend = created;
			case .WebGpu:
				if (WebGpuRhi.CreateBackend() case .Ok(let created))
					backend = created;
			case .Dx12:
#if BF_PLATFORM_WINDOWS
				if (DxRhi.CreateBackend() case .Ok(let created))
					backend = created;
#endif
			}
			if (backend == null)
				continue;
			let device = RhiTestSupport.MakeTestDevice(backend);
			if (device != null)
			{
				Probe(device, cooked, kind);
				device.Destroy();
			}
			else
			{
				Console.WriteLine(scope $"{kind} unavailable: skipped");
			}
			backend.Destroy();
			delete backend;
		}
	}
}
