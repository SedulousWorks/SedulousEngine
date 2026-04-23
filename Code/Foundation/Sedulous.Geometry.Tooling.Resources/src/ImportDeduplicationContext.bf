namespace Sedulous.Geometry.Tooling.Resources;

using System;
using System.Collections;
using Sedulous.Textures.Resources;
using Sedulous.Materials.Resources;

/// Shared context for deduplicating resources across multiple model imports.
/// Pass the same instance to multiple ResourceImportResult.ConvertFrom() calls
/// to avoid creating duplicate TextureResource and MaterialResource objects
/// when models share the same textures and materials.
///
/// Does NOT own resources -- the ResourceImportResult that first created them does.
/// Caller must ensure results outlive or are cleaned up before the context.
class ImportDeduplicationContext
{
	/// Texture cache: source path -> TextureResource.
	private Dictionary<String, TextureResource> mTextures = new .() ~ {
		for (let kv in _) delete kv.key;
		delete _;
	};

	/// Material cache: material name -> MaterialResource.
	private Dictionary<String, MaterialResource> mMaterials = new .() ~ {
		for (let kv in _) delete kv.key;
		delete _;
	};

	/// Tries to find a cached texture by source path.
	/// Returns null if not found or if key is empty.
	public TextureResource FindTexture(StringView sourcePath)
	{
		if (sourcePath.IsEmpty) return null;
		if (mTextures.TryGetValue(scope String(sourcePath), let tex))
			return tex;
		return null;
	}

	/// Registers a texture by source path for future lookups.
	public void RegisterTexture(StringView sourcePath, TextureResource texture)
	{
		if (sourcePath.IsEmpty || texture == null) return;
		if (!mTextures.ContainsKey(scope String(sourcePath)))
			mTextures[new String(sourcePath)] = texture;
	}

	/// Tries to find a cached material by name.
	public MaterialResource FindMaterial(StringView name)
	{
		if (name.IsEmpty) return null;
		if (mMaterials.TryGetValue(scope String(name), let mat))
			return mat;
		return null;
	}

	/// Registers a material by name for future lookups.
	public void RegisterMaterial(StringView name, MaterialResource material)
	{
		if (name.IsEmpty || material == null) return;
		if (!mMaterials.ContainsKey(scope String(name)))
			mMaterials[new String(name)] = material;
	}

	/// Releases refs on all tracked textures and materials.
	/// Call during shutdown after resources are no longer needed.
	public void ReleaseAllRefs()
	{
		for (let kv in mTextures)
			kv.value?.ReleaseRef();
		for (let kv in mMaterials)
			kv.value?.ReleaseRef();
	}
}
