using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
// ALIASED because the class and this project's namespace are both spelled
// TextureCompression, and the nearer one would shadow it.
typealias TexComp = Sedulous.Texture.Compression.TextureCompression;

namespace Sedulous.Integration.TextureCompression;

/// Builds the textures these cases sample, and renders a cube wearing one.
///
/// The cube matters: a compressed texture can only be checked by SAMPLING it, which means a
/// real pipeline, a real draw and a readback. Nothing short of that exercises the block layout
/// the upload had to get right.
static class BcTextureProbe
{
	public const uint32 cSize = 128; // the render target
	public const uint32 cTexSize = 64; // the source texture, sixteen blocks square

	/// A solid colour encoded to `format` and uploaded through the runtime's block aware
	/// layout. Null when the encode or the upload failed. The caller owns both handles.
	public static ITextureView MakeSolidBcTexture(IDevice device, TextureFormat format, uint8 r,
		uint8 g, uint8 b, out ITexture outTexture)
	{
		outTexture = null;

		let texels = (int)cTexSize * (int)cTexSize;
		let src = scope List<uint8>();
		src.Resize(texels * 4);
		for (int i = 0; i < texels; i++)
		{
			src[i * 4 + 0] = r;
			src[i * 4 + 1] = g;
			src[i * 4 + 2] = b;
			src[i * 4 + 3] = 255;
		}

		let blocks = scope List<uint8>();
		if (format == .BC6HRGBUfloat)
		{
			// The HDR leg: the same colour as linear radiance, through the BC6H encoder.
			let hdr = scope List<float>();
			hdr.Resize(texels * 4);
			for (int i = 0; i < texels; i++)
			{
				hdr[i * 4 + 0] = (float)r / 255.0f;
				hdr[i * 4 + 1] = (float)g / 255.0f;
				hdr[i * 4 + 2] = (float)b / 255.0f;
				hdr[i * 4 + 3] = 1.0f;
			}
			TexComp.EncodeBlockCompressedHdr(hdr.Ptr, cTexSize, cTexSize, 255, blocks);
		}
		else
		{
			TexComp.EncodeBlockCompressed(src.Ptr, cTexSize, cTexSize, format, 255,
				blocks);
		}

		// The encoder and the RHI have to agree on the size, or the upload below would be
		// reading past the blocks or leaving some behind.
		if ((uint64)blocks.Count != TextureFormats.CompressedLevelBytes(format, cTexSize, cTexSize))
			return null;

		var td = TextureDesc();
		td.Format = format;
		td.Width = cTexSize;
		td.Height = cTexSize;
		td.MipLevelCount = 1;
		td.Usage = .Sampled | .CopyDst;
		td.Label = "bc.probe.source";

		if (!(device.CreateTexture(td) case .Ok(var texture)))
			return null;

		// Uploaded exactly as the texture resource factory does: a BLOCK row pitch, and rows
		// counted in blocks rather than in texels.
		let queue = device.GetQueue(.Graphics, 0);
		if (queue == null)
		{
			device.DestroyTexture(ref texture);
			return null;
		}

		if (!(queue.CreateTransferBatch() case .Ok(var batch)))
		{
			device.DestroyTexture(ref texture);
			return null;
		}

		var layout = TextureDataLayout();
		layout.BytesPerRow = TextureFormats.CompressedRowPitch(format, cTexSize);
		layout.RowsPerImage = (cTexSize + TextureFormats.BlockHeight(format) - 1) /
			TextureFormats.BlockHeight(format);

		batch.WriteTexture(texture, blocks, layout, Extent3D(cTexSize, cTexSize, 1), 0, 0);
		batch.Submit().IgnoreError();
		queue.DestroyTransferBatch(ref batch);

		var vd = TextureViewDesc();
		vd.Format = format;
		vd.Dimension = .Texture2D;

		if (!(device.CreateTextureView(texture, vd) case .Ok(let view)))
		{
			device.DestroyTexture(ref texture);
			return null;
		}

		outTexture = texture;
		return view;
	}

	/// An 8x8 RGBA8 texture uploaded with a PADDED row pitch: red texels then blue padding on
	/// every row. A backend that ignores the layout's row pitch reads the padding as the next
	/// row's texels and the cube comes out half blue.
	public static ITextureView MakePaddedRgba8Texture(IDevice device, out ITexture outTexture)
	{
		outTexture = null;

		const uint32 cEdge = 8;
		const uint32 cBytesPerRow = cEdge * 4 + 32; // thirty two bytes of padding per row

		let src = scope List<uint8>();
		src.Resize((int)cBytesPerRow * (int)cEdge);
		for (uint32 y = 0; y < cEdge; y++)
		{
			let row = src.Ptr + (int)y * (int)cBytesPerRow;
			for (uint32 x = 0; x < cBytesPerRow / 4; x++)
			{
				let padding = x >= cEdge;
				row[x * 4 + 0] = padding ? 20 : 230;
				row[x * 4 + 1] = 20;
				row[x * 4 + 2] = padding ? 230 : 20;
				row[x * 4 + 3] = 255;
			}
		}

		var td = TextureDesc();
		td.Format = .RGBA8Unorm;
		td.Width = cEdge;
		td.Height = cEdge;
		td.MipLevelCount = 1;
		td.Usage = .Sampled | .CopyDst;
		td.Label = "padded.probe.source";

		if (!(device.CreateTexture(td) case .Ok(var texture)))
			return null;

		let queue = device.GetQueue(.Graphics, 0);
		if (queue == null)
		{
			device.DestroyTexture(ref texture);
			return null;
		}

		if (!(queue.CreateTransferBatch() case .Ok(var batch)))
		{
			device.DestroyTexture(ref texture);
			return null;
		}

		var layout = TextureDataLayout();
		layout.BytesPerRow = cBytesPerRow;
		layout.RowsPerImage = cEdge;

		batch.WriteTexture(texture, src, layout, Extent3D(cEdge, cEdge, 1), 0, 0);
		let submitted = batch.Submit();
		queue.DestroyTransferBatch(ref batch);

		if (submitted case .Err)
		{
			device.DestroyTexture(ref texture);
			return null;
		}

		var vd = TextureViewDesc();
		vd.Format = .RGBA8Unorm;

		if (!(device.CreateTextureView(texture, vd) case .Ok(let view)))
		{
			device.DestroyTexture(ref texture);
			return null;
		}

		outTexture = texture;
		return view;
	}

	/// A screen filling unlit cube wearing `albedo`, read back as LDR.
	///
	/// UNLIT with a white base colour, so the sampled texel passes straight through and what
	/// comes back is the decoded block rather than the decoded block times some lighting.
	public static CapturedImage RenderTexturedCube(BcProbeFixture fixture, ITextureView albedo)
	{
		let device = fixture.Device;
		let shaders = fixture.Shaders;

		let psoCache = scope PipelineStateCache(shaders, device);
		let materials = scope MaterialSystem();
		if (materials.Initialize(device) case .Err)
			return new CapturedImage();

		let meshRenderer = scope MeshRenderer(device, shaders, psoCache, materials, 2);
		if (meshRenderer.Initialize() case .Err)
			return new CapturedImage();

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		let tonemap = scope TonemapPass(device, shaders, 2);
		if (tonemap.Initialize() case .Err)
			return new CapturedImage();

		let frame = scope RenderFrame(device, registry, 2, null, tonemap, null, null, null, null,
			null, null, null);

		let cubeMesh = Primitives.Cube(3.2f);
		defer delete cubeMesh;

		let mat = MaterialPresets.CreateUnlit("bc.probe", .(1, 1, 1, 1));
		defer delete mat;
		mat.SetDefaultTexture("AlbedoMap", albedo);

		let scene = scope ExtractedScene();
		let cube = scene.Add<MeshRenderData>();
		cube.World = Float4x4.RotationY(0.3f) * Float4x4.RotationX(0.2f);
		cube.WorldCenter = .(0, 0, 0);
		cube.Mesh = cubeMesh;
		cube.Material = mat;
		cube.Category = RenderCategories.Opaque;

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 4), .(0, 0, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 0, 4);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "bc.probe.target";

		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return new CapturedImage();
		defer device.DestroyTexture(ref target);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return new CapturedImage();
		defer device.DestroyTextureView(ref targetView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return new CapturedImage();
		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return new CapturedImage();
		defer device.DestroyFence(ref fence);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return new CapturedImage();

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.BloomEnabled = false;

		for (uint32 i = 0; i < 2; i++)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return new CapturedImage();

			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();

			let commandBuffer = encoder.Finish();
			if (commandBuffer == null)
			{
				pool.DestroyEncoder(ref encoder);
				return new CapturedImage();
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

	/// Lit pixels whose given channel is the clear winner. The black background never counts.
	public static uint32 CountDominant(CapturedImage img, int channel)
	{
		uint32 count = 0;
		for (uint32 y = 0; y < img.Height; y++)
		{
			for (uint32 x = 0; x < img.Width; x++)
			{
				let p = img.At(x, y);
				uint32 r = p[0];
				uint32 g = p[1];
				uint32 b = p[2];
				if (r + g + b < 90)
					continue; // background

				let v = (channel == 0) ? r : ((channel == 1) ? g : b);
				let other = (channel == 0) ? Math.Max(g, b)
					: ((channel == 1) ? Math.Max(r, b) : Math.Max(r, g));
				if (v > other + 40)
					count++;
			}
		}
		return count;
	}

	/// The brightest pixel's colour, which is the cube face most head on.
	public static void BrightestRgb(CapturedImage img, out uint32 outR, out uint32 outG,
		out uint32 outB)
	{
		uint32 best = 0;
		outR = 0;
		outG = 0;
		outB = 0;

		for (uint32 y = 0; y < img.Height; y++)
		{
			for (uint32 x = 0; x < img.Width; x++)
			{
				let luma = img.Luma(x, y);
				if (luma > best)
				{
					best = luma;
					let p = img.At(x, y);
					outR = p[0];
					outG = p[1];
					outB = p[2];
				}
			}
		}
	}

	/// Whether the device can actually sample the format. BC is desktop and ASTC is mobile, so
	/// a desktop GPU usually lacks ASTC and that leg skips itself rather than failing.
	public static bool SupportsSampled(IDevice device, TextureFormat format) =>
		device.GetFormatSupport(format).HasFlag(.Texture);
}
