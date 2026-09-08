using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Texture;

namespace Sedulous.Texture.Resource;

/// Builds a cooked texture record into a live GPU texture.
///
/// DEVICE BACKED, which makes it the one factory here that cannot run headless without a
/// backend: the null backend is what the tests stand it up on.
class TextureFactory : IResourceFactory
{
	private IDevice mDevice;

	/// The device is BORROWED and must outlive both this and every product it built.
	public this(IDevice device)
	{
		mDevice = device;
	}

	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<Texture>();

	/// Reading the record and the pixel stream is a pure function of the instance's bytes,
	/// so it moves to a worker. Creating the texture and uploading does NOT: the RHI is the
	/// main thread's.
	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance)
	{
		let decoded = Decode(instance);
		if (decoded == null)
			return null;
		defer delete decoded;

		return BuildTexture(decoded.Record, decoded.Pixels);
	}

	public Object DecodeStage(Instance instance) => Decode(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded)
	{
		let intermediate = decoded as DecodedTexture;
		if (intermediate == null)
		{
			delete decoded;
			return null;
		}
		defer delete intermediate;

		return BuildTexture(intermediate.Record, intermediate.Pixels);
	}

	/// The worker half: the record and the heavy bytes, and nothing that touches a device.
	private DecodedTexture Decode(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let record = stored as TextureResource;
		if (record == null)
		{
			// Something else was stored under this type name. Not a texture, so not a
			// decode failure to paper over.
			delete stored;
			return null;
		}

		let decoded = new DecodedTexture();
		decoded.Record = record;
		ReadCookedPixels(instance, decoded.Pixels);
		return decoded;
	}

	/// The cooked "data" stream. An absent one is not fatal: the record still describes a
	/// texture, and an empty payload simply uploads nothing.
	private static void ReadCookedPixels(Instance instance, List<uint8> outPixels)
	{
		let stream = instance.ReadData("data");
		if (stream == null)
			return;
		defer delete stream;

		let size = stream.Size();
		if (size <= 0)
			return;

		outPixels.Resize((int)size);
		// A short read means the stream lied about its size. Nothing partial is uploaded,
		// because a half filled buffer is worse than an empty one: it looks like data.
		if (stream.Read(.(outPixels.Ptr, (int)size)) != (int)size)
			outPixels.Clear();
	}

	/// MAIN THREAD ONLY: creates the texture, its view and its sampler, and uploads.
	private Object BuildTexture(TextureResource record, List<uint8> pixels)
	{
		let isCube = record.Shape == .Cubemap;
		let layers = isCube ? (uint32)6 : record.DepthOrArrayLayers;

		var desc = TextureDesc();
		desc.Dimension = .Texture2D;
		desc.Format = record.Format;
		desc.Width = record.Width;
		desc.Height = record.Height;
		desc.Depth = 1;
		desc.ArrayLayerCount = layers;
		desc.MipLevelCount = record.MipLevels;
		desc.Usage = .Sampled | .CopyDst;

		if (!(mDevice.CreateTexture(desc) case .Ok(let texture)))
			return null;

		// The default sampled view spans every mip and layer: that is the currency a
		// material binds. A cube shaped asset gets a real cube view, so a skybox can be
		// sampled as one rather than as six unrelated layers.
		var viewDesc = TextureViewDesc();
		viewDesc.Format = record.Format;
		viewDesc.Dimension = isCube ? .TextureCube : .Texture2D;
		viewDesc.MipLevelCount = record.MipLevels;
		viewDesc.ArrayLayerCount = layers;

		if (!(mDevice.CreateTextureView(texture, viewDesc) case .Ok(let view)))
		{
			var doomed = texture;
			mDevice.DestroyTexture(ref doomed);
			return null;
		}

		Upload(texture, record, pixels);

		// A sampler is not worth failing the whole texture over: a bound texture with no
		// sampler is diagnosable, a missing texture is not.
		ISampler sampler = null;
		if (mDevice.CreateSampler(TextureSamplers.Describe(record)) case .Ok(let created))
			sampler = created;

		let product = new Texture();
		product.Adopt(mDevice, texture, view, sampler, record.Width, record.Height, record.Format,
			isCube);
		return product;
	}

	private void Upload(ITexture texture, TextureResource record, List<uint8> pixels)
	{
		if (pixels.IsEmpty)
			return;

		let writes = scope List<TextureUploadWrite>();
		TextureUpload.EnumerateWrites(record, pixels.Count, writes);
		if (writes.IsEmpty)
			return;

		let queue = mDevice.GetQueue(.Graphics, 0);
		if (queue == null)
			return;
		if (!(queue.CreateTransferBatch() case .Ok(var batch)))
			return;
		defer queue.DestroyTransferBatch(ref batch);

		for (let write in writes)
		{
			batch.WriteTexture(texture, .(pixels.Ptr + write.Offset, write.ByteCount),
				write.Layout, write.Extent, write.MipLevel, write.ArrayLayer);
		}
		batch.Submit().IgnoreError();
	}
}
