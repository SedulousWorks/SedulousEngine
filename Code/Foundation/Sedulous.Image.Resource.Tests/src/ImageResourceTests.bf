using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Image;
using Sedulous.Image.Resource;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Image.Resource.Tests;

/// A cooked CPU image: its header out of the envelope, its pixels out of the stream.
class ImageResourceTests
{
	private const String cImageTypeName = "Sedulous.Image.Resource.ImageResource";

	private class Fixture
	{
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Serializers ~ delete _;
		public SerializableRegistry Serializables = new .() ~ delete _;
		public ContentDatabase Database ~ delete _;
		public ResourceManager Manager ~ delete _;
		public ImageFactory Images = new .() ~ delete _;

		private String mRoot = new .() ~ delete _;

		public this(StringView root)
		{
			mRoot.Set(root);
			RemoveDirectoryRecursive(mRoot);
			CreateDirectory(mRoot);

			ImageResources.RegisterAll(Serializables);

			Mount = new NativeFileSystem(mRoot);
			Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(Mount, Serializers, "asset", Serializables);
			Manager = new ResourceManager(Database, null);

			ImageResources.AddFactories(Manager, Images);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(mRoot);
		}

		/// Cooks a header, and the pixels beside it unless told to leave them out.
		public Guid Cook(StringView name, uint32 width, uint32 height, bool withPixels = true)
		{
			let instance = Database.RootGroup.CreateInstance(name, cImageTypeName);

			let record = scope ImageResource();
			record.Width = width;
			record.Height = height;
			record.Format = .RGBA8;
			record.ColorSpace = .Linear;
			instance.WriteObject(record).IgnoreError();

			if (withPixels)
			{
				let pixels = scope uint8[width * height * 4];
				for (int i < pixels.Count)
					pixels[i] = (uint8)(i & 0xFF);
				instance.WriteData("pixels", pixels).IgnoreError();
			}
			return instance.Id;
		}
	}

	[Test]
	public static void AnImageLoadsItsHeaderAndItsPixels()
	{
		let fixture = scope Fixture("scratch_image_resource");
		let id = fixture.Cook("icon", 4, 3);

		let image = fixture.Manager.Bind<ImageResource>(id);
		Test.Assert(image.Get != null);
		Test.Assert(image.State == .Ready);

		Test.Assert(image.Get.Width == 4);
		Test.Assert(image.Get.Height == 3);
		Test.Assert(image.Get.Format == .RGBA8);
		Test.Assert(image.Get.ColorSpace == .Linear, "the colour space is not assumed");

		Test.Assert(image.Get.Pixels.Length == (4 * 3 * 4));
		Test.Assert(image.Get.Pixels[0] == 0);
		Test.Assert(image.Get.Pixels[5] == 5);
	}

	/// The view BORROWS the resource's pixels, which is what lets a consumer read them
	/// without a copy.
	[Test]
	public static void TheViewPointsAtTheResourcesOwnPixels()
	{
		let fixture = scope Fixture("scratch_image_view");
		let image = fixture.Manager.Bind<ImageResource>(fixture.Cook("icon", 2, 2));
		Test.Assert(image.Get != null);

		let view = image.Get.View();
		defer delete view;

		Test.Assert(view.Width == 2);
		Test.Assert(view.Height == 2);
		Test.Assert(view.ColorSpace == .Linear);
		Test.Assert(view.PixelData.Length == (2 * 2 * 4));
		Test.Assert(view.PixelData.Ptr == image.Get.Pixels.Ptr, "the same bytes, not a copy");
	}

	/// No pixel stream leaves the image with its HEADER and nothing else, rather than failing
	/// to bind: the dimensions still describe something, and a consumer sees an empty view.
	[Test]
	public static void AMissingPixelStreamStillBuildsTheHeader()
	{
		let fixture = scope Fixture("scratch_image_headless");
		let image = fixture.Manager.Bind<ImageResource>(fixture.Cook("icon", 8, 8, false));

		Test.Assert(image.Get != null);
		Test.Assert(image.Get.Width == 8);
		Test.Assert(image.Get.Pixels.IsEmpty);

		let view = image.Get.View();
		defer delete view;
		Test.Assert(view.PixelData.IsEmpty);
	}
}
