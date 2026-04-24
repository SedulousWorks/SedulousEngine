using System;
using System.IO;
using Sedulous.Serialization;

namespace Sedulous.Resources;

/// Interface for resource managers that handle specific resource types.
interface IResourceManager
{
	/// Gets the type of resource this manager handles.
	Type ResourceType { get; }

	ISerializerProvider SerializerProvider { get; set; }

	/// Loads a resource from a file path.
	Result<ResourceHandle<IResource>, ResourceLoadError> Load(StringView path);

	/// Loads a resource from memory.
	Result<ResourceHandle<IResource>, ResourceLoadError> Load(MemoryStream stream);

	/// Unloads a resource.
	void Unload(ref ResourceHandle<IResource> resource);

	/// Reloads an existing resource from file, updating its data in-place.
	Result<void, ResourceLoadError> ReloadFromFile(IResource resource, StringView path);
}
