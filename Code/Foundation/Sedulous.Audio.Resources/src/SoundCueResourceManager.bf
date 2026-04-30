using System;
using System.IO;
using Sedulous.Audio;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Audio.Resources;

/// Resource manager for loading and managing SoundCue resources.
class SoundCueResourceManager : ResourceManager<SoundCueResource>
{
	protected override Result<SoundCueResource, ResourceLoadError> LoadFromFile(StringView path)
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
		if (version > SoundCueResource.FileVersion)
			return .Err(.InvalidFormat);

		let resource = new SoundCueResource();
		resource.Serialize(reader);
		resource.AddRef();
		return .Ok(resource);
	}

	protected override Result<SoundCueResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		return .Err(.NotSupported);
	}

	public override void Unload(SoundCueResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(SoundCueResource resource, StringView path)
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
		if (version > SoundCueResource.FileVersion)
			return .Err(.InvalidFormat);

		resource.Serialize(reader);
		return .Ok;
	}
}
