namespace Sedulous.Scenes.Resources;

using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Scenes;
using Sedulous.Serialization;

/// Resource manager for scene files.
/// Loads scene files into SceneResource instances.
/// Uses the ISerializerProvider from ResourceSystem for format-independent serialization.
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
		let bytes = scope List<uint8>();
		bytes.Count = (.)memory.Length;
		if (memory.TryRead(bytes) case .Err)
			return .Err(.ReadError);

		let resource = new SceneResource();
		resource.SetData(Span<uint8>(bytes.Ptr, bytes.Count));
		return .Ok(resource);
	}

	public override void Unload(SceneResource resource)
	{
		delete resource;
	}

	/// Creates a live Scene from a loaded SceneResource.
	/// The scene is populated with entities, transforms, hierarchy, and components.
	/// Component managers are created from the type registry.
	public Result<void> InstantiateScene(SceneResource resource, Scene scene)
	{
		let data = resource.Data;
		if (data.Length == 0)
			return .Err;

		let text = scope String();
		text.Append(Span<char8>((char8*)data.Ptr, data.Length));

		let reader = mSerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err;
		defer delete reader;

		let serializer = scope SceneSerializer(mTypeRegistry);
		serializer.Load(scene, reader);

		return .Ok;
	}

	/// Saves a scene to a file.
	public Result<void> SaveSceneToFile(Scene scene, StringView path)
	{
		let writer = mSerializerProvider.CreateWriter();
		defer delete writer;

		let serializer = scope SceneSerializer(mTypeRegistry);
		serializer.Save(scene, writer);

		let output = scope String();
		mSerializerProvider.GetOutput(writer, output);

		let stream = scope FileStream();
		if (stream.Create(path, .Write) case .Err)
			return .Err;

		stream.Write(Span<uint8>((uint8*)output.Ptr, output.Length));
		return .Ok;
	}
}
