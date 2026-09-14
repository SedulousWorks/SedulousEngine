using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Model.Resource;
using Sedulous.Physics.Pipeline;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter;

/// One collision shape per STATIC mesh, which the generated prefab wires colliders from.
///
/// Skinned meshes get none: what they collide as follows the pose, and a shape cooked from the
/// bind pose would be wrong the moment anything animated.
static class ModelImportCollision
{
	private const String cAssetType = "Sedulous.Physics.Pipeline.CollisionShapeAsset";

	/// Fills the manifest's collision array, parallel to its meshes, with an empty identity
	/// where a mesh gets no shape.
	public static void Import(Group group, ModelManifestSource manifest, bool convex,
		List<String> claimed, ImportOptions options, List<String> meshSourceNames)
	{
		for (int i < manifest.MeshGuid.Count)
		{
			if (manifest.MeshSkinned[i] || (manifest.MeshGuid[i] == Guid.Empty))
			{
				manifest.CollisionGuid.Add(.Empty);
				continue;
			}

			// The plan key is the MESH's source name, which is stable under a rename: the
			// created name below still derives from the live mesh instance, so renaming a mesh
			// cascades to its shape without the decision about it being lost.
			let key = scope String(i < meshSourceNames.Count ? meshSourceNames[i] : "mesh");
			key.Append(".collision");
			if (!options.SelectionEnabled(.Collision, key))
			{
				manifest.CollisionGuid.Add(.Empty);
				continue;
			}

			Instance meshInstance = null;
			for (let candidate in group.Instances)
			{
				if (candidate.Id == manifest.MeshGuid[i])
				{
					meshInstance = candidate;
					break;
				}
			}

			let name = scope String((meshInstance != null) ? meshInstance.Name : "mesh");
			name.Append(".collision");
			let renamed = options.SelectionName(.Collision, key);
			if (renamed != key)
				name.Set(renamed); // an explicit rename beats the derived name

			let instance = ClaimedInstances.Claim(group, name, cAssetType, claimed);
			if (instance == null)
			{
				manifest.CollisionGuid.Add(.Empty);
				continue;
			}

			let asset = scope CollisionShapeAsset();
			asset.SourceMesh = manifest.MeshGuid[i];
			asset.Cook = convex ? .ConvexHull : .TriangleMesh;
			manifest.CollisionGuid.Add((instance.WriteObject(asset) case .Ok) ? instance.Id
				: Guid.Empty);
		}
	}
}
