using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Texture.Pipeline;
using Sedulous.Texture.Resource;
using Sedulous.VFS;

namespace Sedulous.Texture.Pipeline.Tests;

/// A scratch tree, a content database over it, and a build context wired to both.
///
/// The sources mount is the SAME directory as the database, which keeps a case to one scratch
/// tree: what these measure is the cook, not the mount.
class TexturePipelineFixture
{
	public const String cAssetType = "Sedulous.Texture.Pipeline.TextureAsset";
	public const String cProductType = "Sedulous.Texture.Resource.TextureResource";

	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	public ContentDatabase Database ~ delete _;
	public AssetBuildContext Context = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	public this(StringView name)
	{
		mRoot.AppendF("scratch_texpipe_{}", name);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		Mount = new NativeFileSystem(mRoot);
		Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Factory, "rasset");

		Context.Sources = Mount;
		Context.Database = Database;
		Context.Serializers = Factory;

		TextureResources.RegisterAll();
		TexturePipeline.RegisterAll();
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	public StringView Root => mRoot;

	/// A path inside the scratch tree, which is also what the mount resolves against.
	public void PathIn(StringView fileName, String outPath) => PathJoin(mRoot, fileName, outPath);

	public Instance CreateSource(StringView name) => Database.RootGroup.CreateInstance(name, cAssetType);
	public Instance CreateOutput(StringView name) => Database.RootGroup.CreateInstance(name, cProductType);

	/// Cooks an EMBEDDED texture: the pixels go into the source instance's own stream, which is
	/// the shape a model import produces, and no file is involved.
	public Result<void, ErrorCode> CookEmbedded(TextureAsset asset, Span<uint8> pixels,
		Instance outInstance)
	{
		let source = CreateSource(scope $"src_{outInstance.Name}");
		if (source.WriteObject(asset) case .Err(let error))
			return .Err(error);
		if (source.WriteData(TextureAssetBuilder.cEmbeddedStreamName, pixels)
			case .Err(let streamError))
		{
			return .Err(streamError);
		}

		Context.Source = source;
		Context.Output = outInstance;
		return scope TextureAssetBuilder().Build(asset, Context);
	}

	/// The cooked record and its pixel payload, read back the way the runtime would.
	public Result<void, ErrorCode> ReadCooked(Instance instance, TextureResource outRecord,
		List<uint8> outPixels)
	{
		let object = instance.ReadObject();
		if (object == null)
			return .Err(.NotFound);
		defer delete object;

		let record = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
			as TextureResource;
		if (record == null)
			return .Err(.InvalidArgument);

		outRecord.Width = record.Width;
		outRecord.Height = record.Height;
		outRecord.DepthOrArrayLayers = record.DepthOrArrayLayers;
		outRecord.MipLevels = record.MipLevels;
		outRecord.Format = record.Format;
		outRecord.Shape = record.Shape;

		let stream = instance.ReadData(TextureAssetBuilder.cPixelStreamName);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;

		let size = (int)stream.Size();
		outPixels.Count = size;
		if ((size > 0) && (stream.Read(.(outPixels.Ptr, size)) != size))
			return .Err(.Unknown);
		return .Ok;
	}

	/// A deterministic RGBA8 image: ramps across the channels, or grey when a true single
	/// channel mask is what the case needs.
	public static void FillRamp(List<uint8> pixels, uint32 width, uint32 height, bool alpha,
		bool gray)
	{
		pixels.Count = (int)width * (int)height * 4;
		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				let p = &pixels[((int)y * (int)width + (int)x) * 4];
				p[0] = (uint8)((x * 255) / (width - 1));
				p[1] = gray ? p[0] : (uint8)((y * 255) / (height - 1));
				p[2] = gray ? p[0] : (uint8)(((x + y) * 255) / (width + height - 2));
				p[3] = alpha ? (uint8)((x * 255) / (width - 1)) : 255;
			}
		}
	}
}
