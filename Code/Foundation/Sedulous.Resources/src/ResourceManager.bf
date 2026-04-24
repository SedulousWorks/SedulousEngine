using System;
using System.IO;
using System.Collections;
using Sedulous.Serialization;

namespace Sedulous.Resources;

/// Abstract base class for resource managers.
abstract class ResourceManager<T> : IResourceManager where T : IResource
{
	/// Serializer provider for format-independent read/write.
	/// Set by the subsystem that creates this manager, or pulled from ResourceSystem.
	public ISerializerProvider SerializerProvider { get; set; }

	/// Gets the type of resource this manager handles.
	public Type ResourceType => typeof(T);

	/// Loads a resource from a file path.
	public Result<ResourceHandle<IResource>, ResourceLoadError> Load(StringView path)
	{
		let handle = LoadFromFile(path);
		if (handle case .Err(let error))
			return .Err(error);
		return ResourceHandle<IResource>(handle.Value);
	}

	/// Loads a resource from memory.
	public Result<ResourceHandle<IResource>, ResourceLoadError> Load(MemoryStream stream)
	{
		let handle = LoadFromMemory(stream);
		if (handle case .Err(let error))
			return .Err(error);
		return ResourceHandle<IResource>(handle.Value);
	}

	/// Reads a file into a buffer.
	protected virtual Result<void, ResourceLoadError> ReadFile(StringView path, List<uint8> buffer)
	{
		let stream = scope FileStream();
		if (stream.Open(path, .Read, .Read) case .Err)
			return .Err(.NotFound);

		buffer.Count = (.)stream.Length;
		if (stream.TryRead(buffer) case .Err)
			return .Err(.ReadError);

		return .Ok;
	}

	/// Loads a resource from a file. Default implementation reads file and calls LoadFromMemory.
	protected virtual Result<T, ResourceLoadError> LoadFromFile(StringView path)
	{
		let memory = scope List<uint8>();
		if (ReadFile(path, memory) case .Err(let error))
			return .Err(error);

		return LoadFromMemory(scope MemoryStream(memory, false));
	}

	/// Override to implement loading from a memory stream.
	protected abstract Result<T, ResourceLoadError> LoadFromMemory(MemoryStream memory);

	/// Override to implement resource unloading.
	public abstract void Unload(T resource);

	/// Unloads a resource via the interface.
	public void Unload(ref ResourceHandle<IResource> resource)
	{
		if (resource.Resource != null)
			Unload((T)resource.Resource);
	}

	/// Reloads an existing resource from file, updating its data in-place.
	public Result<void, ResourceLoadError> ReloadFromFile(IResource resource, StringView path)
	{
		return ReloadResource((T)resource, path);
	}

	/// Override to implement in-place reload from file.
	protected virtual Result<void, ResourceLoadError> ReloadResource(T resource, StringView path)
	{
		return .Err(.NotSupported);
	}
}
