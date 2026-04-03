using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Animation.Resources;

/// Resource manager for PropertyAnimationClipResource.
class PropertyAnimationClipResourceManager : ResourceManager<PropertyAnimationClipResource>
{
	protected override Result<PropertyAnimationClipResource, ResourceLoadError> LoadFromFile(StringView path)
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
		if (version > PropertyAnimationClipResource.FileVersion)
			return .Err(.InvalidFormat);

		let resource = new PropertyAnimationClipResource();
		resource.Serialize(reader);
		resource.AddRef(); // Manager's ownership ref — released in Unload
		return .Ok(resource);
	}

	protected override Result<PropertyAnimationClipResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		return .Err(.NotSupported);
	}

	public override void Unload(PropertyAnimationClipResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(PropertyAnimationClipResource resource, StringView path)
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
		if (version > PropertyAnimationClipResource.FileVersion)
			return .Err(.InvalidFormat);

		resource.Serialize(reader);
		return .Ok;
	}
}
