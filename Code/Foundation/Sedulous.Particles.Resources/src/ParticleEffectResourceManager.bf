using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Particles.Resources;

/// Resource manager for ParticleEffectResource.
/// Handles loading particle effect definitions from files via the serialization framework.
class ParticleEffectResourceManager : ResourceManager<ParticleEffectResource>
{
	protected override Result<ParticleEffectResource, ResourceLoadError> LoadFromFile(StringView path)
	{
		let text = scope String();
		if (File.ReadAllText(path, text) case .Err)
			return .Err(.NotFound);

		let reader = SerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.InvalidFormat);
		defer delete reader;

		let resource = new ParticleEffectResource();
		let result = resource.Serialize(reader);
		if (result != .Ok)
		{
			delete resource;
			return .Err(.InvalidFormat);
		}

		resource.AddRef();
		return .Ok(resource);
	}

	protected override Result<ParticleEffectResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		return .Err(.NotSupported);
	}

	public override void Unload(ParticleEffectResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}
}
