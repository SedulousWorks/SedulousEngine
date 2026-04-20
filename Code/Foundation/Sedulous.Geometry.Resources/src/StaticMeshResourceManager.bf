using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Geometry;
using Sedulous.Serialization;

namespace Sedulous.Geometry.Resources;

/// Resource manager for MeshResource.
/// Note: Direct file loading is not implemented - use ModelLoader and converters instead.
class StaticMeshResourceManager : ResourceManager<StaticMeshResource>
{
	protected override Result<StaticMeshResource, ResourceLoadError> LoadFromFile(StringView path)
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
		if (version > StaticMeshResource.FileVersion)
			return .Err(.InvalidFormat);

		let resource = new StaticMeshResource();
		resource.Serialize(reader);
		resource.AddRef(); // Manager's ownership ref - released in Unload
		return .Ok(resource);
	}

	protected override Result<StaticMeshResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		return .Err(.NotSupported);
	}

	public override void Unload(StaticMeshResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(StaticMeshResource resource, StringView path)
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
		if (version > StaticMeshResource.FileVersion)
			return .Err(.InvalidFormat);

		resource.Serialize(reader);
		return .Ok;
	}

	/// Registers a pre-created mesh resource.
	public ResourceHandle<StaticMeshResource> Register(StaticMeshResource resource)
	{
		resource.AddRef();
		return .(resource);
	}
}
