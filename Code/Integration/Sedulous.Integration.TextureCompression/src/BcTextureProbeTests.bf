using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.Integration.TextureCompression;

/// Block compressed textures, end to end: encoded by the compressor, uploaded through the
/// runtime's block aware layout, sampled by a real shader on a real device, and read back.
///
/// INTEGRATION rather than unit, because every seam between those four is where this goes
/// wrong, and none of them is visible from either side alone.
class BcTextureProbeTests
{
	/// Every backend, since each decodes these formats in its own driver and each has its own
	/// idea of how a compressed row pitch is counted.
	private static ProbeBackend[3] Backends => .(.Vulkan, .WebGpu, .Dx12);

	[Test]
	public static void BlockCompressedTexturesUploadAndSampleCorrectly()
	{
		for (let kind in Backends)
		{
			let fixture = scope:: BcProbeFixture(kind);
			if (!fixture.Ready)
				continue;

			ProbeBcSampling(fixture);
		}
	}

	/// Found by the Beef port, and kept because it is cheap: the Vulkan transfer batch stored
	/// the data layout and never passed it to the buffer image copy, so a padded upload copied
	/// its padding in as texels.
	[Test]
	public static void APaddedRowPitchUploadsWithoutItsPaddingBecomingPixels()
	{
		for (let kind in Backends)
		{
			let fixture = scope:: BcProbeFixture(kind);
			if (!fixture.Ready)
				continue;

			ProbePaddedUpload(fixture);
		}
	}

	private static void ProbeBcSampling(BcProbeFixture fixture)
	{
		// Each case is a solid colour in one format, with the channel it must come back
		// dominant in. BC5 keeps only red and green, so its blue is nought by construction.
		let cases = scope BcProbeCase[](
			.("BC1-red", .BC1RGBAUnorm, 230, 20, 20, 0),
			.("BC7-green", .BC7RGBAUnorm, 20, 220, 20, 1),
			.("BC5-normalRG", .BC5RGUnorm, 200, 40, 0, 0),
			.("ASTC-blue", .ASTC4x4Unorm, 20, 20, 225, 2),
			.("BC6H-red", .BC6HRGBUfloat, 230, 20, 20, 0));

		for (let c in cases)
		{
			// Expected for ASTC on a desktop GPU, which is a mobile family; the leg runs on
			// hardware that has it.
			if (!BcTextureProbe.SupportsSampled(fixture.Device, c.Format))
				continue;

			let view = BcTextureProbe.MakeSolidBcTexture(fixture.Device, c.Format, c.R, c.G, c.B,
				var tex);
			Test.Assert(view != null, scope $"{fixture.Kind} {c.Name}: the source texture built");

			let img = BcTextureProbe.RenderTexturedCube(fixture, view);
			defer delete img;
			Test.Assert(img.Valid, scope $"{fixture.Kind} {c.Name}: the cube rendered");

			BcTextureProbe.BrightestRgb(img, var pr, var pg, var pb);

			let dominant = (c.Dominant == 0) ? pr : ((c.Dominant == 1) ? pg : pb);

			// It shows the TEXTURE rather than black: the dominant channel is clearly lit.
			Test.Assert(dominant > 120,
				scope $"{fixture.Kind} {c.Name}: sampled ({pr},{pg},{pb}) is lit");

			// And the hue survived the decode, which is what says the upload put the right
			// block bytes at the right pitch. A wrong pitch smears or garbles it.
			if (c.Dominant != 0)
				Test.Assert(dominant > pr, scope $"{fixture.Kind} {c.Name}: beats red");
			if (c.Dominant != 1)
				Test.Assert(dominant > pg, scope $"{fixture.Kind} {c.Name}: beats green");
			if (c.Dominant != 2)
				Test.Assert(dominant > pb, scope $"{fixture.Kind} {c.Name}: beats blue");

			var viewRef = view;
			fixture.Device.DestroyTextureView(ref viewRef);
			fixture.Device.DestroyTexture(ref tex);
		}
	}

	private static void ProbePaddedUpload(BcProbeFixture fixture)
	{
		let view = BcTextureProbe.MakePaddedRgba8Texture(fixture.Device, var tex);
		Test.Assert(view != null, scope $"{fixture.Kind}: the padded texture built");

		let img = BcTextureProbe.RenderTexturedCube(fixture, view);
		defer delete img;
		Test.Assert(img.Valid, scope $"{fixture.Kind}: the cube rendered");

		let red = BcTextureProbe.CountDominant(img, 0);
		let blue = BcTextureProbe.CountDominant(img, 2);

		Test.Assert(red > 0, scope $"{fixture.Kind}: the texture reached the cube");
		// The padding never becomes a texel. With the row pitch ignored, half of them are
		// padding and the cube shows blue columns.
		Test.Assert(blue == 0, scope $"{fixture.Kind}: no padding was sampled, blue={blue}");

		var viewRef = view;
		fixture.Device.DestroyTextureView(ref viewRef);
		fixture.Device.DestroyTexture(ref tex);
	}
}
