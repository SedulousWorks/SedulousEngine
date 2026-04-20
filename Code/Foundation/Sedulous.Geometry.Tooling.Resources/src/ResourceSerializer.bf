using System;
using System.IO;
using System.Collections;
using Sedulous.Serialization;
using Sedulous.Core.Mathematics;
using Sedulous.Geometry;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Geometry.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Materials.Resources;
using Sedulous.Resources;
using Sedulous.Geometry.Tooling;

namespace Sedulous.Geometry.Tooling.Resources;

/// Serializes renderer resources to files.
/// Converts ModelImportResult (plain data types) to resources, then saves.
/// Loading is handled by the resource managers - use ResourceSystem.Load<T>().
static class ResourceSerializer
{
	public const int32 CurrentVersion = 1;

	// ===== Save methods =====

	public static Result<void> SaveStaticMesh(StaticMeshResource resource, StringView path, ISerializerProvider provider)
	{
		return resource?.SaveToFile(path, provider) ?? .Err;
	}

	public static Result<void> SaveSkinnedMesh(SkinnedMeshResource resource, StringView path, ISerializerProvider provider)
	{
		return resource?.SaveToFile(path, provider) ?? .Err;
	}

	public static Result<void> SaveSkeleton(SkeletonResource resource, StringView path, ISerializerProvider provider)
	{
		return resource?.SaveToFile(path, provider) ?? .Err;
	}

	public static Result<void> SaveAnimation(AnimationClipResource resource, StringView path, ISerializerProvider provider)
	{
		return resource?.SaveToFile(path, provider) ?? .Err;
	}

	public static Result<void> SaveMaterial(MaterialResource material, StringView path, ISerializerProvider provider)
	{
		return material?.SaveToFile(path, provider) ?? .Err;
	}

	public static Result<void> SaveTexture(TextureResource resource, StringView path, ISerializerProvider provider)
	{
		return resource?.SaveToFile(path, provider) ?? .Err;
	}

	// ===== Batch operations =====

	/// Save all resources from a ResourceImportResult to a directory.
	public static Result<void> SaveImportResult(ResourceImportResult result, StringView outputDir, ISerializerProvider provider)
	{
		// Ensure directory exists
		if (!Directory.Exists(outputDir))
		{
			if (Directory.CreateDirectory(outputDir) case .Err)
				return .Err;
		}

		for (let tex in result.Textures)
		{
			let path = scope String();
			path.AppendF("{}/{}.texture", outputDir, tex.Name);
			SanitizePath(path);
			SaveTexture(tex, path, provider);
		}

		for (let mat in result.Materials)
		{
			let path = scope String();
			path.AppendF("{}/{}.material", outputDir, mat.Name);
			SanitizePath(path);
			SaveMaterial(mat, path, provider);
		}

		for (let mesh in result.StaticMeshes)
		{
			let path = scope String();
			path.AppendF("{}/{}.mesh", outputDir, mesh.Name);
			SanitizePath(path);
			SaveStaticMesh(mesh, path, provider);
		}

		for (let mesh in result.SkinnedMeshes)
		{
			let path = scope String();
			path.AppendF("{}/{}.skinnedmesh", outputDir, mesh.Name);
			SanitizePath(path);
			SaveSkinnedMesh(mesh, path, provider);
		}

		for (let skeleton in result.Skeletons)
		{
			let path = scope String();
			path.AppendF("{}/{}.skeleton", outputDir, skeleton.Name);
			SanitizePath(path);
			SaveSkeleton(skeleton, path, provider);
		}

		for (let animation in result.Animations)
		{
			let path = scope String();
			path.AppendF("{}/{}.animation", outputDir, animation.Name);
			SanitizePath(path);
			SaveAnimation(animation, path, provider);
		}

		return .Ok;
	}

	/// Save all resources from a plain ModelImportResult to a directory.
	/// Converts plain data -> resources, saves to disk, and returns the ResourceImportResult
	/// (caller takes ownership - needed for registry building with GUIDs).
	public static Result<ResourceImportResult> SaveImportResult(ModelImportResult result, StringView outputDir, ISerializerProvider provider)
	{
		let resourceResult = ResourceImportResult.ConvertFrom(result);

		if (SaveImportResult(resourceResult, outputDir, provider) case .Err)
		{
			delete resourceResult;
			return .Err;
		}

		return .Ok(resourceResult);
	}

	public static void SanitizePath(String path)
	{
		path.Replace("\\", "/");
		for (int i = 0; i < path.Length; i++)
		{
			char8 c = path[i];
			if (c == '<'
				|| c == '>'
				|| c == '"'
				|| c == '|'
				|| c == '?'
				|| c == '*')
			{
				path[i] = '_';
			}
		}
	}
}
