using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Geometry;
using Sedulous.Serialization;

namespace Sedulous.Geometry.Resources;

/// Resource manager for StaticMeshResource.
/// Note: Direct file loading is not implemented - use ModelLoader and converters instead.
class StaticMeshResourceManager : ResourceManager<StaticMeshResource>
{
	protected override Result<StaticMeshResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
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
		if (version > StaticMeshResource.FileVersion)
			return .Err(.InvalidFormat);

		let resource = new StaticMeshResource();
		resource.Serialize(reader);
		resource.AddRef(); // Manager's ownership ref - released in Unload
		return .Ok(resource);
	}

	public override void Unload(StaticMeshResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(StaticMeshResource resource, ResourceLoadContext ctx)
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
		if (version > StaticMeshResource.FileVersion)
			return .Err(.InvalidFormat);

		// Dispatch through Reload so the existing StaticMesh instance is
		// reused (ClearForReload empties it in place). Reading via Serialize
		// directly would call SetMesh and delete outside references.
		return resource.Reload(reader);
	}

	/// Registers a pre-created mesh resource.
	public ResourceHandle<StaticMeshResource> Register(StaticMeshResource resource)
	{
		resource.AddRef();
		return .(resource);
	}
}
