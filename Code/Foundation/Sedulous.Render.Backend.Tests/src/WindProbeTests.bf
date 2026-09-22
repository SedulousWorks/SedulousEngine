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

/// The WIND vertex sway at the texel on real devices.
///
/// A tall card with a windy material is rendered at two frame times: its top rows, where the
/// height mask is one, shift sideways between them, while its bottom rows, below the root and
/// so at a mask of nought, do not. The same card with a material whose WindStrength is nought
/// renders identically at both times, the variant never being selected.
class WindProbeTests
{
	private const uint32 cSize = 128;

	/// One rendered frame: the pixels, and the leftmost lit column of each row, which is what
	/// moves when the card sways.
	private class Capture
	{
		public List<uint8> Pixels = new .() ~ delete _;
		/// Nought or above is the column; below nought means the row is dark.
		public List<int32> Leftmost = new .() ~ delete _;
	}

	/// A one by four metre card in the XY plane with `rows` rows of vertices, its local y
	/// running from -2 to +2.
	///
	/// The height mask is per VERTEX, so the rows below y nought carry no mask and stay put
	/// while the ones above sway. A two triangle quad would instead interpolate the top
	/// vertices' sway all the way down.
	///
	/// THE CALLER OWNS what comes back.
	private static StaticMesh SegmentedCard(uint32 rows)
	{
		let mesh = new StaticMesh();
		let white = 0xFFFFFFFF;
		for (uint32 r = 0; r <= rows; r++)
		{
			let t = (float)r / (float)rows;
			let y = -2.0f + 4.0f * t;
			mesh.Vertices.Add(.(.(-0.5f, y, 0.0f), .(0, 0, 1), .(0.0f, 1.0f - t), white,
				Float4(1, 0, 0, 1)));
			mesh.Vertices.Add(.(.(0.5f, y, 0.0f), .(0, 0, 1), .(1.0f, 1.0f - t), white,
				Float4(1, 0, 0, 1)));
		}
		// The buffer appends through its own cursor within the count, so the count comes first.
		mesh.Indices.Resize(rows * 6);
		for (uint32 r < rows)
		{
			let a = r * 2;
			mesh.Indices.AddTriangle(a, a + 1, a + 3);
			mesh.Indices.AddTriangle(a, a + 3, a + 2);
		}
		mesh.GenerateTangents();
		mesh.Bounds = AABB.FromCenterExtents(.(0, 0, 0), .(0.5f, 2.0f, 0.01f));
		mesh.SubMeshes.Add(.(0, (int32)mesh.IndexCount, 0, .Triangles));
		return mesh;
	}

	/// Renders the card twice at one frame time and reads the target back.
	///
	/// Twice because the second frame is the one whose previous time equals its own: nothing
	/// in the image then depends on which ring slot it landed in.
	///
	/// THE CALLER OWNS what comes back, and null means the frame could not be built.
	private static Capture RenderCard(BackendProbeFixture fixture, StaticMesh card,
		Material material, float time)
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

		let frame = scope RenderFrame(device, registry, 2);

		// The card six metres in front of the camera, its centre at local y nought, so the top
		// half carries the height mask and the bottom half none.
		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));
		let data = scene.Add<MeshRenderData>();
		data.World = Float4x4.Translation(.(0.0f, 0.0f, -6.0f));
		data.WorldCenter = .(0.0f, 0.0f, -6.0f);
		data.WorldRadius = 3.0f;
		data.Mesh = card;
		data.Material = material;
		data.Category = RenderCategories.Opaque;

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
		textureDesc.Label = "wind.target";
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

			// The same clock both frames, so the previous time equals this one and the sway
			// holds still across the pair.
			frame.SetTime(time);
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
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
		defer delete image;
		device.WaitIdle();
		if ((image == null) || !image.Valid)
			return null;

		let capture = new Capture();
		capture.Pixels.AddRange(image.Rgba);
		for (uint32 y < cSize)
		{
			var leftmost = (int32)-1;
			for (uint32 x < cSize)
			{
				if ((image.Luma(x, y) > 30) && (leftmost < 0))
					leftmost = (int32)x;
			}
			capture.Leftmost.Add(leftmost);
		}
		return capture;
	}

	[Test]
	public static void ACardsTipsSwayWithTheFrameTimeAndItsRootsStay()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			ProbeOn(kind);
	}

	private static void ProbeOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let windy = MaterialPresets.CreatePbr("wind.card", .(0.9f, 0.9f, 0.9f, 1), 0.0f, 0.9f);
		defer delete windy;
		// A metre of sway, which is around eighteen texels at this framing.
		windy.SetDefaultFloat("WindStrength", 1.0f);
		windy.SetDefaultFloat("WindSpeed", 1.0f);
		// Full at the card's top edge.
		windy.SetDefaultFloat("WindHeight", 2.0f);

		let still = MaterialPresets.CreatePbr("still.card", .(0.9f, 0.9f, 0.9f, 1), 0.0f, 0.9f);
		defer delete still;

		let card = SegmentedCard(16);
		defer delete card;

		let a = RenderCard(fixture, card, windy, 0.0f);
		defer delete a;
		let b = RenderCard(fixture, card, windy, 1.5f);
		defer delete b;
		Test.Assert((a != null) && (b != null), scope $"{kind}: the windy card rendered");

		// The card's rows, y downward: it spans the middle of the frame. The top quarter of
		// its lit rows are tips and the bottom quarter roots.
		var first = (int32)-1;
		var last = (int32)-1;
		for (int32 y = 0; y < (int32)cSize; y++)
		{
			if ((a.Leftmost[y] >= 0) && (b.Leftmost[y] >= 0))
			{
				if (first < 0)
					first = y;
				last = y;
			}
		}
		Test.Assert(first >= 0, scope $"{kind}: the card is lit");
		// A four metre card fills most of the frame's height.
		Test.Assert((last - first) > 40, scope $"{kind}: the card fills the frame");

		let span = last - first;
		var tipsMoved = false;
		var rootsMoved = false;
		// The screen's top is the card's local plus y.
		for (int32 y = first; y <= (first + span / 4); y++)
			tipsMoved |= a.Leftmost[y] != b.Leftmost[y];
		// And its bottom is below local y nought, where the mask is nought.
		for (int32 y = last - span / 4; y <= last; y++)
			rootsMoved |= a.Leftmost[y] != b.Leftmost[y];

		Test.Assert(tipsMoved, scope $"{kind}: the tips sway with the clock");
		Test.Assert(!rootsMoved, scope $"{kind}: the roots stay put");

		// A material whose strength is nought never selects the variant, so the clock reaches
		// nothing and the two frames are identical.
		let c = RenderCard(fixture, card, still, 0.0f);
		defer delete c;
		let d = RenderCard(fixture, card, still, 1.5f);
		defer delete d;
		Test.Assert((c != null) && (d != null), scope $"{kind}: the still card rendered");
		Test.Assert(c.Pixels.Count == d.Pixels.Count, scope $"{kind}: the same image size");

		var identical = true;
		for (int i < c.Pixels.Count)
			identical &= c.Pixels[i] == d.Pixels[i];
		Test.Assert(identical, scope $"{kind}: a still material renders the same at both times");

		// And its roots sit where the windy card's roots sit, the root rows being the same
		// geometry unmoved.
		Test.Assert(c.Leftmost[last] == a.Leftmost[last], scope $"{kind}: the roots share a column");
	}
}
