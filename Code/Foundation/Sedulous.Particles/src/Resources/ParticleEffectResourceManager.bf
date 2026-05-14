using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Particles.Resources;

/// Resource manager for ParticleEffectResource. Text-based serialization.
class ParticleEffectResourceManager : ResourceManager<ParticleEffectResource>
{
	protected override Result<ParticleEffectResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
	{
		if (SerializerProvider == null)
			return .Err(.NotSupported);

		let text = scope String();
		Try!(ReadAllText(ctx.Stream, text));

		let reader = SerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.InvalidFormat);
		defer delete reader;

		let resource = new ParticleEffectResource();
		if (resource.Serialize(reader) != .Ok)
		{
			delete resource;
			return .Err(.InvalidFormat);
		}

		resource.AddRef();
		return .Ok(resource);
	}

	public override void Unload(ParticleEffectResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}
}
