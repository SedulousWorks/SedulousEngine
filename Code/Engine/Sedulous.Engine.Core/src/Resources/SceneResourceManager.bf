namespace Sedulous.Engine.Core.Resources;

using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Engine.Core;
using Sedulous.Serialization;
using Sedulous.VFS;

/// Resource manager for scene files.
///
/// `Load` parses the resource header (`_type`, `_id`, `_name`, `_sourcePath`)
/// into a `SceneResource`. Live scene instantiation is a separate step -
/// `InstantiateScene` takes the resource plus a fresh mount+locator from which
/// to re-read scene contents into a `Scene` whose component managers are
/// already wired up.
class SceneResourceManager : ResourceManager<SceneResource>
{
	private ComponentTypeRegistry mTypeRegistry;
	private ISerializerProvider mSerializerProvider;

	/// Resource system for prefab instance loading during scene deserialization.
	/// Set by the application after construction (same lifetime as the manager).
	public ResourceSystem ResourceSystem { get; set; }

	/// @param typeRegistry Registry mapping type IDs to component manager factories.
	/// @param serializerProvider Format provider for reading/writing scene data.
	public this(ComponentTypeRegistry typeRegistry, ISerializerProvider serializerProvider)
	{
		mTypeRegistry = typeRegistry;
		mSerializerProvider = serializerProvider;
	}

	protected override Result<SceneResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
	{
		let text = scope String();
		Try!(ReadAllText(ctx.Stream, text));

		let reader = mSerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.ReadError);
		defer delete reader;

		let resource = new SceneResource();
		// No scene or serializer set — header-only load (scene, name, id).
		resource.Serialize(reader);
		resource.AddRef();
		return .Ok(resource);
	}

	public override void Unload(SceneResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	/// Re-reads the scene file from `mount`/`locator` into the live `scene`. The
	/// scene must already have component managers injected (via ISceneAware
	/// subsystems) before calling this.
	public Result<void> InstantiateScene(SceneResource resource, Scene scene, IMount mount, StringView locator)
	{
		if (resource == null || mount == null)
			return .Err;

		let openResult = mount.Open(locator);
		if (openResult case .Err)
			return .Err;
		let stream = openResult.Value;
		defer delete stream;

		let text = scope String();
		if (ReadAllText(stream, text) case .Err)
			return .Err;

		let reader = mSerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err;
		defer delete reader;

		let sceneSerializer = scope SceneSerializer(mTypeRegistry, mSerializerProvider, ResourceSystem);

		resource.Scene = scene;
		resource.SceneSerializer = sceneSerializer;
		resource.Serialize(reader);
		resource.Scene = null;
		resource.SceneSerializer = null;

		return .Ok;
	}

	/// Saves a scene through a writable mount. If the target locator already
	/// exists, preserves its resource GUID. Returns the GUID that was written.
	public Result<Guid> SaveScene(Scene scene, IWritableMount mount, StringView locator)
	{
		let sceneSerializer = scope SceneSerializer(mTypeRegistry, mSerializerProvider, ResourceSystem);

		let resource = scope SceneResource();
		resource.Scene = scene;
		resource.SceneSerializer = sceneSerializer;

		// If an entry already exists at this locator, preserve its GUID.
		if (mount.Exists(locator))
		{
			let existingOpen = mount.Open(locator);
			if (existingOpen case .Ok(let existingStream))
			{
				defer delete existingStream;
				let existingText = scope String();
				if (ReadAllText(existingStream, existingText) case .Ok)
				{
					let reader = mSerializerProvider.CreateReader(existingText);
					if (reader != null)
					{
						let existingRes = scope SceneResource();
						existingRes.Serialize(reader);
						if (existingRes.Id != .Empty)
							resource.Id = existingRes.Id;
						delete reader;
					}
				}
			}
		}

		// Derive a friendly name from the locator filename.
		let name = scope String();
		Path.GetFileNameWithoutExtension(locator, name);
		resource.Name = name;
		let locatorStr = scope String(locator);
		resource.SourcePath = locatorStr;

		// Serialize to a memory buffer, then route to the mount.
		let memStream = scope MemoryStream();
		if (resource.WriteToStream(memStream, mSerializerProvider) case .Err)
			return .Err;
		memStream.Position = 0;

		if (mount.Save(locator, memStream) case .Err)
			return .Err;

		return .Ok(resource.Id);
	}
}
