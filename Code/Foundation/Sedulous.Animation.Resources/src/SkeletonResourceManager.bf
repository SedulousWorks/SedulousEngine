using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Serialization;

namespace Sedulous.Animation.Resources;

class SkeletonResourceManager : ResourceManager<SkeletonResource>
{
	protected override Result<SkeletonResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
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
		if (version > SkeletonResource.FileVersion)
			return .Err(.InvalidFormat);

		let resource = new SkeletonResource();
		resource.Serialize(reader);
		resource.AddRef();
		return .Ok(resource);
	}

	public override void Unload(SkeletonResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(SkeletonResource resource, ResourceLoadContext ctx)
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
		if (version > SkeletonResource.FileVersion)
			return .Err(.InvalidFormat);

		// Dispatch through Reload so the existing Skeleton instance is
		// reused (ClearForReload resizes in place). Reading via Serialize
		// directly would call SetSkeleton and delete outside references.
		return resource.Reload(reader);
	}

	/// Create a skeleton resource from an existing Skeleton. The resource takes ownership.
	public SkeletonResource CreateFromSkeleton(Skeleton skeleton, StringView name = "")
	{
		let resource = new SkeletonResource(skeleton, true);
		resource.Name.Set(name);
		return resource;
	}
}
