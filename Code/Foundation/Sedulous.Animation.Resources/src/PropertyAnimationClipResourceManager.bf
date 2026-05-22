using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Animation.Resources;

class PropertyAnimationClipResourceManager : ResourceManager<PropertyAnimationClipResource>
{
	protected override Result<PropertyAnimationClipResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
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
		if (version > PropertyAnimationClipResource.FileVersion)
			return .Err(.InvalidFormat);

		let resource = new PropertyAnimationClipResource();
		resource.Serialize(reader);
		resource.AddRef();
		return .Ok(resource);
	}

	public override void Unload(PropertyAnimationClipResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(PropertyAnimationClipResource resource, ResourceLoadContext ctx)
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
		if (version > PropertyAnimationClipResource.FileVersion)
			return .Err(.InvalidFormat);

		// Dispatch through Reload so the existing PropertyAnimationClip
		// is reused in-place. Reading via Serialize directly would call
		// SetClip and delete outside references.
		return resource.Reload(reader);
	}
}
