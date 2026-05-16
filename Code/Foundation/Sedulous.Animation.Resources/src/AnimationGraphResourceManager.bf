using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Animation.Resources;

class AnimationGraphResourceManager : ResourceManager<AnimationGraphResource>
{
	protected override Result<AnimationGraphResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
	{
		if (SerializerProvider == null)
			return .Err(.NotSupported);

		let text = scope String();
		Try!(ReadAllText(ctx.Stream, text));

		let reader = SerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.InvalidFormat);
		defer delete reader;

		int32 version = 0;
		reader.Int32("version", ref version);
		if (version > AnimationGraphResource.FileVersion)
			return .Err(.InvalidFormat);

		let resource = new AnimationGraphResource();
		resource.Serialize(reader);
		resource.AddRef();
		return .Ok(resource);
	}

	public override void Unload(AnimationGraphResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(AnimationGraphResource resource, ResourceLoadContext ctx)
	{
		if (SerializerProvider == null)
			return .Err(.NotSupported);

		let text = scope String();
		Try!(ReadAllText(ctx.Stream, text));

		let reader = SerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.InvalidFormat);
		defer delete reader;

		int32 version = 0;
		reader.Int32("version", ref version);
		if (version > AnimationGraphResource.FileVersion)
			return .Err(.InvalidFormat);

		return resource.Reload(reader);
	}
}
