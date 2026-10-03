using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Texture;
using Sedulous.Texture.Pipeline;
using Sedulous.Texture.Resource;

namespace Sedulous.Texture.Pipeline.Tests;

/// A render texture asset: authored, not imported. It cooks to the record its factory makes a
/// render target of, refuses a size past the limit at the cook, and round-trips as authored.
class RenderTextureAssetTests
{
	private const String cProductType = "Sedulous.Texture.Resource.RenderTextureResource";

	[Test]
	public static void ARenderTextureAssetCooksToARecordItsFactoryMakesATargetOf()
	{
		let fixture = scope TexturePipelineFixture("render_texture");
		let builder = scope RenderTextureAssetBuilder();
		Test.Assert(builder.AssetType == typeof(RenderTextureAsset));
		Test.Assert(builder.ProductType == typeof(RenderTextureResource));

		let minimap = fixture.Database.RootGroup.CreateInstance("minimap", cProductType);
		let asset = scope RenderTextureAsset();
		asset.Width = 512;
		asset.Height = 128;
		asset.Format = .Hdr;
		fixture.Context.Output = minimap;
		Test.Assert(builder.Build(asset, fixture.Context) case .Ok);

		// A side past the limit is refused at the cook, not at the first frame.
		let huge = fixture.Database.RootGroup.CreateInstance("huge", cProductType);
		let tooBig = scope RenderTextureAsset();
		tooBig.Width = RenderTextureResource.cMaxSize * 2;
		fixture.Context.Output = huge;
		Test.Assert(builder.Build(tooBig, fixture.Context) case .Err);
		fixture.Context.Output = null;

		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		let factory = scope TextureFactory(device);
		let manager = scope ResourceManager(fixture.Database);
		manager.AddFactory(factory);
		let texture = manager.Bind<Texture>(minimap.Id);
		Test.Assert(texture.Get != null);
		Test.Assert((texture.Get.Width == 512) && (texture.Get.Height == 128));
		Test.Assert(texture.Get.Format == .RGBA16Float);

		// The asset itself round-trips (what the editor saves and the asset form edits).
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			(asset as ISerializable).Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);
		let read = scope RenderTextureAsset();
		{
			let reader = scope BinarySerializer(stream, .Read);
			(read as ISerializable).Serialize(reader);
			Test.Assert(reader.IsOk);
		}
		Test.Assert((read.Width == 512) && (read.Height == 128) && (read.Format == .Hdr));
	}
}
