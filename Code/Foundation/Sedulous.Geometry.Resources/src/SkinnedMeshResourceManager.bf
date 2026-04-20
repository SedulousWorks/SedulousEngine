using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Geometry;
using Sedulous.Serialization;

namespace Sedulous.Geometry.Resources;

/// Resource manager for SkinnedMeshResource.
/// Note: Direct file loading is not implemented - use ModelLoader and converters instead.
class SkinnedMeshResourceManager : ResourceManager<SkinnedMeshResource>
{
	protected override Result<SkinnedMeshResource, ResourceLoadError> LoadFromFile(StringView path)
	{
		let text = scope String();
		if (File.ReadAllText(path, text) case .Err)
			return .Err(.NotFound);

		let reader = SerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.InvalidFormat);
		defer delete reader;

		int32 version = 0;
		reader.Int32("version", ref version);

		let resource = new SkinnedMeshResource();
		resource.Serialize(reader);
		resource.AddRef(); // Manager's ownership ref - released in Unload
		return .Ok(resource);
	}

	protected override Result<SkinnedMeshResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		return .Err(.NotSupported);
	}

	public override void Unload(SkinnedMeshResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(SkinnedMeshResource resource, StringView path)
	{
		let text = scope String();
		if (File.ReadAllText(path, text) case .Err)
			return .Err(.NotFound);

		let reader = SerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.InvalidFormat);
		defer delete reader;

		int32 version = 0;
		reader.Int32("version", ref version);

		resource.Serialize(reader);
		return .Ok;
	}

	/// Registers a pre-created skinned mesh resource.
	public ResourceHandle<SkinnedMeshResource> Register(SkinnedMeshResource resource)
	{
		resource.AddRef();
		return .(resource);
	}
}
