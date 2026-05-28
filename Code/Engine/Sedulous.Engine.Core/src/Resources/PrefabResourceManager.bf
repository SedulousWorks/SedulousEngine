namespace Sedulous.Engine.Core.Resources;

using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Engine.Core;
using Sedulous.Serialization;
using Sedulous.VFS;

/// Resource manager for .prefab files.
/// Loads prefab metadata (exposed parameters) on first load.
/// Full entity instantiation happens at runtime via `LoadPrefabIntoScene`.
class PrefabResourceManager : ResourceManager<PrefabResource>
{
	private ComponentTypeRegistry mTypeRegistry;
	private ISerializerProvider mSerializerProvider;

	public this(ComponentTypeRegistry typeRegistry, ISerializerProvider serializerProvider)
	{
		mTypeRegistry = typeRegistry;
		mSerializerProvider = serializerProvider;
	}

	protected override Result<PrefabResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
	{
		let text = scope String();
		Try!(ReadAllText(ctx.Stream, text));

		let reader = mSerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.ReadError);
		defer delete reader;

		let resource = new PrefabResource();
		resource.TypeRegistry = mTypeRegistry;
		// Scene is null - LoadParametersOnly is called by OnSerialize.
		resource.Serialize(reader);
		resource.AddRef();
		return .Ok(resource);
	}

	public override void Unload(PrefabResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(PrefabResource resource, ResourceLoadContext ctx)
	{
		// The cached PrefabResource is header-only (Scene == null). On hot-reload
		// we don't need to re-read the header - just signal success so the resource
		// system increments the generation and fires OnResourceReloaded. The actual
		// entity re-instantiation is handled by PrefabRebuilder.
		return .Ok;
	}

	/// Re-reads the prefab from `mount`/`locator` and instantiates its entities
	/// into the provided `scene`. The scene should already have component
	/// managers injected.
	public Result<void> LoadPrefabIntoScene(PrefabResource resource, Scene scene, IMount mount, StringView locator)
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

		resource.Scene = scene;
		resource.TypeRegistry = mTypeRegistry;
		resource.Serialize(reader);
		resource.Scene = null;

		return .Ok;
	}

	/// Saves a prefab through a writable mount. If an existing entry is at the
	/// target locator, preserves its GUID.
	public Result<Guid> SavePrefab(Scene scene, IWritableMount mount, StringView locator)
	{
		let resource = scope PrefabResource();
		resource.Scene = scene;
		resource.TypeRegistry = mTypeRegistry;

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
						let existingRes = scope PrefabResource();
						existingRes.Serialize(reader);
						if (existingRes.Id != .Empty)
							resource.Id = existingRes.Id;
						delete reader;
					}
				}
			}
		}

		let name = scope String();
		Path.GetFileNameWithoutExtension(locator, name);
		resource.Name = name;
		let locatorStr = scope String(locator);
		resource.SourcePath = locatorStr;

		let memStream = scope MemoryStream();
		if (resource.WriteToStream(memStream, mSerializerProvider) case .Err)
			return .Err;
		memStream.Position = 0;

		if (mount.Save(locator, memStream) case .Err)
			return .Err;

		return .Ok(resource.Id);
	}
}
