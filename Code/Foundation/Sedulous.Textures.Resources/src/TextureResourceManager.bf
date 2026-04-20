using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Images;

namespace Sedulous.Textures.Resources;

/// Resource manager for TextureResource.
/// Handles .texture files (text metadata + binary sidecar) and standard image files.
class TextureResourceManager : ResourceManager<TextureResource>
{
	protected override Result<TextureResource, ResourceLoadError> LoadFromFile(StringView path)
	{
		// Handle .texture files (text metadata + binary sidecar)
		if (path.EndsWith(".texture"))
		{
			if (LoadTextFormat(path) case .Ok(let resource))
			{
				resource.AddRef();
				return .Ok(resource);
			}
			return .Err(.ReadError);
		}

		// Load standard image files via ImageLoaderFactory
		if (ImageLoaderFactory.LoadImage(path) case .Ok(let image))
		{
			let resource = new TextureResource(image, true);
			resource.Name.Set(path);
			resource.SetupFor3D();
			resource.AddRef();
			return .Ok(resource);
		}

		return .Err(.NotFound);
	}

	protected override Result<TextureResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		let data = new uint8[memory.Length];
		defer delete data;
		memory.TryRead(data);

		if (ImageLoaderFactory.LoadImageFromMemory(data) case .Ok(let image))
		{
			let resource = new TextureResource(image, true);
			resource.SetupFor3D();
			resource.AddRef();
			return .Ok(resource);
		}

		return .Err(.NotSupported);
	}

	public override void Unload(TextureResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(TextureResource resource, StringView path)
	{
		if (path.EndsWith(".texture"))
		{
			if (LoadTextFormat(path) case .Ok(let reloaded))
			{
				TransferData(resource, reloaded);
				delete reloaded;
				return .Ok;
			}
			return .Err(.ReadError);
		}

		if (ImageLoaderFactory.LoadImage(path) case .Ok(let image))
		{
			resource.SetImage(image, true);
			return .Ok;
		}

		return .Err(.NotFound);
	}

	/// Transfers data from a newly loaded resource into an existing one (for reload).
	private void TransferData(TextureResource target, TextureResource source)
	{
		target.SetImage(source.[Friend]mImage, true);
		source.[Friend]mOwnsImage = false;
		target.Name.Set(source.Name);
		target.MinFilter = source.MinFilter;
		target.MagFilter = source.MagFilter;
		target.WrapU = source.WrapU;
		target.WrapV = source.WrapV;
		target.WrapW = source.WrapW;
		target.GenerateMipmaps = source.GenerateMipmaps;
		target.Anisotropy = source.Anisotropy;
	}

	// ==================== New text + sidecar format ====================

	private Result<TextureResource> LoadTextFormat(StringView path)
	{
		if (SerializerProvider == null)
			return .Err;

		let text = scope String();
		if (File.ReadAllText(path, text) case .Err)
			return .Err;

		let reader = SerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err;
		defer delete reader;

		let resource = new TextureResource();
		if (resource.Serialize(reader) != .Ok)
		{
			delete resource;
			return .Err;
		}

		// Load pixel data from binary sidecar
		if (resource.BinaryPath.IsEmpty)
		{
			delete resource;
			return .Err;
		}

		let binStream = scope FileStream();
		if (binStream.Open(resource.BinaryPath, .Read) case .Err)
		{
			delete resource;
			return .Err;
		}

		let binData = new uint8[binStream.Length];
		if (binStream.TryRead(binData) case .Err)
		{
			delete binData;
			delete resource;
			return .Err;
		}

		// Create image from serialized dimensions/format + sidecar pixel data
		let image = new Image((uint32)resource.ImageWidth, (uint32)resource.ImageHeight, (PixelFormat)resource.ImageFormat, binData);
		delete binData;
		resource.SetImage(image, true);

		return .Ok(resource);
	}

}
