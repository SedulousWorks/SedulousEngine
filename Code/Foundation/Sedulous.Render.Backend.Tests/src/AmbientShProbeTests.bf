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

/// The sky's diffuse light (SH9 irradiance) on a real device.
///
/// The sky's radiance is z squared along every direction, a function within the second SH band,
/// so its cosine convolved irradiance is exact: pi/2 on a surface facing +z, pi/4 on one facing
/// +x. A white sphere lit by that sky alone (no lights, no specular IBL) must then read twice as
/// bright where it faces +z as where it faces +x. The L20 term three times too strong made it
/// ten times.
class AmbientShProbeTests
{
	private const uint32 cSize = 128;
	/// The BRDF table and the sky's products bake on the first.
	private const uint32 cFrames = 3;

	private static void Project(ViewCamera camera, Float3 p, out uint32 px, out uint32 py)
	{
		let vp = camera.View * camera.Projection;
		float[4] clip = .();
		for (int j < 4)
			clip[j] = p.X * vp.M[0][j] + p.Y * vp.M[1][j] + p.Z * vp.M[2][j] + vp.M[3][j];
		px = (uint32)((clip[0] / clip[3] * 0.5f + 0.5f) * (float)cSize);
		py = (uint32)((0.5f - clip[1] / clip[3] * 0.5f) * (float)cSize);
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

	/// An equirect image of radiance z squared, in the mapping ibl_equirect.ps.hlsl samples
	/// with: u = atan2(z, x) / 2pi + 0.5, v = 0.5 - asin(y) / pi.
	private static void SkyOfZSquared(uint32 width, uint32 height, List<float> outRgba)
	{
		outRgba.Clear();
		outRgba.Resize((int)width * (int)height * 4);
		let pi = 3.14159265359;
		for (uint32 y < height)
		{
			let theta = (0.5 - ((double)y + 0.5) / (double)height) * pi;
			for (uint32 x < width)
			{
				let phi = (((double)x + 0.5) / (double)width - 0.5) * 2.0 * pi;
				let z = (float)(Math.Cos(theta) * Math.Sin(phi));
				let at = ((int)y * (int)width + (int)x) * 4;
				outRgba[at] = z * z;
				outRgba[at + 1] = z * z;
				outRgba[at + 2] = z * z;
				outRgba[at + 3] = 1.0f;
			}
		}
	}

	[Test]
	public static void ASkyOfZSquaredLightsAFaceTowardZTwiceAsMuchAsOneTowardX()
	{
		let fixture = scope BackendProbeFixture(.Vulkan);
		if (!fixture.Ready)
			return;
		let device = fixture.Device;

		// From +x +z, so the sphere's +x and +z faces both show.
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(5, 0, 5), .(0, 0, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(0.6f, 1.0f, 0.1f, 50.0f);
		camera.Position = .(5, 0, 5);
		camera.FarZ = 50.0f;

		let psoCache = scope PipelineStateCache(fixture.Shaders, device);
		let materials = scope MaterialSystem();
		Test.Assert(materials.Initialize(device) case .Ok);
		let meshRenderer = scope MeshRenderer(device, fixture.Shaders, psoCache, materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let ibl = scope IBLSystem(device, fixture.Shaders);
		Test.Assert(ibl.Initialize() case .Ok);
		let sky = scope List<float>();
		SkyOfZSquared(256, 128, sky);
		ibl.SetEquirect(256, 128, sky);
		let frame = scope RenderFrame(device, registry, 2, null, null, null, ibl);

		let sphere = Primitives.Sphere(1.0f, 64);
		defer delete sphere;
		let white = MaterialPresets.CreatePbr("probe.white", .(1, 1, 1, 1), 0.0f, 1.0f);
		defer delete white;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "ambientshprobe.target";
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

		let scene = scope ExtractedScene();
		var skySettings = SkySnapshot();
		// The programmatic image above, and the diffuse alone.
		skySettings.Mode = .HDREquirect;
		skySettings.IblSpecularIntensity = 0.0f;
		scene.SetSky(skySettings);
		let data = scene.Add<MeshRenderData>();
		data.WorldRadius = 1.0f;
		data.Mesh = sphere;
		data.Material = white;
		data.Category = RenderCategories.Opaque;

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;
		for (uint32 i < cFrames)
		{
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
		// Just inside the sphere where its normal is +z and +x (both 45 degrees from the camera).
		Project(camera, .(0, 0, 0.98f), var x, var y);
		let facingZ = BoxLuma(image, x, y);
		Project(camera, .(0.98f, 0, 0), out x, out y);
		let facingX = BoxLuma(image, x, y);
		device.WaitIdle();

		Test.Assert(facingX > 30.0, scope $"the face toward +x is lit ({facingX})");
		let ratio = facingZ / facingX;
		Test.Assert(Math.Abs(ratio - 2.0) <= 0.2, scope $"twice as bright toward +z as toward +x ({facingZ} against {facingX})");
	}
}
