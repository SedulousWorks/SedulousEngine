namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Resources;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Imaging;
using Sedulous.Core.Mathematics;

/// Shared resource resolution service for render component managers.
/// Resolves ResourceRefs to loaded resources, uploads to GPU, creates MaterialInstances.
/// Handles first load, deferred retry, and hot reload detection via ResolvedResource<T>.
///
/// Used by MeshComponentManager, SkinnedMeshComponentManager, DecalComponentManager, etc.
/// Lives on RenderSubsystem, injected into component managers.
class RenderResourceResolver
{
	private ResourceSystem mResourceSystem;
	private GPUResourceManager mGPUResources;
	private MaterialSystem mMaterialSystem;

	/// Texture cache — same TextureResource maps to one GPU handle.
	private Dictionary<TextureResource, GPUTextureHandle> mTextureCache = new .() ~ delete _;

	// ==================== Setup ====================

	public this(ResourceSystem resourceSystem, GPUResourceManager gpuResources, MaterialSystem materialSystem)
	{
		mResourceSystem = resourceSystem;
		mGPUResources = gpuResources;
		mMaterialSystem = materialSystem;
	}

	public ResourceSystem ResourceSystem => mResourceSystem;

	// ==================== Mesh Resolution ====================

	/// Resolves a static mesh ResourceRef and uploads to GPU if changed.
	/// Returns true if the mesh was (re)uploaded. Sets outHandle and outBounds.
	public bool ResolveMesh(ref ResolvedResource<StaticMeshResource> state, ResourceRef meshRef,
		out GPUMeshHandle outHandle, out BoundingBox outBounds)
	{
		outHandle = .Invalid;
		outBounds = .(.Zero, .Zero);

		if (!state.Resolve(mResourceSystem, meshRef))
			return false;

		let meshResource = state.Handle.Resource;
		if (meshResource?.Mesh == null)
			return false;

		let mesh = meshResource.Mesh;
		let handle = UploadStaticMesh(mesh);
		if (handle.IsValid)
		{
			outHandle = handle;
			outBounds = mesh.GetBounds();
			return true;
		}

		return false;
	}

	/// Resolves a skinned mesh ResourceRef and uploads to GPU if changed.
	public bool ResolveSkinnedMesh(ref ResolvedResource<SkinnedMeshResource> state, ResourceRef meshRef,
		out GPUMeshHandle outHandle, out BoundingBox outBounds)
	{
		outHandle = .Invalid;
		outBounds = .(.Zero, .Zero);

		if (!state.Resolve(mResourceSystem, meshRef))
			return false;

		let meshResource = state.Handle.Resource;
		if (meshResource?.Mesh == null)
			return false;

		let mesh = meshResource.Mesh;
		let handle = UploadSkinnedMesh(mesh);
		if (handle.IsValid)
		{
			outHandle = handle;
			outBounds = mesh.Bounds;
			return true;
		}

		return false;
	}

	// ==================== Material Resolution ====================

	/// Resolves a material ResourceRef, creates a MaterialInstance, and resolves its textures.
	/// Returns true if the material was (re)created.
	public bool ResolveMaterial(ref ResolvedResource<MaterialResource> state, ResourceRef matRef,
		out MaterialInstance outInstance)
	{
		outInstance = null;

		if (!state.Resolve(mResourceSystem, matRef))
			return false;

		let matResource = state.Handle.Resource;
		if (matResource == null)
			return false;

		// Create MaterialInstance from MaterialResource
		let material = matResource.Material;
		if (material == null)
			return false;

		let instance = new MaterialInstance(material);

		// Resolve texture refs from the MaterialResource and set on the instance
		ResolveTextureRefs(matResource, instance);

		// Prepare bind group via MaterialSystem
		mMaterialSystem.PrepareInstance(instance);

		outInstance = instance;
		return true;
	}

	/// Prepares a dirty MaterialInstance (creates/updates uniform buffer and bind group).
	/// Called automatically by component managers for both resolved and manually-set materials.
	public void PrepareMaterial(MaterialInstance instance)
	{
		mMaterialSystem.PrepareInstance(instance);
	}

	/// Releases GPU resources for a MaterialInstance (uniform buffer, bind group).
	/// Called by component managers when a material is replaced or the entity is destroyed.
	public void ReleaseMaterial(MaterialInstance instance)
	{
		if (instance != null)
			mMaterialSystem.ReleaseInstance(instance);
	}

	// ==================== Texture Resolution ====================

	/// Resolves a standalone texture ResourceRef and returns its GPU texture view.
	/// Uploads on first load and caches; subsequent calls return the cached view.
	/// Used by sprites and other systems that need direct texture access outside
	/// of a Material's texture slots.
	public bool ResolveTexture(ref ResolvedResource<TextureResource> state, ResourceRef texRef, out ITextureView outView)
	{
		outView = null;

		if (!state.Resolve(mResourceSystem, texRef))
			return false;

		let texResource = state.Handle.Resource;
		if (texResource?.Image == null)
			return false;

		// Check texture cache.
		if (mTextureCache.TryGetValue(texResource, let gpuHandle))
		{
			let gpuTex = mGPUResources.GetTexture(gpuHandle);
			if (gpuTex != null)
			{
				outView = gpuTex.DefaultView;
				return true;
			}
		}

		// Upload.
		let uploadResult = UploadTexture(texResource.Image);
		if (!uploadResult.IsValid)
			return false;

		mTextureCache[texResource] = uploadResult;
		let gpuTex = mGPUResources.GetTexture(uploadResult);
		if (gpuTex == null) return false;
		outView = gpuTex.DefaultView;
		return true;
	}

	/// Resolves texture references from a MaterialResource and sets them on a MaterialInstance.
	/// Loads each TextureResource, uploads to GPU (cached), and binds to the material instance.
	private void ResolveTextureRefs(MaterialResource matResource, MaterialInstance matInstance)
	{
		for (let kv in matResource.TextureRefs)
		{
			let slotName = kv.key;
			let texRef = kv.value;

			if (!texRef.IsValid)
				continue;

			if (mResourceSystem.LoadByRef<TextureResource>(texRef) case .Ok(var texHandle))
			{
				let texResource = texHandle.Resource;
				if (texResource?.Image == null)
				{
					texHandle.Release();
					continue;
				}

				// Check texture cache
				ITextureView view = null;
				if (mTextureCache.TryGetValue(texResource, let gpuHandle))
				{
					let gpuTex = mGPUResources.GetTexture(gpuHandle);
					if (gpuTex != null)
						view = gpuTex.DefaultView;
				}
				else
				{
					// Upload to GPU
					let image = texResource.Image;
					let uploadResult = UploadTexture(image);
					if (uploadResult.IsValid)
					{
						mTextureCache[texResource] = uploadResult;
						let gpuTex = mGPUResources.GetTexture(uploadResult);
						if (gpuTex != null)
							view = gpuTex.DefaultView;
					}
				}

				if (view != null)
					matInstance.SetTexture(slotName, view);

				texHandle.Release();
			}
		}
	}

	// ==================== GPU Upload Helpers ====================

	private GPUMeshHandle UploadStaticMesh(StaticMesh mesh)
	{
		let vertexDataSize = (uint64)(mesh.VertexCount * mesh.VertexSize);
		let indices = mesh.Indices;
		let hasIndices = indices != null && indices.IndexCount > 0;
		let indexSize = hasIndices ? (indices.Format == .UInt16 ? 2 : 4) : 0;
		let indexDataSize = hasIndices ? (uint64)(indices.IndexCount * indexSize) : 0;

		GPUSubMesh[] subMeshes = null;
		if (mesh.SubMeshes != null && mesh.SubMeshes.Count > 0)
		{
			subMeshes = scope :: GPUSubMesh[mesh.SubMeshes.Count];
			for (int i = 0; i < mesh.SubMeshes.Count; i++)
			{
				let sub = mesh.SubMeshes[i];
				subMeshes[i] = .()
				{
					IndexStart = (uint32)sub.startIndex,
					IndexCount = (uint32)sub.indexCount,
					BaseVertex = 0,
					MaterialSlot = (uint32)sub.materialIndex
				};
			}
		}

		MeshUploadDesc desc = .()
		{
			VertexData = mesh.GetVertexData(),
			VertexDataSize = vertexDataSize,
			VertexCount = (uint32)mesh.VertexCount,
			VertexStride = (uint32)mesh.VertexSize,
			IndexData = hasIndices ? mesh.GetIndexData() : null,
			IndexDataSize = indexDataSize,
			IndexCount = hasIndices ? (uint32)indices.IndexCount : 0,
			IndexFormat = hasIndices && indices.Format == .UInt16 ? .UInt16 : .UInt32,
			SubMeshes = (subMeshes != null) ? subMeshes.Ptr : null,
			SubMeshCount = (subMeshes != null) ? (uint32)subMeshes.Count : 0,
			Bounds = mesh.GetBounds()
		};

		if (mGPUResources.UploadMesh(desc) case .Ok(let handle))
			return handle;

		return .Invalid;
	}

	private GPUMeshHandle UploadSkinnedMesh(SkinnedMesh mesh)
	{
		let vertexDataSize = (uint64)(mesh.VertexCount * mesh.VertexSize);
		let indices = mesh.Indices;
		let hasIndices = indices != null && indices.IndexCount > 0;
		let indexSize = hasIndices ? (indices.Format == .UInt16 ? 2 : 4) : 0;
		let indexDataSize = hasIndices ? (uint64)(indices.IndexCount * indexSize) : 0;

		GPUSubMesh[] subMeshes = null;
		if (mesh.SubMeshes != null && mesh.SubMeshes.Count > 0)
		{
			subMeshes = scope :: GPUSubMesh[mesh.SubMeshes.Count];
			for (int i = 0; i < mesh.SubMeshes.Count; i++)
			{
				let sub = mesh.SubMeshes[i];
				subMeshes[i] = .()
				{
					IndexStart = (uint32)sub.startIndex,
					IndexCount = (uint32)sub.indexCount,
					BaseVertex = 0,
					MaterialSlot = (uint32)sub.materialIndex
				};
			}
		}

		MeshUploadDesc desc = .()
		{
			VertexData = mesh.GetVertexData(),
			VertexDataSize = vertexDataSize,
			VertexCount = (uint32)mesh.VertexCount,
			VertexStride = (uint32)mesh.VertexSize,
			IndexData = hasIndices ? mesh.GetIndexData() : null,
			IndexDataSize = indexDataSize,
			IndexCount = hasIndices ? (uint32)indices.IndexCount : 0,
			IndexFormat = hasIndices && indices.Format == .UInt16 ? .UInt16 : .UInt32,
			SubMeshes = (subMeshes != null) ? subMeshes.Ptr : null,
			SubMeshCount = (subMeshes != null) ? (uint32)subMeshes.Count : 0,
			Bounds = mesh.Bounds,
			IsSkinned = true
		};

		if (mGPUResources.UploadMesh(desc) case .Ok(let handle))
			return handle;

		return .Invalid;
	}

	private GPUTextureHandle UploadTexture(Image image)
	{
		let format = ImageFormatToTextureFormat(image.Format);
		let bytesPerPixel = Image.GetBytesPerPixel(image.Format);

		TextureUploadDesc desc = .()
		{
			PixelData = image.Data.Ptr,
			PixelDataSize = (uint64)image.Data.Length,
			Width = image.Width,
			Height = image.Height,
			DepthOrArrayLayers = 1,
			MipLevels = 1,
			Format = format,
			Dimension = .Texture2D,
			BytesPerRow = image.Width * (uint32)bytesPerPixel,
			RowsPerImage = image.Height
		};

		if (mGPUResources.UploadTexture(desc) case .Ok(let handle))
			return handle;

		return .Invalid;
	}

	private static TextureFormat ImageFormatToTextureFormat(Image.PixelFormat format)
	{
		switch (format)
		{
		case .RGBA8: return .RGBA8Unorm;
		case .RGBA32F: return .RGBA32Float;
		case .RGB32F: return .RGBA32Float; // Will need conversion
		case .R8: return .R8Unorm;
		case .RG8: return .RG8Unorm;
		case .R32F: return .R32Float;
		case .RG32F: return .RG32Float;
		default: return .RGBA8Unorm;
		}
	}
}
