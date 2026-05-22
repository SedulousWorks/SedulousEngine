using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Geometry;
using Sedulous.Serialization;

namespace Sedulous.Geometry.Resources;

/// Resource manager for SkinnedMeshResource.
/// Note: Direct file loading is not implemented - use ModelLoader and converters instead.
class SkinnedMeshResourceManager : ResourceManager<SkinnedMeshResource>
{
	protected override Result<SkinnedMeshResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
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

		let resource = new SkinnedMeshResource();
		resource.Serialize(reader);
		resource.AddRef(); // Manager's ownership ref - released in Unload
		return .Ok(resource);
	}

	public override void Unload(SkinnedMeshResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(SkinnedMeshResource resource, ResourceLoadContext ctx)
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

		// Dispatch through Reload so the existing SkinnedMesh instance is
		// reused (ClearForReload empties it in place). Reading via Serialize
		// directly would delete outside references.
		return resource.Reload(reader);
	}

	/// Registers a pre-created skinned mesh resource.
	public ResourceHandle<SkinnedMeshResource> Register(SkinnedMeshResource resource)
	{
		resource.AddRef();
		return .(resource);
	}
}
