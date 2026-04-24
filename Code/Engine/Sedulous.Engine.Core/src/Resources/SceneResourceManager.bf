namespace Sedulous.Engine.Core.Resources;

using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Engine.Core;
using Sedulous.Serialization;

/// Resource manager for scene files.
/// Saves and loads scenes through the standard Resource serialization path,
/// which writes the resource header (_type, _id, _name, _sourcePath) followed
/// by scene data (entities, transforms, components) via SceneSerializer.
class SceneResourceManager : ResourceManager<SceneResource>
{
	private ComponentTypeRegistry mTypeRegistry;
	private ISerializerProvider mSerializerProvider;

	/// @param typeRegistry Registry mapping type IDs to component manager factories.
	/// @param serializerProvider Format provider for reading/writing scene data.
	public this(ComponentTypeRegistry typeRegistry, ISerializerProvider serializerProvider)
	{
		mTypeRegistry = typeRegistry;
		mSerializerProvider = serializerProvider;
	}

	protected override Result<SceneResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		// Read raw bytes and parse as text
		let bytes = scope List<uint8>();
		bytes.Count = (.)memory.Length;
		if (memory.TryRead(bytes) case .Err)
			return .Err(.ReadError);

		let text = scope String();
		text.Append(Span<char8>((char8*)bytes.Ptr, bytes.Count));

		let reader = mSerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.ReadError);
		defer delete reader;

		// Create resource and deserialize header via Resource.Serialize()
		let resource = new SceneResource();
		resource.TypeRegistry = mTypeRegistry;
		// Scene is not set yet -- will be set when InstantiateScene is called
		resource.Serialize(reader);

		return .Ok(resource);
	}

	public override void Unload(SceneResource resource)
	{
		delete resource;
	}

	/// Creates a live Scene from a loaded SceneResource.
	/// The scene must already have component managers injected (via ISceneAware subsystems).
	public Result<void> InstantiateScene(SceneResource resource, Scene scene)
	{
		if (resource == null)
			return .Err;

		// Re-read the file to deserialize scene data into the live scene.
		// The resource header was already parsed in LoadFromMemory;
		// we need to re-parse to get the scene data section.
		let path = scope String();
		if (resource.SourcePath.Length > 0)
			path.Set(resource.SourcePath);
		else if (resource.Name.Length > 0)
			path.Set(resource.Name);

		if (path.Length == 0)
			return .Err;

		let text = scope String();
		if (File.ReadAllText(path, text) case .Err)
			return .Err;

		let reader = mSerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err;
		defer delete reader;

		// Set scene on resource so OnSerialize can load into it
		resource.Scene = scene;
		resource.TypeRegistry = mTypeRegistry;
		resource.Serialize(reader);
		resource.Scene = null; // Clear reference after loading

		return .Ok;
	}

	/// Saves a scene to a file through the standard Resource serialization path.
	/// Writes resource header followed by scene data.
	public Result<void> SaveSceneToFile(Scene scene, StringView path)
	{
		let resource = scope SceneResource();
		resource.Scene = scene;
		resource.TypeRegistry = mTypeRegistry;

		// Use filename without extension as the resource name
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(path, name);
		resource.Name = name;
		resource.SourcePath = scope .(path);

		// Use Resource.SaveToFile which calls Serialize() in write mode
		return resource.SaveToFile(path, mSerializerProvider);
	}
}
