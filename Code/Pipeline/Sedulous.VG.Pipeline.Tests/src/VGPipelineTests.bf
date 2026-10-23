using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.VFS;
using Sedulous.VG.Pipeline;
using Sedulous.VG.Resource;

namespace Sedulous.VG.Pipeline.Tests;

/// Vector images, source side: a linked `.svg` cooks when the engine reads it and fails when
/// not, the product binds through VG.Resource's factory, the importer takes `.svg`, and another
/// cook reads the image from its product or from its source.
class VGPipelineTests
{
	private const String cProductType = "Sedulous.VG.Resource.VectorImageResource";
	private const String cAssetType = "Sedulous.VG.Pipeline.VectorImageAsset";
	private const String cHeartSvg = """
		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 21 L3 12 A5 5 0 0 1 12 5 A5 5 0 0 1 21 12 Z" fill="#E53935"/></svg>
		""";

	/// A sources tree holding the heart and a file that is no SVG, and an output database.
	private class Bed
	{
		private const String cSources = "scratch_vgpipe_src";
		private const String cDatabase = "scratch_vgpipe_db";

		public NativeFileSystem Sources ~ delete _;
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Serializers ~ delete _;
		public ContentDatabase Database ~ delete _;
		public AssetBuildContext Context = new .() ~ delete _;

		public this()
		{
			VGResources.RegisterAll();
			VGPipeline.RegisterAll();
			RemoveDirectoryRecursive(cSources);
			RemoveDirectoryRecursive(cDatabase);
			CreateDirectory(cSources);
			CreateDirectory(cDatabase);
			Write("heart.svg", cHeartSvg);
			Write("broken.svg", "<html>not a vector image</html>");

			Sources = new NativeFileSystem(cSources);
			Mount = new NativeFileSystem(cDatabase);
			Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(Mount, Serializers, "rasset");
			Context.Sources = Sources;
		}

		public ~this()
		{
			RemoveDirectoryRecursive(cSources);
			RemoveDirectoryRecursive(cDatabase);
		}

		private static void Write(StringView fileName, StringView text)
		{
			let path = PathJoin(cSources, fileName, .. scope .());
			WriteFile(path, .((uint8*)text.Ptr, text.Length)).IgnoreError();
		}

		public Result<void, ErrorCode> Cook(StringView fileName, Instance output)
		{
			let asset = scope VectorImageAsset();
			if (!fileName.IsEmpty)
				asset.FileName.Set(fileName);
			Context.Output = output;
			return scope VectorImageAssetBuilder().Build(asset, Context);
		}
	}

	[Test]
	public static void AVectorImageCooksWhenItIsAnSvgTheEngineReadsAndFailsWhenNot()
	{
		let bed = scope Bed();
		let heart = bed.Database.RootGroup.CreateInstance("heart", cProductType);
		Test.Assert(bed.Cook("heart.svg", heart) case .Ok);
		Test.Assert(bed.Cook("broken.svg", bed.Database.RootGroup.CreateInstance("broken", cProductType)) case .Err);
		Test.Assert(bed.Cook("", bed.Database.RootGroup.CreateInstance("unlinked", cProductType)) case .Err);

		let factory = scope VectorImageFactory();
		let manager = scope ResourceManager(bed.Database);
		manager.AddFactory(factory);
		let image = manager.Bind<VectorImage>(heart.Id);
		Test.Assert(image.Get != null);
		Test.Assert(image.Get.Svg == cHeartSvg);
	}

	[Test]
	public static void TheImporterTakesAnSvgAndOnlyThat()
	{
		let importer = scope VectorImageFileImporter();
		Test.Assert(importer.Accepts("svg"));
		Test.Assert(!importer.Accepts("sss"));
		Test.Assert(!importer.Accepts("png"));
	}

	[Test]
	public static void AnotherCookReadsAVectorImageFromItsProductOrFromItsSourceBeforeItIsCooked()
	{
		let bed = scope Bed();
		// Cooked: the product's text.
		let cooked = bed.Database.RootGroup.CreateInstance("heart", cProductType);
		Test.Assert(bed.Cook("heart.svg", cooked) case .Ok);
		bed.Context.Output = null;
		bed.Context.Database = bed.Database;
		let svg = scope String();
		Test.Assert(VGPipeline.ReadVectorImage(bed.Context, cooked.Id, svg) case .Ok);
		Test.Assert(svg == cHeartSvg);

		// Not cooked yet: the asset, read through its linked file.
		let source = bed.Database.RootGroup.CreateInstance("heart-source", cAssetType);
		let asset = scope VectorImageAsset();
		asset.FileName.Set("heart.svg");
		Test.Assert(source.WriteObject(asset) case .Ok);
		svg.Clear();
		Test.Assert(VGPipeline.ReadVectorImage(bed.Context, source.Id, svg) case .Ok);
		Test.Assert(svg == cHeartSvg);

		let unknown = Guid.Parse("0b7e2f6a-1c3d-4e5f-8a9b-0c1d2e3f4a5b").Value;
		Test.Assert(VGPipeline.ReadVectorImage(bed.Context, unknown, svg) case .Err(.NotFound));
	}
}
