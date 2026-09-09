using System;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Resource;

namespace Sedulous.Image.Resource;

/// Loads a cooked image: the header from the envelope, the pixels from the stream beside it.
///
/// PURELY CPU, so the whole build runs on a worker: nothing here touches a device. Whatever
/// consumes the image uploads it itself.
class ImageFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<ImageResource>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let image = stored as ImageResource;
		if (image == null)
		{
			// Something else was stored under this type name, so this is not an image rather
			// than an image that failed to read.
			delete stored;
			return null;
		}

		// A missing or unreadable stream leaves the image with its header and NO pixels: the
		// dimensions still describe something, and a consumer sees an empty view rather than
		// a resource that failed to bind.
		let stream = instance.ReadData("pixels");
		if (stream == null)
			return image;
		defer delete stream;

		let size = stream.Size();
		if (size <= 0)
			return image;

		let pixels = scope uint8[(int)size];
		if (stream.Read(pixels) == (int)size)
			image.SetPixels(pixels);

		return image;
	}
}
