using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Animation.Resources;

class AnimationClipResourceManager : ResourceManager<AnimationClipResource>
{
	protected override Result<AnimationClipResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
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
		if (version > AnimationClipResource.FileVersion)
			return .Err(.InvalidFormat);

		let resource = new AnimationClipResource();
		resource.Serialize(reader);
		resource.AddRef();
		return .Ok(resource);
	}

	public override void Unload(AnimationClipResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(AnimationClipResource resource, ResourceLoadContext ctx)
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
		if (version > AnimationClipResource.FileVersion)
			return .Err(.InvalidFormat);

		// Dispatch through Reload so the existing AnimationClip is reused
		// in-place. Reading via Serialize directly would call SetClip and
		// delete outside references (skeletal players, editor preview state).
		return resource.Reload(reader);
	}
}
