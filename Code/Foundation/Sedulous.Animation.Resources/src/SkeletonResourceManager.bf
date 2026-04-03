using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Serialization;

namespace Sedulous.Animation.Resources;

/// Resource manager for SkeletonResource.
class SkeletonResourceManager : ResourceManager<SkeletonResource>
{
	protected override Result<SkeletonResource, ResourceLoadError> LoadFromFile(StringView path)
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
		if (version > SkeletonResource.FileVersion)
			return .Err(.InvalidFormat);

		let resource = new SkeletonResource();
		resource.Serialize(reader);
		resource.AddRef(); // Manager's ownership ref — released in Unload
		return .Ok(resource);
	}

	protected override Result<SkeletonResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		return .Err(.NotSupported);
	}

	public override void Unload(SkeletonResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(SkeletonResource resource, StringView path)
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
		if (version > SkeletonResource.FileVersion)
			return .Err(.InvalidFormat);

		resource.Serialize(reader);
		return .Ok;
	}

	/// Create a skeleton resource from an existing Skeleton.
	/// The resource takes ownership of the skeleton.
	public SkeletonResource CreateFromSkeleton(Skeleton skeleton, StringView name = "")
	{
		let resource = new SkeletonResource(skeleton, true);
		resource.Name.Set(name);
		return resource;
	}
}
