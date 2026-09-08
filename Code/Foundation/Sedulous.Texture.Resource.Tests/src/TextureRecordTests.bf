using System;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.RHI;
using Sedulous.Texture;
using Sedulous.Texture.Resource;

namespace Sedulous.Texture.Resource.Tests;

/// The cooked record, and the registration without which it cannot be read back.
class TextureRecordTests
{
	[Test]
	public static void TheRecordRoundTrips()
	{
		let authored = scope TextureResource();
		authored.Width = 256;
		authored.Height = 128;
		authored.DepthOrArrayLayers = 4;
		authored.MipLevels = 9;
		authored.Format = .BC7RGBAUnormSrgb;
		authored.Shape = .Texture2DArray;
		authored.MinFilter = .MipmapLinear;
		authored.MagFilter = .Nearest;
		authored.WrapU = .MirroredRepeat;
		authored.WrapV = .ClampToBorder;
		authored.WrapW = .ClampToEdge;
		authored.GenerateMipmaps = false;
		authored.Anisotropy = 16.0f;

		ISerializable writable = authored;
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			writable.Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		buffer.Seek(0, .Begin);

		let loaded = scope TextureResource();
		ISerializable readable = loaded;
		let reader = scope BinarySerializer(buffer, .Read);
		readable.Serialize(reader);
		Test.Assert(reader.IsOk);

		Test.Assert(loaded.Width == 256);
		Test.Assert(loaded.Height == 128);
		Test.Assert(loaded.DepthOrArrayLayers == 4);
		Test.Assert(loaded.MipLevels == 9);
		Test.Assert(loaded.Format == .BC7RGBAUnormSrgb);
		Test.Assert(loaded.Shape == .Texture2DArray);
		Test.Assert(loaded.MinFilter == .MipmapLinear);
		Test.Assert(loaded.MagFilter == .Nearest);
		Test.Assert(loaded.WrapU == .MirroredRepeat);
		Test.Assert(loaded.WrapV == .ClampToBorder);
		Test.Assert(loaded.WrapW == .ClampToEdge);
		Test.Assert(!loaded.GenerateMipmaps);
		Test.Assert(loaded.Anisotropy == 16.0f);
	}

	/// A fresh record describes a plain 2D texture with no mips, which is what an importer
	/// that sets only the dimensions gets.
	[Test]
	public static void TheDefaultsAreAPlain2DTexture()
	{
		let record = scope TextureResource();
		Test.Assert(record.DepthOrArrayLayers == 1);
		Test.Assert(record.MipLevels == 1);
		Test.Assert(record.Format == .RGBA8Unorm);
		Test.Assert(record.Shape == .Texture2D);
		Test.Assert(record.WrapU == .Repeat);
		Test.Assert(record.Anisotropy == 1.0f);
	}

	[Test]
	public static void TheRecordTypeRegisters()
	{
		let registry = scope SerializableRegistry();
		TextureResources.RegisterAll(registry);

		Test.Assert(registry.IsRegistered(TextureResource.TypeId));
		Test.Assert(registry.IsRegistered(TypeIdOf("Sedulous.Texture.Resource.TextureResource")),
			"registered under the name an instance stores");

		let created = registry.Create(TextureResource.TypeId);
		defer delete created;
		Test.Assert(created is TextureResource);
	}
}
